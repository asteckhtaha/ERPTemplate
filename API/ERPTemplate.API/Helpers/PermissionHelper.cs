using System.Data;

namespace ERPTemplate.API.Helpers;

/// <summary>
/// Centralized permission checks via dbo.usp_Permission_Check.
/// Database is the source of truth. Client input is never trusted.
/// </summary>
public sealed class PermissionHelper
{
    private const string ProcedureName = "dbo.usp_Permission_Check";

    private readonly DbHelper _dbHelper;
    private readonly TenantHelper _tenantHelper;

    public PermissionHelper(DbHelper dbHelper, TenantHelper tenantHelper)
    {
        _dbHelper = dbHelper ?? throw new ArgumentNullException(nameof(dbHelper));
        _tenantHelper = tenantHelper ?? throw new ArgumentNullException(nameof(tenantHelper));
    }

    public async Task<bool> HasPermissionAsync(
        string pageCode,
        string actionCode,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(pageCode))
        {
            throw new ArgumentException("Page code is required.", nameof(pageCode));
        }

        if (string.IsNullOrWhiteSpace(actionCode))
        {
            throw new ArgumentException("Action code is required.", nameof(actionCode));
        }

        var userId = _tenantHelper.UserId;
        if (!userId.HasValue)
        {
            return false;
        }

        var parameters = new[]
        {
            DbHelper.CreateParameter("@UserID", userId.Value, SqlDbType.Int),
            DbHelper.CreateParameter("@CompanyID", _tenantHelper.CompanyId, SqlDbType.Int),
            DbHelper.CreateParameter("@BranchID", _tenantHelper.BranchId, SqlDbType.Int),
            DbHelper.CreateParameter("@PageCode", pageCode, SqlDbType.VarChar, 100),
            DbHelper.CreateParameter("@ActionCode", actionCode, SqlDbType.VarChar, 50)
        };

        var result = await _dbHelper.ExecuteScalarAsync(ProcedureName, parameters, cancellationToken);

        return result switch
        {
            null => false,
            bool b => b,
            byte bt => bt == 1,
            short s => s == 1,
            int i => i == 1,
            long l => l == 1,
            _ => Convert.ToInt32(result) == 1
        };
    }

    public Task<bool> CanViewAsync(string pageCode, CancellationToken cancellationToken = default)
        => HasPermissionAsync(pageCode, "VIEW", cancellationToken);

    public Task<bool> CanCreateAsync(string pageCode, CancellationToken cancellationToken = default)
        => HasPermissionAsync(pageCode, "CREATE", cancellationToken);

    public Task<bool> CanUpdateAsync(string pageCode, CancellationToken cancellationToken = default)
        => HasPermissionAsync(pageCode, "UPDATE", cancellationToken);

    public Task<bool> CanDeleteAsync(string pageCode, CancellationToken cancellationToken = default)
        => HasPermissionAsync(pageCode, "DELETE", cancellationToken);

    public Task<bool> CanExportAsync(string pageCode, CancellationToken cancellationToken = default)
        => HasPermissionAsync(pageCode, "EXPORT", cancellationToken);

    public Task<bool> CanPrintAsync(string pageCode, CancellationToken cancellationToken = default)
        => HasPermissionAsync(pageCode, "PRINT", cancellationToken);
}
