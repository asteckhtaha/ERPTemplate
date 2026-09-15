using System.ComponentModel.DataAnnotations;

namespace ERPTemplate.API.DTOs.System;

public sealed class CreateNavigationRequest
{
    [Required] public ModuleCreateDto Module { get; set; } = new();
    [Required, MinLength(1)] public List<PageCreateDto> Pages { get; set; } = new();
}

public sealed class ModuleCreateDto
{
    [Required, StringLength(50)] public string ModuleCode { get; set; } = string.Empty;
    [Required, StringLength(150)] public string ModuleName { get; set; } = string.Empty;
    [Required, StringLength(150)] public string DisplayName { get; set; } = string.Empty;
    [StringLength(500)] public string? Description { get; set; }
    [StringLength(100)] public string? IconClass { get; set; }
    public int SortOrder { get; set; }
    public bool IsMenuItem { get; set; } = true;
    public bool IsSystemModule { get; set; }
}

public sealed class PageCreateDto
{
    [Required, StringLength(100)] public string PageCode { get; set; } = string.Empty;
    [Required, StringLength(150)] public string PageName { get; set; } = string.Empty;
    [Required, StringLength(150)] public string DisplayName { get; set; } = string.Empty;
    public List<string> Actions { get; set; } = new();
}

public sealed class UpdateModuleRequest
{
    [Required, StringLength(150)] public string ModuleName { get; set; } = string.Empty;
    [Required, StringLength(150)] public string DisplayName { get; set; } = string.Empty;
    [StringLength(500)] public string? Description { get; set; }
    [StringLength(100)] public string? IconClass { get; set; }
    public int SortOrder { get; set; }
    public bool IsMenuItem { get; set; } = true;
    public bool IsActive { get; set; } = true;
    public byte[]? RowVersion { get; set; }
}

public sealed class UpdatePageRequest
{
    [Required, StringLength(150)] public string PageName { get; set; } = string.Empty;
    [Required, StringLength(150)] public string DisplayName { get; set; } = string.Empty;
    [StringLength(500)] public string? Description { get; set; }
    [StringLength(300)] public string? URL { get; set; }
    [StringLength(100)] public string? IconClass { get; set; }
    public int SortOrder { get; set; }
    public bool IsMenuItem { get; set; } = true;
    public bool RequiresAuth { get; set; } = true;
    public bool IsActive { get; set; } = true;
    public List<string> Actions { get; set; } = new();
    public byte[]? RowVersion { get; set; }
}

public sealed class CreateActionRequest
{
    [Required, StringLength(50)] public string ActionCode { get; set; } = string.Empty;
    [Required, StringLength(150)] public string ActionName { get; set; } = string.Empty;
    [StringLength(500)] public string? Description { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsSystemAction { get; set; }
}

public sealed class UpdateActionRequest
{
    [Required, StringLength(150)] public string ActionName { get; set; } = string.Empty;
    [StringLength(500)] public string? Description { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public byte[]? RowVersion { get; set; }
}

public sealed class NavigationQuery
{
    public string? Search { get; set; }
    public int? ModuleId { get; set; }
    public string? Status { get; set; }
    public string? SortBy { get; set; }
    public string? SortDirection { get; set; }
}
