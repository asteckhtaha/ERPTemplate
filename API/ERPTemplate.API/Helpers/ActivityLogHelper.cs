using System.Data;

namespace ERPTemplate.API.Helpers;

/// <summary>
/// Centralized ActivityLog creation via dbo.usp_ActivityLog_Create.
/// Records meaningful user/system activities only.
/// </summary>
public sealed class ActivityLogHelper
{
    private const string ProcedureName = "dbo.usp_ActivityLog_Create";

    private readonly DbHelper _dbHelper;
    private readonly TenantHelper _tenantHelper;
    private readonly SecurityHelper _securityHelper;

    public ActivityLogHelper(
        DbHelper dbHelper,
        TenantHelper tenantHelper,
        SecurityHelper securityHelper)
    {
        _dbHelper = dbHelper ?? throw new ArgumentNullException(nameof(dbHelper));
        _tenantHelper = tenantHelper ?? throw new ArgumentNullException(nameof(tenantHelper));
        _securityHelper = securityHelper ?? throw new ArgumentNullException(nameof(securityHelper));
    }

    public async Task LogAsync(ActivityLogEntry entry, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(entry);

        if (string.IsNullOrWhiteSpace(entry.ScopeType))
        {
            throw new ArgumentException("ScopeType is required.", nameof(entry));
        }

        if (string.IsNullOrWhiteSpace(entry.ActivityType))
        {
            throw new ArgumentException("ActivityType is required.", nameof(entry));
        }

        var parameters = new[]
        {
            DbHelper.CreateParameter("@ActivityLogGUID", Guid.NewGuid(), SqlDbType.UniqueIdentifier),
            DbHelper.CreateParameter("@ScopeType", entry.ScopeType, SqlDbType.VarChar, 20),
            DbHelper.CreateParameter("@CompanyID", entry.CompanyId ?? _tenantHelper.CompanyId, SqlDbType.Int),
            DbHelper.CreateParameter("@BranchID", entry.BranchId ?? _tenantHelper.BranchId, SqlDbType.Int),
            DbHelper.CreateParameter("@UserID", entry.UserId ?? _tenantHelper.UserId, SqlDbType.Int),
            DbHelper.CreateParameter("@RoleID", entry.RoleId ?? _tenantHelper.RoleId, SqlDbType.Int),
            DbHelper.CreateParameter("@ActivityType", entry.ActivityType, SqlDbType.VarChar, 50),
            DbHelper.CreateParameter("@ModuleName", entry.ModuleName, SqlDbType.VarChar, 100),
            DbHelper.CreateParameter("@PageName", entry.PageName, SqlDbType.VarChar, 150),
            DbHelper.CreateParameter("@EntityName", entry.EntityName, SqlDbType.VarChar, 150),
            DbHelper.CreateParameter("@EntityID", entry.EntityId, SqlDbType.BigInt),
            DbHelper.CreateParameter("@Description", entry.Description, SqlDbType.NVarChar, 1000),
            DbHelper.CreateParameter("@IPAddress", _securityHelper.ClientIpAddress, SqlDbType.VarChar, 45),
            DbHelper.CreateParameter("@UserAgent", _securityHelper.UserAgent, SqlDbType.NVarChar, 1000),
            DbHelper.CreateParameter("@RequestURL", _securityHelper.RequestUrl, SqlDbType.NVarChar, 1000),
            DbHelper.CreateParameter("@SessionID", entry.SessionId, SqlDbType.VarChar, 200),
            DbHelper.CreateParameter("@CorrelationID", entry.CorrelationId, SqlDbType.UniqueIdentifier)
        };

        await _dbHelper.ExecuteNonQueryAsync(ProcedureName, parameters, cancellationToken);
    }
}

public sealed record ActivityLogEntry(
    string ScopeType,
    string ActivityType,
    int? CompanyId = null,
    int? BranchId = null,
    int? UserId = null,
    int? RoleId = null,
    string? ModuleName = null,
    string? PageName = null,
    string? EntityName = null,
    long? EntityId = null,
    string? Description = null,
    string? SessionId = null,
    Guid? CorrelationId = null);
