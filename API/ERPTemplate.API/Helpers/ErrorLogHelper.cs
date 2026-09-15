using System.Data;

namespace ERPTemplate.API.Helpers;

/// <summary>
/// Centralized application ErrorLog creation via dbo.usp_ErrorLog_Create.
/// Does not swallow exceptions. Logging only.
/// </summary>
public sealed class ErrorLogHelper
{
    private const string ProcedureName = "dbo.usp_ErrorLog_Create";

    private readonly DbHelper _dbHelper;
    private readonly TenantHelper _tenantHelper;
    private readonly SecurityHelper _securityHelper;

    public ErrorLogHelper(
        DbHelper dbHelper,
        TenantHelper tenantHelper,
        SecurityHelper securityHelper)
    {
        _dbHelper = dbHelper ?? throw new ArgumentNullException(nameof(dbHelper));
        _tenantHelper = tenantHelper ?? throw new ArgumentNullException(nameof(tenantHelper));
        _securityHelper = securityHelper ?? throw new ArgumentNullException(nameof(securityHelper));
    }

    public async Task LogAsync(ErrorLogEntry entry, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(entry);

        if (string.IsNullOrWhiteSpace(entry.ErrorMessage))
        {
            throw new ArgumentException("ErrorMessage is required.", nameof(entry));
        }

        var parameters = new[]
        {
            DbHelper.CreateParameter("@ErrorLogGUID", Guid.NewGuid(), SqlDbType.UniqueIdentifier),
            DbHelper.CreateParameter("@ErrorCode", entry.ErrorCode ?? "APP-ERROR", SqlDbType.VarChar, 50),
            DbHelper.CreateParameter("@ErrorType", entry.ErrorType ?? "Application", SqlDbType.VarChar, 100),
            DbHelper.CreateParameter("@Severity", entry.Severity ?? "Error", SqlDbType.VarChar, 20),
            DbHelper.CreateParameter("@Status", entry.Status ?? "NEW", SqlDbType.VarChar, 20),
            DbHelper.CreateParameter("@ModuleName", entry.ModuleName, SqlDbType.VarChar, 100),
            DbHelper.CreateParameter("@PageName", entry.PageName, SqlDbType.VarChar, 150),
            DbHelper.CreateParameter("@MethodName", entry.MethodName, SqlDbType.VarChar, 200),
            DbHelper.CreateParameter("@CompanyID", entry.CompanyId ?? _tenantHelper.CompanyId, SqlDbType.Int),
            DbHelper.CreateParameter("@BranchID", entry.BranchId ?? _tenantHelper.BranchId, SqlDbType.Int),
            DbHelper.CreateParameter("@UserID", entry.UserId ?? _tenantHelper.UserId, SqlDbType.Int),
            DbHelper.CreateParameter("@ExceptionType", entry.ExceptionType, SqlDbType.VarChar, 500),
            DbHelper.CreateParameter("@ErrorMessage", entry.ErrorMessage, SqlDbType.NVarChar, -1),
            DbHelper.CreateParameter("@StackTrace", entry.StackTrace, SqlDbType.NVarChar, -1),
            DbHelper.CreateParameter("@InnerException", entry.InnerException, SqlDbType.NVarChar, -1),
            DbHelper.CreateParameter("@RequestURL", entry.RequestUrl ?? _securityHelper.RequestUrl, SqlDbType.NVarChar, 1000),
            DbHelper.CreateParameter("@RequestMethod", entry.RequestMethod ?? _securityHelper.RequestMethod, SqlDbType.VarChar, 20),
            DbHelper.CreateParameter("@IPAddress", _securityHelper.ClientIpAddress, SqlDbType.VarChar, 45),
            DbHelper.CreateParameter("@UserAgent", _securityHelper.UserAgent, SqlDbType.NVarChar, 1000),
            DbHelper.CreateParameter("@RequestDataJson", entry.RequestDataJson, SqlDbType.NVarChar, -1),
            DbHelper.CreateParameter("@CorrelationID", entry.CorrelationId, SqlDbType.UniqueIdentifier),
            DbHelper.CreateParameter("@OccurredDate", entry.OccurredDate ?? DateTimeHelper.UtcNow, SqlDbType.DateTime2)
        };

        await _dbHelper.ExecuteNonQueryAsync(ProcedureName, parameters, cancellationToken);
    }

    public Task LogAsync(
        Exception exception,
        string? moduleName = null,
        string? pageName = null,
        string? methodName = null,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(exception);

        var entry = new ErrorLogEntry(
            ErrorMessage: exception.Message,
            ErrorCode: exception.HResult != 0 ? $"E{exception.HResult:X8}" : "APP-ERROR",
            ErrorType: "Exception",
            Severity: "Error",
            Status: "NEW",
            ModuleName: moduleName,
            PageName: pageName,
            MethodName: methodName,
            ExceptionType: exception.GetType().FullName,
            StackTrace: exception.StackTrace,
            InnerException: exception.InnerException?.ToString());

        return LogAsync(entry, cancellationToken);
    }
}

public sealed record ErrorLogEntry(
    string ErrorMessage,
    string? ErrorCode = null,
    string? ErrorType = null,
    string? Severity = null,
    string? Status = null,
    string? ModuleName = null,
    string? PageName = null,
    string? MethodName = null,
    int? CompanyId = null,
    int? BranchId = null,
    int? UserId = null,
    string? ExceptionType = null,
    string? StackTrace = null,
    string? InnerException = null,
    string? RequestUrl = null,
    string? RequestMethod = null,
    string? RequestDataJson = null,
    Guid? CorrelationId = null,
    DateTime? OccurredDate = null);
