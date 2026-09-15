namespace ERPTemplate.API.Helpers
{
    /// <summary>
    /// Provides the trusted multi-company / multi-branch context of the current request.
    /// <para>
    /// The context is built exclusively from the authenticated principal's claims — never from route
    /// values, query strings, headers or request bodies. A client-supplied <c>CompanyID</c>/<c>BranchID</c>/
    /// <c>UserID</c> is never used as an authority; it may only be validated against this context elsewhere.
    /// </para>
    /// <para>
    /// Concurrency: the helper holds no request state at all. The context is materialised from
    /// <see cref="IHttpContextAccessor"/> on each access, so concurrent requests can never see each other's
    /// company/branch (no static mutable fields are used).
    /// </para>
    /// </summary>
    public sealed class TenantHelper
    {
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly SecurityHelper _securityHelper;

        public TenantHelper(IHttpContextAccessor httpContextAccessor, SecurityHelper securityHelper)
        {
            _httpContextAccessor = httpContextAccessor
                ?? throw new ArgumentNullException(nameof(httpContextAccessor));
            _securityHelper = securityHelper ?? throw new ArgumentNullException(nameof(securityHelper));
        }

        /// <summary>True when the current request carries an authenticated principal.</summary>
        public bool IsAuthenticated => _securityHelper.IsAuthenticated;

        /// <summary>
        /// Current tenant context, or <c>null</c> when the request is not authenticated.
        /// A token without a valid <c>user_id</c> claim is treated as not authenticated.
        /// </summary>
        public TenantContext? Current
        {
            get
            {
                var principal = _httpContextAccessor.HttpContext?.User;

                var userId = SecurityHelper.GetInt32ClaimValue(principal, SecurityHelper.AppClaims.UserId);
                if (userId is null or <= 0)
                {
                    return null;
                }

                return new TenantContext(
                    UserId: userId.Value,
                    CompanyId: SecurityHelper.GetInt32ClaimValue(principal, SecurityHelper.AppClaims.CompanyId),
                    BranchId: SecurityHelper.GetInt32ClaimValue(principal, SecurityHelper.AppClaims.BranchId),
                    RoleId: SecurityHelper.GetInt32ClaimValue(principal, SecurityHelper.AppClaims.RoleId),
                    UserTypeId: SecurityHelper.GetInt32ClaimValue(principal, SecurityHelper.AppClaims.UserTypeId),
                    UserName: SecurityHelper.GetClaimValue(principal, SecurityHelper.AppClaims.UserName));
            }
        }

        /// <summary>Current tenant context; throws when the request is not authenticated.</summary>
        /// <exception cref="InvalidOperationException">Thrown when there is no authenticated tenant context.</exception>
        public TenantContext GetRequired() =>
            Current ?? throw new InvalidOperationException(
                "No authenticated user context is available for the current request.");

        /// <summary>
        /// Company id of the current request (required for every company-scoped operation).
        /// </summary>
        /// <exception cref="InvalidOperationException">Thrown when the authenticated context has no company.</exception>
        public int GetRequiredCompanyId() =>
            GetRequired().CompanyId ?? throw new InvalidOperationException(
                "The authenticated user context does not contain a company ('company_id' claim).");

        /// <summary>
        /// Branch id of the current request when the page/action is branch-scoped.
        /// Returns <c>null</c> for company-level work (BranchID is nullable in the approved schema).
        /// </summary>
        public int? GetBranchId() => Current?.BranchId;
    }

    /// <summary>
    /// Immutable tenant/identity context of the authenticated request, mirroring the approved claim
    /// design (UserID, CompanyID, BranchID, RoleID, UserTypeID).
    /// </summary>
    /// <param name="UserId">Authenticated user id (<c>Users.UserID</c>).</param>
    /// <param name="CompanyId">Company the session is scoped to, when applicable.</param>
    /// <param name="BranchId">Branch the session is scoped to, when applicable.</param>
    /// <param name="RoleId">Primary role id of the session, when applicable.</param>
    /// <param name="UserTypeId">User type id (<c>UserTypes.UserTypeID</c>), when applicable.</param>
    /// <param name="UserName">Login name, for display and audit records.</param>
    public sealed record TenantContext(
        int UserId,
        int? CompanyId = null,
        int? BranchId = null,
        int? RoleId = null,
        int? UserTypeId = null,
        string? UserName = null);
}
