using System.Data;
using Microsoft.Data.SqlClient;

namespace ERPTemplate.API.Helpers
{
    /// <summary>
    /// Centralizes <c>ActivityLogs</c> creation (user/system activity history).
    /// <para>
    /// Answers: <i>what action did the user or system perform?</i> — for example login, logout, page view,
    /// create/update/delete, export, print or report generation. Use <see cref="AuditHelper"/> when the
    /// question is "what important data/security change was made?".
    /// </para>
    /// <para>
    /// The caller supplies the activity facts; the helper fills user/company/branch/role, request metadata
    /// and the timestamp, and inserts exactly one row through <c>dbo.usp_ActivityLog_Create</c>.
    /// </para>
    /// <para>
    /// Concurrency: one asynchronous stored-procedure call per entry through <see cref="DbHelper"/>, with a
    /// per-call connection. No shared connection, no lock and no in-memory queue, so concurrent requests do
    /// not wait for each other. Only meaningful activities should be logged; logging exceptions are never
    /// swallowed — they propagate to the caller.
    /// </para>
    /// </summary>
    public sealed class ActivityLogHelper
    {
        /// <summary>Stored procedure that inserts one <c>ActivityLogs</c> row.</summary>
        public const string CreateProcedureName = "usp_ActivityLog_Create";

        private const int MaxScopeType = 20;
        private const int MaxActivityType = 50;
        private const int MaxModuleName = 100;
        private const int MaxPageName = 150;
        private const int MaxEntityName = 150;
        private const int MaxDescription = 1000;
        private const int MaxSessionId = 200;

        private readonly DbHelper _dbHelper;
        private readonly TenantHelper _tenantHelper;
        private readonly SecurityHelper _securityHelper;

        public ActivityLogHelper(DbHelper dbHelper, TenantHelper tenantHelper, SecurityHelper securityHelper)
        {
            _dbHelper = dbHelper ?? throw new ArgumentNullException(nameof(dbHelper));
            _tenantHelper = tenantHelper ?? throw new ArgumentNullException(nameof(tenantHelper));
            _securityHelper = securityHelper ?? throw new ArgumentNullException(nameof(securityHelper));
        }

        /// <summary>
        /// Writes one activity record. The user/company/branch/role and request information are taken from
        /// the authenticated request when the entry does not override them.
        /// </summary>
        public async Task LogAsync(ActivityLogEntry entry, CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(entry);

            var context = _tenantHelper.Current;

            var parameters = new SqlParameter[]
            {
                DbHelper.Param("@ScopeType", SecurityHelper.TrimToLength(entry.ScopeType, MaxScopeType), SqlDbType.VarChar, MaxScopeType),
                DbHelper.Param("@CompanyID", entry.CompanyId ?? context?.CompanyId, SqlDbType.Int),
                DbHelper.Param("@BranchID", entry.BranchId ?? context?.BranchId, SqlDbType.Int),
                DbHelper.Param("@UserID", entry.UserId ?? context?.UserId, SqlDbType.Int),
                DbHelper.Param("@RoleID", entry.RoleId ?? context?.RoleId, SqlDbType.Int),
                DbHelper.Param("@ActivityType", SecurityHelper.TrimToLength(entry.ActivityType, MaxActivityType), SqlDbType.VarChar, MaxActivityType),
                DbHelper.Param("@ModuleName", SecurityHelper.TrimToLength(entry.ModuleName, MaxModuleName), SqlDbType.VarChar, MaxModuleName),
                DbHelper.Param("@PageName", SecurityHelper.TrimToLength(entry.PageName, MaxPageName), SqlDbType.VarChar, MaxPageName),
                DbHelper.Param("@EntityName", SecurityHelper.TrimToLength(entry.EntityName, MaxEntityName), SqlDbType.VarChar, MaxEntityName),
                DbHelper.Param("@EntityID", entry.EntityId, SqlDbType.BigInt),
                DbHelper.Param("@Description", SecurityHelper.TrimToLength(entry.Description, MaxDescription), SqlDbType.NVarChar, MaxDescription),
                DbHelper.Param("@IPAddress", _securityHelper.GetClientIpAddress(), SqlDbType.VarChar, 45),
                DbHelper.Param("@UserAgent", _securityHelper.GetUserAgent(), SqlDbType.NVarChar, 1000),
                DbHelper.Param("@RequestURL", _securityHelper.GetRequestUrl(), SqlDbType.NVarChar, 1000),
                DbHelper.Param("@SessionID", SecurityHelper.TrimToLength(entry.SessionId, MaxSessionId), SqlDbType.VarChar, MaxSessionId),
                DbHelper.Param("@CorrelationID", entry.CorrelationId ?? _securityHelper.GetOrCreateCorrelationId(), SqlDbType.UniqueIdentifier),
                DbHelper.Param("@CreatedDate", DateTimeHelper.UtcNow, SqlDbType.DateTime2)
            };

            await _dbHelper.ExecuteNonQueryAsync(CreateProcedureName, parameters, cancellationToken).ConfigureAwait(false);
        }

        /// <summary>
        /// One activity record. <paramref name="activityType"/> and <paramref name="scopeType"/> are required
        /// by the schema; everything else is optional and is filled from the current request when omitted.
        /// </summary>
        public sealed record ActivityLogEntry(string ActivityType, string ScopeType)
        {
            /// <summary>Module key/module name the activity belongs to (for example <c>Products</c>).</summary>
            public string? ModuleName { get; init; }

            /// <summary>Page the activity happened on (for example <c>ProductList</c>).</summary>
            public string? PageName { get; init; }

            /// <summary>Entity/table involved, when the activity concerns one record.</summary>
            public string? EntityName { get; init; }

            /// <summary>Primary key of the affected record (<c>ActivityLogs.EntityID</c> is <c>BIGINT</c>).</summary>
            public long? EntityId { get; init; }

            /// <summary>Optional short description of the activity.</summary>
            public string? Description { get; init; }

            /// <summary>Session identifier, when the session feature supplies one.</summary>
            public string? SessionId { get; init; }

            /// <summary>Correlation id; defaults to the current request's correlation id.</summary>
            public Guid? CorrelationId { get; init; }

            /// <summary>Overrides the authenticated user (system/background operations only).</summary>
            public int? UserId { get; init; }

            /// <summary>Overrides the company of the authenticated context (system operations only).</summary>
            public int? CompanyId { get; init; }

            /// <summary>Overrides the branch of the authenticated context (system operations only).</summary>
            public int? BranchId { get; init; }

            /// <summary>Overrides the role of the authenticated context (system operations only).</summary>
            public int? RoleId { get; init; }
        }

        /// <summary><c>ActivityLogs.ScopeType</c> values (VARCHAR(20), no CHECK constraint in the schema).</summary>
        public static class ScopeTypes
        {
            public const string System = "SYSTEM";
            public const string Company = "COMPANY";
            public const string Branch = "BRANCH";
        }

        /// <summary><c>ActivityLogs.ActivityType</c> values (VARCHAR(50)) used for activity records.</summary>
        public static class ActivityTypes
        {
            public const string Login = "LOGIN";
            public const string Logout = "LOGOUT";
            public const string PageView = "PAGE_VIEW";
            public const string Create = "CREATE";
            public const string Update = "UPDATE";
            public const string Delete = "DELETE";
            public const string Export = "EXPORT";
            public const string Print = "PRINT";
            public const string ReportGenerated = "REPORT_GENERATED";
            public const string BranchChanged = "BRANCH_CHANGED";
        }
    }
}
