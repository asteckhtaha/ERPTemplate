using System.Data;
using Microsoft.Data.SqlClient;

namespace ERPTemplate.API.Helpers
{
    /// <summary>
    /// Centralizes <c>AuditLogs</c> creation so services do not repeat audit code.
    /// <para>
    /// Answers: <i>what important data/security change was made?</i> — for example a role permission
    /// change, a product update or a settings change. Use <see cref="ActivityLogHelper"/> for
    /// user/system activity such as login, page view or export.
    /// </para>
    /// <para>
    /// The caller supplies the business facts (action, entity, old/new values); the helper fills the
    /// request context (user, company, branch, role, IP, user agent, URL, correlation id) from the
    /// authenticated request and inserts exactly one row through <c>dbo.usp_AuditLog_Create</c>.
    /// </para>
    /// <para>
    /// Concurrency: one asynchronous stored-procedure call per entry through <see cref="DbHelper"/>, with
    /// per-call connections. No shared connection, no lock and no queue, so concurrent requests never wait
    /// for each other. Exceptions are never swallowed: a failed audit insert propagates to the caller
    /// (a caller that wants best-effort logging must catch it explicitly).
    /// </para>
    /// </summary>
    public sealed class AuditHelper
    {
        /// <summary>Stored procedure that inserts one <c>AuditLogs</c> row.</summary>
        public const string CreateProcedureName = "usp_AuditLog_Create";

        private const int MaxScopeType = 20;
        private const int MaxActionType = 30;
        private const int MaxEntityName = 150;
        private const int MaxRecordDisplayName = 300;
        private const int MaxDescription = 1000;
        private const int MaxSessionId = 200;

        private readonly DbHelper _dbHelper;
        private readonly TenantHelper _tenantHelper;
        private readonly SecurityHelper _securityHelper;

        public AuditHelper(DbHelper dbHelper, TenantHelper tenantHelper, SecurityHelper securityHelper)
        {
            _dbHelper = dbHelper ?? throw new ArgumentNullException(nameof(dbHelper));
            _tenantHelper = tenantHelper ?? throw new ArgumentNullException(nameof(tenantHelper));
            _securityHelper = securityHelper ?? throw new ArgumentNullException(nameof(securityHelper));
        }

        /// <summary>
        /// Writes one audit record. The request context is taken from the authenticated token
        /// (<see cref="TenantHelper"/>) and the current HTTP request (<see cref="SecurityHelper"/>).
        /// </summary>
        public async Task LogAsync(AuditLogEntry entry, CancellationToken cancellationToken = default)
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
                DbHelper.Param("@ActionType", SecurityHelper.TrimToLength(entry.ActionType, MaxActionType), SqlDbType.VarChar, MaxActionType),
                DbHelper.Param("@EntityName", SecurityHelper.TrimToLength(entry.EntityName, MaxEntityName), SqlDbType.VarChar, MaxEntityName),
                DbHelper.Param("@EntityID", entry.EntityId, SqlDbType.BigInt),
                DbHelper.Param("@EntityGUID", entry.EntityGuid, SqlDbType.UniqueIdentifier),
                DbHelper.Param("@RecordDisplayName", SecurityHelper.TrimToLength(entry.RecordDisplayName, MaxRecordDisplayName), SqlDbType.NVarChar, MaxRecordDisplayName),
                DbHelper.Param("@OldValuesJson", entry.OldValuesJson, SqlDbType.NVarChar, DbHelper.MaxSize),
                DbHelper.Param("@NewValuesJson", entry.NewValuesJson, SqlDbType.NVarChar, DbHelper.MaxSize),
                DbHelper.Param("@ChangedColumnsJson", entry.ChangedColumnsJson, SqlDbType.NVarChar, DbHelper.MaxSize),
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
        /// One audit record. <paramref name="actionType"/>, <paramref name="entityName"/> and
        /// <paramref name="scopeType"/> are required by the schema; every other value is optional and is
        /// filled from the current request when omitted.
        /// </summary>
        public sealed record AuditLogEntry(string ActionType, string EntityName, string ScopeType)
        {
            /// <summary>Primary key of the affected record (<c>AuditLogs.EntityID</c> is <c>BIGINT</c>).</summary>
            public long? EntityId { get; init; }

            /// <summary>GUID of the affected record, when the entity has one.</summary>
            public Guid? EntityGuid { get; init; }

            /// <summary>Human-readable name of the affected record.</summary>
            public string? RecordDisplayName { get; init; }

            /// <summary>JSON snapshot before the change (write it only when it adds value).</summary>
            public string? OldValuesJson { get; init; }

            /// <summary>JSON snapshot after the change.</summary>
            public string? NewValuesJson { get; init; }

            /// <summary>JSON array of the columns that actually changed.</summary>
            public string? ChangedColumnsJson { get; init; }

            /// <summary>Optional free-text clarification for the audit reader.</summary>
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

        /// <summary><c>AuditLogs.ScopeType</c> values (VARCHAR(20), no CHECK constraint in the schema).</summary>
        public static class ScopeTypes
        {
            public const string System = "SYSTEM";
            public const string Company = "COMPANY";
            public const string Branch = "BRANCH";
        }

        /// <summary><c>AuditLogs.ActionType</c> values (VARCHAR(30)) used for audit records.</summary>
        public static class ActionTypes
        {
            public const string Insert = "INSERT";
            public const string Update = "UPDATE";
            public const string Delete = "DELETE";
            public const string Login = "LOGIN";
            public const string Logout = "LOGOUT";
            public const string PermissionChange = "PERMISSION_CHANGE";
            public const string SettingChange = "SETTING_CHANGE";
        }
    }
}
