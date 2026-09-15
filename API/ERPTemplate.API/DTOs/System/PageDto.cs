namespace ERPTemplate.API.DTOs.System;

public sealed class PageDto
{
    public int SystemPageID { get; set; }
    public Guid SystemPageGUID { get; set; }
    public string PageKey { get; set; } = string.Empty;
    public string PageCode { get; set; } = string.Empty;
    public string PageName { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int? SystemModuleID { get; set; }
    public int? ParentPageID { get; set; }
    public string? URL { get; set; }
    public string? IconClass { get; set; }
    public string PageType { get; set; } = "PAGE";
    public int SortOrder { get; set; }
    public bool IsMenuItem { get; set; }
    public bool IsSystemPage { get; set; }
    public bool RequiresAuthentication { get; set; }
    public bool IsActive { get; set; }
    public bool IsDeleted { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }
    public byte[]? RowVersion { get; set; }
    public List<PageActionDto> Actions { get; set; } = new();
}
