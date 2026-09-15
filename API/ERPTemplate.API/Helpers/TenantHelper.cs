namespace ERPTemplate.API.Helpers;

/// <summary>
/// Current multi-tenant context from the authenticated request.
/// Never trusts client-supplied IDs.
/// </summary>
public sealed class TenantHelper
{
    private readonly SecurityHelper _securityHelper;

    public TenantHelper(SecurityHelper securityHelper)
    {
        _securityHelper = securityHelper ?? throw new ArgumentNullException(nameof(securityHelper));
    }

    public int? UserId => _securityHelper.UserId;

    public int? CompanyId => _securityHelper.GetIntClaim("CompanyID");

    public int? BranchId => _securityHelper.GetIntClaim("BranchID");

    public int? RoleId => _securityHelper.GetIntClaim("RoleID");

    public int? UserTypeId => _securityHelper.GetIntClaim("UserTypeID");

    public TenantContext GetContext()
        => new(UserId, CompanyId, BranchId, RoleId, UserTypeId);
}

public sealed record TenantContext(
    int? UserId,
    int? CompanyId,
    int? BranchId,
    int? RoleId,
    int? UserTypeId);
