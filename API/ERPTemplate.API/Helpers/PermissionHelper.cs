using System.Data;
using Microsoft.Data.SqlClient;

namespace ERPTemplate.API.Helpers
{
    /// <summary>
    /// Centralizes the approved access model so permission logic is not duplicated in Controllers and Services.
    /// <para>
    /// The helper is a thin, typed caller of <c>dbo.usp_Permission_Check</c>, which evaluates the approved chain:
    /// user active AND user company access AND user branch access AND role assignment AND subscription page
    /// permission AND role page permission AND subscription action permission AND role action permission AND
    /// parent-role constraint.
    /// </para>
    /// <para>
    /// The database is the only source of truth: permissions sent by the client are never used, no
    /// permission is hardcoded here, and results are not cached (so a permission change takes effect
    /// immediately and can never become a stale, client-trusted value).
    /// </para>
    /// <para>Stateless apart from its injected dependencies: safe for concurrent requests.</para>
    /// </summary>
    public sealed class PermissionHelper
    {
        /// <summary>Stored procedure evaluated by this helper (expected in <c>Data/StoredProcedures</c>).</summary>
        public const string CheckProcedureName = "usp_Permission_Check";

        private const int MaxKeyLength = 100;
        private const int MaxReasonLength = 200;

        private readonly DbHelper _dbHelper;
        private readonly TenantHelper _tenantHelper;
        private readonly ILogger<PermissionHelper> _logger;

        public PermissionHelper(DbHelper dbHelper, TenantHelper tenantHelper, ILogger<PermissionHelper> logger)
        {
            _dbHelper = dbHelper ?? throw new ArgumentNullException(nameof(dbHelper));
            _tenantHelper = tenantHelper ?? throw new ArgumentNullException(nameof(tenantHelper));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        /// <summary>
        /// Checks one page/action permission for the current authenticated tenant context.
        /// <paramref name="userId"/>, <paramref name="companyId"/> and <paramref name="branchId"/> are
        /// optional overrides for internal/system checks; when omitted, the trusted values from the token are used.
        /// </summary>
        /// <exception cref="InvalidOperationException">Thrown when no authenticated context (or no company) is available.</exception>
        public async Task<PermissionResult> CheckAsync(
            string pageKey,
            string actionKey,
            int? userId = null,
            int? companyId = null,
            int? branchId = null,
            CancellationToken cancellationToken = default)
        {
            ArgumentException.ThrowIfNullOrWhiteSpace(pageKey);
            ArgumentException.ThrowIfNullOrWhiteSpace(actionKey);

            var context = _tenantHelper.GetRequired();
            var effectiveUserId = userId ?? context.UserId;
            var effectiveCompanyId = companyId ?? context.CompanyId
                ?? throw new InvalidOperationException(
                    "A company context is required to check permissions ('company_id' claim is missing).");
            var effectiveBranchId = branchId ?? context.BranchId;

            var parameters = new SqlParameter[]
            {
                DbHelper.Param("@UserID", effectiveUserId, SqlDbType.Int),
                DbHelper.Param("@CompanyID", effectiveCompanyId, SqlDbType.Int),
                DbHelper.Param("@BranchID", effectiveBranchId, SqlDbType.Int),
                DbHelper.Param("@PageKey", pageKey, SqlDbType.VarChar, MaxKeyLength),
                DbHelper.Param("@ActionKey", actionKey, SqlDbType.VarChar, MaxKeyLength)
            };

            var result = await _dbHelper
                .ExecuteSingleOrDefaultAsync(CheckProcedureName, MapResult, parameters, cancellationToken)
                .ConfigureAwait(false);

            if (result is null)
            {
                // Fail closed: a permission check that returns no row must never be treated as allowed.
                _logger.LogWarning(
                    "Permission check returned no result (page {PageKey}, action {ActionKey}, user {UserId}, company {CompanyId}).",
                    pageKey, actionKey, effectiveUserId, effectiveCompanyId);

                return PermissionResult.Denied("Permission could not be determined.");
            }

            return result;
        }

        /// <summary>True when the current user may perform <paramref name="actionKey"/> on the page.</summary>
        public async Task<bool> HasAsync(string pageKey, string actionKey, CancellationToken cancellationToken = default)
        {
            var result = await CheckAsync(pageKey, actionKey, cancellationToken: cancellationToken).ConfigureAwait(false);
            return result.IsAllowed;
        }

        /// <summary>True when the current user may open/view the page.</summary>
        public Task<bool> CanViewAsync(string pageKey, CancellationToken cancellationToken = default) =>
            HasAsync(pageKey, Actions.View, cancellationToken);

        /// <summary>True when the current user may create records on the page.</summary>
        public Task<bool> CanCreateAsync(string pageKey, CancellationToken cancellationToken = default) =>
            HasAsync(pageKey, Actions.Create, cancellationToken);

        /// <summary>True when the current user may update records on the page.</summary>
        public Task<bool> CanUpdateAsync(string pageKey, CancellationToken cancellationToken = default) =>
            HasAsync(pageKey, Actions.Update, cancellationToken);

        /// <summary>True when the current user may delete records on the page.</summary>
        public Task<bool> CanDeleteAsync(string pageKey, CancellationToken cancellationToken = default) =>
            HasAsync(pageKey, Actions.Delete, cancellationToken);

        /// <summary>True when the current user may export data from the page.</summary>
        public Task<bool> CanExportAsync(string pageKey, CancellationToken cancellationToken = default) =>
            HasAsync(pageKey, Actions.Export, cancellationToken);

        /// <summary>True when the current user may print from the page.</summary>
        public Task<bool> CanPrintAsync(string pageKey, CancellationToken cancellationToken = default) =>
            HasAsync(pageKey, Actions.Print, cancellationToken);

        private static PermissionResult MapResult(SqlDataReader reader)
        {
            var isAllowed = reader["IsAllowed"] is bool allowed && allowed;
            var reason = SecurityHelper.TrimToLength(reader["FailureReason"] as string, MaxReasonLength);
            return new PermissionResult(isAllowed, reason);
        }

        /// <summary>
        /// Result of a permission check. <see cref="FailureReason"/> is the step that denied access
        /// (useful for logging) and is never shown to end users as-is.
        /// </summary>
        public sealed record PermissionResult(bool IsAllowed, string? FailureReason = null)
        {
            /// <summary>Shorthand for an allowed result.</summary>
            public static PermissionResult Allowed => new(true);

            /// <summary>Creates a denied result with a reason.</summary>
            public static PermissionResult Denied(string? reason) => new(false, reason);
        }

        /// <summary>
        /// Action keys as stored in <c>SystemActions.ActionKey</c>.
        /// These values are the approved action vocabulary; they must match the seeded <c>SystemActions</c> rows.
        /// </summary>
        public static class Actions
        {
            public const string View = "VIEW";
            public const string Create = "CREATE";
            public const string Update = "UPDATE";
            public const string Delete = "DELETE";
            public const string Export = "EXPORT";
            public const string Print = "PRINT";
        }
    }
}
