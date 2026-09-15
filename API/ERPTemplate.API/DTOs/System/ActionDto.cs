namespace ERPTemplate.API.DTOs.System;

public sealed class ActionDto
{
    public int ActionID { get; set; }
    public Guid ActionGUID { get; set; }
    public string ActionKey { get; set; } = string.Empty;
    public string ActionCode { get; set; } = string.Empty;
    public string ActionName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int SortOrder { get; set; }
    public bool IsSystemAction { get; set; }
    public bool IsActive { get; set; }
    public bool IsDeleted { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }
    public byte[]? RowVersion { get; set; }
}

public sealed class PageActionDto
{
    public int PageActionID { get; set; }
    public int ActionID { get; set; }
    public string ActionCode { get; set; } = string.Empty;
    public string ActionName { get; set; } = string.Empty;
    public int SortOrder { get; set; }
    public bool IsDefault { get; set; }
    public bool IsActive { get; set; }
}
