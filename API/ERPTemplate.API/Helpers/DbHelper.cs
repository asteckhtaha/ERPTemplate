using System.Data;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace ERPTemplate.API.Helpers;

/// <summary>
/// Central low-level ADO.NET helper for SQL Server.
/// No business logic. Only connection/command execution.
/// </summary>
public sealed class DbHelper
{
    private readonly string _connectionString;

    public DbHelper(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Connection string 'DefaultConnection' is not configured.");
    }

    public SqlConnection CreateConnection() => new(_connectionString);

    public async Task<int> ExecuteNonQueryAsync(
        string procedureName,
        IEnumerable<SqlParameter>? parameters = null,
        CancellationToken cancellationToken = default)
    {
        await using var connection = CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(procedureName, connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        AddParameters(command, parameters);

        return await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<object?> ExecuteScalarAsync(
        string procedureName,
        IEnumerable<SqlParameter>? parameters = null,
        CancellationToken cancellationToken = default)
    {
        await using var connection = CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(procedureName, connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        AddParameters(command, parameters);

        var result = await command.ExecuteScalarAsync(cancellationToken);
        return result == DBNull.Value ? null : result;
    }

    public async Task<T?> ExecuteSingleAsync<T>(
        string procedureName,
        IEnumerable<SqlParameter>? parameters,
        Func<SqlDataReader, T> map,
        CancellationToken cancellationToken = default)
        where T : class
    {
        ArgumentNullException.ThrowIfNull(map);

        await using var connection = CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(procedureName, connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        AddParameters(command, parameters);

        await using var reader = await command.ExecuteReaderAsync(
            CommandBehavior.SingleRow, cancellationToken);

        if (await reader.ReadAsync(cancellationToken))
        {
            return map(reader);
        }

        return null;
    }

    public async Task<List<T>> ExecuteListAsync<T>(
        string procedureName,
        IEnumerable<SqlParameter>? parameters,
        Func<SqlDataReader, T> map,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(map);

        var results = new List<T>();

        await using var connection = CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(procedureName, connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        AddParameters(command, parameters);

        await using var reader = await command.ExecuteReaderAsync(
            CommandBehavior.SequentialAccess, cancellationToken);

        while (await reader.ReadAsync(cancellationToken))
        {
            results.Add(map(reader));
        }

        return results;
    }

    public static SqlParameter CreateParameter(
        string name,
        object? value,
        SqlDbType? dbType = null,
        int? size = null)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new ArgumentException("Parameter name is required.", nameof(name));
        }

        var parameter = new SqlParameter
        {
            ParameterName = name,
            Value = value ?? DBNull.Value
        };

        if (dbType.HasValue)
        {
            parameter.SqlDbType = dbType.Value;
        }

        if (size.HasValue)
        {
            parameter.Size = size.Value;
        }

        return parameter;
    }

    public async Task<T> ExecuteReaderAsync<T>(
    string procedureName,
    IEnumerable<SqlParameter>? parameters,
    Func<SqlDataReader, CancellationToken, Task<T>> readResults,
    CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(readResults);

        await using var connection = CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(procedureName, connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        AddParameters(command, parameters);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        return await readResults(reader, cancellationToken);
    }

    private static void AddParameters(SqlCommand command, IEnumerable<SqlParameter>? parameters)
    {
        if (parameters is null)
        {
            return;
        }

        foreach (var parameter in parameters)
        {
            if (parameter is null)
            {
                continue;
            }

            command.Parameters.Add(parameter);
        }
    }
}
