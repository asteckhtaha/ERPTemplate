namespace ERPTemplate.API.DTOs.System;

public sealed class ModuleDto
{
    public int SystemModuleID { get; set; }
    public Guid SystemModuleGUID { get; set; }
    public string ModuleKey { get; set; } = string.Empty;
    public string ModuleCode { get; set; } = string.Empty;
    public string ModuleName { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? IconClass { get; set; }
    public int SortOrder { get; set; }
    public bool IsMenuItem { get; set; }
    public bool IsSystemModule { get; set; }
    public bool IsActive { get; set; }
    public bool IsDeleted { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }
    public byte[]? RowVersion { get; set; }
    public List<PageDto> Pages { get; set; } = new();
}
