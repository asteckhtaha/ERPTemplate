/* ============================================================================================
   ERPTemplate — 02_ForeignKeys.sql
   --------------------------------------------------------------------------------------------
   Purpose : Create every approved FOREIGN KEY relationship using SQL Server syntax.
   Target  : SQL Server 2019 or later. Schema: dbo.
   Run after: 01_Tables.sql

   Rules applied
   - Only relationships specified in the approved schema are created; nothing was added.
   - Audit columns (CreatedBy / UpdatedBy / DeletedBy / ChangedBy / RevokedBy / PerformedBy /
     ResolvedBy / AssignedToUserID / InitiatedBy) reference dbo.Users because the approved schema
     states "FK" / "FK -> Users" for those columns.
   - Users.CreatedBy references dbo.Users (self reference, documented in the approved schema).
   - Naming: FK_<ChildTable>_<ParentColumn>  (e.g. FK_Branches_Company)
   - ON DELETE / ON UPDATE are NO ACTION (SQL Server default). Deletes are soft deletes performed by
     the application inside transactions, so no cascade rules are introduced.

   Idempotent: each foreign key is created only when a constraint with that name does not exist.

   ON HOLD — PENDING APPROVAL (docs/DATABASE-SCHEMA-REVIEW.md item 1):
     RolePageActionPermissions.PageActionID          -> dbo.SystemActions(ActionID)
     SubscriptionPageActionPermissions.PageActionID -> dbo.SystemActions(ActionID)
   Both columns stay INT NOT NULL as approved; only the referenced table is unclear.
   ============================================================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================ Company module ============================ */

/* 1. Companies -> audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Companies_CreatedBy')
    ALTER TABLE dbo.Companies ADD CONSTRAINT FK_Companies_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Companies_UpdatedBy')
    ALTER TABLE dbo.Companies ADD CONSTRAINT FK_Companies_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Companies_DeletedBy')
    ALTER TABLE dbo.Companies ADD CONSTRAINT FK_Companies_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 2. CompanyProfiles -> Companies, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanyProfiles_Company')
    ALTER TABLE dbo.CompanyProfiles ADD CONSTRAINT FK_CompanyProfiles_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanyProfiles_CreatedBy')
    ALTER TABLE dbo.CompanyProfiles ADD CONSTRAINT FK_CompanyProfiles_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanyProfiles_UpdatedBy')
    ALTER TABLE dbo.CompanyProfiles ADD CONSTRAINT FK_CompanyProfiles_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanyProfiles_DeletedBy')
    ALTER TABLE dbo.CompanyProfiles ADD CONSTRAINT FK_CompanyProfiles_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 3. CompanySettings -> Companies, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySettings_Company')
    ALTER TABLE dbo.CompanySettings ADD CONSTRAINT FK_CompanySettings_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySettings_CreatedBy')
    ALTER TABLE dbo.CompanySettings ADD CONSTRAINT FK_CompanySettings_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySettings_UpdatedBy')
    ALTER TABLE dbo.CompanySettings ADD CONSTRAINT FK_CompanySettings_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySettings_DeletedBy')
    ALTER TABLE dbo.CompanySettings ADD CONSTRAINT FK_CompanySettings_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 4. CompanySubscriptions -> Companies, SubscriptionPlans, Currencies, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptions_Company')
    ALTER TABLE dbo.CompanySubscriptions ADD CONSTRAINT FK_CompanySubscriptions_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptions_SubscriptionPlan')
    ALTER TABLE dbo.CompanySubscriptions ADD CONSTRAINT FK_CompanySubscriptions_SubscriptionPlan FOREIGN KEY (SubscriptionPlanID) REFERENCES dbo.SubscriptionPlans (SubscriptionPlanID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptions_Currency')
    ALTER TABLE dbo.CompanySubscriptions ADD CONSTRAINT FK_CompanySubscriptions_Currency FOREIGN KEY (CurrencyID) REFERENCES dbo.Currencies (CurrencyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptions_CreatedBy')
    ALTER TABLE dbo.CompanySubscriptions ADD CONSTRAINT FK_CompanySubscriptions_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptions_UpdatedBy')
    ALTER TABLE dbo.CompanySubscriptions ADD CONSTRAINT FK_CompanySubscriptions_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptions_DeletedBy')
    ALTER TABLE dbo.CompanySubscriptions ADD CONSTRAINT FK_CompanySubscriptions_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 5. CompanySubscriptionHistory -> CompanySubscriptions, Companies, SubscriptionPlans, Users */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionHistory_CompanySubscription')
    ALTER TABLE dbo.CompanySubscriptionHistory ADD CONSTRAINT FK_CompanySubscriptionHistory_CompanySubscription FOREIGN KEY (CompanySubscriptionID) REFERENCES dbo.CompanySubscriptions (CompanySubscriptionID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionHistory_Company')
    ALTER TABLE dbo.CompanySubscriptionHistory ADD CONSTRAINT FK_CompanySubscriptionHistory_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionHistory_PreviousPlan')
    ALTER TABLE dbo.CompanySubscriptionHistory ADD CONSTRAINT FK_CompanySubscriptionHistory_PreviousPlan FOREIGN KEY (PreviousPlanID) REFERENCES dbo.SubscriptionPlans (SubscriptionPlanID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionHistory_NewPlan')
    ALTER TABLE dbo.CompanySubscriptionHistory ADD CONSTRAINT FK_CompanySubscriptionHistory_NewPlan FOREIGN KEY (NewPlanID) REFERENCES dbo.SubscriptionPlans (SubscriptionPlanID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionHistory_ChangedBy')
    ALTER TABLE dbo.CompanySubscriptionHistory ADD CONSTRAINT FK_CompanySubscriptionHistory_ChangedBy FOREIGN KEY (ChangedBy) REFERENCES dbo.Users (UserID);
GO

/* 6. CompanySubscriptionUsage -> CompanySubscriptions, Companies, SubscriptionPlanLimits, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionUsage_CompanySubscription')
    ALTER TABLE dbo.CompanySubscriptionUsage ADD CONSTRAINT FK_CompanySubscriptionUsage_CompanySubscription FOREIGN KEY (CompanySubscriptionID) REFERENCES dbo.CompanySubscriptions (CompanySubscriptionID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionUsage_Company')
    ALTER TABLE dbo.CompanySubscriptionUsage ADD CONSTRAINT FK_CompanySubscriptionUsage_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionUsage_SubscriptionPlanLimit')
    ALTER TABLE dbo.CompanySubscriptionUsage ADD CONSTRAINT FK_CompanySubscriptionUsage_SubscriptionPlanLimit FOREIGN KEY (SubscriptionPlanLimitID) REFERENCES dbo.SubscriptionPlanLimits (SubscriptionPlanLimitID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionUsage_CreatedBy')
    ALTER TABLE dbo.CompanySubscriptionUsage ADD CONSTRAINT FK_CompanySubscriptionUsage_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionUsage_UpdatedBy')
    ALTER TABLE dbo.CompanySubscriptionUsage ADD CONSTRAINT FK_CompanySubscriptionUsage_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionUsage_DeletedBy')
    ALTER TABLE dbo.CompanySubscriptionUsage ADD CONSTRAINT FK_CompanySubscriptionUsage_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 7. CompanySubscriptionInvoices -> Companies, CompanySubscriptions, Currencies, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionInvoices_Company')
    ALTER TABLE dbo.CompanySubscriptionInvoices ADD CONSTRAINT FK_CompanySubscriptionInvoices_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionInvoices_CompanySubscription')
    ALTER TABLE dbo.CompanySubscriptionInvoices ADD CONSTRAINT FK_CompanySubscriptionInvoices_CompanySubscription FOREIGN KEY (CompanySubscriptionID) REFERENCES dbo.CompanySubscriptions (CompanySubscriptionID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionInvoices_Currency')
    ALTER TABLE dbo.CompanySubscriptionInvoices ADD CONSTRAINT FK_CompanySubscriptionInvoices_Currency FOREIGN KEY (CurrencyID) REFERENCES dbo.Currencies (CurrencyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionInvoices_CreatedBy')
    ALTER TABLE dbo.CompanySubscriptionInvoices ADD CONSTRAINT FK_CompanySubscriptionInvoices_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionInvoices_UpdatedBy')
    ALTER TABLE dbo.CompanySubscriptionInvoices ADD CONSTRAINT FK_CompanySubscriptionInvoices_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionInvoices_DeletedBy')
    ALTER TABLE dbo.CompanySubscriptionInvoices ADD CONSTRAINT FK_CompanySubscriptionInvoices_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 8. CompanySubscriptionPayments -> Companies, CompanySubscriptionInvoices, Currencies, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionPayments_Company')
    ALTER TABLE dbo.CompanySubscriptionPayments ADD CONSTRAINT FK_CompanySubscriptionPayments_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionPayments_CompanySubscriptionInvoice')
    ALTER TABLE dbo.CompanySubscriptionPayments ADD CONSTRAINT FK_CompanySubscriptionPayments_CompanySubscriptionInvoice FOREIGN KEY (CompanySubscriptionInvoiceID) REFERENCES dbo.CompanySubscriptionInvoices (CompanySubscriptionInvoiceID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionPayments_Currency')
    ALTER TABLE dbo.CompanySubscriptionPayments ADD CONSTRAINT FK_CompanySubscriptionPayments_Currency FOREIGN KEY (CurrencyID) REFERENCES dbo.Currencies (CurrencyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionPayments_CreatedBy')
    ALTER TABLE dbo.CompanySubscriptionPayments ADD CONSTRAINT FK_CompanySubscriptionPayments_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionPayments_UpdatedBy')
    ALTER TABLE dbo.CompanySubscriptionPayments ADD CONSTRAINT FK_CompanySubscriptionPayments_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionPayments_DeletedBy')
    ALTER TABLE dbo.CompanySubscriptionPayments ADD CONSTRAINT FK_CompanySubscriptionPayments_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 9. CompanySubscriptionCredits -> Companies, CompanySubscriptions, CompanySubscriptionInvoices, Currencies, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionCredits_Company')
    ALTER TABLE dbo.CompanySubscriptionCredits ADD CONSTRAINT FK_CompanySubscriptionCredits_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionCredits_CompanySubscription')
    ALTER TABLE dbo.CompanySubscriptionCredits ADD CONSTRAINT FK_CompanySubscriptionCredits_CompanySubscription FOREIGN KEY (CompanySubscriptionID) REFERENCES dbo.CompanySubscriptions (CompanySubscriptionID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionCredits_CompanySubscriptionInvoice')
    ALTER TABLE dbo.CompanySubscriptionCredits ADD CONSTRAINT FK_CompanySubscriptionCredits_CompanySubscriptionInvoice FOREIGN KEY (CompanySubscriptionInvoiceID) REFERENCES dbo.CompanySubscriptionInvoices (CompanySubscriptionInvoiceID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionCredits_Currency')
    ALTER TABLE dbo.CompanySubscriptionCredits ADD CONSTRAINT FK_CompanySubscriptionCredits_Currency FOREIGN KEY (CurrencyID) REFERENCES dbo.Currencies (CurrencyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionCredits_CreatedBy')
    ALTER TABLE dbo.CompanySubscriptionCredits ADD CONSTRAINT FK_CompanySubscriptionCredits_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionCredits_UpdatedBy')
    ALTER TABLE dbo.CompanySubscriptionCredits ADD CONSTRAINT FK_CompanySubscriptionCredits_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CompanySubscriptionCredits_DeletedBy')
    ALTER TABLE dbo.CompanySubscriptionCredits ADD CONSTRAINT FK_CompanySubscriptionCredits_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* ============================ Branch module ============================ */

/* 10. Branches -> Companies, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Branches_Company')
    ALTER TABLE dbo.Branches ADD CONSTRAINT FK_Branches_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Branches_CreatedBy')
    ALTER TABLE dbo.Branches ADD CONSTRAINT FK_Branches_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Branches_UpdatedBy')
    ALTER TABLE dbo.Branches ADD CONSTRAINT FK_Branches_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Branches_DeletedBy')
    ALTER TABLE dbo.Branches ADD CONSTRAINT FK_Branches_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 11. BranchProfiles -> Branches, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BranchProfiles_Branch')
    ALTER TABLE dbo.BranchProfiles ADD CONSTRAINT FK_BranchProfiles_Branch FOREIGN KEY (BranchID) REFERENCES dbo.Branches (BranchID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BranchProfiles_CreatedBy')
    ALTER TABLE dbo.BranchProfiles ADD CONSTRAINT FK_BranchProfiles_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BranchProfiles_UpdatedBy')
    ALTER TABLE dbo.BranchProfiles ADD CONSTRAINT FK_BranchProfiles_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BranchProfiles_DeletedBy')
    ALTER TABLE dbo.BranchProfiles ADD CONSTRAINT FK_BranchProfiles_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 12. BranchSettings -> Branches, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BranchSettings_Branch')
    ALTER TABLE dbo.BranchSettings ADD CONSTRAINT FK_BranchSettings_Branch FOREIGN KEY (BranchID) REFERENCES dbo.Branches (BranchID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BranchSettings_CreatedBy')
    ALTER TABLE dbo.BranchSettings ADD CONSTRAINT FK_BranchSettings_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BranchSettings_UpdatedBy')
    ALTER TABLE dbo.BranchSettings ADD CONSTRAINT FK_BranchSettings_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BranchSettings_DeletedBy')
    ALTER TABLE dbo.BranchSettings ADD CONSTRAINT FK_BranchSettings_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* ============================ Users & security ============================ */

/* 13. Users -> UserTypes, self reference on audit columns */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Users_UserType')
    ALTER TABLE dbo.Users ADD CONSTRAINT FK_Users_UserType FOREIGN KEY (UserTypeID) REFERENCES dbo.UserTypes (UserTypeID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Users_CreatedBy')
    ALTER TABLE dbo.Users ADD CONSTRAINT FK_Users_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Users_UpdatedBy')
    ALTER TABLE dbo.Users ADD CONSTRAINT FK_Users_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Users_DeletedBy')
    ALTER TABLE dbo.Users ADD CONSTRAINT FK_Users_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 14. UserTypes -> audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserTypes_CreatedBy')
    ALTER TABLE dbo.UserTypes ADD CONSTRAINT FK_UserTypes_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserTypes_UpdatedBy')
    ALTER TABLE dbo.UserTypes ADD CONSTRAINT FK_UserTypes_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserTypes_DeletedBy')
    ALTER TABLE dbo.UserTypes ADD CONSTRAINT FK_UserTypes_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 15. UserProfiles -> Users, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserProfiles_User')
    ALTER TABLE dbo.UserProfiles ADD CONSTRAINT FK_UserProfiles_User FOREIGN KEY (UserID) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserProfiles_CreatedBy')
    ALTER TABLE dbo.UserProfiles ADD CONSTRAINT FK_UserProfiles_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserProfiles_UpdatedBy')
    ALTER TABLE dbo.UserProfiles ADD CONSTRAINT FK_UserProfiles_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserProfiles_DeletedBy')
    ALTER TABLE dbo.UserProfiles ADD CONSTRAINT FK_UserProfiles_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 16. UserCompanyAccess -> Users, Companies, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserCompanyAccess_User')
    ALTER TABLE dbo.UserCompanyAccess ADD CONSTRAINT FK_UserCompanyAccess_User FOREIGN KEY (UserID) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserCompanyAccess_Company')
    ALTER TABLE dbo.UserCompanyAccess ADD CONSTRAINT FK_UserCompanyAccess_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserCompanyAccess_CreatedBy')
    ALTER TABLE dbo.UserCompanyAccess ADD CONSTRAINT FK_UserCompanyAccess_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserCompanyAccess_UpdatedBy')
    ALTER TABLE dbo.UserCompanyAccess ADD CONSTRAINT FK_UserCompanyAccess_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserCompanyAccess_DeletedBy')
    ALTER TABLE dbo.UserCompanyAccess ADD CONSTRAINT FK_UserCompanyAccess_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 17. UserBranchAccess -> Users, Companies, Branches, audit
   "DB must enforce Branch belongs to Company" — enforced by the composite context FK pair below:
   FK_UserBranchAccess_Branch          : BranchID -> Branches(BranchID)
   FK_UserBranchAccess_Company         : CompanyID -> Companies(CompanyID)
   FK_UserBranchAccess_Branch_Company  : (BranchID, CompanyID) -> Branches(BranchID, CompanyID)
   The third one requires the UQ_Branches_Branch_Company unique key created in 04_Constraints.sql
   (it is the technical implementation of the approved rule and adds no new column). */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserBranchAccess_User')
    ALTER TABLE dbo.UserBranchAccess ADD CONSTRAINT FK_UserBranchAccess_User FOREIGN KEY (UserID) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserBranchAccess_Company')
    ALTER TABLE dbo.UserBranchAccess ADD CONSTRAINT FK_UserBranchAccess_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserBranchAccess_Branch')
    ALTER TABLE dbo.UserBranchAccess ADD CONSTRAINT FK_UserBranchAccess_Branch FOREIGN KEY (BranchID) REFERENCES dbo.Branches (BranchID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserBranchAccess_CreatedBy')
    ALTER TABLE dbo.UserBranchAccess ADD CONSTRAINT FK_UserBranchAccess_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserBranchAccess_UpdatedBy')
    ALTER TABLE dbo.UserBranchAccess ADD CONSTRAINT FK_UserBranchAccess_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserBranchAccess_DeletedBy')
    ALTER TABLE dbo.UserBranchAccess ADD CONSTRAINT FK_UserBranchAccess_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 18. UserRoleAssignments -> Users, Companies, Branches, Roles, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserRoleAssignments_User')
    ALTER TABLE dbo.UserRoleAssignments ADD CONSTRAINT FK_UserRoleAssignments_User FOREIGN KEY (UserID) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserRoleAssignments_Company')
    ALTER TABLE dbo.UserRoleAssignments ADD CONSTRAINT FK_UserRoleAssignments_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserRoleAssignments_Branch')
    ALTER TABLE dbo.UserRoleAssignments ADD CONSTRAINT FK_UserRoleAssignments_Branch FOREIGN KEY (BranchID) REFERENCES dbo.Branches (BranchID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserRoleAssignments_Role')
    ALTER TABLE dbo.UserRoleAssignments ADD CONSTRAINT FK_UserRoleAssignments_Role FOREIGN KEY (RoleID) REFERENCES dbo.Roles (RoleID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserRoleAssignments_CreatedBy')
    ALTER TABLE dbo.UserRoleAssignments ADD CONSTRAINT FK_UserRoleAssignments_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserRoleAssignments_UpdatedBy')
    ALTER TABLE dbo.UserRoleAssignments ADD CONSTRAINT FK_UserRoleAssignments_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserRoleAssignments_DeletedBy')
    ALTER TABLE dbo.UserRoleAssignments ADD CONSTRAINT FK_UserRoleAssignments_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* ============================ Roles ============================ */

/* 19. Roles -> Companies, self (ParentRoleID), audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Roles_Company')
    ALTER TABLE dbo.Roles ADD CONSTRAINT FK_Roles_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Roles_ParentRole')
    ALTER TABLE dbo.Roles ADD CONSTRAINT FK_Roles_ParentRole FOREIGN KEY (ParentRoleID) REFERENCES dbo.Roles (RoleID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Roles_CreatedBy')
    ALTER TABLE dbo.Roles ADD CONSTRAINT FK_Roles_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Roles_UpdatedBy')
    ALTER TABLE dbo.Roles ADD CONSTRAINT FK_Roles_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Roles_DeletedBy')
    ALTER TABLE dbo.Roles ADD CONSTRAINT FK_Roles_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 20. RolePagePermissions -> Roles, SystemPages, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_RolePagePermissions_Role')
    ALTER TABLE dbo.RolePagePermissions ADD CONSTRAINT FK_RolePagePermissions_Role FOREIGN KEY (RoleID) REFERENCES dbo.Roles (RoleID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_RolePagePermissions_SystemPage')
    ALTER TABLE dbo.RolePagePermissions ADD CONSTRAINT FK_RolePagePermissions_SystemPage FOREIGN KEY (SystemPageID) REFERENCES dbo.SystemPages (SystemPageID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_RolePagePermissions_CreatedBy')
    ALTER TABLE dbo.RolePagePermissions ADD CONSTRAINT FK_RolePagePermissions_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_RolePagePermissions_UpdatedBy')
    ALTER TABLE dbo.RolePagePermissions ADD CONSTRAINT FK_RolePagePermissions_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_RolePagePermissions_DeletedBy')
    ALTER TABLE dbo.RolePagePermissions ADD CONSTRAINT FK_RolePagePermissions_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 21. RolePageActionPermissions -> Roles, SystemPages, audit
   (PageActionID FK ON HOLD — see file header.) */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_RolePageActionPermissions_Role')
    ALTER TABLE dbo.RolePageActionPermissions ADD CONSTRAINT FK_RolePageActionPermissions_Role FOREIGN KEY (RoleID) REFERENCES dbo.Roles (RoleID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_RolePageActionPermissions_SystemPage')
    ALTER TABLE dbo.RolePageActionPermissions ADD CONSTRAINT FK_RolePageActionPermissions_SystemPage FOREIGN KEY (SystemPageID) REFERENCES dbo.SystemPages (SystemPageID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_RolePageActionPermissions_CreatedBy')
    ALTER TABLE dbo.RolePageActionPermissions ADD CONSTRAINT FK_RolePageActionPermissions_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_RolePageActionPermissions_UpdatedBy')
    ALTER TABLE dbo.RolePageActionPermissions ADD CONSTRAINT FK_RolePageActionPermissions_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_RolePageActionPermissions_DeletedBy')
    ALTER TABLE dbo.RolePageActionPermissions ADD CONSTRAINT FK_RolePageActionPermissions_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* ============================ User security ============================ */

/* 22. UserSessions -> Users, Companies, Branches, Users (RevokedBy) */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserSessions_User')
    ALTER TABLE dbo.UserSessions ADD CONSTRAINT FK_UserSessions_User FOREIGN KEY (UserID) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserSessions_Company')
    ALTER TABLE dbo.UserSessions ADD CONSTRAINT FK_UserSessions_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserSessions_Branch')
    ALTER TABLE dbo.UserSessions ADD CONSTRAINT FK_UserSessions_Branch FOREIGN KEY (BranchID) REFERENCES dbo.Branches (BranchID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserSessions_RevokedBy')
    ALTER TABLE dbo.UserSessions ADD CONSTRAINT FK_UserSessions_RevokedBy FOREIGN KEY (RevokedBy) REFERENCES dbo.Users (UserID);
GO

/* 23. UserLoginHistory -> Users, Companies, Branches */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserLoginHistory_User')
    ALTER TABLE dbo.UserLoginHistory ADD CONSTRAINT FK_UserLoginHistory_User FOREIGN KEY (UserID) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserLoginHistory_Company')
    ALTER TABLE dbo.UserLoginHistory ADD CONSTRAINT FK_UserLoginHistory_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserLoginHistory_Branch')
    ALTER TABLE dbo.UserLoginHistory ADD CONSTRAINT FK_UserLoginHistory_Branch FOREIGN KEY (BranchID) REFERENCES dbo.Branches (BranchID);
GO

/* 24. UserPasswordHistory -> Users, Users (ChangedBy) */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserPasswordHistory_User')
    ALTER TABLE dbo.UserPasswordHistory ADD CONSTRAINT FK_UserPasswordHistory_User FOREIGN KEY (UserID) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserPasswordHistory_ChangedBy')
    ALTER TABLE dbo.UserPasswordHistory ADD CONSTRAINT FK_UserPasswordHistory_ChangedBy FOREIGN KEY (ChangedBy) REFERENCES dbo.Users (UserID);
GO

/* 25. UserSecuritySettings -> Users, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserSecuritySettings_User')
    ALTER TABLE dbo.UserSecuritySettings ADD CONSTRAINT FK_UserSecuritySettings_User FOREIGN KEY (UserID) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserSecuritySettings_CreatedBy')
    ALTER TABLE dbo.UserSecuritySettings ADD CONSTRAINT FK_UserSecuritySettings_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserSecuritySettings_UpdatedBy')
    ALTER TABLE dbo.UserSecuritySettings ADD CONSTRAINT FK_UserSecuritySettings_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserSecuritySettings_DeletedBy')
    ALTER TABLE dbo.UserSecuritySettings ADD CONSTRAINT FK_UserSecuritySettings_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 26. UserNotifications -> NotificationLogs, Users, Companies, Branches */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserNotifications_NotificationLog')
    ALTER TABLE dbo.UserNotifications ADD CONSTRAINT FK_UserNotifications_NotificationLog FOREIGN KEY (NotificationLogID) REFERENCES dbo.NotificationLogs (NotificationLogID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserNotifications_User')
    ALTER TABLE dbo.UserNotifications ADD CONSTRAINT FK_UserNotifications_User FOREIGN KEY (UserID) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserNotifications_Company')
    ALTER TABLE dbo.UserNotifications ADD CONSTRAINT FK_UserNotifications_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserNotifications_Branch')
    ALTER TABLE dbo.UserNotifications ADD CONSTRAINT FK_UserNotifications_Branch FOREIGN KEY (BranchID) REFERENCES dbo.Branches (BranchID);
GO

/* ============================ System & permissions ============================ */

/* 27. SystemModules -> audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SystemModules_CreatedBy')
    ALTER TABLE dbo.SystemModules ADD CONSTRAINT FK_SystemModules_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SystemModules_UpdatedBy')
    ALTER TABLE dbo.SystemModules ADD CONSTRAINT FK_SystemModules_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SystemModules_DeletedBy')
    ALTER TABLE dbo.SystemModules ADD CONSTRAINT FK_SystemModules_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 28. SystemPages -> SystemModules, self (ParentPageID), audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SystemPages_SystemModule')
    ALTER TABLE dbo.SystemPages ADD CONSTRAINT FK_SystemPages_SystemModule FOREIGN KEY (SystemModuleID) REFERENCES dbo.SystemModules (SystemModuleID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SystemPages_ParentPage')
    ALTER TABLE dbo.SystemPages ADD CONSTRAINT FK_SystemPages_ParentPage FOREIGN KEY (ParentPageID) REFERENCES dbo.SystemPages (SystemPageID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SystemPages_CreatedBy')
    ALTER TABLE dbo.SystemPages ADD CONSTRAINT FK_SystemPages_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SystemPages_UpdatedBy')
    ALTER TABLE dbo.SystemPages ADD CONSTRAINT FK_SystemPages_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SystemPages_DeletedBy')
    ALTER TABLE dbo.SystemPages ADD CONSTRAINT FK_SystemPages_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 29. SystemActions -> audit (global action master; target of PageActionID — see header note) */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SystemActions_CreatedBy')
    ALTER TABLE dbo.SystemActions ADD CONSTRAINT FK_SystemActions_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SystemActions_UpdatedBy')
    ALTER TABLE dbo.SystemActions ADD CONSTRAINT FK_SystemActions_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SystemActions_DeletedBy')
    ALTER TABLE dbo.SystemActions ADD CONSTRAINT FK_SystemActions_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 30. SubscriptionPlans -> Currencies, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPlans_Currency')
    ALTER TABLE dbo.SubscriptionPlans ADD CONSTRAINT FK_SubscriptionPlans_Currency FOREIGN KEY (CurrencyID) REFERENCES dbo.Currencies (CurrencyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPlans_CreatedBy')
    ALTER TABLE dbo.SubscriptionPlans ADD CONSTRAINT FK_SubscriptionPlans_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPlans_UpdatedBy')
    ALTER TABLE dbo.SubscriptionPlans ADD CONSTRAINT FK_SubscriptionPlans_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPlans_DeletedBy')
    ALTER TABLE dbo.SubscriptionPlans ADD CONSTRAINT FK_SubscriptionPlans_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 31. SubscriptionPlanLimits -> SubscriptionPlans, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPlanLimits_SubscriptionPlan')
    ALTER TABLE dbo.SubscriptionPlanLimits ADD CONSTRAINT FK_SubscriptionPlanLimits_SubscriptionPlan FOREIGN KEY (SubscriptionPlanID) REFERENCES dbo.SubscriptionPlans (SubscriptionPlanID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPlanLimits_CreatedBy')
    ALTER TABLE dbo.SubscriptionPlanLimits ADD CONSTRAINT FK_SubscriptionPlanLimits_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPlanLimits_UpdatedBy')
    ALTER TABLE dbo.SubscriptionPlanLimits ADD CONSTRAINT FK_SubscriptionPlanLimits_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPlanLimits_DeletedBy')
    ALTER TABLE dbo.SubscriptionPlanLimits ADD CONSTRAINT FK_SubscriptionPlanLimits_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 32. SubscriptionPagePermissions -> SubscriptionPlans, SystemPages, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPagePermissions_SubscriptionPlan')
    ALTER TABLE dbo.SubscriptionPagePermissions ADD CONSTRAINT FK_SubscriptionPagePermissions_SubscriptionPlan FOREIGN KEY (SubscriptionPlanID) REFERENCES dbo.SubscriptionPlans (SubscriptionPlanID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPagePermissions_SystemPage')
    ALTER TABLE dbo.SubscriptionPagePermissions ADD CONSTRAINT FK_SubscriptionPagePermissions_SystemPage FOREIGN KEY (SystemPageID) REFERENCES dbo.SystemPages (SystemPageID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPagePermissions_CreatedBy')
    ALTER TABLE dbo.SubscriptionPagePermissions ADD CONSTRAINT FK_SubscriptionPagePermissions_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPagePermissions_UpdatedBy')
    ALTER TABLE dbo.SubscriptionPagePermissions ADD CONSTRAINT FK_SubscriptionPagePermissions_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPagePermissions_DeletedBy')
    ALTER TABLE dbo.SubscriptionPagePermissions ADD CONSTRAINT FK_SubscriptionPagePermissions_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 33. SubscriptionPageActionPermissions -> SubscriptionPlans, SystemPages, audit
   (PageActionID FK ON HOLD — see file header.) */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPageActionPermissions_SubscriptionPlan')
    ALTER TABLE dbo.SubscriptionPageActionPermissions ADD CONSTRAINT FK_SubscriptionPageActionPermissions_SubscriptionPlan FOREIGN KEY (SubscriptionPlanID) REFERENCES dbo.SubscriptionPlans (SubscriptionPlanID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPageActionPermissions_SystemPage')
    ALTER TABLE dbo.SubscriptionPageActionPermissions ADD CONSTRAINT FK_SubscriptionPageActionPermissions_SystemPage FOREIGN KEY (SystemPageID) REFERENCES dbo.SystemPages (SystemPageID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPageActionPermissions_CreatedBy')
    ALTER TABLE dbo.SubscriptionPageActionPermissions ADD CONSTRAINT FK_SubscriptionPageActionPermissions_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPageActionPermissions_UpdatedBy')
    ALTER TABLE dbo.SubscriptionPageActionPermissions ADD CONSTRAINT FK_SubscriptionPageActionPermissions_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SubscriptionPageActionPermissions_DeletedBy')
    ALTER TABLE dbo.SubscriptionPageActionPermissions ADD CONSTRAINT FK_SubscriptionPageActionPermissions_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* ============================ Currency ============================ */

/* 34. Currencies -> audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Currencies_CreatedBy')
    ALTER TABLE dbo.Currencies ADD CONSTRAINT FK_Currencies_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Currencies_UpdatedBy')
    ALTER TABLE dbo.Currencies ADD CONSTRAINT FK_Currencies_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Currencies_DeletedBy')
    ALTER TABLE dbo.Currencies ADD CONSTRAINT FK_Currencies_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* ============================ Notifications ============================ */

/* 35. NotificationTypes -> audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NotificationTypes_CreatedBy')
    ALTER TABLE dbo.NotificationTypes ADD CONSTRAINT FK_NotificationTypes_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NotificationTypes_UpdatedBy')
    ALTER TABLE dbo.NotificationTypes ADD CONSTRAINT FK_NotificationTypes_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NotificationTypes_DeletedBy')
    ALTER TABLE dbo.NotificationTypes ADD CONSTRAINT FK_NotificationTypes_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 36. NotificationTemplates -> NotificationTypes, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NotificationTemplates_NotificationType')
    ALTER TABLE dbo.NotificationTemplates ADD CONSTRAINT FK_NotificationTemplates_NotificationType FOREIGN KEY (NotificationTypeID) REFERENCES dbo.NotificationTypes (NotificationTypeID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NotificationTemplates_CreatedBy')
    ALTER TABLE dbo.NotificationTemplates ADD CONSTRAINT FK_NotificationTemplates_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NotificationTemplates_UpdatedBy')
    ALTER TABLE dbo.NotificationTemplates ADD CONSTRAINT FK_NotificationTemplates_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NotificationTemplates_DeletedBy')
    ALTER TABLE dbo.NotificationTemplates ADD CONSTRAINT FK_NotificationTemplates_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* 37. NotificationLogs -> NotificationTypes, NotificationTemplates, Companies, Branches, Users, Roles */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NotificationLogs_NotificationType')
    ALTER TABLE dbo.NotificationLogs ADD CONSTRAINT FK_NotificationLogs_NotificationType FOREIGN KEY (NotificationTypeID) REFERENCES dbo.NotificationTypes (NotificationTypeID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NotificationLogs_NotificationTemplate')
    ALTER TABLE dbo.NotificationLogs ADD CONSTRAINT FK_NotificationLogs_NotificationTemplate FOREIGN KEY (NotificationTemplateID) REFERENCES dbo.NotificationTemplates (NotificationTemplateID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NotificationLogs_Company')
    ALTER TABLE dbo.NotificationLogs ADD CONSTRAINT FK_NotificationLogs_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NotificationLogs_Branch')
    ALTER TABLE dbo.NotificationLogs ADD CONSTRAINT FK_NotificationLogs_Branch FOREIGN KEY (BranchID) REFERENCES dbo.Branches (BranchID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NotificationLogs_User')
    ALTER TABLE dbo.NotificationLogs ADD CONSTRAINT FK_NotificationLogs_User FOREIGN KEY (UserID) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NotificationLogs_Role')
    ALTER TABLE dbo.NotificationLogs ADD CONSTRAINT FK_NotificationLogs_Role FOREIGN KEY (RoleID) REFERENCES dbo.Roles (RoleID);
GO

/* 38. UserNotificationPreferences -> Users, NotificationTypes, audit */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserNotificationPreferences_User')
    ALTER TABLE dbo.UserNotificationPreferences ADD CONSTRAINT FK_UserNotificationPreferences_User FOREIGN KEY (UserID) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserNotificationPreferences_NotificationType')
    ALTER TABLE dbo.UserNotificationPreferences ADD CONSTRAINT FK_UserNotificationPreferences_NotificationType FOREIGN KEY (NotificationTypeID) REFERENCES dbo.NotificationTypes (NotificationTypeID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserNotificationPreferences_CreatedBy')
    ALTER TABLE dbo.UserNotificationPreferences ADD CONSTRAINT FK_UserNotificationPreferences_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserNotificationPreferences_UpdatedBy')
    ALTER TABLE dbo.UserNotificationPreferences ADD CONSTRAINT FK_UserNotificationPreferences_UpdatedBy FOREIGN KEY (UpdatedBy) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserNotificationPreferences_DeletedBy')
    ALTER TABLE dbo.UserNotificationPreferences ADD CONSTRAINT FK_UserNotificationPreferences_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserID);
GO

/* ============================ Audit / activity ============================ */

/* 39. AuditLogs -> Companies, Branches, Users, Roles */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_AuditLogs_Company')
    ALTER TABLE dbo.AuditLogs ADD CONSTRAINT FK_AuditLogs_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_AuditLogs_Branch')
    ALTER TABLE dbo.AuditLogs ADD CONSTRAINT FK_AuditLogs_Branch FOREIGN KEY (BranchID) REFERENCES dbo.Branches (BranchID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_AuditLogs_User')
    ALTER TABLE dbo.AuditLogs ADD CONSTRAINT FK_AuditLogs_User FOREIGN KEY (UserID) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_AuditLogs_Role')
    ALTER TABLE dbo.AuditLogs ADD CONSTRAINT FK_AuditLogs_Role FOREIGN KEY (RoleID) REFERENCES dbo.Roles (RoleID);
GO

/* 40. ActivityLogs -> Companies, Branches, Users, Roles */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ActivityLogs_Company')
    ALTER TABLE dbo.ActivityLogs ADD CONSTRAINT FK_ActivityLogs_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ActivityLogs_Branch')
    ALTER TABLE dbo.ActivityLogs ADD CONSTRAINT FK_ActivityLogs_Branch FOREIGN KEY (BranchID) REFERENCES dbo.Branches (BranchID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ActivityLogs_User')
    ALTER TABLE dbo.ActivityLogs ADD CONSTRAINT FK_ActivityLogs_User FOREIGN KEY (UserID) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ActivityLogs_Role')
    ALTER TABLE dbo.ActivityLogs ADD CONSTRAINT FK_ActivityLogs_Role FOREIGN KEY (RoleID) REFERENCES dbo.Roles (RoleID);
GO

/* ============================ Error / system ============================ */

/* 41. ErrorLogs -> Companies, Branches, Users, Users (AssignedToUserID), Users (ResolvedBy) */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ErrorLogs_Company')
    ALTER TABLE dbo.ErrorLogs ADD CONSTRAINT FK_ErrorLogs_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ErrorLogs_Branch')
    ALTER TABLE dbo.ErrorLogs ADD CONSTRAINT FK_ErrorLogs_Branch FOREIGN KEY (BranchID) REFERENCES dbo.Branches (BranchID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ErrorLogs_User')
    ALTER TABLE dbo.ErrorLogs ADD CONSTRAINT FK_ErrorLogs_User FOREIGN KEY (UserID) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ErrorLogs_AssignedToUser')
    ALTER TABLE dbo.ErrorLogs ADD CONSTRAINT FK_ErrorLogs_AssignedToUser FOREIGN KEY (AssignedToUserID) REFERENCES dbo.Users (UserID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_ErrorLogs_ResolvedBy')
    ALTER TABLE dbo.ErrorLogs ADD CONSTRAINT FK_ErrorLogs_ResolvedBy FOREIGN KEY (ResolvedBy) REFERENCES dbo.Users (UserID);
GO

/* 42. SystemLogs -> Companies, Branches, Users */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SystemLogs_Company')
    ALTER TABLE dbo.SystemLogs ADD CONSTRAINT FK_SystemLogs_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SystemLogs_Branch')
    ALTER TABLE dbo.SystemLogs ADD CONSTRAINT FK_SystemLogs_Branch FOREIGN KEY (BranchID) REFERENCES dbo.Branches (BranchID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SystemLogs_User')
    ALTER TABLE dbo.SystemLogs ADD CONSTRAINT FK_SystemLogs_User FOREIGN KEY (UserID) REFERENCES dbo.Users (UserID);
GO

/* 43. BackupLogs -> Users (InitiatedBy) */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BackupLogs_InitiatedBy')
    ALTER TABLE dbo.BackupLogs ADD CONSTRAINT FK_BackupLogs_InitiatedBy FOREIGN KEY (InitiatedBy) REFERENCES dbo.Users (UserID);
GO

/* 44. MaintenanceLogs -> Companies, Branches, Users (PerformedBy) */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_MaintenanceLogs_Company')
    ALTER TABLE dbo.MaintenanceLogs ADD CONSTRAINT FK_MaintenanceLogs_Company FOREIGN KEY (CompanyID) REFERENCES dbo.Companies (CompanyID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_MaintenanceLogs_Branch')
    ALTER TABLE dbo.MaintenanceLogs ADD CONSTRAINT FK_MaintenanceLogs_Branch FOREIGN KEY (BranchID) REFERENCES dbo.Branches (BranchID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_MaintenanceLogs_PerformedBy')
    ALTER TABLE dbo.MaintenanceLogs ADD CONSTRAINT FK_MaintenanceLogs_PerformedBy FOREIGN KEY (PerformedBy) REFERENCES dbo.Users (UserID);
GO

PRINT N'02_ForeignKeys.sql completed (2 PageActionID foreign keys intentionally on hold).';
GO
