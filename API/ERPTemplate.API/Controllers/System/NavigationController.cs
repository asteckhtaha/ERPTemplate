using ERPTemplate.API.DTOs.System;
using ERPTemplate.API.Helpers;
using ERPTemplate.API.Services.System;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ERPTemplate.API.Controllers.System;

[ApiController]
[Authorize]
[Route("api/system/navigation")]
public sealed class NavigationController : ControllerBase
{
    private const string PageCode = "SYSTEM_NAVIGATION";

    private readonly NavigationService _service;
    private readonly PermissionHelper _permissions;

    public NavigationController(NavigationService service, PermissionHelper permissions)
    {
        _service = service;
        _permissions = permissions;
    }

    /* ---- 1. GET /api/system/navigation ---- */
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<ModuleDto>>>> Get(
        [FromQuery] NavigationQuery query, CancellationToken ct)
    {
        if (!await _permissions.HasPermissionAsync(PageCode, "VIEW", ct)) return Forbid();

        var data = await _service.GetNavigationAsync(query, ct);
        return Ok(ApiResponse<List<ModuleDto>>.Ok(data));
    }

    /* ---- 2. POST /api/system/navigation ---- */
    [HttpPost]
    public async Task<ActionResult<ApiResponse<int>>> Create(
        [FromBody] CreateNavigationRequest request, CancellationToken ct)
    {
        if (!await _permissions.HasPermissionAsync(PageCode, "CREATE", ct)) return Forbid();

        var id = await _service.CreateNavigationAsync(request, ct);
        return CreatedAtAction(nameof(GetModule), new { id },
            ApiResponse<int>.Ok(id, "Navigation created successfully."));
    }

    /* ---- 3. GET modules/{id} ---- */
    [HttpGet("modules/{id:int}")]
    public async Task<ActionResult<ApiResponse<ModuleDto>>> GetModule(int id, CancellationToken ct)
    {
        if (!await _permissions.HasPermissionAsync(PageCode, "VIEW", ct)) return Forbid();

        var module = await _service.GetModuleAsync(id, ct);
        if (module is null) return NotFound(ApiResponse<ModuleDto>.Fail("Module not found."));
        return Ok(ApiResponse<ModuleDto>.Ok(module));
    }

    /* ---- 4. PUT modules/{id} ---- */
    [HttpPut("modules/{id:int}")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateModule(
        int id, [FromBody] UpdateModuleRequest request, CancellationToken ct)
    {
        if (!await _permissions.HasPermissionAsync(PageCode, "UPDATE", ct)) return Forbid();

        await _service.UpdateModuleAsync(id, request, ct);
        return Ok(ApiResponse<object>.Ok(new { id }, "Module updated successfully."));
    }

    /* ---- 5. DELETE modules/{id} ---- */
    [HttpDelete("modules/{id:int}")]
    public async Task<ActionResult<ApiResponse<object>>> DeleteModule(
        int id, [FromQuery] string? rowVersion, CancellationToken ct)
    {
        if (!await _permissions.HasPermissionAsync(PageCode, "DELETE", ct)) return Forbid();

        var rv = TryDecodeRowVersion(rowVersion);
        await _service.DeleteModuleAsync(id, rv, ct);
        return Ok(ApiResponse<object>.Ok(new { id }, "Module deleted successfully."));
    }

    /* ---- 6. GET pages/{id} ---- */
    [HttpGet("pages/{id:int}")]
    public async Task<ActionResult<ApiResponse<PageDto>>> GetPage(int id, CancellationToken ct)
    {
        if (!await _permissions.HasPermissionAsync(PageCode, "VIEW", ct)) return Forbid();

        var page = await _service.GetPageAsync(id, ct);
        if (page is null) return NotFound(ApiResponse<PageDto>.Fail("Page not found."));
        return Ok(ApiResponse<PageDto>.Ok(page));
    }

    /* ---- 7. PUT pages/{id} ---- */
    [HttpPut("pages/{id:int}")]
    public async Task<ActionResult<ApiResponse<object>>> UpdatePage(
        int id, [FromBody] UpdatePageRequest request, CancellationToken ct)
    {
        if (!await _permissions.HasPermissionAsync(PageCode, "UPDATE", ct)) return Forbid();

        await _service.UpdatePageAsync(id, request, ct);
        return Ok(ApiResponse<object>.Ok(new { id }, "Page updated successfully."));
    }

    /* ---- 8. DELETE pages/{id} ---- */
    [HttpDelete("pages/{id:int}")]
    public async Task<ActionResult<ApiResponse<object>>> DeletePage(
        int id, [FromQuery] string? rowVersion, CancellationToken ct)
    {
        if (!await _permissions.HasPermissionAsync(PageCode, "DELETE", ct)) return Forbid();

        var rv = TryDecodeRowVersion(rowVersion);
        await _service.DeletePageAsync(id, rv, ct);
        return Ok(ApiResponse<object>.Ok(new { id }, "Page deleted successfully."));
    }

    /* ---- 9. GET actions ---- */
    [HttpGet("actions")]
    public async Task<ActionResult<ApiResponse<List<ActionDto>>>> GetActions(
        [FromQuery] NavigationQuery query, CancellationToken ct)
    {
        if (!await _permissions.HasPermissionAsync(PageCode, "VIEW", ct)) return Forbid();

        var data = await _service.GetActionsAsync(query, ct);
        return Ok(ApiResponse<List<ActionDto>>.Ok(data));
    }

    /* ---- 10. POST actions ---- */
    [HttpPost("actions")]
    public async Task<ActionResult<ApiResponse<int>>> CreateAction(
        [FromBody] CreateActionRequest request, CancellationToken ct)
    {
        if (!await _permissions.HasPermissionAsync(PageCode, "CREATE", ct)) return Forbid();

        var id = await _service.CreateActionAsync(request, ct);
        return CreatedAtAction(nameof(GetAction), new { id },
            ApiResponse<int>.Ok(id, "Action created successfully."));
    }

    /* ---- 11. GET actions/{id} ---- */
    [HttpGet("actions/{id:int}")]
    public async Task<ActionResult<ApiResponse<ActionDto>>> GetAction(int id, CancellationToken ct)
    {
        if (!await _permissions.HasPermissionAsync(PageCode, "VIEW", ct)) return Forbid();

        var action = await _service.GetActionAsync(id, ct);
        if (action is null) return NotFound(ApiResponse<ActionDto>.Fail("Action not found."));
        return Ok(ApiResponse<ActionDto>.Ok(action));
    }

    /* ---- 12. PUT actions/{id} ---- */
    [HttpPut("actions/{id:int}")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateAction(
        int id, [FromBody] UpdateActionRequest request, CancellationToken ct)
    {
        if (!await _permissions.HasPermissionAsync(PageCode, "UPDATE", ct)) return Forbid();

        await _service.UpdateActionAsync(id, request, ct);
        return Ok(ApiResponse<object>.Ok(new { id }, "Action updated successfully."));
    }

    /* ---- 13. DELETE actions/{id} ---- */
    [HttpDelete("actions/{id:int}")]
    public async Task<ActionResult<ApiResponse<object>>> DeleteAction(
        int id, [FromQuery] string? rowVersion, CancellationToken ct)
    {
        if (!await _permissions.HasPermissionAsync(PageCode, "DELETE", ct)) return Forbid();

        var rv = TryDecodeRowVersion(rowVersion);
        await _service.DeleteActionAsync(id, rv, ct);
        return Ok(ApiResponse<object>.Ok(new { id }, "Action deleted successfully."));
    }

    private static byte[]? TryDecodeRowVersion(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        try { return Convert.FromBase64String(value); }
        catch (FormatException) { return null; }
    }
}
