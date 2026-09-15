using System.Data;

namespace ERPTemplate.API.Helpers;

/// <summary>
/// Centralized AuditLog creation via dbo.usp_AuditLog_Create.
/// Records important data/security changes only.
/// </summary>
public sealed class AuditHelper
{
    private const string ProcedureName = "dbo.usp_AuditLog_Create";

    private readonly DbHelper _dbHelper;
    private readonly TenantHelper _tenantHelper;
    private readonly SecurityHelper _securityHelper;

    public AuditHelper(
        DbHelper dbHelper,
        TenantHelper tenantHelper,
        SecurityHelper securityHelper)
    {
        _dbHelper = dbHelper ?? throw new ArgumentNullException(nameof(dbHelper));
        _tenantHelper = tenantHelper ?? throw new ArgumentNullException(nameof(tenantHelper));
        _securityHelper = securityHelper ?? throw new ArgumentNullException(nameof(securityHelper));
    }

    public async Task LogAsync(AuditLogEntry entry, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(entry);

        if (string.IsNullOrWhiteSpace(entry.ScopeType))
        {
            throw new ArgumentException("ScopeType is required.", nameof(entry));
        }

        if (string.IsNullOrWhiteSpace(entry.ActionType))
        {
            throw new ArgumentException("ActionType is required.", nameof(entry));
        }

        if (string.IsNullOrWhiteSpace(entry.EntityName))
        {
            throw new ArgumentException("EntityName is required.", nameof(entry));
        }

        var parameters = new[]
        {
            DbHelper.CreateParameter("@AuditLogGUID", Guid.NewGuid(), SqlDbType.UniqueIdentifier),
            DbHelper.CreateParameter("@ScopeType", entry.ScopeType, SqlDbType.VarChar, 20),
            DbHelper.CreateParameter("@CompanyID", entry.CompanyId ?? _tenantHelper.CompanyId, SqlDbType.Int),
            DbHelper.CreateParameter("@BranchID", entry.BranchId ?? _tenantHelper.BranchId, SqlDbType.Int),
            DbHelper.CreateParameter("@UserID", entry.UserId ?? _tenantHelper.UserId, SqlDbType.Int),
            DbHelper.CreateParameter("@RoleID", entry.RoleId ?? _tenantHelper.RoleId, SqlDbType.Int),
            DbHelper.CreateParameter("@ActionType", entry.ActionType, SqlDbType.VarChar, 30),
            DbHelper.CreateParameter("@EntityName", entry.EntityName, SqlDbType.VarChar, 150),
            DbHelper.CreateParameter("@EntityID", entry.EntityId, SqlDbType.BigInt),
            DbHelper.CreateParameter("@EntityGUID", entry.EntityGuid, SqlDbType.UniqueIdentifier),
            DbHelper.CreateParameter("@RecordDisplayName", entry.RecordDisplayName, SqlDbType.NVarChar, 300),
            DbHelper.CreateParameter("@OldValuesJson", entry.OldValuesJson, SqlDbType.NVarChar, -1),
            DbHelper.CreateParameter("@NewValuesJson", entry.NewValuesJson, SqlDbType.NVarChar, -1),
            DbHelper.CreateParameter("@ChangedColumnsJson", entry.ChangedColumnsJson, SqlDbType.NVarChar, -1),
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

public sealed record AuditLogEntry(
    string ScopeType,
    string ActionType,
    string EntityName,
    int? CompanyId = null,
    int? BranchId = null,
    int? UserId = null,
    int? RoleId = null,
    long? EntityId = null,
    Guid? EntityGuid = null,
    string? RecordDisplayName = null,
    string? OldValuesJson = null,
    string? NewValuesJson = null,
    string? ChangedColumnsJson = null,
    string? Description = null,
    string? SessionId = null,
    Guid? CorrelationId = null);
