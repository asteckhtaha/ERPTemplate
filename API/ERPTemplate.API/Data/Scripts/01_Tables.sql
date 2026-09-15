/* ============================================================================================
   ERPTemplate — 01_Tables.sql
   --------------------------------------------------------------------------------------------
   Purpose : Create all approved tables (44) with PRIMARY KEY and UNIQUE constraints exactly as
             specified in the approved database schema (source of truth).
   Target  : SQL Server 2019 or later. Schema: dbo.
   Order   : Dependency-friendly order (reference -> company/branch -> users/roles -> system ->
             subscription -> notification -> logs). Foreign keys are added in 02_ForeignKeys.sql,
             so no ordering conflict exists at this stage.

   Rules applied
   - Table names, column names, data types, NULL/NOT NULL, identity columns, defaults and unique
     constraints are taken verbatim from the approved schema. Nothing was added or renamed.
   - DEFAULT values exist only where the approved schema specifies them (Companies.IsActive,
     Companies.IsDeleted). See docs/DATABASE-SCHEMA-REVIEW.md item 5.
   - CHECK constraints are NOT created here (only where the approved schema gave exact values).
     They live in 04_Constraints.sql.
   - Primary key constraints  : PK_<Table>
   - Unique constraints       : UQ_<Table>_<Columns>

   Idempotent: every object is created only when it does not already exist.

   PENDING APPROVAL (see docs/DATABASE-SCHEMA-REVIEW.md):
   1. SystemPageActions table is referenced by the relationship diagram but not present in the
      approved table list -> 2 foreign keys and 2 same-page constraints are on hold.
   ============================================================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* --------------------------------------------------------------------------------------------
   A. Company module
   -------------------------------------------------------------------------------------------- */

/* 1. Companies */
IF OBJECT_ID(N'dbo.Companies', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Companies
    (
        CompanyID          INT             IDENTITY(1,1) NOT NULL,
        CompanyGUID        UNIQUEIDENTIFIER             NOT NULL,
        CompanyKey         VARCHAR(100)                 NOT NULL,
        CompanyCode        VARCHAR(50)                  NOT NULL,
        CompanyName        NVARCHAR(200)                NOT NULL,
        LegalName          NVARCHAR(250)                NULL,
        CompanyType        VARCHAR(50)                  NULL,
        Status             VARCHAR(20)                  NOT NULL,
        RegistrationDate   DATE                         NULL,
        IsActive           BIT                           NOT NULL CONSTRAINT DF_Companies_IsActive  DEFAULT (1),
        IsDeleted          BIT                           NOT NULL CONSTRAINT DF_Companies_IsDeleted DEFAULT (0),
        CreatedBy          INT                           NOT NULL,
        CreatedDate        DATETIME2(3)                  NOT NULL,
        UpdatedBy          INT                           NULL,
        UpdatedDate        DATETIME2(3)                  NULL,
        DeletedBy          INT                           NULL,
        DeletedDate        DATETIME2(3)                  NULL,
        RowVersion         ROWVERSION                     NOT NULL,
        CONSTRAINT PK_Companies         PRIMARY KEY CLUSTERED (CompanyID),
        CONSTRAINT UQ_Companies_GUID    UNIQUE (CompanyGUID),
        CONSTRAINT UQ_Companies_Key     UNIQUE (CompanyKey),
        CONSTRAINT UQ_Companies_Code    UNIQUE (CompanyCode)
    );
END;
GO

/* 2. CompanyProfiles */
IF OBJECT_ID(N'dbo.CompanyProfiles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CompanyProfiles
    (
        CompanyProfileID   INT             IDENTITY(1,1) NOT NULL,
        CompanyProfileGUID UNIQUEIDENTIFIER             NOT NULL,
        CompanyID          INT                          NOT NULL,
        DisplayName        NVARCHAR(200)                NULL,
        LegalName          NVARCHAR(250)                NULL,
        RegistrationNumber VARCHAR(100)                 NULL,
        TaxNumber          VARCHAR(100)                 NULL,
        Phone              VARCHAR(30)                  NULL,
        AlternatePhone     VARCHAR(30)                  NULL,
        Email              VARCHAR(254)                 NULL,
        Website            VARCHAR(300)                 NULL,
        AddressLine1       NVARCHAR(250)                NULL,
        AddressLine2       NVARCHAR(250)                NULL,
        Area               NVARCHAR(100)                NULL,
        City               NVARCHAR(100)                NULL,
        StateProvince      NVARCHAR(100)                NULL,
        Country            NVARCHAR(100)                NULL,
        CountryCode        CHAR(2)                      NULL,
        PostalCode         VARCHAR(20)                  NULL,
        LogoPath           NVARCHAR(500)                NULL,
        Description        NVARCHAR(500)                NULL,
        IsActive           BIT                          NOT NULL,
        IsDeleted          BIT                          NOT NULL,
        CreatedBy          INT                          NOT NULL,
        CreatedDate        DATETIME2(3)                 NOT NULL,
        UpdatedBy          INT                          NULL,
        UpdatedDate        DATETIME2(3)                 NULL,
        DeletedBy          INT                          NULL,
        DeletedDate        DATETIME2(3)                 NULL,
        RowVersion         ROWVERSION                   NOT NULL,
        CONSTRAINT PK_CompanyProfiles              PRIMARY KEY CLUSTERED (CompanyProfileID),
        CONSTRAINT UQ_CompanyProfiles_GUID         UNIQUE (CompanyProfileGUID),
        CONSTRAINT UQ_CompanyProfiles_CompanyID    UNIQUE (CompanyID)
    );
END;
GO

/* 3. CompanySettings */
IF OBJECT_ID(N'dbo.CompanySettings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CompanySettings
    (
        CompanySettingID   BIGINT          IDENTITY(1,1) NOT NULL,
        CompanySettingGUID UNIQUEIDENTIFIER             NOT NULL,
        CompanyID          INT                          NOT NULL,
        SettingKey         VARCHAR(100)                 NOT NULL,
        SettingValue       NVARCHAR(MAX)                NULL,
        SettingDataType    VARCHAR(20)                  NOT NULL,
        SettingGroup       VARCHAR(50)                  NULL,
        Description        NVARCHAR(500)                NULL,
        DefaultValue       NVARCHAR(MAX)                NULL,
        IsEncrypted        BIT                          NOT NULL,
        IsRequired         BIT                          NOT NULL,
        IsEditable         BIT                          NOT NULL,
        IsActive           BIT                          NOT NULL,
        IsDeleted          BIT                          NOT NULL,
        CreatedBy          INT                          NOT NULL,
        CreatedDate        DATETIME2(3)                 NOT NULL,
        UpdatedBy          INT                          NULL,
        UpdatedDate        DATETIME2(3)                 NULL,
        DeletedBy          INT                          NULL,
        DeletedDate        DATETIME2(3)                 NULL,
        RowVersion         ROWVERSION                   NOT NULL,
        CONSTRAINT PK_CompanySettings             PRIMARY KEY CLUSTERED (CompanySettingID),
        CONSTRAINT UQ_CompanySettings_GUID        UNIQUE (CompanySettingGUID),
        CONSTRAINT UQ_CompanySettings_Company_Key UNIQUE (CompanyID, SettingKey)
    );
END;
GO

/* 4. CompanySubscriptions */
IF OBJECT_ID(N'dbo.CompanySubscriptions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CompanySubscriptions
    (
        CompanySubscriptionID   BIGINT          IDENTITY(1,1) NOT NULL,
        CompanySubscriptionGUID UNIQUEIDENTIFIER             NOT NULL,
        CompanyID               INT                          NOT NULL,
        SubscriptionPlanID      INT                          NOT NULL,
        CurrencyID              INT                          NULL,
        Status                  VARCHAR(20)                  NOT NULL,
        StartDate               DATETIME2(3)                 NOT NULL,
        EndDate                 DATETIME2(3)                 NULL,
        TrialStartDate          DATETIME2(3)                 NULL,
        TrialEndDate            DATETIME2(3)                 NULL,
        AutoRenew               BIT                          NOT NULL,
        CancelledDate           DATETIME2(3)                 NULL,
        CancellationReason      NVARCHAR(500)                NULL,
        UnitPrice               DECIMAL(19,4)                NOT NULL,
        DiscountAmount          DECIMAL(19,4)                NOT NULL,
        TaxAmount               DECIMAL(19,4)                NOT NULL,
        FinalAmount             DECIMAL(19,4)                NOT NULL,
        Notes                   NVARCHAR(1000)               NULL,
        IsActive                BIT                          NOT NULL,
        IsDeleted               BIT                          NOT NULL,
        CreatedBy               INT                          NOT NULL,
        CreatedDate             DATETIME2(3)                 NOT NULL,
        UpdatedBy               INT                          NULL,
        UpdatedDate             DATETIME2(3)                 NULL,
        DeletedBy               INT                          NULL,
        DeletedDate             DATETIME2(3)                 NULL,
        RowVersion              ROWVERSION                   NOT NULL,
        CONSTRAINT PK_CompanySubscriptions      PRIMARY KEY CLUSTERED (CompanySubscriptionID),
        CONSTRAINT UQ_CompanySubscriptions_GUID UNIQUE (CompanySubscriptionGUID)
    );
END;
GO

/* 5. CompanySubscriptionHistory  (immutable lifecycle history) */
IF OBJECT_ID(N'dbo.CompanySubscriptionHistory', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CompanySubscriptionHistory
    (
        CompanySubscriptionHistoryID   BIGINT          IDENTITY(1,1) NOT NULL,
        CompanySubscriptionHistoryGUID UNIQUEIDENTIFIER             NOT NULL,
        CompanySubscriptionID          BIGINT                       NOT NULL,
        CompanyID                      INT                          NOT NULL,
        EventType                      VARCHAR(30)                  NOT NULL,
        PreviousPlanID                 INT                          NULL,
        NewPlanID                      INT                          NULL,
        PreviousStartDate              DATETIME2(3)                 NULL,
        NewStartDate                   DATETIME2(3)                 NULL,
        PreviousEndDate                DATETIME2(3)                 NULL,
        NewEndDate                     DATETIME2(3)                 NULL,
        PreviousAmount                 DECIMAL(19,4)                NULL,
        NewAmount                      DECIMAL(19,4)                NULL,
        Reason                         NVARCHAR(1000)               NULL,
        ChangedBy                      INT                          NULL,
        ChangedDate                    DATETIME2(3)                 NOT NULL,
        CorrelationID                  UNIQUEIDENTIFIER             NULL,
        CONSTRAINT PK_CompanySubscriptionHistory      PRIMARY KEY CLUSTERED (CompanySubscriptionHistoryID),
        CONSTRAINT UQ_CompanySubscriptionHistory_GUID UNIQUE (CompanySubscriptionHistoryGUID)
    );
END;
GO

/* 6. CompanySubscriptionUsage */
IF OBJECT_ID(N'dbo.CompanySubscriptionUsage', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CompanySubscriptionUsage
    (
        CompanySubscriptionUsageID   BIGINT          IDENTITY(1,1) NOT NULL,
        CompanySubscriptionUsageGUID UNIQUEIDENTIFIER             NOT NULL,
        CompanySubscriptionID        BIGINT                       NOT NULL,
        CompanyID                    INT                          NOT NULL,
        SubscriptionPlanLimitID      BIGINT                       NOT NULL,
        LimitKey                     VARCHAR(100)                 NOT NULL,
        AllowedValue                 BIGINT                       NULL,
        UsedValue                    BIGINT                       NOT NULL,
        UsageDate                    DATE                         NOT NULL,
        LastCalculatedDate           DATETIME2(3)                 NOT NULL,
        IsActive                     BIT                          NOT NULL,
        IsDeleted                    BIT                          NOT NULL,
        CreatedBy                    INT                          NOT NULL,
        CreatedDate                  DATETIME2(3)                 NOT NULL,
        UpdatedBy                    INT                          NULL,
        UpdatedDate                  DATETIME2(3)                 NULL,
        DeletedBy                    INT                          NULL,
        DeletedDate                  DATETIME2(3)                 NULL,
        RowVersion                   ROWVERSION                   NOT NULL,
        CONSTRAINT PK_CompanySubscriptionUsage      PRIMARY KEY CLUSTERED (CompanySubscriptionUsageID),
        CONSTRAINT UQ_CompanySubscriptionUsage_GUID UNIQUE (CompanySubscriptionUsageGUID)
    );
END;
GO

/* 7. CompanySubscriptionInvoices  (SaaS subscription invoices only) */
IF OBJECT_ID(N'dbo.CompanySubscriptionInvoices', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CompanySubscriptionInvoices
    (
        CompanySubscriptionInvoiceID   BIGINT          IDENTITY(1,1) NOT NULL,
        CompanySubscriptionInvoiceGUID UNIQUEIDENTIFIER             NOT NULL,
        CompanyID                      INT                          NOT NULL,
        CompanySubscriptionID          BIGINT                       NOT NULL,
        InvoiceNumber                  VARCHAR(60)                  NOT NULL,
        CurrencyID                     INT                          NULL,
        InvoiceDate                    DATETIME2(3)                 NOT NULL,
        DueDate                        DATETIME2(3)                 NULL,
        SubTotal                       DECIMAL(19,4)                NOT NULL,
        DiscountAmount                 DECIMAL(19,4)                NOT NULL,
        TaxAmount                      DECIMAL(19,4)                NOT NULL,
        TotalAmount                    DECIMAL(19,4)                NOT NULL,
        PaidAmount                     DECIMAL(19,4)                NOT NULL,
        BalanceAmount                  DECIMAL(19,4)                NOT NULL,
        Status                         VARCHAR(20)                  NOT NULL,
        Notes                          NVARCHAR(1000)               NULL,
        IsActive                       BIT                          NOT NULL,
        IsDeleted                      BIT                          NOT NULL,
        CreatedBy                      INT                          NOT NULL,
        CreatedDate                    DATETIME2(3)                 NOT NULL,
        UpdatedBy                      INT                          NULL,
        UpdatedDate                    DATETIME2(3)                 NULL,
        DeletedBy                      INT                          NULL,
        DeletedDate                    DATETIME2(3)                 NULL,
        RowVersion                     ROWVERSION                   NOT NULL,
        CONSTRAINT PK_CompanySubscriptionInvoices           PRIMARY KEY CLUSTERED (CompanySubscriptionInvoiceID),
        CONSTRAINT UQ_CompanySubscriptionInvoices_GUID      UNIQUE (CompanySubscriptionInvoiceGUID),
        CONSTRAINT UQ_CompanySubscriptionInvoices_Number    UNIQUE (InvoiceNumber)
    );
END;
GO

/* 8. CompanySubscriptionPayments  (SaaS billing payments only) */
IF OBJECT_ID(N'dbo.CompanySubscriptionPayments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CompanySubscriptionPayments
    (
        CompanySubscriptionPaymentID   BIGINT          IDENTITY(1,1) NOT NULL,
        CompanySubscriptionPaymentGUID UNIQUEIDENTIFIER             NOT NULL,
        CompanyID                      INT                          NOT NULL,
        CompanySubscriptionInvoiceID   BIGINT                       NOT NULL,
        PaymentReference               VARCHAR(100)                 NULL,
        PaymentMethod                  VARCHAR(30)                  NOT NULL,
        CurrencyID                     INT                          NULL,
        PaymentDate                    DATETIME2(3)                 NOT NULL,
        Amount                         DECIMAL(19,4)                NOT NULL,
        TransactionReference           VARCHAR(200)                 NULL,
        Status                         VARCHAR(20)                  NOT NULL,
        Notes                          NVARCHAR(1000)               NULL,
        IsActive                       BIT                          NOT NULL,
        IsDeleted                      BIT                          NOT NULL,
        CreatedBy                      INT                          NOT NULL,
        CreatedDate                    DATETIME2(3)                 NOT NULL,
        UpdatedBy                      INT                          NULL,
        UpdatedDate                    DATETIME2(3)                 NULL,
        DeletedBy                      INT                          NULL,
        DeletedDate                    DATETIME2(3)                 NULL,
        RowVersion                     ROWVERSION                   NOT NULL,
        CONSTRAINT PK_CompanySubscriptionPayments      PRIMARY KEY CLUSTERED (CompanySubscriptionPaymentID),
        CONSTRAINT UQ_CompanySubscriptionPayments_GUID UNIQUE (CompanySubscriptionPaymentGUID)
    );
END;
GO

/* 9. CompanySubscriptionCredits */
IF OBJECT_ID(N'dbo.CompanySubscriptionCredits', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CompanySubscriptionCredits
    (
        CompanySubscriptionCreditID   BIGINT          IDENTITY(1,1) NOT NULL,
        CompanySubscriptionCreditGUID UNIQUEIDENTIFIER             NOT NULL,
        CompanyID                     INT                          NOT NULL,
        CompanySubscriptionID         BIGINT                       NOT NULL,
        CompanySubscriptionInvoiceID  BIGINT                       NULL,
        CreditReference               VARCHAR(100)                 NOT NULL,
        CreditType                    VARCHAR(30)                  NOT NULL,
        CurrencyID                    INT                          NULL,
        CreditDate                    DATETIME2(3)                 NOT NULL,
        Amount                        DECIMAL(19,4)                NOT NULL,
        Reason                        NVARCHAR(1000)               NOT NULL,
        Status                        VARCHAR(20)                  NOT NULL,
        IsActive                      BIT                          NOT NULL,
        IsDeleted                     BIT                          NOT NULL,
        CreatedBy                     INT                          NOT NULL,
        CreatedDate                   DATETIME2(3)                 NOT NULL,
        UpdatedBy                     INT                          NULL,
        UpdatedDate                   DATETIME2(3)                 NULL,
        DeletedBy                     INT                          NULL,
        DeletedDate                   DATETIME2(3)                 NULL,
        RowVersion                    ROWVERSION                   NOT NULL,
        CONSTRAINT PK_CompanySubscriptionCredits         PRIMARY KEY CLUSTERED (CompanySubscriptionCreditID),
        CONSTRAINT UQ_CompanySubscriptionCredits_GUID    UNIQUE (CompanySubscriptionCreditGUID),
        CONSTRAINT UQ_CompanySubscriptionCredits_Ref     UNIQUE (CreditReference)
    );
END;
GO

/* --------------------------------------------------------------------------------------------
   B. Branch module
   -------------------------------------------------------------------------------------------- */

/* 10. Branches */
IF OBJECT_ID(N'dbo.Branches', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Branches
    (
        BranchID     INT             IDENTITY(1,1) NOT NULL,
        BranchGUID   UNIQUEIDENTIFIER             NOT NULL,
        CompanyID    INT                          NOT NULL,
        BranchKey    VARCHAR(100)                 NOT NULL,
        BranchCode   VARCHAR(50)                  NOT NULL,
        BranchName   NVARCHAR(150)                NOT NULL,
        BranchType   VARCHAR(30)                  NOT NULL,
        IsMainBranch BIT                          NOT NULL,
        Status       VARCHAR(20)                  NOT NULL,
        OpeningDate  DATE                         NULL,
        ClosingDate  DATE                         NULL,
        Description  NVARCHAR(500)                NULL,
        IsActive     BIT                          NOT NULL,
        IsDeleted    BIT                          NOT NULL,
        CreatedBy    INT                          NOT NULL,
        CreatedDate  DATETIME2(3)                 NOT NULL,
        UpdatedBy    INT                          NULL,
        UpdatedDate  DATETIME2(3)                 NULL,
        DeletedBy    INT                          NULL,
        DeletedDate  DATETIME2(3)                 NULL,
        RowVersion   ROWVERSION                   NOT NULL,
        CONSTRAINT PK_Branches              PRIMARY KEY CLUSTERED (BranchID),
        CONSTRAINT UQ_Branches_GUID         UNIQUE (BranchGUID),
        CONSTRAINT UQ_Branches_Company_Key  UNIQUE (CompanyID, BranchKey),
        CONSTRAINT UQ_Branches_Company_Code UNIQUE (CompanyID, BranchCode)
    );
END;
GO

/* 11. BranchProfiles */
IF OBJECT_ID(N'dbo.BranchProfiles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BranchProfiles
    (
        BranchProfileID   INT             IDENTITY(1,1) NOT NULL,
        BranchProfileGUID UNIQUEIDENTIFIER             NOT NULL,
        BranchID          INT                          NOT NULL,
        DisplayName       NVARCHAR(150)                NULL,
        LegalName         NVARCHAR(200)                NULL,
        ContactPerson     NVARCHAR(150)                NULL,
        Phone             VARCHAR(30)                  NULL,
        AlternatePhone    VARCHAR(30)                  NULL,
        Email             VARCHAR(254)                 NULL,
        Website           VARCHAR(300)                 NULL,
        AddressLine1      NVARCHAR(250)                NULL,
        AddressLine2      NVARCHAR(250)                NULL,
        Area              NVARCHAR(100)                NULL,
        City              NVARCHAR(100)                NULL,
        StateProvince     NVARCHAR(100)                NULL,
        Country           NVARCHAR(100)                NULL,
        CountryCode       CHAR(2)                      NULL,
        PostalCode        VARCHAR(20)                  NULL,
        LogoPath          NVARCHAR(500)                NULL,
        Description       NVARCHAR(500)                NULL,
        IsActive          BIT                          NOT NULL,
        IsDeleted         BIT                          NOT NULL,
        CreatedBy         INT                          NOT NULL,
        CreatedDate       DATETIME2(3)                 NOT NULL,
        UpdatedBy         INT                          NULL,
        UpdatedDate       DATETIME2(3)                 NULL,
        DeletedBy         INT                          NULL,
        DeletedDate       DATETIME2(3)                 NULL,
        RowVersion        ROWVERSION                   NOT NULL,
        CONSTRAINT PK_BranchProfiles           PRIMARY KEY CLUSTERED (BranchProfileID),
        CONSTRAINT UQ_BranchProfiles_GUID      UNIQUE (BranchProfileGUID),
        CONSTRAINT UQ_BranchProfiles_BranchID  UNIQUE (BranchID)
    );
END;
GO

/* 12. BranchSettings */
IF OBJECT_ID(N'dbo.BranchSettings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BranchSettings
    (
        BranchSettingID   BIGINT          IDENTITY(1,1) NOT NULL,
        BranchSettingGUID UNIQUEIDENTIFIER             NOT NULL,
        BranchID          INT                          NOT NULL,
        SettingKey        VARCHAR(100)                 NOT NULL,
        SettingValue      NVARCHAR(MAX)                NULL,
        SettingDataType   VARCHAR(20)                  NOT NULL,
        SettingGroup      VARCHAR(50)                  NULL,
        Description       NVARCHAR(500)                NULL,
        DefaultValue      NVARCHAR(MAX)                NULL,
        IsEncrypted       BIT                          NOT NULL,
        IsRequired        BIT                          NOT NULL,
        IsEditable        BIT                          NOT NULL,
        IsActive          BIT                          NOT NULL,
        IsDeleted         BIT                          NOT NULL,
        CreatedBy         INT                          NOT NULL,
        CreatedDate       DATETIME2(3)                 NOT NULL,
        UpdatedBy         INT                          NULL,
        UpdatedDate       DATETIME2(3)                 NULL,
        DeletedBy         INT                          NULL,
        DeletedDate       DATETIME2(3)                 NULL,
        RowVersion        ROWVERSION                   NOT NULL,
        CONSTRAINT PK_BranchSettings             PRIMARY KEY CLUSTERED (BranchSettingID),
        CONSTRAINT UQ_BranchSettings_GUID        UNIQUE (BranchSettingGUID),
        CONSTRAINT UQ_BranchSettings_Branch_Key  UNIQUE (BranchID, SettingKey)
    );
END;
GO

/* --------------------------------------------------------------------------------------------
   C. Users & security
   -------------------------------------------------------------------------------------------- */

/* 13. Users */
IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Users
    (
        UserID               INT             IDENTITY(1,1) NOT NULL,
        UserGUID             UNIQUEIDENTIFIER             NOT NULL,
        UserTypeID           INT                          NOT NULL,
        UserName             VARCHAR(100)                 NOT NULL,
        Email                VARCHAR(254)                 NULL,
        Phone                VARCHAR(30)                  NULL,
        PasswordHash         VARBINARY(MAX)               NOT NULL,
        PasswordSalt         VARBINARY(256)               NOT NULL,
        PasswordAlgorithm    VARCHAR(30)                  NOT NULL,
        PasswordIterations   INT                          NOT NULL,
        FirstName            NVARCHAR(100)                NOT NULL,
        MiddleName           NVARCHAR(100)                NULL,
        LastName             NVARCHAR(100)                NULL,
        DisplayName          NVARCHAR(200)                NULL,
        Status               VARCHAR(20)                  NOT NULL,
        IsEmailVerified      BIT                          NOT NULL,
        IsPhoneVerified      BIT                          NOT NULL,
        LastLoginDate        DATETIME2(3)                 NULL,
        LastLogoutDate       DATETIME2(3)                 NULL,
        FailedLoginAttempts  INT                          NOT NULL,
        LockedUntil          DATETIME2(3)                 NULL,
        PasswordChangedDate  DATETIME2(3)                 NULL,
        MustChangePassword   BIT                          NOT NULL,
        PreferredLanguage    VARCHAR(10)                  NULL,
        PreferredDirection   VARCHAR(3)                   NULL,
        TimeZone             VARCHAR(100)                 NULL,
        IsActive             BIT                          NOT NULL,
        IsDeleted            BIT                          NOT NULL,
        CreatedBy            INT                          NOT NULL,
        CreatedDate          DATETIME2(3)                 NOT NULL,
        UpdatedBy            INT                          NULL,
        UpdatedDate          DATETIME2(3)                 NULL,
        DeletedBy            INT                          NULL,
        DeletedDate          DATETIME2(3)                 NULL,
        RowVersion           ROWVERSION                   NOT NULL,
        CONSTRAINT PK_Users           PRIMARY KEY CLUSTERED (UserID),
        CONSTRAINT UQ_Users_GUID      UNIQUE (UserGUID),
        CONSTRAINT UQ_Users_UserName  UNIQUE (UserName)
    );
END;
GO

/* 14. UserTypes */
IF OBJECT_ID(N'dbo.UserTypes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserTypes
    (
        UserTypeID    INT             IDENTITY(1,1) NOT NULL,
        UserTypeGUID  UNIQUEIDENTIFIER             NOT NULL,
        UserTypeKey   VARCHAR(50)                  NOT NULL,
        UserTypeCode  VARCHAR(30)                  NOT NULL,
        UserTypeName  NVARCHAR(100)                NOT NULL,
        Description   NVARCHAR(500)                NULL,
        IsSystemType  BIT                          NOT NULL,
        IsAssignable  BIT                          NOT NULL,
        SortOrder     INT                          NOT NULL,
        IsActive      BIT                          NOT NULL,
        IsDeleted     BIT                          NOT NULL,
        CreatedBy     INT                          NOT NULL,
        CreatedDate   DATETIME2(3)                 NOT NULL,
        UpdatedBy     INT                          NULL,
        UpdatedDate   DATETIME2(3)                 NULL,
        DeletedBy     INT                          NULL,
        DeletedDate   DATETIME2(3)                 NULL,
        RowVersion    ROWVERSION                   NOT NULL,
        CONSTRAINT PK_UserTypes        PRIMARY KEY CLUSTERED (UserTypeID),
        CONSTRAINT UQ_UserTypes_GUID   UNIQUE (UserTypeGUID),
        CONSTRAINT UQ_UserTypes_Key    UNIQUE (UserTypeKey),
        CONSTRAINT UQ_UserTypes_Code   UNIQUE (UserTypeCode)
    );
END;
GO

/* 15. UserProfiles */
IF OBJECT_ID(N'dbo.UserProfiles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserProfiles
    (
        UserProfileID         INT             IDENTITY(1,1) NOT NULL,
        UserProfileGUID       UNIQUEIDENTIFIER             NOT NULL,
        UserID                INT                          NOT NULL,
        ProfilePhotoPath      NVARCHAR(500)                NULL,
        DateOfBirth           DATE                         NULL,
        Gender                VARCHAR(20)                  NULL,
        AddressLine1          NVARCHAR(250)                NULL,
        AddressLine2          NVARCHAR(250)                NULL,
        City                  NVARCHAR(100)                NULL,
        StateProvince         NVARCHAR(100)                NULL,
        Country               NVARCHAR(100)                NULL,
        PostalCode            VARCHAR(20)                  NULL,
        EmergencyContactName  NVARCHAR(150)                NULL,
        EmergencyContactPhone VARCHAR(30)                  NULL,
        Notes                 NVARCHAR(1000)               NULL,
        IsActive              BIT                          NOT NULL,
        IsDeleted             BIT                          NOT NULL,
        CreatedBy             INT                          NOT NULL,
        CreatedDate           DATETIME2(3)                 NOT NULL,
        UpdatedBy             INT                          NULL,
        UpdatedDate           DATETIME2(3)                 NULL,
        DeletedBy             INT                          NULL,
        DeletedDate           DATETIME2(3)                 NULL,
        RowVersion            ROWVERSION                   NOT NULL,
        CONSTRAINT PK_UserProfiles         PRIMARY KEY CLUSTERED (UserProfileID),
        CONSTRAINT UQ_UserProfiles_GUID    UNIQUE (UserProfileGUID),
        CONSTRAINT UQ_UserProfiles_UserID  UNIQUE (UserID)
    );
END;
GO

/* 16. UserCompanyAccess  (UNIQUE(UserID, CompanyID)) */
IF OBJECT_ID(N'dbo.UserCompanyAccess', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserCompanyAccess
    (
        UserCompanyAccessID   BIGINT          IDENTITY(1,1) NOT NULL,
        UserCompanyAccessGUID UNIQUEIDENTIFIER             NOT NULL,
        UserID                INT                          NOT NULL,
        CompanyID             INT                          NOT NULL,
        IsDefaultCompany      BIT                          NOT NULL,
        AccessStatus          VARCHAR(20)                  NOT NULL,
        StartDate             DATETIME2(3)                 NULL,
        EndDate               DATETIME2(3)                 NULL,
        IsActive              BIT                          NOT NULL,
        IsDeleted             BIT                          NOT NULL,
        CreatedBy             INT                          NOT NULL,
        CreatedDate           DATETIME2(3)                 NOT NULL,
        UpdatedBy             INT                          NULL,
        UpdatedDate           DATETIME2(3)                 NULL,
        DeletedBy             INT                          NULL,
        DeletedDate           DATETIME2(3)                 NULL,
        RowVersion            ROWVERSION                   NOT NULL,
        CONSTRAINT PK_UserCompanyAccess              PRIMARY KEY CLUSTERED (UserCompanyAccessID),
        CONSTRAINT UQ_UserCompanyAccess_GUID         UNIQUE (UserCompanyAccessGUID),
        CONSTRAINT UQ_UserCompanyAccess_User_Company UNIQUE (UserID, CompanyID)
    );
END;
GO

/* 17. UserBranchAccess */
IF OBJECT_ID(N'dbo.UserBranchAccess', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserBranchAccess
    (
        UserBranchAccessID   BIGINT          IDENTITY(1,1) NOT NULL,
        UserBranchAccessGUID UNIQUEIDENTIFIER             NOT NULL,
        UserID               INT                          NOT NULL,
        CompanyID            INT                          NOT NULL,
        BranchID             INT                          NOT NULL,
        IsDefaultBranch      BIT                          NOT NULL,
        AccessStatus         VARCHAR(20)                  NOT NULL,
        StartDate            DATETIME2(3)                 NULL,
        EndDate              DATETIME2(3)                 NULL,
        IsActive             BIT                          NOT NULL,
        IsDeleted            BIT                          NOT NULL,
        CreatedBy            INT                          NOT NULL,
        CreatedDate          DATETIME2(3)                 NOT NULL,
        UpdatedBy            INT                          NULL,
        UpdatedDate          DATETIME2(3)                 NULL,
        DeletedBy            INT                          NULL,
        DeletedDate          DATETIME2(3)                 NULL,
        RowVersion           ROWVERSION                   NOT NULL,
        CONSTRAINT PK_UserBranchAccess      PRIMARY KEY CLUSTERED (UserBranchAccessID),
        CONSTRAINT UQ_UserBranchAccess_GUID UNIQUE (UserBranchAccessGUID)
    );
END;
GO

/* 18. UserRoleAssignments */
IF OBJECT_ID(N'dbo.UserRoleAssignments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserRoleAssignments
    (
        UserRoleAssignmentID   BIGINT          IDENTITY(1,1) NOT NULL,
        UserRoleAssignmentGUID UNIQUEIDENTIFIER             NOT NULL,
        UserID                 INT                          NOT NULL,
        CompanyID              INT                          NOT NULL,
        BranchID               INT                          NULL,
        RoleID                 INT                          NOT NULL,
        IsPrimaryRole          BIT                          NOT NULL,
        StartDate              DATETIME2(3)                 NULL,
        EndDate                DATETIME2(3)                 NULL,
        IsActive               BIT                          NOT NULL,
        IsDeleted              BIT                          NOT NULL,
        CreatedBy              INT                          NOT NULL,
        CreatedDate            DATETIME2(3)                 NOT NULL,
        UpdatedBy              INT                          NULL,
        UpdatedDate            DATETIME2(3)                 NULL,
        DeletedBy              INT                          NULL,
        DeletedDate            DATETIME2(3)                 NULL,
        RowVersion             ROWVERSION                   NOT NULL,
        CONSTRAINT PK_UserRoleAssignments      PRIMARY KEY CLUSTERED (UserRoleAssignmentID),
        CONSTRAINT UQ_UserRoleAssignments_GUID UNIQUE (UserRoleAssignmentGUID)
    );
END;
GO

/* --------------------------------------------------------------------------------------------
   D. Roles
   -------------------------------------------------------------------------------------------- */

/* 19. Roles */
IF OBJECT_ID(N'dbo.Roles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Roles
    (
        RoleID        INT             IDENTITY(1,1) NOT NULL,
        RoleGUID      UNIQUEIDENTIFIER             NOT NULL,
        CompanyID     INT                          NOT NULL,
        ParentRoleID  INT                          NULL,
        RoleKey       VARCHAR(100)                 NOT NULL,
        RoleCode      VARCHAR(50)                  NOT NULL,
        RoleName      NVARCHAR(100)                NOT NULL,
        Description   NVARCHAR(500)                NULL,
        IsSystemRole  BIT                          NOT NULL,
        IsActive      BIT                          NOT NULL,
        IsDeleted     BIT                          NOT NULL,
        CreatedBy     INT                          NOT NULL,
        CreatedDate   DATETIME2(3)                 NOT NULL,
        UpdatedBy     INT                          NULL,
        UpdatedDate   DATETIME2(3)                 NULL,
        DeletedBy     INT                          NULL,
        DeletedDate   DATETIME2(3)                 NULL,
        RowVersion    ROWVERSION                   NOT NULL,
        CONSTRAINT PK_Roles                PRIMARY KEY CLUSTERED (RoleID),
        CONSTRAINT UQ_Roles_GUID           UNIQUE (RoleGUID),
        CONSTRAINT UQ_Roles_Company_Key    UNIQUE (CompanyID, RoleKey),
        CONSTRAINT UQ_Roles_Company_Code   UNIQUE (CompanyID, RoleCode)
    );
END;
GO

/* 20. RolePagePermissions  (UNIQUE(RoleID, SystemPageID)) */
IF OBJECT_ID(N'dbo.RolePagePermissions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RolePagePermissions
    (
        RolePagePermissionID   BIGINT          IDENTITY(1,1) NOT NULL,
        RolePagePermissionGUID UNIQUEIDENTIFIER             NOT NULL,
        RoleID                 INT                          NOT NULL,
        SystemPageID           INT                          NOT NULL,
        IsAllowed              BIT                          NOT NULL,
        IsActive               BIT                          NOT NULL,
        IsDeleted              BIT                          NOT NULL,
        CreatedBy              INT                          NOT NULL,
        CreatedDate            DATETIME2(3)                 NOT NULL,
        UpdatedBy              INT                          NULL,
        UpdatedDate            DATETIME2(3)                 NULL,
        DeletedBy              INT                          NULL,
        DeletedDate            DATETIME2(3)                 NULL,
        RowVersion             ROWVERSION                   NOT NULL,
        CONSTRAINT PK_RolePagePermissions          PRIMARY KEY CLUSTERED (RolePagePermissionID),
        CONSTRAINT UQ_RolePagePermissions_GUID     UNIQUE (RolePagePermissionGUID),
        CONSTRAINT UQ_RolePagePermissions_Role_Page UNIQUE (RoleID, SystemPageID)
    );
END;
GO

/* 21. RolePageActionPermissions
   NOTE: PageActionID foreign key + same-page constraint are on hold (docs/DATABASE-SCHEMA-REVIEW.md item 1). */
IF OBJECT_ID(N'dbo.RolePageActionPermissions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RolePageActionPermissions
    (
        RolePageActionPermissionID   BIGINT          IDENTITY(1,1) NOT NULL,
        RolePageActionPermissionGUID UNIQUEIDENTIFIER             NOT NULL,
        RoleID                       INT                          NOT NULL,
        SystemPageID                 INT                          NOT NULL,
        PageActionID                 INT                          NOT NULL,
        IsAllowed                    BIT                          NOT NULL,
        IsActive                     BIT                          NOT NULL,
        IsDeleted                    BIT                          NOT NULL,
        CreatedBy                    INT                          NOT NULL,
        CreatedDate                  DATETIME2(3)                 NOT NULL,
        UpdatedBy                    INT                          NULL,
        UpdatedDate                  DATETIME2(3)                 NULL,
        DeletedBy                    INT                          NULL,
        DeletedDate                  DATETIME2(3)                 NULL,
        RowVersion                   ROWVERSION                   NOT NULL,
        CONSTRAINT PK_RolePageActionPermissions      PRIMARY KEY CLUSTERED (RolePageActionPermissionID),
        CONSTRAINT UQ_RolePageActionPermissions_GUID UNIQUE (RolePageActionPermissionGUID)
    );
END;
GO

/* --------------------------------------------------------------------------------------------
   E. User security
   -------------------------------------------------------------------------------------------- */

/* 22. UserSessions */
IF OBJECT_ID(N'dbo.UserSessions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserSessions
    (
        UserSessionID     BIGINT          IDENTITY(1,1) NOT NULL,
        UserSessionGUID   UNIQUEIDENTIFIER             NOT NULL,
        UserID            INT                          NOT NULL,
        SessionKeyHash    VARBINARY(64)                NOT NULL,
        CompanyID         INT                          NULL,
        BranchID          INT                          NULL,
        IPAddress         VARCHAR(45)                  NULL,
        UserAgent         NVARCHAR(1000)               NULL,
        LoginDate         DATETIME2(3)                 NOT NULL,
        LastActivityDate  DATETIME2(3)                 NOT NULL,
        ExpiryDate        DATETIME2(3)                 NOT NULL,
        LogoutDate        DATETIME2(3)                 NULL,
        Status            VARCHAR(20)                  NOT NULL,
        RevokedBy         INT                          NULL,
        RevokedDate       DATETIME2(3)                 NULL,
        RowVersion        ROWVERSION                   NOT NULL,
        CONSTRAINT PK_UserSessions            PRIMARY KEY CLUSTERED (UserSessionID),
        CONSTRAINT UQ_UserSessions_GUID       UNIQUE (UserSessionGUID),
        CONSTRAINT UQ_UserSessions_KeyHash    UNIQUE (SessionKeyHash)
    );
END;
GO

/* 23. UserLoginHistory */
IF OBJECT_ID(N'dbo.UserLoginHistory', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserLoginHistory
    (
        UserLoginHistoryID   BIGINT          IDENTITY(1,1) NOT NULL,
        UserLoginHistoryGUID UNIQUEIDENTIFIER             NOT NULL,
        UserID               INT                          NULL,
        UserNameAttempted    VARCHAR(100)                 NULL,
        CompanyID            INT                          NULL,
        BranchID             INT                          NULL,
        LoginStatus          VARCHAR(20)                  NOT NULL,
        FailureReason        VARCHAR(100)                 NULL,
        IPAddress            VARCHAR(45)                  NULL,
        UserAgent            NVARCHAR(1000)               NULL,
        SessionID            VARCHAR(200)                 NULL,
        LoginDate            DATETIME2(3)                 NOT NULL,
        LogoutDate           DATETIME2(3)                 NULL,
        CorrelationID        UNIQUEIDENTIFIER             NULL,
        CONSTRAINT PK_UserLoginHistory      PRIMARY KEY CLUSTERED (UserLoginHistoryID),
        CONSTRAINT UQ_UserLoginHistory_GUID UNIQUE (UserLoginHistoryGUID)
    );
END;
GO

/* 24. UserPasswordHistory  (append-only: no normal update/delete) */
IF OBJECT_ID(N'dbo.UserPasswordHistory', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserPasswordHistory
    (
        UserPasswordHistoryID   BIGINT          IDENTITY(1,1) NOT NULL,
        UserPasswordHistoryGUID UNIQUEIDENTIFIER             NOT NULL,
        UserID                  INT                          NOT NULL,
        PasswordHash            VARBINARY(MAX)               NOT NULL,
        PasswordSalt            VARBINARY(256)               NOT NULL,
        PasswordAlgorithm       VARCHAR(30)                  NOT NULL,
        PasswordIterations      INT                          NOT NULL,
        ChangedReason           VARCHAR(30)                  NULL,
        ChangedBy               INT                          NULL,
        ChangedDate             DATETIME2(3)                 NOT NULL,
        CONSTRAINT PK_UserPasswordHistory      PRIMARY KEY CLUSTERED (UserPasswordHistoryID),
        CONSTRAINT UQ_UserPasswordHistory_GUID UNIQUE (UserPasswordHistoryGUID)
    );
END;
GO

/* 25. UserSecuritySettings */
IF OBJECT_ID(N'dbo.UserSecuritySettings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserSecuritySettings
    (
        UserSecuritySettingID    INT             IDENTITY(1,1) NOT NULL,
        UserSecuritySettingGUID  UNIQUEIDENTIFIER             NOT NULL,
        UserID                   INT                          NOT NULL,
        MFAEnabled               BIT                          NOT NULL,
        MFAMethod                VARCHAR(20)                  NULL,
        MFASecretEncrypted       VARBINARY(MAX)               NULL,
        BackupCodesHash          VARBINARY(MAX)               NULL,
        RequireMFA               BIT                          NOT NULL,
        PasswordExpiryDays       INT                          NULL,
        LastSecurityReviewDate   DATETIME2(3)                 NULL,
        IsActive                 BIT                          NOT NULL,
        IsDeleted                BIT                          NOT NULL,
        CreatedBy                INT                          NOT NULL,
        CreatedDate              DATETIME2(3)                 NOT NULL,
        UpdatedBy                INT                          NULL,
        UpdatedDate              DATETIME2(3)                 NULL,
        DeletedBy                INT                          NULL,
        DeletedDate              DATETIME2(3)                 NULL,
        RowVersion               ROWVERSION                   NOT NULL,
        CONSTRAINT PK_UserSecuritySettings         PRIMARY KEY CLUSTERED (UserSecuritySettingID),
        CONSTRAINT UQ_UserSecuritySettings_GUID    UNIQUE (UserSecuritySettingGUID),
        CONSTRAINT UQ_UserSecuritySettings_UserID  UNIQUE (UserID)
    );
END;
GO

/* 26. UserNotifications  (per-user inbox state) */
IF OBJECT_ID(N'dbo.UserNotifications', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserNotifications
    (
        UserNotificationID   BIGINT          IDENTITY(1,1) NOT NULL,
        UserNotificationGUID UNIQUEIDENTIFIER             NOT NULL,
        NotificationLogID    BIGINT                       NOT NULL,
        UserID               INT                          NOT NULL,
        CompanyID            INT                          NULL,
        BranchID             INT                          NULL,
        IsRead               BIT                          NOT NULL,
        ReadDate             DATETIME2(3)                 NULL,
        IsDismissed          BIT                          NOT NULL,
        DismissedDate        DATETIME2(3)                 NULL,
        CreatedDate          DATETIME2(3)                 NOT NULL,
        CONSTRAINT PK_UserNotifications      PRIMARY KEY CLUSTERED (UserNotificationID),
        CONSTRAINT UQ_UserNotifications_GUID UNIQUE (UserNotificationGUID)
    );
END;
GO

/* --------------------------------------------------------------------------------------------
   F. System & permission tables
   -------------------------------------------------------------------------------------------- */

/* 27. SystemModules */
IF OBJECT_ID(N'dbo.SystemModules', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SystemModules
    (
        SystemModuleID   INT             IDENTITY(1,1) NOT NULL,
        SystemModuleGUID UNIQUEIDENTIFIER             NOT NULL,
        ModuleKey        VARCHAR(100)                 NOT NULL,
        ModuleCode       VARCHAR(50)                  NOT NULL,
        ModuleName       NVARCHAR(150)                NOT NULL,
        DisplayName      NVARCHAR(150)                NOT NULL,
        Description      NVARCHAR(500)                NULL,
        IconClass        VARCHAR(100)                 NULL,
        SortOrder        INT                          NOT NULL,
        IsMenuItem       BIT                          NOT NULL,
        IsSystemModule   BIT                          NOT NULL,
        IsActive         BIT                          NOT NULL,
        IsDeleted        BIT                          NOT NULL,
        CreatedBy        INT                          NOT NULL,
        CreatedDate      DATETIME2(3)                 NOT NULL,
        UpdatedBy        INT                          NULL,
        UpdatedDate      DATETIME2(3)                 NULL,
        DeletedBy        INT                          NULL,
        DeletedDate      DATETIME2(3)                 NULL,
        RowVersion       ROWVERSION                   NOT NULL,
        CONSTRAINT PK_SystemModules      PRIMARY KEY CLUSTERED (SystemModuleID),
        CONSTRAINT UQ_SystemModules_GUID UNIQUE (SystemModuleGUID),
        CONSTRAINT UQ_SystemModules_Key  UNIQUE (ModuleKey),
        CONSTRAINT UQ_SystemModules_Code UNIQUE (ModuleCode)
    );
END;
GO

/* 28. SystemPages */
IF OBJECT_ID(N'dbo.SystemPages', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SystemPages
    (
        SystemPageID           INT             IDENTITY(1,1) NOT NULL,
        SystemPageGUID         UNIQUEIDENTIFIER             NOT NULL,
        PageKey                VARCHAR(100)                 NOT NULL,
        PageCode               VARCHAR(100)                 NOT NULL,
        PageName               NVARCHAR(150)                NOT NULL,
        DisplayName            NVARCHAR(150)                NOT NULL,
        Description            NVARCHAR(500)                NULL,
        SystemModuleID         INT                          NULL,
        ParentPageID           INT                          NULL,
        URL                    NVARCHAR(300)                NULL,
        IconClass              VARCHAR(100)                 NULL,
        PageType               VARCHAR(30)                  NOT NULL,
        SortOrder              INT                          NOT NULL,
        IsMenuItem             BIT                          NOT NULL,
        IsSystemPage           BIT                          NOT NULL,
        RequiresAuthentication BIT                          NOT NULL,
        IsActive               BIT                          NOT NULL,
        IsDeleted              BIT                          NOT NULL,
        CreatedBy              INT                          NOT NULL,
        CreatedDate            DATETIME2(3)                 NOT NULL,
        UpdatedBy              INT                          NULL,
        UpdatedDate            DATETIME2(3)                 NULL,
        DeletedBy              INT                          NULL,
        DeletedDate            DATETIME2(3)                 NULL,
        RowVersion             ROWVERSION                   NOT NULL,
        CONSTRAINT PK_SystemPages      PRIMARY KEY CLUSTERED (SystemPageID),
        CONSTRAINT UQ_SystemPages_GUID UNIQUE (SystemPageGUID),
        CONSTRAINT UQ_SystemPages_Key  UNIQUE (PageKey),
        CONSTRAINT UQ_SystemPages_Code UNIQUE (PageCode)
    );
END;
GO

/* 29. SystemActions  (global action master) */
IF OBJECT_ID(N'dbo.SystemActions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SystemActions
    (
        ActionID         INT             IDENTITY(1,1) NOT NULL,
        ActionGUID       UNIQUEIDENTIFIER             NOT NULL,
        ActionKey        VARCHAR(100)                 NOT NULL,
        ActionCode       VARCHAR(50)                  NOT NULL,
        ActionName       NVARCHAR(100)                NOT NULL,
        Description      NVARCHAR(300)                NULL,
        SortOrder        INT                          NOT NULL,
        IsSystemAction   BIT                          NOT NULL,
        IsActive         BIT                          NOT NULL,
        IsDeleted        BIT                          NOT NULL,
        CreatedBy        INT                          NOT NULL,
        CreatedDate      DATETIME2(3)                 NOT NULL,
        UpdatedBy        INT                          NULL,
        UpdatedDate      DATETIME2(3)                 NULL,
        DeletedBy        INT                          NULL,
        DeletedDate      DATETIME2(3)                 NULL,
        RowVersion       ROWVERSION                   NOT NULL,
        CONSTRAINT PK_SystemActions      PRIMARY KEY CLUSTERED (ActionID),
        CONSTRAINT UQ_SystemActions_GUID UNIQUE (ActionGUID),
        CONSTRAINT UQ_SystemActions_Key  UNIQUE (ActionKey),
        CONSTRAINT UQ_SystemActions_Code UNIQUE (ActionCode)
    );
END;
GO

/* 30. SubscriptionPlans */
IF OBJECT_ID(N'dbo.SubscriptionPlans', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SubscriptionPlans
    (
        SubscriptionPlanID   INT             IDENTITY(1,1) NOT NULL,
        SubscriptionPlanGUID UNIQUEIDENTIFIER             NOT NULL,
        PlanKey              VARCHAR(100)                 NOT NULL,
        PlanCode             VARCHAR(50)                  NOT NULL,
        PlanName             NVARCHAR(100)                NOT NULL,
        Description          NVARCHAR(500)                NULL,
        BillingCycle         VARCHAR(20)                  NOT NULL,
        Price                DECIMAL(19,4)                NOT NULL,
        CurrencyID           INT                          NULL,
        TrialDays            INT                          NOT NULL,
        IsPublic             BIT                          NOT NULL,
        IsRecommended        BIT                          NOT NULL,
        SortOrder            INT                          NOT NULL,
        IsActive             BIT                          NOT NULL,
        IsDeleted            BIT                          NOT NULL,
        CreatedBy            INT                          NOT NULL,
        CreatedDate          DATETIME2(3)                 NOT NULL,
        UpdatedBy            INT                          NULL,
        UpdatedDate          DATETIME2(3)                 NULL,
        DeletedBy            INT                          NULL,
        DeletedDate          DATETIME2(3)                 NULL,
        RowVersion           ROWVERSION                   NOT NULL,
        CONSTRAINT PK_SubscriptionPlans      PRIMARY KEY CLUSTERED (SubscriptionPlanID),
        CONSTRAINT UQ_SubscriptionPlans_GUID UNIQUE (SubscriptionPlanGUID),
        CONSTRAINT UQ_SubscriptionPlans_Key  UNIQUE (PlanKey),
        CONSTRAINT UQ_SubscriptionPlans_Code UNIQUE (PlanCode)
    );
END;
GO

/* 31. SubscriptionPlanLimits  (UNIQUE(SubscriptionPlanID, LimitKey)) */
IF OBJECT_ID(N'dbo.SubscriptionPlanLimits', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SubscriptionPlanLimits
    (
        SubscriptionPlanLimitID   BIGINT          IDENTITY(1,1) NOT NULL,
        SubscriptionPlanLimitGUID UNIQUEIDENTIFIER             NOT NULL,
        SubscriptionPlanID        INT                          NOT NULL,
        LimitKey                  VARCHAR(100)                 NOT NULL,
        LimitName                 NVARCHAR(150)                NOT NULL,
        LimitValue                BIGINT                       NULL,
        IsUnlimited               BIT                          NOT NULL,
        IsActive                  BIT                          NOT NULL,
        IsDeleted                 BIT                          NOT NULL,
        CreatedBy                 INT                          NOT NULL,
        CreatedDate               DATETIME2(3)                 NOT NULL,
        UpdatedBy                 INT                          NULL,
        UpdatedDate               DATETIME2(3)                 NULL,
        DeletedBy                 INT                          NULL,
        DeletedDate               DATETIME2(3)                 NULL,
        RowVersion                ROWVERSION                   NOT NULL,
        CONSTRAINT PK_SubscriptionPlanLimits           PRIMARY KEY CLUSTERED (SubscriptionPlanLimitID),
        CONSTRAINT UQ_SubscriptionPlanLimits_GUID      UNIQUE (SubscriptionPlanLimitGUID),
        CONSTRAINT UQ_SubscriptionPlanLimits_Plan_Key  UNIQUE (SubscriptionPlanID, LimitKey)
    );
END;
GO

/* 32. SubscriptionPagePermissions  (UNIQUE(SubscriptionPlanID, SystemPageID)) */
IF OBJECT_ID(N'dbo.SubscriptionPagePermissions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SubscriptionPagePermissions
    (
        SubscriptionPagePermissionID   BIGINT          IDENTITY(1,1) NOT NULL,
        SubscriptionPagePermissionGUID UNIQUEIDENTIFIER             NOT NULL,
        SubscriptionPlanID             INT                          NOT NULL,
        SystemPageID                   INT                          NOT NULL,
        IsAllowed                      BIT                          NOT NULL,
        IsActive                       BIT                          NOT NULL,
        IsDeleted                      BIT                          NOT NULL,
        CreatedBy                      INT                          NOT NULL,
        CreatedDate                    DATETIME2(3)                 NOT NULL,
        UpdatedBy                      INT                          NULL,
        UpdatedDate                    DATETIME2(3)                 NULL,
        DeletedBy                      INT                          NULL,
        DeletedDate                    DATETIME2(3)                 NULL,
        RowVersion                     ROWVERSION                   NOT NULL,
        CONSTRAINT PK_SubscriptionPagePermissions            PRIMARY KEY CLUSTERED (SubscriptionPagePermissionID),
        CONSTRAINT UQ_SubscriptionPagePermissions_GUID       UNIQUE (SubscriptionPagePermissionGUID),
        CONSTRAINT UQ_SubscriptionPagePermissions_Plan_Page  UNIQUE (SubscriptionPlanID, SystemPageID)
    );
END;
GO

/* 33. SubscriptionPageActionPermissions
   NOTE: PageActionID foreign key + same-page constraint are on hold (docs/DATABASE-SCHEMA-REVIEW.md item 1). */
IF OBJECT_ID(N'dbo.SubscriptionPageActionPermissions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SubscriptionPageActionPermissions
    (
        SubscriptionPageActionPermissionID   BIGINT          IDENTITY(1,1) NOT NULL,
        SubscriptionPageActionPermissionGUID UNIQUEIDENTIFIER             NOT NULL,
        SubscriptionPlanID                   INT                          NOT NULL,
        SystemPageID                         INT                          NOT NULL,
        PageActionID                         INT                          NOT NULL,
        IsAllowed                            BIT                          NOT NULL,
        IsActive                             BIT                          NOT NULL,
        IsDeleted                            BIT                          NOT NULL,
        CreatedBy                            INT                          NOT NULL,
        CreatedDate                          DATETIME2(3)                 NOT NULL,
        UpdatedBy                            INT                          NULL,
        UpdatedDate                          DATETIME2(3)                 NULL,
        DeletedBy                            INT                          NULL,
        DeletedDate                          DATETIME2(3)                 NULL,
        RowVersion                           ROWVERSION                   NOT NULL,
        CONSTRAINT PK_SubscriptionPageActionPermissions               PRIMARY KEY CLUSTERED (SubscriptionPageActionPermissionID),
        CONSTRAINT UQ_SubscriptionPageActionPermissions_GUID          UNIQUE (SubscriptionPageActionPermissionGUID),
        CONSTRAINT UQ_SubscriptionPageActionPermissions_Plan_Action   UNIQUE (SubscriptionPlanID, PageActionID)
    );
END;
GO

/* --------------------------------------------------------------------------------------------
   H. Currency
   -------------------------------------------------------------------------------------------- */

/* 34. Currencies */
IF OBJECT_ID(N'dbo.Currencies', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Currencies
    (
        CurrencyID               INT             IDENTITY(1,1) NOT NULL,
        CurrencyGUID             UNIQUEIDENTIFIER             NOT NULL,
        CurrencyCode             CHAR(3)                      NOT NULL,
        CurrencyName             NVARCHAR(100)                NOT NULL,
        CurrencySymbol           NVARCHAR(10)                 NOT NULL,
        CurrencySymbolPosition   VARCHAR(10)                  NOT NULL,
        DecimalPlaces            TINYINT                      NOT NULL,
        ThousandsSeparator       NVARCHAR(5)                  NULL,
        DecimalSeparator         NVARCHAR(5)                  NULL,
        DisplayFormat            NVARCHAR(50)                 NULL,
        CountryCode              CHAR(2)                      NULL,
        IsBaseCurrencyAllowed    BIT                          NOT NULL,
        IsActive                 BIT                          NOT NULL,
        IsDeleted                BIT                          NOT NULL,
        CreatedBy                INT                          NOT NULL,
        CreatedDate              DATETIME2(3)                 NOT NULL,
        UpdatedBy                INT                          NULL,
        UpdatedDate              DATETIME2(3)                 NULL,
        DeletedBy                INT                          NULL,
        DeletedDate              DATETIME2(3)                 NULL,
        RowVersion               ROWVERSION                   NOT NULL,
        CONSTRAINT PK_Currencies       PRIMARY KEY CLUSTERED (CurrencyID),
        CONSTRAINT UQ_Currencies_GUID  UNIQUE (CurrencyGUID),
        CONSTRAINT UQ_Currencies_Code  UNIQUE (CurrencyCode)
    );
END;
GO

/* --------------------------------------------------------------------------------------------
   I. Notifications
   -------------------------------------------------------------------------------------------- */

/* 35. NotificationTypes */
IF OBJECT_ID(N'dbo.NotificationTypes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.NotificationTypes
    (
        NotificationTypeID       INT             IDENTITY(1,1) NOT NULL,
        NotificationTypeGUID     UNIQUEIDENTIFIER             NOT NULL,
        NotificationTypeKey      VARCHAR(100)                 NOT NULL,
        NotificationTypeCode     VARCHAR(50)                  NOT NULL,
        NotificationTypeName     NVARCHAR(150)                NOT NULL,
        Description              NVARCHAR(500)                NULL,
        Category                 VARCHAR(50)                  NOT NULL,
        ScopeType                VARCHAR(20)                  NOT NULL,
        Severity                 VARCHAR(20)                  NOT NULL,
        IsSystemNotification     BIT                          NOT NULL,
        IsUserNotification       BIT                          NOT NULL,
        IsEmailEnabled           BIT                          NOT NULL,
        IsPushEnabled            BIT                          NOT NULL,
        IsInAppEnabled           BIT                          NOT NULL,
        IsSMSAllowed             BIT                          NOT NULL,
        IsActive                 BIT                          NOT NULL,
        IsDeleted                BIT                          NOT NULL,
        CreatedBy                INT                          NOT NULL,
        CreatedDate              DATETIME2(3)                 NOT NULL,
        UpdatedBy                INT                          NULL,
        UpdatedDate              DATETIME2(3)                 NULL,
        DeletedBy                INT                          NULL,
        DeletedDate              DATETIME2(3)                 NULL,
        RowVersion               ROWVERSION                   NOT NULL,
        CONSTRAINT PK_NotificationTypes      PRIMARY KEY CLUSTERED (NotificationTypeID),
        CONSTRAINT UQ_NotificationTypes_GUID UNIQUE (NotificationTypeGUID),
        CONSTRAINT UQ_NotificationTypes_Key  UNIQUE (NotificationTypeKey),
        CONSTRAINT UQ_NotificationTypes_Code UNIQUE (NotificationTypeCode)
    );
END;
GO

/* 36. NotificationTemplates */
IF OBJECT_ID(N'dbo.NotificationTemplates', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.NotificationTemplates
    (
        NotificationTemplateID   BIGINT          IDENTITY(1,1) NOT NULL,
        NotificationTemplateGUID UNIQUEIDENTIFIER             NOT NULL,
        NotificationTypeID       INT                          NOT NULL,
        TemplateKey              VARCHAR(100)                 NOT NULL,
        TemplateName             NVARCHAR(150)                NOT NULL,
        Channel                  VARCHAR(20)                  NOT NULL,
        LanguageCode             VARCHAR(10)                  NOT NULL,
        SubjectTemplate          NVARCHAR(500)                NULL,
        BodyTemplate             NVARCHAR(MAX)                NOT NULL,
        VariablesJson            NVARCHAR(MAX)                NULL,
        IsDefault                BIT                          NOT NULL,
        IsActive                 BIT                          NOT NULL,
        IsDeleted                BIT                          NOT NULL,
        CreatedBy                INT                          NOT NULL,
        CreatedDate              DATETIME2(3)                 NOT NULL,
        UpdatedBy                INT                          NULL,
        UpdatedDate              DATETIME2(3)                 NULL,
        DeletedBy                INT                          NULL,
        DeletedDate              DATETIME2(3)                 NULL,
        RowVersion               ROWVERSION                   NOT NULL,
        CONSTRAINT PK_NotificationTemplates      PRIMARY KEY CLUSTERED (NotificationTemplateID),
        CONSTRAINT UQ_NotificationTemplates_GUID UNIQUE (NotificationTemplateGUID),
        CONSTRAINT UQ_NotificationTemplates_Key  UNIQUE (TemplateKey)
    );
END;
GO

/* 37. NotificationLogs */
IF OBJECT_ID(N'dbo.NotificationLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.NotificationLogs
    (
        NotificationLogID       BIGINT          IDENTITY(1,1) NOT NULL,
        NotificationLogGUID     UNIQUEIDENTIFIER             NOT NULL,
        NotificationTypeID      INT                          NOT NULL,
        NotificationTemplateID  BIGINT                       NULL,
        ScopeType               VARCHAR(20)                  NOT NULL,
        CompanyID               INT                          NULL,
        BranchID                INT                          NULL,
        UserID                  INT                          NULL,
        RoleID                  INT                          NULL,
        Title                   NVARCHAR(300)                NOT NULL,
        Message                 NVARCHAR(MAX)                NOT NULL,
        DataJson                NVARCHAR(MAX)                NULL,
        Channel                 VARCHAR(20)                  NOT NULL,
        Priority                VARCHAR(20)                  NOT NULL,
        Status                  VARCHAR(20)                  NOT NULL,
        IsRead                  BIT                          NOT NULL,
        ReadDate                DATETIME2(3)                 NULL,
        SentDate                DATETIME2(3)                 NULL,
        FailedDate              DATETIME2(3)                 NULL,
        FailureReason           NVARCHAR(1000)               NULL,
        ExpiresDate             DATETIME2(3)                 NULL,
        CreatedDate             DATETIME2(3)                 NOT NULL,
        RowVersion              ROWVERSION                   NOT NULL,
        CONSTRAINT PK_NotificationLogs      PRIMARY KEY CLUSTERED (NotificationLogID),
        CONSTRAINT UQ_NotificationLogs_GUID UNIQUE (NotificationLogGUID)
    );
END;
GO

/* 38. UserNotificationPreferences */
IF OBJECT_ID(N'dbo.UserNotificationPreferences', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserNotificationPreferences
    (
        UserNotificationPreferenceID   BIGINT          IDENTITY(1,1) NOT NULL,
        UserNotificationPreferenceGUID UNIQUEIDENTIFIER             NOT NULL,
        UserID                         INT                          NOT NULL,
        NotificationTypeID             INT                          NOT NULL,
        InAppEnabled                   BIT                          NOT NULL,
        EmailEnabled                   BIT                          NOT NULL,
        PushEnabled                    BIT                          NOT NULL,
        SMSEnabled                     BIT                          NOT NULL,
        IsActive                       BIT                          NOT NULL,
        IsDeleted                      BIT                          NOT NULL,
        CreatedBy                      INT                          NOT NULL,
        CreatedDate                    DATETIME2(3)                 NOT NULL,
        UpdatedBy                      INT                          NULL,
        UpdatedDate                    DATETIME2(3)                 NULL,
        DeletedBy                      INT                          NULL,
        DeletedDate                    DATETIME2(3)                 NULL,
        RowVersion                     ROWVERSION                   NOT NULL,
        CONSTRAINT PK_UserNotificationPreferences      PRIMARY KEY CLUSTERED (UserNotificationPreferenceID),
        CONSTRAINT UQ_UserNotificationPreferences_GUID UNIQUE (UserNotificationPreferenceGUID)
    );
END;
GO

/* --------------------------------------------------------------------------------------------
   J. Audit / activity  (append-only)
   -------------------------------------------------------------------------------------------- */

/* 39. AuditLogs */
IF OBJECT_ID(N'dbo.AuditLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AuditLogs
    (
        AuditLogID          BIGINT          IDENTITY(1,1) NOT NULL,
        AuditLogGUID        UNIQUEIDENTIFIER             NOT NULL,
        ScopeType           VARCHAR(20)                  NOT NULL,
        CompanyID           INT                          NULL,
        BranchID            INT                          NULL,
        UserID              INT                          NULL,
        RoleID              INT                          NULL,
        ActionType          VARCHAR(30)                  NOT NULL,
        EntityName          VARCHAR(150)                 NOT NULL,
        EntityID            BIGINT                       NULL,
        EntityGUID          UNIQUEIDENTIFIER             NULL,
        RecordDisplayName   NVARCHAR(300)                NULL,
        OldValuesJson       NVARCHAR(MAX)                NULL,
        NewValuesJson       NVARCHAR(MAX)                NULL,
        ChangedColumnsJson  NVARCHAR(MAX)                NULL,
        Description         NVARCHAR(1000)               NULL,
        IPAddress           VARCHAR(45)                  NULL,
        UserAgent           NVARCHAR(1000)               NULL,
        RequestURL          NVARCHAR(1000)               NULL,
        SessionID           VARCHAR(200)                 NULL,
        CorrelationID       UNIQUEIDENTIFIER             NULL,
        CreatedDate         DATETIME2(3)                 NOT NULL,
        CONSTRAINT PK_AuditLogs      PRIMARY KEY CLUSTERED (AuditLogID),
        CONSTRAINT UQ_AuditLogs_GUID UNIQUE (AuditLogGUID)
    );
END;
GO

/* 40. ActivityLogs */
IF OBJECT_ID(N'dbo.ActivityLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ActivityLogs
    (
        ActivityLogID     BIGINT          IDENTITY(1,1) NOT NULL,
        ActivityLogGUID   UNIQUEIDENTIFIER             NOT NULL,
        ScopeType         VARCHAR(20)                  NOT NULL,
        CompanyID         INT                          NULL,
        BranchID          INT                          NULL,
        UserID            INT                          NULL,
        RoleID            INT                          NULL,
        ActivityType      VARCHAR(50)                  NOT NULL,
        ModuleName        VARCHAR(100)                 NULL,
        PageName          VARCHAR(150)                 NULL,
        EntityName        VARCHAR(150)                 NULL,
        EntityID          BIGINT                       NULL,
        Description       NVARCHAR(1000)               NULL,
        IPAddress         VARCHAR(45)                  NULL,
        UserAgent         NVARCHAR(1000)               NULL,
        RequestURL        NVARCHAR(1000)               NULL,
        SessionID         VARCHAR(200)                 NULL,
        CorrelationID     UNIQUEIDENTIFIER             NULL,
        CreatedDate       DATETIME2(3)                 NOT NULL,
        CONSTRAINT PK_ActivityLogs      PRIMARY KEY CLUSTERED (ActivityLogID),
        CONSTRAINT UQ_ActivityLogs_GUID UNIQUE (ActivityLogGUID)
    );
END;
GO

/* --------------------------------------------------------------------------------------------
   K. Error / system
   -------------------------------------------------------------------------------------------- */

/* 41. ErrorLogs */
IF OBJECT_ID(N'dbo.ErrorLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ErrorLogs
    (
        ErrorLogID         BIGINT          IDENTITY(1,1) NOT NULL,
        ErrorLogGUID       UNIQUEIDENTIFIER             NOT NULL,
        ErrorCode          VARCHAR(50)                  NOT NULL,
        ErrorType          VARCHAR(100)                 NOT NULL,
        Severity           VARCHAR(20)                  NOT NULL,
        Status             VARCHAR(20)                  NOT NULL,
        ModuleName         VARCHAR(100)                 NULL,
        PageName           VARCHAR(150)                 NULL,
        MethodName         VARCHAR(200)                 NULL,
        CompanyID          INT                          NULL,
        BranchID           INT                          NULL,
        UserID             INT                          NULL,
        ExceptionType      VARCHAR(500)                 NULL,
        ErrorMessage       NVARCHAR(MAX)                NOT NULL,
        StackTrace         NVARCHAR(MAX)                NULL,
        InnerException     NVARCHAR(MAX)                NULL,
        RequestURL         NVARCHAR(1000)               NULL,
        RequestMethod      VARCHAR(20)                  NULL,
        IPAddress          VARCHAR(45)                  NULL,
        UserAgent          NVARCHAR(1000)               NULL,
        RequestDataJson    NVARCHAR(MAX)                NULL,
        CorrelationID      UNIQUEIDENTIFIER             NULL,
        AssignedToUserID   INT                          NULL,
        ResolutionNotes    NVARCHAR(2000)               NULL,
        OccurredDate       DATETIME2(3)                 NOT NULL,
        AcknowledgedDate   DATETIME2(3)                 NULL,
        ResolvedDate       DATETIME2(3)                 NULL,
        ResolvedBy         INT                          NULL,
        IsActive           BIT                          NOT NULL,
        IsDeleted          BIT                          NOT NULL,
        RowVersion         ROWVERSION                   NOT NULL,
        CONSTRAINT PK_ErrorLogs      PRIMARY KEY CLUSTERED (ErrorLogID),
        CONSTRAINT UQ_ErrorLogs_GUID UNIQUE (ErrorLogGUID)
    );
END;
GO

/* 42. SystemLogs */
IF OBJECT_ID(N'dbo.SystemLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SystemLogs
    (
        SystemLogID     BIGINT          IDENTITY(1,1) NOT NULL,
        SystemLogGUID   UNIQUEIDENTIFIER             NOT NULL,
        LogLevel        VARCHAR(20)                  NOT NULL,
        LogType         VARCHAR(50)                  NOT NULL,
        ModuleName      VARCHAR(100)                 NULL,
        ServiceName     VARCHAR(150)                 NULL,
        OperationName   VARCHAR(150)                 NULL,
        Message         NVARCHAR(MAX)                NOT NULL,
        DataJson        NVARCHAR(MAX)                NULL,
        CorrelationID   UNIQUEIDENTIFIER             NULL,
        CompanyID       INT                          NULL,
        BranchID        INT                          NULL,
        UserID          INT                          NULL,
        CreatedDate     DATETIME2(3)                 NOT NULL,
        CONSTRAINT PK_SystemLogs      PRIMARY KEY CLUSTERED (SystemLogID),
        CONSTRAINT UQ_SystemLogs_GUID UNIQUE (SystemLogGUID)
    );
END;
GO

/* 43. BackupLogs */
IF OBJECT_ID(N'dbo.BackupLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BackupLogs
    (
        BackupLogID       BIGINT          IDENTITY(1,1) NOT NULL,
        BackupLogGUID     UNIQUEIDENTIFIER             NOT NULL,
        BackupType        VARCHAR(30)                  NOT NULL,
        BackupScope       VARCHAR(30)                  NOT NULL,
        Status            VARCHAR(20)                  NOT NULL,
        StartedDate       DATETIME2(3)                 NOT NULL,
        CompletedDate     DATETIME2(3)                 NULL,
        BackupSizeBytes   BIGINT                       NULL,
        BackupLocation    NVARCHAR(1000)               NULL,
        BackupFileName    NVARCHAR(500)                NULL,
        Checksum          VARCHAR(256)                 NULL,
        ErrorMessage      NVARCHAR(2000)               NULL,
        InitiatedBy       INT                          NULL,
        CorrelationID     UNIQUEIDENTIFIER             NULL,
        CreatedDate       DATETIME2(3)                 NOT NULL,
        RowVersion        ROWVERSION                   NOT NULL,
        CONSTRAINT PK_BackupLogs      PRIMARY KEY CLUSTERED (BackupLogID),
        CONSTRAINT UQ_BackupLogs_GUID UNIQUE (BackupLogGUID)
    );
END;
GO

/* 44. MaintenanceLogs */
IF OBJECT_ID(N'dbo.MaintenanceLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.MaintenanceLogs
    (
        MaintenanceLogID   BIGINT          IDENTITY(1,1) NOT NULL,
        MaintenanceLogGUID UNIQUEIDENTIFIER             NOT NULL,
        MaintenanceType    VARCHAR(50)                  NOT NULL,
        ScopeType          VARCHAR(20)                  NOT NULL,
        CompanyID          INT                          NULL,
        BranchID           INT                          NULL,
        Status             VARCHAR(20)                  NOT NULL,
        Title              NVARCHAR(250)                NOT NULL,
        Description        NVARCHAR(2000)               NULL,
        StartedDate        DATETIME2(3)                 NOT NULL,
        CompletedDate      DATETIME2(3)                 NULL,
        ScheduledDate      DATETIME2(3)                 NULL,
        PerformedBy        INT                          NULL,
        ResultMessage      NVARCHAR(2000)               NULL,
        ErrorMessage       NVARCHAR(2000)               NULL,
        DataJson           NVARCHAR(MAX)                NULL,
        CorrelationID      UNIQUEIDENTIFIER             NULL,
        CreatedDate        DATETIME2(3)                 NOT NULL,
        RowVersion         ROWVERSION                   NOT NULL,
        CONSTRAINT PK_MaintenanceLogs      PRIMARY KEY CLUSTERED (MaintenanceLogID),
        CONSTRAINT UQ_MaintenanceLogs_GUID UNIQUE (MaintenanceLogGUID)
    );
END;
GO

PRINT N'01_Tables.sql completed: 44 approved tables created (where missing).';
GO
