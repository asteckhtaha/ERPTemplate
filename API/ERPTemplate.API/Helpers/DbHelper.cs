using System.Data;
using System.Globalization;
using Microsoft.Data.SqlClient;

namespace ERPTemplate.API.Helpers
{
    /// <summary>
    /// Central low-level ADO.NET execution layer for SQL Server stored procedures.
    /// <para>
    /// Responsibilities: create connections, build <see cref="CommandType.StoredProcedure"/> commands,
    /// add parameters safely (null becomes <see cref="DBNull"/>), execute asynchronously and dispose
    /// every ADO.NET object. It contains no business logic and no SQL text.
    /// </para>
    /// <para>
    /// Concurrency: every call opens its own connection from the connection pool and uses its own
    /// command/reader. Nothing is stored in static or shared mutable state, so concurrent API requests
    /// run independently and never block each other. Never share a <see cref="SqlConnection"/>,
    /// <see cref="SqlCommand"/>, <see cref="SqlDataReader"/>, <see cref="SqlTransaction"/> or a
    /// <see cref="SqlParameter"/> instance between requests.
    /// </para>
    /// </summary>
    public sealed class DbHelper
    {
        /// <summary>Value for <c>size</c> when the target column is <c>NVARCHAR(MAX)</c>.</summary>
        public const int MaxSize = -1;

        private const string ConnectionStringName = "Default";
        private const string CommandTimeoutKey = "Database:CommandTimeoutSeconds";
        private const int DefaultCommandTimeoutSeconds = 30;

        private readonly string _connectionString;
        private readonly int _commandTimeoutSeconds;

        /// <summary>
        /// Creates the helper and reads its configuration once.
        /// The connection string is validated at construction time so a misconfigured application fails
        /// fast instead of failing on the first request.
        /// </summary>
        /// <exception cref="InvalidOperationException">Thrown when <c>ConnectionStrings:Default</c> is missing.</exception>
        public DbHelper(IConfiguration configuration)
        {
            ArgumentNullException.ThrowIfNull(configuration);

            _connectionString = configuration.GetConnectionString(ConnectionStringName)
                ?? throw new InvalidOperationException(
                    $"Connection string 'ConnectionStrings:{ConnectionStringName}' is not configured.");

            var configuredTimeout = configuration.GetValue<int?>(CommandTimeoutKey);
            _commandTimeoutSeconds = configuredTimeout is > 0 ? configuredTimeout.Value : DefaultCommandTimeoutSeconds;
        }

        /// <summary>Command timeout (seconds) applied to every command created by this helper.</summary>
        public int CommandTimeoutSeconds => _commandTimeoutSeconds;

        // ---------------------------------------------------------------------------------------------
        // Connection / command factories
        // ---------------------------------------------------------------------------------------------

        /// <summary>
        /// Opens a pooled connection. The caller owns the returned instance and must dispose it
        /// (or use it inside <see cref="ExecuteInTransactionAsync"/>).
        /// </summary>
        public async Task<SqlConnection> OpenConnectionAsync(CancellationToken cancellationToken = default)
        {
            var connection = new SqlConnection(_connectionString);
            try
            {
                await connection.OpenAsync(cancellationToken).ConfigureAwait(false);
                return connection;
            }
            catch
            {
                await connection.DisposeAsync().ConfigureAwait(false);
                throw;
            }
        }

        /// <summary>
        /// Creates a stored-procedure command with the configured timeout and the supplied parameters.
        /// </summary>
        public SqlCommand CreateProcedureCommand(
            SqlConnection connection,
            string procedureName,
            SqlParameter[]? parameters = null,
            SqlTransaction? transaction = null)
        {
            ArgumentNullException.ThrowIfNull(connection);
            ArgumentException.ThrowIfNullOrWhiteSpace(procedureName);

            var command = connection.CreateCommand();
            command.CommandText = procedureName;
            command.CommandType = CommandType.StoredProcedure;
            command.CommandTimeout = _commandTimeoutSeconds;

            if (transaction is not null)
            {
                command.Transaction = transaction;
            }

            if (parameters is { Length: > 0 })
            {
                command.Parameters.AddRange(parameters);
            }

            return command;
        }

        // ---------------------------------------------------------------------------------------------
        // Asynchronous execution (one connection per operation - no shared connections, no blocking)
        // ---------------------------------------------------------------------------------------------

        /// <summary>Executes a stored procedure and returns the number of affected rows.</summary>
        public async Task<int> ExecuteNonQueryAsync(
            string procedureName,
            SqlParameter[]? parameters = null,
            CancellationToken cancellationToken = default)
        {
            await using var connection = await OpenConnectionAsync(cancellationToken).ConfigureAwait(false);
            await using var command = CreateProcedureCommand(connection, procedureName, parameters);

            return await command.ExecuteNonQueryAsync(cancellationToken).ConfigureAwait(false);
        }

        /// <summary>
        /// Executes a stored procedure and returns the first column of the first row
        /// (<see cref="DBNull"/> is returned as <c>null</c>).
        /// </summary>
        public async Task<object?> ExecuteScalarAsync(
            string procedureName,
            SqlParameter[]? parameters = null,
            CancellationToken cancellationToken = default)
        {
            await using var connection = await OpenConnectionAsync(cancellationToken).ConfigureAwait(false);
            await using var command = CreateProcedureCommand(connection, procedureName, parameters);

            var value = await command.ExecuteScalarAsync(cancellationToken).ConfigureAwait(false);
            return value is DBNull ? null : value;
        }

        /// <summary>Executes a stored procedure and converts the scalar result to <typeparamref name="T"/>.</summary>
        public async Task<T?> ExecuteScalarAsync<T>(
            string procedureName,
            SqlParameter[]? parameters = null,
            CancellationToken cancellationToken = default)
        {
            var value = await ExecuteScalarAsync(procedureName, parameters, cancellationToken).ConfigureAwait(false);
            return ConvertScalar<T>(value);
        }

        /// <summary>Executes a stored procedure and maps every row of the first result set.</summary>
        public async Task<List<T>> ExecuteListAsync<T>(
            string procedureName,
            Func<SqlDataReader, T> map,
            SqlParameter[]? parameters = null,
            CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(map);

            var items = new List<T>();

            await using var connection = await OpenConnectionAsync(cancellationToken).ConfigureAwait(false);
            await using var command = CreateProcedureCommand(connection, procedureName, parameters);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken).ConfigureAwait(false);

            while (await reader.ReadAsync(cancellationToken).ConfigureAwait(false))
            {
                items.Add(map(reader));
            }

            return items;
        }

        /// <summary>
        /// Executes a stored procedure and maps the first row of the first result set,
        /// or returns <c>null</c> when the procedure returned no rows.
        /// </summary>
        public async Task<T?> ExecuteSingleOrDefaultAsync<T>(
            string procedureName,
            Func<SqlDataReader, T> map,
            SqlParameter[]? parameters = null,
            CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(map);

            await using var connection = await OpenConnectionAsync(cancellationToken).ConfigureAwait(false);
            await using var command = CreateProcedureCommand(connection, procedureName, parameters);
            await using var reader = await command.ExecuteReaderAsync(cancellationToken).ConfigureAwait(false);

            if (!await reader.ReadAsync(cancellationToken).ConfigureAwait(false))
            {
                return default;
            }

            return map(reader);
        }

        /// <summary>
        /// Runs <paramref name="work"/> inside one database transaction.
        /// Use this only when several statements must succeed or fail together (for example a document
        /// plus its lines); single stored procedures own their own transaction.
        /// The original exception is always preserved: if the rollback itself fails, both exceptions are
        /// reported in an <see cref="AggregateException"/>.
        /// </summary>
        public async Task ExecuteInTransactionAsync(
            Func<SqlConnection, SqlTransaction, CancellationToken, Task> work,
            CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(work);

            await using var connection = await OpenConnectionAsync(cancellationToken).ConfigureAwait(false);
            await using var transaction =
                (SqlTransaction)await connection.BeginTransactionAsync(cancellationToken).ConfigureAwait(false);

            try
            {
                await work(connection, transaction, cancellationToken).ConfigureAwait(false);
                await transaction.CommitAsync(cancellationToken).ConfigureAwait(false);
            }
            catch (Exception originalException)
            {
                try
                {
                    await transaction.RollbackAsync(CancellationToken.None).ConfigureAwait(false);
                }
                catch (Exception rollbackException)
                {
                    throw new AggregateException(
                        "Stored procedure execution failed and the transaction rollback also failed.",
                        originalException,
                        rollbackException);
                }

                throw;
            }
        }

        // ---------------------------------------------------------------------------------------------
        // Parameter helpers
        // ---------------------------------------------------------------------------------------------

        /// <summary>Creates a parameter, converting <c>null</c> to <see cref="DBNull"/>.</summary>
        public static SqlParameter Param(string name, object? value)
        {
            ArgumentException.ThrowIfNullOrWhiteSpace(name);
            return new SqlParameter(name, value ?? DBNull.Value);
        }

        /// <summary>
        /// Creates a strongly typed parameter (recommended for <c>VARCHAR</c>/<c>NVARCHAR</c>/<c>VARBINARY</c>
        /// columns: pass the column length, or <see cref="MaxSize"/> for <c>(MAX)</c>).
        /// </summary>
        public static SqlParameter Param(string name, object? value, SqlDbType dbType, int size = 0)
        {
            ArgumentException.ThrowIfNullOrWhiteSpace(name);

            var parameter = size != 0
                ? new SqlParameter(name, dbType, size)
                : new SqlParameter(name, dbType);

            parameter.Value = value ?? DBNull.Value;
            return parameter;
        }

        // ---------------------------------------------------------------------------------------------
        // Internals
        // ---------------------------------------------------------------------------------------------

        private static T? ConvertScalar<T>(object? value)
        {
            if (value is null or DBNull)
            {
                return default;
            }

            if (value is T alreadyTyped)
            {
                return alreadyTyped;
            }

            var targetType = Nullable.GetUnderlyingType(typeof(T)) ?? typeof(T);
            return (T)Convert.ChangeType(value, targetType, CultureInfo.InvariantCulture);
        }
    }
}
