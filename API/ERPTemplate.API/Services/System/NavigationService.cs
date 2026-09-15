using System.Data;
using ERPTemplate.API.DTOs.System;
using ERPTemplate.API.Helpers;
using ERPTemplate.API.Models.System;
using Microsoft.Data.SqlClient;
using System.Text.Json;

namespace ERPTemplate.API.Services.System;

public sealed class NavigationService
{
    private const string PageCode = "SYSTEM_NAVIGATION";

    private readonly DbHelper _dbHelper;
    private readonly TenantHelper _tenant;
    private readonly AuditHelper _audit;
    private readonly ActivityLogHelper _activity;

    public NavigationService(
        DbHelper dbHelper,
        TenantHelper tenant,
        AuditHelper audit,
        ActivityLogHelper activity)
    {
        _dbHelper = dbHelper;
        _tenant = tenant;
        _audit = audit;
        _activity = activity;
    }

    /* --------------------------------------------------------------
       GET /api/system/navigation
       -------------------------------------------------------------- */
    public async Task<List<ModuleDto>> GetNavigationAsync(
        NavigationQuery query, CancellationToken ct = default)
    {
        var parameters = new[]
        {
            DbHelper.CreateParameter("@Search",        query.Search,        SqlDbType.NVarChar, 200),
            DbHelper.CreateParameter("@ModuleID",      query.ModuleId,      SqlDbType.Int),
            DbHelper.CreateParameter("@Status",        query.Status,        SqlDbType.VarChar, 20),
            DbHelper.CreateParameter("@SortBy",        query.SortBy,        SqlDbType.VarChar, 30),
            DbHelper.CreateParameter("@SortDirection", query.SortDirection, SqlDbType.VarChar, 4)
        };

        var rows = await _dbHelper.ExecuteListAsync(
            "dbo.usp_SystemNavigation_Get",
            parameters,
            MapNavigationRow,
            ct);

        return GroupIntoModules(rows);
    }

    /* --------------------------------------------------------------
       POST /api/system/navigation
       -------------------------------------------------------------- */
    public async Task<int> CreateNavigationAsync(
        CreateNavigationRequest request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var pagesJson = JsonSerializer.Serialize(
            request.Pages.Select(p => new
            {
                pageCode = p.PageCode,
                pageName = p.PageName,
                displayName = p.DisplayName,
                actions = p.Actions
            }));

        var userId = _tenant.UserId
            ?? throw new InvalidOperationException("Authenticated UserID is required.");

        var parameters = new[]
        {
            DbHelper.CreateParameter("@ModuleCode",     request.Module.ModuleCode,     SqlDbType.VarChar, 50),
            DbHelper.CreateParameter("@ModuleName",     request.Module.ModuleName,     SqlDbType.NVarChar, 150),
            DbHelper.CreateParameter("@DisplayName",    request.Module.DisplayName,    SqlDbType.NVarChar, 150),
            DbHelper.CreateParameter("@Description",    request.Module.Description,    SqlDbType.NVarChar, 500),
            DbHelper.CreateParameter("@IconClass",      request.Module.IconClass,      SqlDbType.VarChar, 100),
            DbHelper.CreateParameter("@SortOrder",      request.Module.SortOrder,      SqlDbType.Int),
            DbHelper.CreateParameter("@IsMenuItem",     request.Module.IsMenuItem,     SqlDbType.Bit),
            DbHelper.CreateParameter("@IsSystemModule", request.Module.IsSystemModule, SqlDbType.Bit),
            DbHelper.CreateParameter("@PagesJson",      pagesJson,                     SqlDbType.NVarChar, -1),
            DbHelper.CreateParameter("@CreatedBy",      userId,                        SqlDbType.Int)
        };

        var scalar = await _dbHelper.ExecuteScalarAsync(
            "dbo.usp_SystemNavigation_Create", parameters, ct);
        var moduleId = Convert.ToInt32(scalar);

        await _audit.LogAsync(new AuditLogEntry(
            ScopeType: "SYSTEM",
            ActionType: "CREATE",
            EntityName: "SystemModules",
            EntityId: moduleId,
            Description: $"Navigation module '{request.Module.ModuleCode}' created with {request.Pages.Count} page(s)."), ct);

        await _activity.LogAsync(new ActivityLogEntry(
            ScopeType: "SYSTEM",
            ActivityType: "CREATE",
            ModuleName: "SystemNavigation",
            PageName: PageCode,
            EntityName: "SystemModules",
            EntityId: moduleId,
            Description: $"Created navigation module {request.Module.ModuleCode}."), ct);

        return moduleId;
    }

    /* --------------------------------------------------------------
       GET modules/{id}
       -------------------------------------------------------------- */
    public async Task<ModuleDto?> GetModuleAsync(int id, CancellationToken ct = default)
    {
        var parameters = new[]
        {
            DbHelper.CreateParameter("@SystemModuleID", id, SqlDbType.Int)
        };

        return await _dbHelper.ExecuteSingleAsync(
            "dbo.usp_SystemNavigation_GetModule",
            parameters,
            MapModule,
            ct);
    }

    /* --------------------------------------------------------------
       PUT modules/{id}
       -------------------------------------------------------------- */
    public async Task UpdateModuleAsync(int id, UpdateModuleRequest request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var userId = _tenant.UserId
            ?? throw new InvalidOperationException("Authenticated UserID is required.");

        var parameters = new[]
        {
            DbHelper.CreateParameter("@SystemModuleID", id,                  SqlDbType.Int),
            DbHelper.CreateParameter("@ModuleName",     request.ModuleName,  SqlDbType.NVarChar, 150),
            DbHelper.CreateParameter("@DisplayName",    request.DisplayName, SqlDbType.NVarChar, 150),
            DbHelper.CreateParameter("@Description",    request.Description, SqlDbType.NVarChar, 500),
            DbHelper.CreateParameter("@IconClass",      request.IconClass,   SqlDbType.VarChar, 100),
            DbHelper.CreateParameter("@SortOrder",      request.SortOrder,   SqlDbType.Int),
            DbHelper.CreateParameter("@IsMenuItem",     request.IsMenuItem,  SqlDbType.Bit),
            DbHelper.CreateParameter("@IsActive",       request.IsActive,    SqlDbType.Bit),
            DbHelper.CreateParameter("@RowVersion",     request.RowVersion,  SqlDbType.VarBinary, 8),
            DbHelper.CreateParameter("@UpdatedBy",      userId,              SqlDbType.Int)
        };

        await _dbHelper.ExecuteNonQueryAsync("dbo.usp_SystemNavigation_UpdateModule", parameters, ct);

        await _audit.LogAsync(new AuditLogEntry(
            ScopeType: "SYSTEM",
            ActionType: request.IsActive ? "UPDATE" : "DEACTIVATE",
            EntityName: "SystemModules",
            EntityId: id,
            Description: $"Module {id} updated (IsActive={request.IsActive})."), ct);
    }

    /* --------------------------------------------------------------
       DELETE modules/{id}
       -------------------------------------------------------------- */
    public async Task DeleteModuleAsync(int id, byte[]? rowVersion, CancellationToken ct = default)
    {
        var userId = _tenant.UserId
            ?? throw new InvalidOperationException("Authenticated UserID is required.");

        var parameters = new[]
        {
            DbHelper.CreateParameter("@SystemModuleID", id,         SqlDbType.Int),
            DbHelper.CreateParameter("@RowVersion",     rowVersion, SqlDbType.VarBinary, 8),
            DbHelper.CreateParameter("@DeletedBy",      userId,     SqlDbType.Int)
        };

        await _dbHelper.ExecuteNonQueryAsync("dbo.usp_SystemNavigation_DeleteModule", parameters, ct);

        await _audit.LogAsync(new AuditLogEntry(
            ScopeType: "SYSTEM",
            ActionType: "DELETE",
            EntityName: "SystemModules",
            EntityId: id,
            Description: $"Module {id} soft-deleted."), ct);
    }

    /* --------------------------------------------------------------
       GET pages/{id}   — uses new DbHelper.ExecuteReaderAsync<T>
       -------------------------------------------------------------- */
    public async Task<PageDto?> GetPageAsync(int id, CancellationToken ct = default)
    {
        var parameters = new[]
        {
            DbHelper.CreateParameter("@SystemPageID", id, SqlDbType.Int)
        };

        return await _dbHelper.ExecuteReaderAsync(
            "dbo.usp_SystemNavigation_GetPage",
            parameters,
            async (reader, c) =>
            {
                PageDto? page = null;

                if (await reader.ReadAsync(c))
                    page = MapPage(reader);

                if (page is null) return null;

                if (await reader.NextResultAsync(c))
                {
                    while (await reader.ReadAsync(c))
                        page.Actions.Add(MapPageActionRow(reader));
                }

                return page;
            },
            ct);
    }

    /* --------------------------------------------------------------
       PUT pages/{id}
       -------------------------------------------------------------- */
    public async Task UpdatePageAsync(int id, UpdatePageRequest request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var userId = _tenant.UserId
            ?? throw new InvalidOperationException("Authenticated UserID is required.");

        var actionsJson = JsonSerializer.Serialize(request.Actions ?? new List<string>());

        var parameters = new[]
        {
            DbHelper.CreateParameter("@SystemPageID",    id,                   SqlDbType.Int),
            DbHelper.CreateParameter("@PageName",        request.PageName,     SqlDbType.NVarChar, 150),
            DbHelper.CreateParameter("@DisplayName",     request.DisplayName,  SqlDbType.NVarChar, 150),
            DbHelper.CreateParameter("@Description",     request.Description,  SqlDbType.NVarChar, 500),
            DbHelper.CreateParameter("@URL",             request.URL,          SqlDbType.NVarChar, 300),
            DbHelper.CreateParameter("@IconClass",       request.IconClass,    SqlDbType.VarChar, 100),
            DbHelper.CreateParameter("@SortOrder",       request.SortOrder,    SqlDbType.Int),
            DbHelper.CreateParameter("@IsMenuItem",      request.IsMenuItem,   SqlDbType.Bit),
            DbHelper.CreateParameter("@RequiresAuth",    request.RequiresAuth, SqlDbType.Bit),
            DbHelper.CreateParameter("@IsActive",        request.IsActive,     SqlDbType.Bit),
            DbHelper.CreateParameter("@ActionCodesJson", actionsJson,          SqlDbType.NVarChar, -1),
            DbHelper.CreateParameter("@RowVersion",      request.RowVersion,   SqlDbType.VarBinary, 8),
            DbHelper.CreateParameter("@UpdatedBy",       userId,               SqlDbType.Int)
        };

        await _dbHelper.ExecuteNonQueryAsync("dbo.usp_SystemNavigation_UpdatePage", parameters, ct);

        await _audit.LogAsync(new AuditLogEntry(
            ScopeType: "SYSTEM",
            ActionType: "UPDATE",
            EntityName: "SystemPages",
            EntityId: id,
            Description: $"Page {id} updated and actions synchronized."), ct);
    }

    /* --------------------------------------------------------------
       DELETE pages/{id}
       -------------------------------------------------------------- */
    public async Task DeletePageAsync(int id, byte[]? rowVersion, CancellationToken ct = default)
    {
        var userId = _tenant.UserId
            ?? throw new InvalidOperationException("Authenticated UserID is required.");

        var parameters = new[]
        {
            DbHelper.CreateParameter("@SystemPageID", id,         SqlDbType.Int),
            DbHelper.CreateParameter("@RowVersion",   rowVersion, SqlDbType.VarBinary, 8),
            DbHelper.CreateParameter("@DeletedBy",    userId,     SqlDbType.Int)
        };

        await _dbHelper.ExecuteNonQueryAsync("dbo.usp_SystemNavigation_DeletePage", parameters, ct);

        await _audit.LogAsync(new AuditLogEntry(
            ScopeType: "SYSTEM",
            ActionType: "DELETE",
            EntityName: "SystemPages",
            EntityId: id,
            Description: $"Page {id} soft-deleted."), ct);
    }

    /* --------------------------------------------------------------
       GET actions
       -------------------------------------------------------------- */
    public async Task<List<ActionDto>> GetActionsAsync(
        NavigationQuery query, CancellationToken ct = default)
    {
        var parameters = new[]
        {
            DbHelper.CreateParameter("@Search",        query.Search,        SqlDbType.NVarChar, 200),
            DbHelper.CreateParameter("@Status",        query.Status,        SqlDbType.VarChar, 20),
            DbHelper.CreateParameter("@SortBy",        query.SortBy,        SqlDbType.VarChar, 30),
            DbHelper.CreateParameter("@SortDirection", query.SortDirection, SqlDbType.VarChar, 4)
        };

        return await _dbHelper.ExecuteListAsync(
            "dbo.usp_SystemNavigation_GetActions",
            parameters,
            MapAction,
            ct);
    }

    /* --------------------------------------------------------------
       POST actions
       -------------------------------------------------------------- */
    public async Task<int> CreateActionAsync(CreateActionRequest request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var userId = _tenant.UserId
            ?? throw new InvalidOperationException("Authenticated UserID is required.");

        var parameters = new[]
        {
            DbHelper.CreateParameter("@ActionCode",     request.ActionCode,     SqlDbType.VarChar, 50),
            DbHelper.CreateParameter("@ActionName",     request.ActionName,     SqlDbType.NVarChar, 150),
            DbHelper.CreateParameter("@Description",    request.Description,    SqlDbType.NVarChar, 500),
            DbHelper.CreateParameter("@SortOrder",      request.SortOrder,      SqlDbType.Int),
            DbHelper.CreateParameter("@IsActive",       request.IsActive,       SqlDbType.Bit),
            DbHelper.CreateParameter("@IsSystemAction", request.IsSystemAction, SqlDbType.Bit),
            DbHelper.CreateParameter("@CreatedBy",      userId,                 SqlDbType.Int)
        };

        var scalar = await _dbHelper.ExecuteScalarAsync(
            "dbo.usp_SystemNavigation_CreateAction", parameters, ct);
        var newId = Convert.ToInt32(scalar);

        await _audit.LogAsync(new AuditLogEntry(
            ScopeType: "SYSTEM",
            ActionType: "CREATE",
            EntityName: "SystemActions",
            EntityId: newId,
            Description: $"Global action '{request.ActionCode}' created."), ct);

        return newId;
    }

    /* --------------------------------------------------------------
       GET actions/{id}
       -------------------------------------------------------------- */
    public async Task<ActionDto?> GetActionAsync(int id, CancellationToken ct = default)
    {
        var parameters = new[]
        {
            DbHelper.CreateParameter("@ActionID", id, SqlDbType.Int)
        };

        return await _dbHelper.ExecuteSingleAsync(
            "dbo.usp_SystemNavigation_GetAction",
            parameters,
            MapAction,
            ct);
    }

    /* --------------------------------------------------------------
       PUT actions/{id}
       -------------------------------------------------------------- */
    public async Task UpdateActionAsync(int id, UpdateActionRequest request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var userId = _tenant.UserId
            ?? throw new InvalidOperationException("Authenticated UserID is required.");

        var parameters = new[]
        {
            DbHelper.CreateParameter("@ActionID",    id,                 SqlDbType.Int),
            DbHelper.CreateParameter("@ActionName",  request.ActionName, SqlDbType.NVarChar, 150),
            DbHelper.CreateParameter("@Description", request.Description, SqlDbType.NVarChar, 500),
            DbHelper.CreateParameter("@SortOrder",   request.SortOrder,  SqlDbType.Int),
            DbHelper.CreateParameter("@IsActive",    request.IsActive,   SqlDbType.Bit),
            DbHelper.CreateParameter("@RowVersion",  request.RowVersion, SqlDbType.VarBinary, 8),
            DbHelper.CreateParameter("@UpdatedBy",   userId,             SqlDbType.Int)
        };

        await _dbHelper.ExecuteNonQueryAsync("dbo.usp_SystemNavigation_UpdateAction", parameters, ct);

        await _audit.LogAsync(new AuditLogEntry(
            ScopeType: "SYSTEM",
            ActionType: "UPDATE",
            EntityName: "SystemActions",
            EntityId: id,
            Description: $"Global action {id} updated."), ct);
    }

    /* --------------------------------------------------------------
       DELETE actions/{id}
       -------------------------------------------------------------- */
    public async Task DeleteActionAsync(int id, byte[]? rowVersion, CancellationToken ct = default)
    {
        var userId = _tenant.UserId
            ?? throw new InvalidOperationException("Authenticated UserID is required.");

        var parameters = new[]
        {
            DbHelper.CreateParameter("@ActionID",   id,         SqlDbType.Int),
            DbHelper.CreateParameter("@RowVersion", rowVersion, SqlDbType.VarBinary, 8),
            DbHelper.CreateParameter("@DeletedBy",  userId,     SqlDbType.Int)
        };

        await _dbHelper.ExecuteNonQueryAsync("dbo.usp_SystemNavigation_DeleteAction", parameters, ct);

        await _audit.LogAsync(new AuditLogEntry(
            ScopeType: "SYSTEM",
            ActionType: "DELETE",
            EntityName: "SystemActions",
            EntityId: id,
            Description: $"Global action {id} soft-deleted."), ct);
    }

    /* ==============================================================
       Mapping helpers — private to this service
       ============================================================== */

    private static bool IsDbNull(SqlDataReader r, string column)
        => r.IsDBNull(r.GetOrdinal(column));

    private static ModuleDto MapModule(SqlDataReader r) => new()
    {
        SystemModuleID = r.GetInt32(r.GetOrdinal("SystemModuleID")),
        SystemModuleGUID = r.GetGuid(r.GetOrdinal("SystemModuleGUID")),
        ModuleKey = r.GetString(r.GetOrdinal("ModuleKey")),
        ModuleCode = r.GetString(r.GetOrdinal("ModuleCode")),
        ModuleName = r.GetString(r.GetOrdinal("ModuleName")),
        DisplayName = r.GetString(r.GetOrdinal("DisplayName")),
        Description = IsDbNull(r, "Description") ? null : r.GetString(r.GetOrdinal("Description")),
        IconClass = IsDbNull(r, "IconClass") ? null : r.GetString(r.GetOrdinal("IconClass")),
        SortOrder = r.GetInt32(r.GetOrdinal("SortOrder")),
        IsMenuItem = r.GetBoolean(r.GetOrdinal("IsMenuItem")),
        IsSystemModule = r.GetBoolean(r.GetOrdinal("IsSystemModule")),
        IsActive = r.GetBoolean(r.GetOrdinal("IsActive")),
        IsDeleted = r.GetBoolean(r.GetOrdinal("IsDeleted")),
        CreatedDate = r.GetDateTime(r.GetOrdinal("CreatedDate")),
        UpdatedDate = IsDbNull(r, "UpdatedDate") ? null : r.GetDateTime(r.GetOrdinal("UpdatedDate")),
        RowVersion = (byte[])r["RowVersion"]
    };

    private static PageDto MapPage(SqlDataReader r) => new()
    {
        SystemPageID = r.GetInt32(r.GetOrdinal("SystemPageID")),
        SystemPageGUID = r.GetGuid(r.GetOrdinal("SystemPageGUID")),
        PageKey = r.GetString(r.GetOrdinal("PageKey")),
        PageCode = r.GetString(r.GetOrdinal("PageCode")),
        PageName = r.GetString(r.GetOrdinal("PageName")),
        DisplayName = r.GetString(r.GetOrdinal("DisplayName")),
        Description = IsDbNull(r, "Description") ? null : r.GetString(r.GetOrdinal("Description")),
        SystemModuleID = IsDbNull(r, "SystemModuleID") ? null : r.GetInt32(r.GetOrdinal("SystemModuleID")),
        ParentPageID = IsDbNull(r, "ParentPageID") ? null : r.GetInt32(r.GetOrdinal("ParentPageID")),
        URL = IsDbNull(r, "URL") ? null : r.GetString(r.GetOrdinal("URL")),
        IconClass = IsDbNull(r, "IconClass") ? null : r.GetString(r.GetOrdinal("IconClass")),
        PageType = r.GetString(r.GetOrdinal("PageType")),
        SortOrder = r.GetInt32(r.GetOrdinal("SortOrder")),
        IsMenuItem = r.GetBoolean(r.GetOrdinal("IsMenuItem")),
        IsSystemPage = r.GetBoolean(r.GetOrdinal("IsSystemPage")),
        RequiresAuthentication = r.GetBoolean(r.GetOrdinal("RequiresAuthentication")),
        IsActive = r.GetBoolean(r.GetOrdinal("IsActive")),
        IsDeleted = r.GetBoolean(r.GetOrdinal("IsDeleted")),
        CreatedDate = r.GetDateTime(r.GetOrdinal("CreatedDate")),
        UpdatedDate = IsDbNull(r, "UpdatedDate") ? null : r.GetDateTime(r.GetOrdinal("UpdatedDate")),
        RowVersion = (byte[])r["RowVersion"]
    };

    private static PageActionDto MapPageActionRow(SqlDataReader r) => new()
    {
        PageActionID = r.GetInt32(r.GetOrdinal("PageActionID")),
        ActionID = r.GetInt32(r.GetOrdinal("ActionID")),
        ActionCode = r.GetString(r.GetOrdinal("ActionCode")),
        ActionName = r.GetString(r.GetOrdinal("ActionName")),
        SortOrder = r.GetInt32(r.GetOrdinal("SortOrder")),
        IsDefault = r.GetBoolean(r.GetOrdinal("IsDefault")),
        IsActive = r.GetBoolean(r.GetOrdinal("IsActive"))
    };

    private static ActionDto MapAction(SqlDataReader r) => new()
    {
        ActionID = r.GetInt32(r.GetOrdinal("ActionID")),
        ActionGUID = r.GetGuid(r.GetOrdinal("ActionGUID")),
        ActionKey = r.GetString(r.GetOrdinal("ActionKey")),
        ActionCode = r.GetString(r.GetOrdinal("ActionCode")),
        ActionName = r.GetString(r.GetOrdinal("ActionName")),
        Description = IsDbNull(r, "Description") ? null : r.GetString(r.GetOrdinal("Description")),
        SortOrder = r.GetInt32(r.GetOrdinal("SortOrder")),
        IsSystemAction = r.GetBoolean(r.GetOrdinal("IsSystemAction")),
        IsActive = r.GetBoolean(r.GetOrdinal("IsActive")),
        IsDeleted = r.GetBoolean(r.GetOrdinal("IsDeleted")),
        CreatedDate = r.GetDateTime(r.GetOrdinal("CreatedDate")),
        UpdatedDate = IsDbNull(r, "UpdatedDate") ? null : r.GetDateTime(r.GetOrdinal("UpdatedDate")),
        RowVersion = (byte[])r["RowVersion"]
    };

    private static NavigationRow MapNavigationRow(SqlDataReader r) => new()
    {
        SystemModuleID = r.GetInt32(r.GetOrdinal("SystemModuleID")),
        SystemModuleGUID = r.GetGuid(r.GetOrdinal("SystemModuleGUID")),
        ModuleCode = r.GetString(r.GetOrdinal("ModuleCode")),
        ModuleName = r.GetString(r.GetOrdinal("ModuleName")),
        ModuleDisplayName = r.GetString(r.GetOrdinal("ModuleDisplayName")),
        ModuleSortOrder = r.GetInt32(r.GetOrdinal("ModuleSortOrder")),
        ModuleIsActive = r.GetBoolean(r.GetOrdinal("ModuleIsActive")),
        ModuleIsDeleted = r.GetBoolean(r.GetOrdinal("ModuleIsDeleted")),
        ModuleCreatedDate = r.GetDateTime(r.GetOrdinal("ModuleCreatedDate")),
        ModuleUpdatedDate = IsDbNull(r, "ModuleUpdatedDate") ? null : r.GetDateTime(r.GetOrdinal("ModuleUpdatedDate")),

        SystemPageID = IsDbNull(r, "SystemPageID") ? null : r.GetInt32(r.GetOrdinal("SystemPageID")),
        SystemPageGUID = IsDbNull(r, "SystemPageGUID") ? null : r.GetGuid(r.GetOrdinal("SystemPageGUID")),
        PageCode = IsDbNull(r, "PageCode") ? null : r.GetString(r.GetOrdinal("PageCode")),
        PageName = IsDbNull(r, "PageName") ? null : r.GetString(r.GetOrdinal("PageName")),
        PageDisplayName = IsDbNull(r, "PageDisplayName") ? null : r.GetString(r.GetOrdinal("PageDisplayName")),
        PageSortOrder = IsDbNull(r, "PageSortOrder") ? null : r.GetInt32(r.GetOrdinal("PageSortOrder")),
        PageIsActive = IsDbNull(r, "PageIsActive") ? null : r.GetBoolean(r.GetOrdinal("PageIsActive")),
        PageIsDeleted = IsDbNull(r, "PageIsDeleted") ? null : r.GetBoolean(r.GetOrdinal("PageIsDeleted")),

        PageActionID = IsDbNull(r, "PageActionID") ? null : r.GetInt32(r.GetOrdinal("PageActionID")),
        ActionID = IsDbNull(r, "ActionID") ? null : r.GetInt32(r.GetOrdinal("ActionID")),
        ActionCode = IsDbNull(r, "ActionCode") ? null : r.GetString(r.GetOrdinal("ActionCode")),
        ActionName = IsDbNull(r, "ActionName") ? null : r.GetString(r.GetOrdinal("ActionName")),
        PageActionSortOrder = IsDbNull(r, "PageActionSortOrder") ? null : r.GetInt32(r.GetOrdinal("PageActionSortOrder")),
        PageActionIsDefault = IsDbNull(r, "PageActionIsDefault") ? null : r.GetBoolean(r.GetOrdinal("PageActionIsDefault"))
    };

    private static List<ModuleDto> GroupIntoModules(List<NavigationRow> rows)
    {
        return rows
            .GroupBy(r => new
            {
                r.SystemModuleID,
                r.SystemModuleGUID,
                r.ModuleCode,
                r.ModuleName,
                r.ModuleDisplayName,
                r.ModuleSortOrder,
                r.ModuleIsActive,
                r.ModuleIsDeleted,
                r.ModuleCreatedDate,
                r.ModuleUpdatedDate
            })
            .Select(mg => new ModuleDto
            {
                SystemModuleID = mg.Key.SystemModuleID,
                SystemModuleGUID = mg.Key.SystemModuleGUID,
                ModuleCode = mg.Key.ModuleCode,
                ModuleName = mg.Key.ModuleName,
                DisplayName = mg.Key.ModuleDisplayName,
                SortOrder = mg.Key.ModuleSortOrder,
                IsActive = mg.Key.ModuleIsActive,
                IsDeleted = mg.Key.ModuleIsDeleted,
                CreatedDate = mg.Key.ModuleCreatedDate,
                UpdatedDate = mg.Key.ModuleUpdatedDate,
                Pages = mg
                    .Where(r => r.SystemPageID.HasValue)
                    .GroupBy(r => r.SystemPageID!.Value)
                    .Select(pg =>
                    {
                        var first = pg.First();
                        return new PageDto
                        {
                            SystemPageID = first.SystemPageID!.Value,
                            SystemPageGUID = first.SystemPageGUID ?? Guid.Empty,
                            PageCode = first.PageCode ?? string.Empty,
                            PageName = first.PageName ?? string.Empty,
                            DisplayName = first.PageDisplayName ?? string.Empty,
                            SortOrder = first.PageSortOrder ?? 0,
                            IsActive = first.PageIsActive ?? false,
                            IsDeleted = first.PageIsDeleted ?? false,
                            Actions = pg
                                .Where(r => r.PageActionID.HasValue && r.ActionID.HasValue)
                                .Select(r => new PageActionDto
                                {
                                    PageActionID = r.PageActionID!.Value,
                                    ActionID = r.ActionID!.Value,
                                    ActionCode = r.ActionCode ?? string.Empty,
                                    ActionName = r.ActionName ?? string.Empty,
                                    SortOrder = r.PageActionSortOrder ?? 0,
                                    IsDefault = r.PageActionIsDefault ?? false,
                                    IsActive = true
                                })
                                .ToList()
                        };
                    })
                    .ToList()
            })
            .ToList();
    }
}
