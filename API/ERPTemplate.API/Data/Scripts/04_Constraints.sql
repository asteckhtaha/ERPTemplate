/* ============================================================================================
   ERPTemplate — 04_Constraints.sql
   --------------------------------------------------------------------------------------------
   Purpose : CHECK constraints and the composite constraints that implement the approved
             "must be consistent" business rules at database level.
   Target  : SQL Server 2019 or later. Schema: dbo.
   Run after: 01_Tables.sql, 02_ForeignKeys.sql, 03_Indexes.sql

   Contents
   A. CHECK constraints where the approved schema specifies the exact rule/values.
   B. Consistency constraints (super-key unique constraints + composite foreign keys) that implement
      the approved DB-level rules:
        - UserBranchAccess   : "DB must enforce Branch belongs to Company"
        - Roles              : "Parent role same Company ka hona mandatory"
        - UserRoleAssignments: "Role/company/branch consistency DB level par enforce hogi"
      These add NO columns and change no business meaning; they only make the approved rules
      enforceable (the technique is documented in docs/DATABASE-SCHEMA-REVIEW.md item 6).

   NOT created here (values not supplied in the approved schema — see
   docs/DATABASE-SCHEMA-REVIEW.md item 3):
     Companies.Status, CompanySettings.SettingDataType, CompanySubscriptions.Status,
     CompanySubscriptionHistory.EventType, CompanySubscriptionInvoices.Status,
     Users.PasswordIterations.
   Supply the exact allowed values and they will be added in a new numbered script.

   ON HOLD — PENDING APPROVAL (docs/DATABASE-SCHEMA-REVIEW.md item 1):
     RolePageActionPermissions        : "same page" constraint (PageActionID + SystemPageID)
     SubscriptionPageActionPermissions: "same page" constraint (PageActionID + SystemPageID)
   Both need the SystemPageActions table, which is not in the approved table list.

   Idempotent: every object is created only when it does not already exist.
   ============================================================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================================================
   A. CHECK constraints (only where the approved schema gave exact values)
   ============================================================================================ */

/* 34. Currencies — DecimalPlaces CHECK 0-6 */
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Currencies_DecimalPlaces')
    ALTER TABLE dbo.Currencies ADD CONSTRAINT CK_Currencies_DecimalPlaces CHECK (DecimalPlaces BETWEEN 0 AND 6);
GO

/* 41. ErrorLogs — approved error workflow:
       NEW -> ACKNOWLEDGED -> IN_PROGRESS -> RESOLVED -> CLOSED */
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ErrorLogs_Status')
    ALTER TABLE dbo.ErrorLogs ADD CONSTRAINT CK_ErrorLogs_Status
        CHECK (Status IN ('NEW', 'ACKNOWLEDGED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'));
GO

/* ============================================================================================
   B. Consistency constraints
   ============================================================================================ */

/* --------------------------------------------------------------------------------------------
   B1. "Branch belongs to Company" (UserBranchAccess)
   Implementation: a super-key unique constraint on Branches (BranchID is already unique as PK, so
   this adds no business meaning) allows the composite foreign key below to guarantee that the
   CompanyID stored on UserBranchAccess is really the branch's company.
   -------------------------------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_Branches_Branch_Company')
    ALTER TABLE dbo.Branches ADD CONSTRAINT UQ_Branches_Branch_Company UNIQUE (BranchID, CompanyID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserBranchAccess_Branch_Company')
    ALTER TABLE dbo.UserBranchAccess ADD CONSTRAINT FK_UserBranchAccess_Branch_Company
        FOREIGN KEY (BranchID, CompanyID) REFERENCES dbo.Branches (BranchID, CompanyID);
GO

/* UserRoleAssignments.BranchID (nullable) must also belong to the same company.
   SQL Server does not check a composite FK when one of the columns is NULL, so "no branch" rows
   remain valid while branch-scoped rows are verified. */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserRoleAssignments_Branch_Company')
    ALTER TABLE dbo.UserRoleAssignments ADD CONSTRAINT FK_UserRoleAssignments_Branch_Company
        FOREIGN KEY (BranchID, CompanyID) REFERENCES dbo.Branches (BranchID, CompanyID);
GO

/* --------------------------------------------------------------------------------------------
   B2. "Parent role same Company ka hona mandatory" (Roles)
   Implementation: super-key unique constraint on Roles (RoleID is already unique as PK) + composite
   self-referencing foreign key. A role can therefore only use a parent role of the same company.
   -------------------------------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = N'UQ_Roles_Role_Company')
    ALTER TABLE dbo.Roles ADD CONSTRAINT UQ_Roles_Role_Company UNIQUE (RoleID, CompanyID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Roles_ParentRole_Company')
    ALTER TABLE dbo.Roles ADD CONSTRAINT FK_Roles_ParentRole_Company
        FOREIGN KEY (ParentRoleID, CompanyID) REFERENCES dbo.Roles (RoleID, CompanyID);
GO

/* --------------------------------------------------------------------------------------------
   B3. "Role/company consistency" (UserRoleAssignments)
   A user's role assignment can only reference a role that belongs to the same company.
   -------------------------------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_UserRoleAssignments_Role_Company')
    ALTER TABLE dbo.UserRoleAssignments ADD CONSTRAINT FK_UserRoleAssignments_Role_Company
        FOREIGN KEY (RoleID, CompanyID) REFERENCES dbo.Roles (RoleID, CompanyID);
GO

/* --------------------------------------------------------------------------------------------
   Not enforceable in the approved schema (documented, needs an approved design):
   UserRoleAssignments — the rule that a role must additionally be allowed for the specific branch
   (RoleID + BranchID) cannot be enforced without a Role/Branch mapping table (e.g. RoleBranches),
   which is not part of the approved schema. Do not add such a table without approval
   (DEVELOPMENT-GUIDELINES.md sections 6.3 and 32).
   -------------------------------------------------------------------------------------------- */

PRINT N'04_Constraints.sql completed.';
GO
