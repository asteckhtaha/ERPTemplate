using System.Data;
using Microsoft.Data.SqlClient;

namespace ERPTemplate.API.Helpers
{
    /// <summary>
    /// Centralizes <c>ErrorLogs</c> creation for application exceptions.
    /// <para>
    /// It writes to the approved <c>ErrorLogs</c> table through <c>dbo.usp_ErrorLog_Create</c> and is the
    /// logging mechanism only — it is <b>not</b> the application's exception-handling system. The future
    /// central exception middleware decides the HTTP response and calls
    /// <see cref="LogAsync(ErrorLogEntry, CancellationToken)"/> once, so no duplicated try/catch logging
    /// is spread across the codebase.
    /// </para>
    /// <para>
    /// Concurrency: one asynchronous stored-procedure call per error through <see cref="DbHelper"/>, with a
    /// per-call connection. No shared connection, no lock, no background queue. The original exception is
    /// never swallowed or converted into a fake success — failures from this helper propagate to the caller.
    /// </para>
    /// </summary>
    public sealed class ErrorLogHelper
    {
        /// <summary>Stored procedure that inserts one <c>ErrorLogs</c> row (sets IsActive = 1, IsDeleted = 0).</summary>
        public const string CreateProcedureName = "usp_ErrorLog_Create";

        /// <summary>Default <c>ErrorCode</c> used when the caller does not supply a specific code.</summary>
        public const string DefaultErrorCode = "UNHANDLED_ERROR";

        /// <summary>Default <c>ErrorType</c> used when no module/type classification is supplied.</summary>
        public const string DefaultErrorType = "APPLICATION";

        private const int MaxErrorCode = 50;
        private const int MaxErrorType = 100;
        private const int MaxSeverity = 20;
        private const int MaxStatus = 20;
        private const int MaxModuleName = 100;
        private const int MaxPageName = 150;
        private const int MaxMethodName = 200;
        private const int MaxExceptionType = 500;

        private readonly DbHelper _dbHelper;
        private readonly TenantHelper _tenantHelper;
        private readonly SecurityHelper _securityHelper;

        public ErrorLogHelper(DbHelper dbHelper, TenantHelper tenantHelper, SecurityHelper securityHelper)
        {
            _dbHelper = dbHelper ?? throw new ArgumentNullException(nameof(dbHelper));
            _tenantHelper = tenantHelper ?? throw new ArgumentNullException(nameof(tenantHelper));
            _securityHelper = securityHelper ?? throw new ArgumentNullException(nameof(securityHelper));
        }

        /// <summary>
        /// Writes one error record. User/company/branch and request information are taken from the current
        /// request when available; all of them are nullable, so errors from unauthenticated requests and
        /// background work can be logged as well.
        /// </summary>
        public async Task LogAsync(ErrorLogEntry entry, CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(entry);

            var context = _tenantHelper.Current;

            var parameters = new SqlParameter[]
            {
                DbHelper.Param("@ErrorCode", SecurityHelper.TrimToLength(entry.ErrorCode ?? DefaultErrorCode, MaxErrorCode), SqlDbType.VarChar, MaxErrorCode),
                DbHelper.Param("@ErrorType", SecurityHelper.TrimToLength(entry.ErrorType ?? DefaultErrorType, MaxErrorType), SqlDbType.VarChar, MaxErrorType),
                DbHelper.Param("@Severity", SecurityHelper.TrimToLength(entry.Severity, MaxSeverity), SqlDbType.VarChar, MaxSeverity),
                DbHelper.Param("@Status", SecurityHelper.TrimToLength(entry.Status, MaxStatus), SqlDbType.VarChar, MaxStatus),
                DbHelper.Param("@ModuleName", SecurityHelper.TrimToLength(entry.ModuleName, MaxModuleName), SqlDbType.VarChar, MaxModuleName),
                DbHelper.Param("@PageName", SecurityHelper.TrimToLength(entry.PageName, MaxPageName), SqlDbType.VarChar, MaxPageName),
                DbHelper.Param("@MethodName", SecurityHelper.TrimToLength(entry.MethodName, MaxMethodName), SqlDbType.VarChar, MaxMethodName),
                DbHelper.Param("@CompanyID", entry.CompanyId ?? context?.CompanyId, SqlDbType.Int),
                DbHelper.Param("@BranchID", entry.BranchId ?? context?.BranchId, SqlDbType.Int),
                DbHelper.Param("@UserID", entry.UserId ?? context?.UserId, SqlDbType.Int),
                DbHelper.Param("@ExceptionType", SecurityHelper.TrimToLength(entry.ExceptionType, MaxExceptionType), SqlDbType.VarChar, MaxExceptionType),
                DbHelper.Param("@ErrorMessage", entry.ErrorMessage ?? string.Empty, SqlDbType.NVarChar, DbHelper.MaxSize),
                DbHelper.Param("@StackTrace", entry.StackTrace, SqlDbType.NVarChar, DbHelper.MaxSize),
                DbHelper.Param("@InnerException", entry.InnerException, SqlDbType.NVarChar, DbHelper.MaxSize),
                DbHelper.Param("@RequestURL", entry.RequestUrl ?? _securityHelper.GetRequestUrl(), SqlDbType.NVarChar, 1000),
                DbHelper.Param("@RequestMethod", entry.RequestMethod ?? _securityHelper.GetRequestMethod(), SqlDbType.VarChar, 20),
                DbHelper.Param("@RequestDataJson", entry.RequestDataJson, SqlDbType.NVarChar, DbHelper.MaxSize),
                DbHelper.Param("@IPAddress", _securityHelper.GetClientIpAddress(), SqlDbType.VarChar, 45),
                DbHelper.Param("@UserAgent", _securityHelper.GetUserAgent(), SqlDbType.NVarChar, 1000),
                DbHelper.Param("@CorrelationID", entry.CorrelationId ?? _securityHelper.GetOrCreateCorrelationId(), SqlDbType.UniqueIdentifier),
                DbHelper.Param("@OccurredDate", entry.OccurredDate ?? DateTimeHelper.UtcNow, SqlDbType.DateTime2)
            };

            await _dbHelper.ExecuteNonQueryAsync(CreateProcedureName, parameters, cancellationToken).ConfigureAwait(false);
        }

        /// <summary>
        /// Builds an entry from an exception, filling the columns the approved schema provides for it
        /// (<c>ExceptionType</c>, <c>ErrorMessage</c>, <c>StackTrace</c>, <c>InnerException</c>).
        /// Request and user information is added by <see cref="LogAsync(ErrorLogEntry, CancellationToken)"/>.
        /// </summary>
        public static ErrorLogEntry FromException(
            Exception exception,
            string? errorCode = null,
            string? errorType = null,
            string? moduleName = null,
            string? pageName = null,
            string? methodName = null)
        {
            ArgumentNullException.ThrowIfNull(exception);

            return new ErrorLogEntry(SeverityLevels.Error)
            {
                ErrorCode = errorCode ?? DefaultErrorCode,
                ErrorType = errorType ?? DefaultErrorType,
                ModuleName = moduleName,
                PageName = pageName,
                MethodName = methodName ?? exception.TargetSite?.Name,
                ExceptionType = exception.GetType().FullName,
                ErrorMessage = exception.Message,
                StackTrace = exception.StackTrace,
                InnerException = exception.InnerException?.ToString()
            };
        }

        /// <summary>
        /// One error record. <paramref name="severity"/> is required by convention; the helper supplies the
        /// approved defaults for <c>ErrorCode</c>, <c>ErrorType</c>, <c>Status</c> and <c>OccurredDate</c>.
        /// </summary>
        public sealed record ErrorLogEntry(string Severity)
        {
            /// <summary>Application error code (<c>VARCHAR(50)</c>); defaults to <see cref="DefaultErrorCode"/>.</summary>
            public string? ErrorCode { get; init; }

            /// <summary>Error classification (<c>VARCHAR(100)</c>); defaults to <see cref="DefaultErrorType"/>.</summary>
            public string? ErrorType { get; init; }

            /// <summary>
            /// Workflow status (<c>VARCHAR(20)</c>).
            /// Defaults to <c>NEW</c>, the first state of the approved workflow
            /// (NEW → ACKNOWLEDGED → IN_PROGRESS → RESOLVED → CLOSED) enforced by <c>CK_ErrorLogs_Status</c>.
            /// </summary>
            public string Status { get; init; } = Statuses.New;

            /// <summary>Module where the error happened.</summary>
            public string? ModuleName { get; init; }

            /// <summary>Page/screen where the error happened.</summary>
            public string? PageName { get; init; }

            /// <summary>Method/operation where the error happened.</summary>
            public string? MethodName { get; init; }

            /// <summary>Full type name of the exception.</summary>
            public string? ExceptionType { get; init; }

            /// <summary>Exception message (<c>NVARCHAR(MAX)</c>).</summary>
            public string? ErrorMessage { get; init; }

            /// <summary>Exception stack trace (<c>NVARCHAR(MAX)</c>).</summary>
            public string? StackTrace { get; init; }

            /// <summary>Formatted inner exception (<c>NVARCHAR(MAX)</c>).</summary>
            public string? InnerException { get; init; }

            /// <summary>Request URL; defaults to the current request URL.</summary>
            public string? RequestUrl { get; init; }

            /// <summary>HTTP method; defaults to the current request method.</summary>
            public string? RequestMethod { get; init; }

            /// <summary>Sanitized request payload — never include passwords, tokens or other secrets.</summary>
            public string? RequestDataJson { get; init; }

            /// <summary>UTC timestamp; defaults to "now" in UTC.</summary>
            public DateTime? OccurredDate { get; init; }

            /// <summary>Correlation id; defaults to the current request's correlation id.</summary>
            public Guid? CorrelationId { get; init; }

            /// <summary>Overrides the authenticated user (system/background operations only).</summary>
            public int? UserId { get; init; }

            /// <summary>Overrides the company of the authenticated context (system operations only).</summary>
            public int? CompanyId { get; init; }

            /// <summary>Overrides the branch of the authenticated context (system operations only).</summary>
            public int? BranchId { get; init; }
        }

        /// <summary><c>ErrorLogs.Severity</c> values (VARCHAR(20), no CHECK constraint in the schema).</summary>
        public static class SeverityLevels
        {
            public const string Information = "INFORMATION";
            public const string Warning = "WARNING";
            public const string Error = "ERROR";
            public const string Critical = "CRITICAL";
        }

        /// <summary><c>ErrorLogs.Status</c> values — the approved workflow, enforced by <c>CK_ErrorLogs_Status</c>.</summary>
        public static class Statuses
        {
            public const string New = "NEW";
            public const string Acknowledged = "ACKNOWLEDGED";
            public const string InProgress = "IN_PROGRESS";
            public const string Resolved = "RESOLVED";
            public const string Closed = "CLOSED";
        }
    }
}
