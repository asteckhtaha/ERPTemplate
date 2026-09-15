/* ============================================================================================
   ERPTemplate — 03_Indexes.sql
   --------------------------------------------------------------------------------------------
   Purpose : Create supporting (non-unique) indexes.
   Target  : SQL Server 2019 or later. Schema: dbo.
   Run after: 01_Tables.sql, 02_ForeignKeys.sql

   Why these indexes exist
   - SQL Server does not index foreign key columns automatically. Every foreign key column that is
     used for lookups/joins gets an index here.
   - Tenant columns (CompanyID, BranchID) and commonly filtered status/date columns are indexed
     because every list/report query filters on them (see DEVELOPMENT-GUIDELINES.md sections 11.2, 26).
   - Nothing else is added: no covering/index-spam, no indexed columns that no approved query uses.

   Not duplicated here: columns already covered by a PRIMARY KEY or UNIQUE constraint
   (for example CompanyProfiles.CompanyID via UQ_CompanyProfiles_CompanyID,
   CompanySettings (CompanyID, SettingKey), UserCompanyAccess (UserID, CompanyID), etc.).

   Idempotent: each index is created only when an index with that name does not exist.
   ============================================================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================ A. Company module ============================ */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptions_Company' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptions'))
    CREATE INDEX IX_CompanySubscriptions_Company ON dbo.CompanySubscriptions (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptions_SubscriptionPlan' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptions'))
    CREATE INDEX IX_CompanySubscriptions_SubscriptionPlan ON dbo.CompanySubscriptions (SubscriptionPlanID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptions_Currency' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptions'))
    CREATE INDEX IX_CompanySubscriptions_Currency ON dbo.CompanySubscriptions (CurrencyID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptions_Company_Status' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptions'))
    CREATE INDEX IX_CompanySubscriptions_Company_Status ON dbo.CompanySubscriptions (CompanyID, Status);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionHistory_CompanySubscription' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionHistory'))
    CREATE INDEX IX_CompanySubscriptionHistory_CompanySubscription ON dbo.CompanySubscriptionHistory (CompanySubscriptionID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionHistory_Company' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionHistory'))
    CREATE INDEX IX_CompanySubscriptionHistory_Company ON dbo.CompanySubscriptionHistory (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionHistory_PreviousPlan' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionHistory'))
    CREATE INDEX IX_CompanySubscriptionHistory_PreviousPlan ON dbo.CompanySubscriptionHistory (PreviousPlanID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionHistory_NewPlan' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionHistory'))
    CREATE INDEX IX_CompanySubscriptionHistory_NewPlan ON dbo.CompanySubscriptionHistory (NewPlanID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionUsage_CompanySubscription' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionUsage'))
    CREATE INDEX IX_CompanySubscriptionUsage_CompanySubscription ON dbo.CompanySubscriptionUsage (CompanySubscriptionID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionUsage_Company' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionUsage'))
    CREATE INDEX IX_CompanySubscriptionUsage_Company ON dbo.CompanySubscriptionUsage (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionUsage_SubscriptionPlanLimit' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionUsage'))
    CREATE INDEX IX_CompanySubscriptionUsage_SubscriptionPlanLimit ON dbo.CompanySubscriptionUsage (SubscriptionPlanLimitID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionInvoices_Company' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionInvoices'))
    CREATE INDEX IX_CompanySubscriptionInvoices_Company ON dbo.CompanySubscriptionInvoices (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionInvoices_CompanySubscription' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionInvoices'))
    CREATE INDEX IX_CompanySubscriptionInvoices_CompanySubscription ON dbo.CompanySubscriptionInvoices (CompanySubscriptionID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionInvoices_Currency' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionInvoices'))
    CREATE INDEX IX_CompanySubscriptionInvoices_Currency ON dbo.CompanySubscriptionInvoices (CurrencyID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionInvoices_Company_Status_InvoiceDate' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionInvoices'))
    CREATE INDEX IX_CompanySubscriptionInvoices_Company_Status_InvoiceDate ON dbo.CompanySubscriptionInvoices (CompanyID, Status, InvoiceDate);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionPayments_Company' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionPayments'))
    CREATE INDEX IX_CompanySubscriptionPayments_Company ON dbo.CompanySubscriptionPayments (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionPayments_CompanySubscriptionInvoice' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionPayments'))
    CREATE INDEX IX_CompanySubscriptionPayments_CompanySubscriptionInvoice ON dbo.CompanySubscriptionPayments (CompanySubscriptionInvoiceID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionPayments_Currency' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionPayments'))
    CREATE INDEX IX_CompanySubscriptionPayments_Currency ON dbo.CompanySubscriptionPayments (CurrencyID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionPayments_PaymentDate' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionPayments'))
    CREATE INDEX IX_CompanySubscriptionPayments_PaymentDate ON dbo.CompanySubscriptionPayments (PaymentDate);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionCredits_Company' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionCredits'))
    CREATE INDEX IX_CompanySubscriptionCredits_Company ON dbo.CompanySubscriptionCredits (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionCredits_CompanySubscription' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionCredits'))
    CREATE INDEX IX_CompanySubscriptionCredits_CompanySubscription ON dbo.CompanySubscriptionCredits (CompanySubscriptionID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionCredits_CompanySubscriptionInvoice' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionCredits'))
    CREATE INDEX IX_CompanySubscriptionCredits_CompanySubscriptionInvoice ON dbo.CompanySubscriptionCredits (CompanySubscriptionInvoiceID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CompanySubscriptionCredits_Currency' AND object_id = OBJECT_ID(N'dbo.CompanySubscriptionCredits'))
    CREATE INDEX IX_CompanySubscriptionCredits_Currency ON dbo.CompanySubscriptionCredits (CurrencyID);
GO

/* ============================ B. Branch module ============================ */
/* Branches.CompanyID is covered by UQ_Branches_Company_Key / UQ_Branches_Company_Code.
   BranchProfiles.BranchID and BranchSettings (BranchID, SettingKey) are covered by unique keys. */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Branches_Company_IsActive' AND object_id = OBJECT_ID(N'dbo.Branches'))
    CREATE INDEX IX_Branches_Company_IsActive ON dbo.Branches (CompanyID, IsActive);
GO

/* ============================ C. Users & security ============================ */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Users_UserType' AND object_id = OBJECT_ID(N'dbo.Users'))
    CREATE INDEX IX_Users_UserType ON dbo.Users (UserTypeID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Users_Email' AND object_id = OBJECT_ID(N'dbo.Users'))
    CREATE INDEX IX_Users_Email ON dbo.Users (Email);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Users_Status_IsActive' AND object_id = OBJECT_ID(N'dbo.Users'))
    CREATE INDEX IX_Users_Status_IsActive ON dbo.Users (Status, IsActive);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserCompanyAccess_Company' AND object_id = OBJECT_ID(N'dbo.UserCompanyAccess'))
    CREATE INDEX IX_UserCompanyAccess_Company ON dbo.UserCompanyAccess (CompanyID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserBranchAccess_User' AND object_id = OBJECT_ID(N'dbo.UserBranchAccess'))
    CREATE INDEX IX_UserBranchAccess_User ON dbo.UserBranchAccess (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserBranchAccess_Company' AND object_id = OBJECT_ID(N'dbo.UserBranchAccess'))
    CREATE INDEX IX_UserBranchAccess_Company ON dbo.UserBranchAccess (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserBranchAccess_Branch_Company' AND object_id = OBJECT_ID(N'dbo.UserBranchAccess'))
    CREATE INDEX IX_UserBranchAccess_Branch_Company ON dbo.UserBranchAccess (BranchID, CompanyID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserRoleAssignments_User' AND object_id = OBJECT_ID(N'dbo.UserRoleAssignments'))
    CREATE INDEX IX_UserRoleAssignments_User ON dbo.UserRoleAssignments (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserRoleAssignments_Company' AND object_id = OBJECT_ID(N'dbo.UserRoleAssignments'))
    CREATE INDEX IX_UserRoleAssignments_Company ON dbo.UserRoleAssignments (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserRoleAssignments_Branch' AND object_id = OBJECT_ID(N'dbo.UserRoleAssignments'))
    CREATE INDEX IX_UserRoleAssignments_Branch ON dbo.UserRoleAssignments (BranchID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserRoleAssignments_Role' AND object_id = OBJECT_ID(N'dbo.UserRoleAssignments'))
    CREATE INDEX IX_UserRoleAssignments_Role ON dbo.UserRoleAssignments (RoleID);
GO

/* ============================ D. Roles ============================ */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Roles_ParentRole' AND object_id = OBJECT_ID(N'dbo.Roles'))
    CREATE INDEX IX_Roles_ParentRole ON dbo.Roles (ParentRoleID);
/* Roles.CompanyID is covered by UQ_Roles_Company_Key / UQ_Roles_Company_Code. */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_RolePagePermissions_SystemPage' AND object_id = OBJECT_ID(N'dbo.RolePagePermissions'))
    CREATE INDEX IX_RolePagePermissions_SystemPage ON dbo.RolePagePermissions (SystemPageID);
/* (RoleID, SystemPageID) is covered by UQ_RolePagePermissions_Role_Page. */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_RolePageActionPermissions_Role_Page' AND object_id = OBJECT_ID(N'dbo.RolePageActionPermissions'))
    CREATE INDEX IX_RolePageActionPermissions_Role_Page ON dbo.RolePageActionPermissions (RoleID, SystemPageID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_RolePageActionPermissions_SystemPage' AND object_id = OBJECT_ID(N'dbo.RolePageActionPermissions'))
    CREATE INDEX IX_RolePageActionPermissions_SystemPage ON dbo.RolePageActionPermissions (SystemPageID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_RolePageActionPermissions_PageAction' AND object_id = OBJECT_ID(N'dbo.RolePageActionPermissions'))
    CREATE INDEX IX_RolePageActionPermissions_PageAction ON dbo.RolePageActionPermissions (PageActionID);
GO

/* ============================ E. User security ============================ */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserSessions_User' AND object_id = OBJECT_ID(N'dbo.UserSessions'))
    CREATE INDEX IX_UserSessions_User ON dbo.UserSessions (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserSessions_Status_ExpiryDate' AND object_id = OBJECT_ID(N'dbo.UserSessions'))
    CREATE INDEX IX_UserSessions_Status_ExpiryDate ON dbo.UserSessions (Status, ExpiryDate);
/* SessionKeyHash is covered by UQ_UserSessions_KeyHash. */
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserLoginHistory_User_LoginDate' AND object_id = OBJECT_ID(N'dbo.UserLoginHistory'))
    CREATE INDEX IX_UserLoginHistory_User_LoginDate ON dbo.UserLoginHistory (UserID, LoginDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserLoginHistory_LoginDate' AND object_id = OBJECT_ID(N'dbo.UserLoginHistory'))
    CREATE INDEX IX_UserLoginHistory_LoginDate ON dbo.UserLoginHistory (LoginDate);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserPasswordHistory_User' AND object_id = OBJECT_ID(N'dbo.UserPasswordHistory'))
    CREATE INDEX IX_UserPasswordHistory_User ON dbo.UserPasswordHistory (UserID);
/* UserSecuritySettings.UserID is covered by UQ_UserSecuritySettings_UserID. */
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserNotifications_User_IsRead' AND object_id = OBJECT_ID(N'dbo.UserNotifications'))
    CREATE INDEX IX_UserNotifications_User_IsRead ON dbo.UserNotifications (UserID, IsRead);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserNotifications_NotificationLog' AND object_id = OBJECT_ID(N'dbo.UserNotifications'))
    CREATE INDEX IX_UserNotifications_NotificationLog ON dbo.UserNotifications (NotificationLogID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserNotifications_Company' AND object_id = OBJECT_ID(N'dbo.UserNotifications'))
    CREATE INDEX IX_UserNotifications_Company ON dbo.UserNotifications (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserNotifications_Branch' AND object_id = OBJECT_ID(N'dbo.UserNotifications'))
    CREATE INDEX IX_UserNotifications_Branch ON dbo.UserNotifications (BranchID);
GO

/* ============================ F. System & permissions ============================ */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SystemPages_SystemModule' AND object_id = OBJECT_ID(N'dbo.SystemPages'))
    CREATE INDEX IX_SystemPages_SystemModule ON dbo.SystemPages (SystemModuleID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SystemPages_ParentPage' AND object_id = OBJECT_ID(N'dbo.SystemPages'))
    CREATE INDEX IX_SystemPages_ParentPage ON dbo.SystemPages (ParentPageID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SubscriptionPlans_Currency' AND object_id = OBJECT_ID(N'dbo.SubscriptionPlans'))
    CREATE INDEX IX_SubscriptionPlans_Currency ON dbo.SubscriptionPlans (CurrencyID);
/* SubscriptionPlanLimits (SubscriptionPlanID, LimitKey) is covered by its unique key. */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SubscriptionPagePermissions_SystemPage' AND object_id = OBJECT_ID(N'dbo.SubscriptionPagePermissions'))
    CREATE INDEX IX_SubscriptionPagePermissions_SystemPage ON dbo.SubscriptionPagePermissions (SystemPageID);
/* (SubscriptionPlanID, SystemPageID) is covered by UQ_SubscriptionPagePermissions_Plan_Page. */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SubscriptionPageActionPermissions_Plan_Page' AND object_id = OBJECT_ID(N'dbo.SubscriptionPageActionPermissions'))
    CREATE INDEX IX_SubscriptionPageActionPermissions_Plan_Page ON dbo.SubscriptionPageActionPermissions (SubscriptionPlanID, SystemPageID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SubscriptionPageActionPermissions_SystemPage' AND object_id = OBJECT_ID(N'dbo.SubscriptionPageActionPermissions'))
    CREATE INDEX IX_SubscriptionPageActionPermissions_SystemPage ON dbo.SubscriptionPageActionPermissions (SystemPageID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SubscriptionPageActionPermissions_PageAction' AND object_id = OBJECT_ID(N'dbo.SubscriptionPageActionPermissions'))
    CREATE INDEX IX_SubscriptionPageActionPermissions_PageAction ON dbo.SubscriptionPageActionPermissions (PageActionID);
GO

/* ============================ I. Notifications ============================ */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_NotificationTemplates_NotificationType' AND object_id = OBJECT_ID(N'dbo.NotificationTemplates'))
    CREATE INDEX IX_NotificationTemplates_NotificationType ON dbo.NotificationTemplates (NotificationTypeID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_NotificationTemplates_Type_Channel_Language' AND object_id = OBJECT_ID(N'dbo.NotificationTemplates'))
    CREATE INDEX IX_NotificationTemplates_Type_Channel_Language ON dbo.NotificationTemplates (NotificationTypeID, Channel, LanguageCode);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_NotificationLogs_NotificationType' AND object_id = OBJECT_ID(N'dbo.NotificationLogs'))
    CREATE INDEX IX_NotificationLogs_NotificationType ON dbo.NotificationLogs (NotificationTypeID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_NotificationLogs_NotificationTemplate' AND object_id = OBJECT_ID(N'dbo.NotificationLogs'))
    CREATE INDEX IX_NotificationLogs_NotificationTemplate ON dbo.NotificationLogs (NotificationTemplateID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_NotificationLogs_Company_CreatedDate' AND object_id = OBJECT_ID(N'dbo.NotificationLogs'))
    CREATE INDEX IX_NotificationLogs_Company_CreatedDate ON dbo.NotificationLogs (CompanyID, CreatedDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_NotificationLogs_User_IsRead' AND object_id = OBJECT_ID(N'dbo.NotificationLogs'))
    CREATE INDEX IX_NotificationLogs_User_IsRead ON dbo.NotificationLogs (UserID, IsRead);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_NotificationLogs_Branch' AND object_id = OBJECT_ID(N'dbo.NotificationLogs'))
    CREATE INDEX IX_NotificationLogs_Branch ON dbo.NotificationLogs (BranchID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_NotificationLogs_Role' AND object_id = OBJECT_ID(N'dbo.NotificationLogs'))
    CREATE INDEX IX_NotificationLogs_Role ON dbo.NotificationLogs (RoleID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserNotificationPreferences_User' AND object_id = OBJECT_ID(N'dbo.UserNotificationPreferences'))
    CREATE INDEX IX_UserNotificationPreferences_User ON dbo.UserNotificationPreferences (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserNotificationPreferences_NotificationType' AND object_id = OBJECT_ID(N'dbo.UserNotificationPreferences'))
    CREATE INDEX IX_UserNotificationPreferences_NotificationType ON dbo.UserNotificationPreferences (NotificationTypeID);
GO

/* ============================ J. Audit / activity ============================ */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AuditLogs_Company_CreatedDate' AND object_id = OBJECT_ID(N'dbo.AuditLogs'))
    CREATE INDEX IX_AuditLogs_Company_CreatedDate ON dbo.AuditLogs (CompanyID, CreatedDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AuditLogs_User_CreatedDate' AND object_id = OBJECT_ID(N'dbo.AuditLogs'))
    CREATE INDEX IX_AuditLogs_User_CreatedDate ON dbo.AuditLogs (UserID, CreatedDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AuditLogs_Entity' AND object_id = OBJECT_ID(N'dbo.AuditLogs'))
    CREATE INDEX IX_AuditLogs_Entity ON dbo.AuditLogs (EntityName, EntityID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AuditLogs_Branch' AND object_id = OBJECT_ID(N'dbo.AuditLogs'))
    CREATE INDEX IX_AuditLogs_Branch ON dbo.AuditLogs (BranchID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_AuditLogs_CorrelationID' AND object_id = OBJECT_ID(N'dbo.AuditLogs'))
    CREATE INDEX IX_AuditLogs_CorrelationID ON dbo.AuditLogs (CorrelationID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ActivityLogs_Company_CreatedDate' AND object_id = OBJECT_ID(N'dbo.ActivityLogs'))
    CREATE INDEX IX_ActivityLogs_Company_CreatedDate ON dbo.ActivityLogs (CompanyID, CreatedDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ActivityLogs_User_CreatedDate' AND object_id = OBJECT_ID(N'dbo.ActivityLogs'))
    CREATE INDEX IX_ActivityLogs_User_CreatedDate ON dbo.ActivityLogs (UserID, CreatedDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ActivityLogs_Entity' AND object_id = OBJECT_ID(N'dbo.ActivityLogs'))
    CREATE INDEX IX_ActivityLogs_Entity ON dbo.ActivityLogs (EntityName, EntityID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ActivityLogs_Branch' AND object_id = OBJECT_ID(N'dbo.ActivityLogs'))
    CREATE INDEX IX_ActivityLogs_Branch ON dbo.ActivityLogs (BranchID);
GO

/* ============================ K. Error / system ============================ */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ErrorLogs_Status_OccurredDate' AND object_id = OBJECT_ID(N'dbo.ErrorLogs'))
    CREATE INDEX IX_ErrorLogs_Status_OccurredDate ON dbo.ErrorLogs (Status, OccurredDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ErrorLogs_Severity' AND object_id = OBJECT_ID(N'dbo.ErrorLogs'))
    CREATE INDEX IX_ErrorLogs_Severity ON dbo.ErrorLogs (Severity);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ErrorLogs_Company_OccurredDate' AND object_id = OBJECT_ID(N'dbo.ErrorLogs'))
    CREATE INDEX IX_ErrorLogs_Company_OccurredDate ON dbo.ErrorLogs (CompanyID, OccurredDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ErrorLogs_AssignedToUser' AND object_id = OBJECT_ID(N'dbo.ErrorLogs'))
    CREATE INDEX IX_ErrorLogs_AssignedToUser ON dbo.ErrorLogs (AssignedToUserID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ErrorLogs_CorrelationID' AND object_id = OBJECT_ID(N'dbo.ErrorLogs'))
    CREATE INDEX IX_ErrorLogs_CorrelationID ON dbo.ErrorLogs (CorrelationID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ErrorLogs_Branch' AND object_id = OBJECT_ID(N'dbo.ErrorLogs'))
    CREATE INDEX IX_ErrorLogs_Branch ON dbo.ErrorLogs (BranchID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SystemLogs_CreatedDate' AND object_id = OBJECT_ID(N'dbo.SystemLogs'))
    CREATE INDEX IX_SystemLogs_CreatedDate ON dbo.SystemLogs (CreatedDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SystemLogs_LogLevel_CreatedDate' AND object_id = OBJECT_ID(N'dbo.SystemLogs'))
    CREATE INDEX IX_SystemLogs_LogLevel_CreatedDate ON dbo.SystemLogs (LogLevel, CreatedDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SystemLogs_CorrelationID' AND object_id = OBJECT_ID(N'dbo.SystemLogs'))
    CREATE INDEX IX_SystemLogs_CorrelationID ON dbo.SystemLogs (CorrelationID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_SystemLogs_Company' AND object_id = OBJECT_ID(N'dbo.SystemLogs'))
    CREATE INDEX IX_SystemLogs_Company ON dbo.SystemLogs (CompanyID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BackupLogs_Status_StartedDate' AND object_id = OBJECT_ID(N'dbo.BackupLogs'))
    CREATE INDEX IX_BackupLogs_Status_StartedDate ON dbo.BackupLogs (Status, StartedDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_BackupLogs_CorrelationID' AND object_id = OBJECT_ID(N'dbo.BackupLogs'))
    CREATE INDEX IX_BackupLogs_CorrelationID ON dbo.BackupLogs (CorrelationID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_MaintenanceLogs_Status_StartedDate' AND object_id = OBJECT_ID(N'dbo.MaintenanceLogs'))
    CREATE INDEX IX_MaintenanceLogs_Status_StartedDate ON dbo.MaintenanceLogs (Status, StartedDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_MaintenanceLogs_Company' AND object_id = OBJECT_ID(N'dbo.MaintenanceLogs'))
    CREATE INDEX IX_MaintenanceLogs_Company ON dbo.MaintenanceLogs (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_MaintenanceLogs_Branch' AND object_id = OBJECT_ID(N'dbo.MaintenanceLogs'))
    CREATE INDEX IX_MaintenanceLogs_Branch ON dbo.MaintenanceLogs (BranchID);
GO

PRINT N'03_Indexes.sql completed.';
GO
