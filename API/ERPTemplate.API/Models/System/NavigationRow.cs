namespace ERPTemplate.API.Models.System;

public sealed class NavigationRow
{
    public int SystemModuleID { get; set; }
    public Guid SystemModuleGUID { get; set; }
    public string ModuleCode { get; set; } = string.Empty;
    public string ModuleName { get; set; } = string.Empty;
    public string ModuleDisplayName { get; set; } = string.Empty;
    public int ModuleSortOrder { get; set; }
    public bool ModuleIsActive { get; set; }
    public bool ModuleIsDeleted { get; set; }
    public DateTime ModuleCreatedDate { get; set; }
    public DateTime? ModuleUpdatedDate { get; set; }

    public int? SystemPageID { get; set; }
    public Guid? SystemPageGUID { get; set; }
    public string? PageCode { get; set; }
    public string? PageName { get; set; }
    public string? PageDisplayName { get; set; }
    public int? PageSortOrder { get; set; }
    public bool? PageIsActive { get; set; }
    public bool? PageIsDeleted { get; set; }

    public int? PageActionID { get; set; }
    public int? ActionID { get; set; }
    public string? ActionCode { get; set; }
    public string? ActionName { get; set; }
    public int? PageActionSortOrder { get; set; }
    public bool? PageActionIsDefault { get; set; }
}
