/* =============================================================
   ERPTemplate — System Navigation Stored Procedures
   File: Data/StoredProcedures/Navigation/Navigation.sql
   ============================================================= */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =============================================================
   1. usp_SystemNavigation_Get
   Returns flat rows for the navigation tree.
   Caller groups rows by Module -> Page -> Action.
   ============================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_SystemNavigation_Get
    @Search        NVARCHAR(200) = NULL,
    @ModuleID      INT = NULL,
    @Status        VARCHAR(20) = NULL,
    @SortBy        VARCHAR(30) = NULL,
    @SortDirection VARCHAR(4)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StatusNorm VARCHAR(20) = LOWER(ISNULL(NULLIF(LTRIM(RTRIM(@Status)), ''), 'active'));
    DECLARE @SortByNorm VARCHAR(30) = LOWER(ISNULL(NULLIF(LTRIM(RTRIM(@SortBy)), ''), 'name'));
    DECLARE @SortDir    VARCHAR(4)  = UPPER(ISNULL(NULLIF(LTRIM(RTRIM(@SortDirection)), ''), 'ASC'));
    DECLARE @SearchLike NVARCHAR(202) =
        CASE WHEN @Search IS NULL OR LTRIM(RTRIM(@Search)) = '' THEN NULL
             ELSE N'%' + LTRIM(RTRIM(@Search)) + N'%' END;

    IF @SortDir NOT IN ('ASC','DESC') SET @SortDir = 'ASC';

    SELECT
        m.SystemModuleID,
        m.SystemModuleGUID,
        m.ModuleCode,
        m.ModuleName,
        m.DisplayName   AS ModuleDisplayName,
        m.SortOrder     AS ModuleSortOrder,
        m.IsActive      AS ModuleIsActive,
        m.IsDeleted     AS ModuleIsDeleted,
        m.CreatedDate   AS ModuleCreatedDate,
        m.UpdatedDate   AS ModuleUpdatedDate,

        p.SystemPageID,
        p.SystemPageGUID,
        p.PageCode,
        p.PageName,
        p.DisplayName   AS PageDisplayName,
        p.SortOrder     AS PageSortOrder,
        p.IsActive      AS PageIsActive,
        p.IsDeleted     AS PageIsDeleted,

        pa.PageActionID,
        pa.ActionID,
        pa.SortOrder    AS PageActionSortOrder,
        pa.IsDefault    AS PageActionIsDefault,
        a.ActionCode,
        a.ActionName
    FROM dbo.SystemModules m
    LEFT JOIN dbo.SystemPages p
        ON p.SystemModuleID = m.SystemModuleID
       AND (@StatusNorm <> 'deleted' OR p.IsDeleted = 1)
    LEFT JOIN dbo.SystemPageActions pa
        ON pa.SystemPageID = p.SystemPageID
       AND pa.IsDeleted = 0
       AND pa.IsActive  = 1
    LEFT JOIN dbo.SystemActions a
        ON a.ActionID = pa.ActionID
       AND a.IsDeleted = 0
    WHERE
        (@ModuleID IS NULL OR m.SystemModuleID = @ModuleID)
        AND (
            @StatusNorm = 'all'
            OR (@StatusNorm = 'active'   AND m.IsActive = 1 AND m.IsDeleted = 0)
            OR (@StatusNorm = 'inactive' AND m.IsActive = 0 AND m.IsDeleted = 0)
            OR (@StatusNorm = 'deleted'  AND m.IsDeleted = 1)
        )
        AND (
            @SearchLike IS NULL
            OR m.ModuleCode LIKE @SearchLike
            OR m.ModuleName LIKE @SearchLike
            OR p.PageCode   LIKE @SearchLike
            OR p.PageName   LIKE @SearchLike
            OR a.ActionCode LIKE @SearchLike
            OR a.ActionName LIKE @SearchLike
        )
    ORDER BY
        CASE WHEN @SortByNorm='name'        AND @SortDir='ASC'  THEN m.ModuleName   END ASC,
        CASE WHEN @SortByNorm='name'        AND @SortDir='DESC' THEN m.ModuleName   END DESC,
        CASE WHEN @SortByNorm='code'        AND @SortDir='ASC'  THEN m.ModuleCode   END ASC,
        CASE WHEN @SortByNorm='code'        AND @SortDir='DESC' THEN m.ModuleCode   END DESC,
        CASE WHEN @SortByNorm='createddate' AND @SortDir='ASC'  THEN m.CreatedDate  END ASC,
        CASE WHEN @SortByNorm='createddate' AND @SortDir='DESC' THEN m.CreatedDate  END DESC,
        CASE WHEN @SortByNorm='updateddate' AND @SortDir='ASC'  THEN m.UpdatedDate  END ASC,
        CASE WHEN @SortByNorm='updateddate' AND @SortDir='DESC' THEN m.UpdatedDate  END DESC,
        m.SortOrder ASC, p.SortOrder ASC, pa.SortOrder ASC;
END
GO

/* =============================================================
   2. usp_SystemNavigation_Create
   Creates Module + Pages + SystemPageActions in one transaction.
   @PagesJson : [ { pageCode, pageName, displayName, actions:["VIEW",...] } ]
   ============================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_SystemNavigation_Create
    @ModuleCode     VARCHAR(50),
    @ModuleName     NVARCHAR(150),
    @DisplayName    NVARCHAR(150),
    @Description    NVARCHAR(500) = NULL,
    @IconClass      VARCHAR(100)  = NULL,
    @SortOrder      INT           = 0,
    @IsMenuItem     BIT           = 1,
    @IsSystemModule BIT           = 0,
    @PagesJson      NVARCHAR(MAX),
    @CreatedBy      INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @ModuleCode IS NULL OR LTRIM(RTRIM(@ModuleCode)) = ''
        THROW 50001, 'ModuleCode is required.', 1;
    IF @ModuleName IS NULL OR LTRIM(RTRIM(@ModuleName)) = ''
        THROW 50002, 'ModuleName is required.', 1;
    IF @DisplayName IS NULL OR LTRIM(RTRIM(@DisplayName)) = ''
        THROW 50003, 'DisplayName is required.', 1;
    IF @CreatedBy IS NULL OR @CreatedBy <= 0
        THROW 50004, 'CreatedBy is required.', 1;
    IF @PagesJson IS NULL OR LTRIM(RTRIM(@PagesJson)) = ''
        THROW 50005, 'PagesJson is required.', 1;
    IF ISJSON(@PagesJson) <> 1
        THROW 50006, 'PagesJson is not valid JSON.', 1;

    SET @ModuleCode = UPPER(LTRIM(RTRIM(@ModuleCode)));

    IF EXISTS (SELECT 1 FROM dbo.SystemModules WHERE ModuleCode = @ModuleCode AND IsDeleted = 0)
        THROW 50010, 'ModuleCode already exists.', 1;

    /* Validate that every page has a valid, unique PageCode */
    IF EXISTS (
        SELECT 1
        FROM OPENJSON(@PagesJson) WITH (
            pageCode VARCHAR(100) '$.pageCode'
        ) p
        GROUP BY UPPER(LTRIM(RTRIM(p.pageCode)))
        HAVING COUNT(*) > 1
    )
        THROW 50011, 'Duplicate PageCode found in request.', 1;

    /* Validate every requested action code exists in SystemActions */
    IF EXISTS (
        SELECT 1
        FROM OPENJSON(@PagesJson) WITH (
            actions NVARCHAR(MAX) '$.actions' AS JSON
        ) p
        CROSS APPLY OPENJSON(p.actions) WITH (actionCode VARCHAR(50) '$') a
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.SystemActions sa
            WHERE sa.ActionCode = UPPER(LTRIM(RTRIM(a.actionCode)))
              AND sa.IsDeleted = 0
        )
    )
        THROW 50012, 'One or more action codes do not exist in SystemActions.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();
        DECLARE @ModuleGUID UNIQUEIDENTIFIER = NEWID();
        DECLARE @ModuleKey VARCHAR(100) = LOWER(@ModuleCode);

        INSERT INTO dbo.SystemModules
        (SystemModuleGUID, ModuleKey, ModuleCode, ModuleName, DisplayName, Description,
         IconClass, SortOrder, IsMenuItem, IsSystemModule,
         IsActive, IsDeleted, CreatedBy, CreatedDate)
        VALUES
        (@ModuleGUID, @ModuleKey, @ModuleCode, @ModuleName, @DisplayName, @Description,
         @IconClass, ISNULL(@SortOrder,0), ISNULL(@IsMenuItem,1), ISNULL(@IsSystemModule,0),
         1, 0, @CreatedBy, @Now);

        DECLARE @NewModuleID INT = SCOPE_IDENTITY();

        DECLARE @Pages TABLE (
            RowNum      INT IDENTITY(1,1) PRIMARY KEY,
            PageCode    VARCHAR(100),
            PageName    NVARCHAR(150),
            DisplayName NVARCHAR(150),
            ActionsJson NVARCHAR(MAX)
        );

        INSERT INTO @Pages (PageCode, PageName, DisplayName, ActionsJson)
        SELECT UPPER(LTRIM(RTRIM(p.pageCode))),
               p.pageName,
               p.displayName,
               p.actions
        FROM OPENJSON(@PagesJson) WITH (
            pageCode    VARCHAR(100)  '$.pageCode',
            pageName    NVARCHAR(150) '$.pageName',
            displayName NVARCHAR(150) '$.displayName',
            actions     NVARCHAR(MAX) '$.actions' AS JSON
        ) p;

        DECLARE @i INT = 1;
        DECLARE @total INT = (SELECT COUNT(*) FROM @Pages);
        DECLARE @pageCode VARCHAR(100), @pageName NVARCHAR(150),
                @pageDisplay NVARCHAR(150), @actionsJson NVARCHAR(MAX),
                @pageId INT;

        WHILE @i <= @total
        BEGIN
            SELECT @pageCode    = PageCode,
                   @pageName    = PageName,
                   @pageDisplay = DisplayName,
                   @actionsJson = ActionsJson
            FROM @Pages WHERE RowNum = @i;

            IF EXISTS (SELECT 1 FROM dbo.SystemPages WHERE PageCode = @pageCode AND IsDeleted = 0)
                THROW 50013, 'PageCode already exists.', 1;

            INSERT INTO dbo.SystemPages
            (SystemPageGUID, PageKey, PageCode, PageName, DisplayName,
             SystemModuleID, PageType, SortOrder, IsMenuItem, IsSystemPage,
             RequiresAuthentication, IsActive, IsDeleted, CreatedBy, CreatedDate)
            VALUES
            (NEWID(), LOWER(@pageCode), @pageCode, @pageName, @pageDisplay,
             @NewModuleID, 'PAGE', 0, 1, 0,
             1, 1, 0, @CreatedBy, @Now);

            SET @pageId = SCOPE_IDENTITY();

            INSERT INTO dbo.SystemPageActions
            (PageActionGUID, SystemPageID, ActionID, SortOrder, IsDefault,
             IsActive, IsDeleted, CreatedBy, CreatedDate)
            SELECT NEWID(), @pageId, sa.ActionID, ISNULL(sa.SortOrder, 0),
                   CASE WHEN sa.ActionCode = 'VIEW' THEN 1 ELSE 0 END,
                   1, 0, @CreatedBy, @Now
            FROM OPENJSON(@actionsJson) WITH (actionCode VARCHAR(50) '$') a
            INNER JOIN dbo.SystemActions sa
                ON sa.ActionCode = UPPER(LTRIM(RTRIM(a.actionCode)))
               AND sa.IsDeleted = 0;

            SET @i = @i + 1;
        END

        COMMIT TRANSACTION;

        SELECT @NewModuleID AS SystemModuleID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* =============================================================
   3. usp_SystemNavigation_GetModule
   ============================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_SystemNavigation_GetModule
    @SystemModuleID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @SystemModuleID IS NULL OR @SystemModuleID <= 0
        THROW 50020, 'SystemModuleID is required.', 1;

    SELECT
        SystemModuleID,
        SystemModuleGUID,
        ModuleKey,
        ModuleCode,
        ModuleName,
        DisplayName,
        Description,
        IconClass,
        SortOrder,
        IsMenuItem,
        IsSystemModule,
        IsActive,
        IsDeleted,
        CreatedBy,
        CreatedDate,
        UpdatedBy,
        UpdatedDate,
        RowVersion
    FROM dbo.SystemModules
    WHERE SystemModuleID = @SystemModuleID;
END
GO

/* =============================================================
   4. usp_SystemNavigation_UpdateModule
   ============================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_SystemNavigation_UpdateModule
    @SystemModuleID INT,
    @ModuleName     NVARCHAR(150),
    @DisplayName    NVARCHAR(150),
    @Description    NVARCHAR(500) = NULL,
    @IconClass      VARCHAR(100)  = NULL,
    @SortOrder      INT = 0,
    @IsMenuItem     BIT = 1,
    @IsActive       BIT = 1,
    @RowVersion     VARBINARY(8) = NULL,
    @UpdatedBy      INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @SystemModuleID IS NULL OR @SystemModuleID <= 0
        THROW 50021, 'SystemModuleID is required.', 1;
    IF @ModuleName IS NULL OR LTRIM(RTRIM(@ModuleName)) = ''
        THROW 50022, 'ModuleName is required.', 1;
    IF @DisplayName IS NULL OR LTRIM(RTRIM(@DisplayName)) = ''
        THROW 50023, 'DisplayName is required.', 1;
    IF @UpdatedBy IS NULL OR @UpdatedBy <= 0
        THROW 50024, 'UpdatedBy is required.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.SystemModules WHERE SystemModuleID = @SystemModuleID AND IsDeleted = 0)
        THROW 50025, 'Module not found.', 1;

    IF @RowVersion IS NOT NULL
       AND EXISTS (
            SELECT 1 FROM dbo.SystemModules
            WHERE SystemModuleID = @SystemModuleID
              AND RowVersion <> @RowVersion)
        THROW 50026, 'The record was modified by another user. Please refresh and try again.', 1;

    UPDATE dbo.SystemModules
    SET ModuleName  = @ModuleName,
        DisplayName = @DisplayName,
        Description = @Description,
        IconClass   = @IconClass,
        SortOrder   = ISNULL(@SortOrder, 0),
        IsMenuItem  = ISNULL(@IsMenuItem, 1),
        IsActive    = ISNULL(@IsActive, 1),
        UpdatedBy   = @UpdatedBy,
        UpdatedDate = SYSUTCDATETIME()
    WHERE SystemModuleID = @SystemModuleID;

    SELECT 1 AS Affected;
END
GO

/* =============================================================
   5. usp_SystemNavigation_DeleteModule
   Soft delete. Fails if module has active pages.
   ============================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_SystemNavigation_DeleteModule
    @SystemModuleID INT,
    @RowVersion     VARBINARY(8) = NULL,
    @DeletedBy      INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @SystemModuleID IS NULL OR @SystemModuleID <= 0
        THROW 50030, 'SystemModuleID is required.', 1;
    IF @DeletedBy IS NULL OR @DeletedBy <= 0
        THROW 50031, 'DeletedBy is required.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.SystemModules WHERE SystemModuleID = @SystemModuleID AND IsDeleted = 0)
        THROW 50032, 'Module not found.', 1;

    IF EXISTS (SELECT 1 FROM dbo.SystemPages WHERE SystemModuleID = @SystemModuleID AND IsDeleted = 0)
        THROW 50033, 'Module has active pages. Remove or reassign them first.', 1;

    IF @RowVersion IS NOT NULL
       AND EXISTS (
            SELECT 1 FROM dbo.SystemModules
            WHERE SystemModuleID = @SystemModuleID
              AND RowVersion <> @RowVersion)
        THROW 50034, 'The record was modified by another user. Please refresh and try again.', 1;

    UPDATE dbo.SystemModules
    SET IsDeleted   = 1,
        IsActive    = 0,
        DeletedBy   = @DeletedBy,
        DeletedDate = SYSUTCDATETIME(),
        UpdatedBy   = @DeletedBy,
        UpdatedDate = SYSUTCDATETIME()
    WHERE SystemModuleID = @SystemModuleID;

    SELECT 1 AS Affected;
END
GO

/* =============================================================
   6. usp_SystemNavigation_GetPage
   Returns page header (result set 1) and assigned actions (result set 2).
   ============================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_SystemNavigation_GetPage
    @SystemPageID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @SystemPageID IS NULL OR @SystemPageID <= 0
        THROW 50040, 'SystemPageID is required.', 1;

    SELECT
        SystemPageID,
        SystemPageGUID,
        PageKey,
        PageCode,
        PageName,
        DisplayName,
        Description,
        SystemModuleID,
        ParentPageID,
        URL,
        IconClass,
        PageType,
        SortOrder,
        IsMenuItem,
        IsSystemPage,
        RequiresAuthentication,
        IsActive,
        IsDeleted,
        CreatedBy,
        CreatedDate,
        UpdatedBy,
        UpdatedDate,
        RowVersion
    FROM dbo.SystemPages
    WHERE SystemPageID = @SystemPageID;

    SELECT
        pa.PageActionID,
        pa.ActionID,
        a.ActionCode,
        a.ActionName,
        pa.SortOrder,
        pa.IsDefault,
        pa.IsActive
    FROM dbo.SystemPageActions pa
    INNER JOIN dbo.SystemActions a ON a.ActionID = pa.ActionID
    WHERE pa.SystemPageID = @SystemPageID
      AND pa.IsDeleted = 0;
END
GO

/* =============================================================
   7. usp_SystemNavigation_UpdatePage
   Updates SystemPages and synchronizes SystemPageActions in one tx.
   @ActionCodesJson: [ "VIEW","CREATE","DELETE","EXPORT" ]
   ============================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_SystemNavigation_UpdatePage
    @SystemPageID     INT,
    @PageName         NVARCHAR(150),
    @DisplayName      NVARCHAR(150),
    @Description      NVARCHAR(500) = NULL,
    @URL              NVARCHAR(300) = NULL,
    @IconClass        VARCHAR(100)  = NULL,
    @SortOrder        INT = 0,
    @IsMenuItem       BIT = 1,
    @RequiresAuth     BIT = 1,
    @IsActive         BIT = 1,
    @ActionCodesJson  NVARCHAR(MAX),
    @RowVersion       VARBINARY(8) = NULL,
    @UpdatedBy        INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @SystemPageID IS NULL OR @SystemPageID <= 0
        THROW 50041, 'SystemPageID is required.', 1;
    IF @PageName IS NULL OR LTRIM(RTRIM(@PageName)) = ''
        THROW 50042, 'PageName is required.', 1;
    IF @DisplayName IS NULL OR LTRIM(RTRIM(@DisplayName)) = ''
        THROW 50043, 'DisplayName is required.', 1;
    IF @UpdatedBy IS NULL OR @UpdatedBy <= 0
        THROW 50044, 'UpdatedBy is required.', 1;
    IF @ActionCodesJson IS NULL SET @ActionCodesJson = N'[]';
    IF ISJSON(@ActionCodesJson) <> 1
        THROW 50045, 'ActionCodesJson is not valid JSON.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.SystemPages WHERE SystemPageID = @SystemPageID AND IsDeleted = 0)
        THROW 50046, 'Page not found.', 1;

    /* Validate every incoming action code exists */
    IF EXISTS (
        SELECT 1 FROM OPENJSON(@ActionCodesJson) WITH (actionCode VARCHAR(50) '$') a
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.SystemActions sa
            WHERE sa.ActionCode = UPPER(LTRIM(RTRIM(a.actionCode)))
              AND sa.IsDeleted = 0
        )
    )
        THROW 50047, 'One or more action codes do not exist in SystemActions.', 1;

    IF @RowVersion IS NOT NULL
       AND EXISTS (
            SELECT 1 FROM dbo.SystemPages
            WHERE SystemPageID = @SystemPageID
              AND RowVersion <> @RowVersion)
        THROW 50048, 'The record was modified by another user. Please refresh and try again.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();

        UPDATE dbo.SystemPages
        SET PageName               = @PageName,
            DisplayName            = @DisplayName,
            Description            = @Description,
            URL                    = @URL,
            IconClass              = @IconClass,
            SortOrder              = ISNULL(@SortOrder,0),
            IsMenuItem             = ISNULL(@IsMenuItem,1),
            RequiresAuthentication = ISNULL(@RequiresAuth,1),
            IsActive               = ISNULL(@IsActive,1),
            UpdatedBy              = @UpdatedBy,
            UpdatedDate            = @Now
        WHERE SystemPageID = @SystemPageID;

        /* Load incoming codes */
        DECLARE @Incoming TABLE (ActionID INT PRIMARY KEY);
        INSERT INTO @Incoming (ActionID)
        SELECT DISTINCT sa.ActionID
        FROM OPENJSON(@ActionCodesJson) WITH (actionCode VARCHAR(50) '$') a
        INNER JOIN dbo.SystemActions sa
            ON sa.ActionCode = UPPER(LTRIM(RTRIM(a.actionCode)))
           AND sa.IsDeleted = 0;

        /* Reactivate existing rows that are requested again */
        UPDATE pa
        SET pa.IsDeleted    = 0,
            pa.IsActive     = 1,
            pa.UpdatedBy    = @UpdatedBy,
            pa.UpdatedDate  = @Now
        FROM dbo.SystemPageActions pa
        INNER JOIN @Incoming i ON i.ActionID = pa.ActionID
        WHERE pa.SystemPageID = @SystemPageID
          AND (pa.IsDeleted = 1 OR pa.IsActive = 0);

        /* Soft delete rows that are no longer requested */
        UPDATE pa
        SET pa.IsDeleted   = 1,
            pa.IsActive    = 0,
            pa.DeletedBy   = @UpdatedBy,
            pa.DeletedDate = @Now,
            pa.UpdatedBy   = @UpdatedBy,
            pa.UpdatedDate = @Now
        FROM dbo.SystemPageActions pa
        WHERE pa.SystemPageID = @SystemPageID
          AND pa.IsDeleted = 0
          AND NOT EXISTS (SELECT 1 FROM @Incoming i WHERE i.ActionID = pa.ActionID);

        /* Insert brand new ones */
        INSERT INTO dbo.SystemPageActions
        (PageActionGUID, SystemPageID, ActionID, SortOrder, IsDefault,
         IsActive, IsDeleted, CreatedBy, CreatedDate)
        SELECT NEWID(), @SystemPageID, i.ActionID, ISNULL(sa.SortOrder,0),
               CASE WHEN sa.ActionCode = 'VIEW' THEN 1 ELSE 0 END,
               1, 0, @UpdatedBy, @Now
        FROM @Incoming i
        INNER JOIN dbo.SystemActions sa ON sa.ActionID = i.ActionID
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.SystemPageActions pa
            WHERE pa.SystemPageID = @SystemPageID AND pa.ActionID = i.ActionID);

        COMMIT TRANSACTION;

        SELECT 1 AS Affected;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* =============================================================
   8. usp_SystemNavigation_DeletePage
   ============================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_SystemNavigation_DeletePage
    @SystemPageID INT,
    @RowVersion   VARBINARY(8) = NULL,
    @DeletedBy    INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @SystemPageID IS NULL OR @SystemPageID <= 0
        THROW 50050, 'SystemPageID is required.', 1;
    IF @DeletedBy IS NULL OR @DeletedBy <= 0
        THROW 50051, 'DeletedBy is required.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.SystemPages WHERE SystemPageID = @SystemPageID AND IsDeleted = 0)
        THROW 50052, 'Page not found.', 1;

    IF EXISTS (SELECT 1 FROM dbo.SystemPages WHERE ParentPageID = @SystemPageID AND IsDeleted = 0)
        THROW 50053, 'Page has active child pages.', 1;

    IF EXISTS (SELECT 1 FROM dbo.RolePageActionPermissions
               WHERE SystemPageID = @SystemPageID AND IsDeleted = 0)
        THROW 50054, 'Page is referenced by role permissions.', 1;

    IF EXISTS (SELECT 1 FROM dbo.SubscriptionPageActionPermissions
               WHERE SystemPageID = @SystemPageID AND IsDeleted = 0)
        THROW 50055, 'Page is referenced by subscription permissions.', 1;

    IF @RowVersion IS NOT NULL
       AND EXISTS (SELECT 1 FROM dbo.SystemPages
                   WHERE SystemPageID = @SystemPageID AND RowVersion <> @RowVersion)
        THROW 50056, 'The record was modified by another user. Please refresh and try again.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Now DATETIME2(3) = SYSUTCDATETIME();

        UPDATE dbo.SystemPageActions
        SET IsDeleted   = 1,
            IsActive    = 0,
            DeletedBy   = @DeletedBy,
            DeletedDate = @Now
        WHERE SystemPageID = @SystemPageID
          AND IsDeleted = 0;

        UPDATE dbo.SystemPages
        SET IsDeleted   = 1,
            IsActive    = 0,
            DeletedBy   = @DeletedBy,
            DeletedDate = @Now,
            UpdatedBy   = @DeletedBy,
            UpdatedDate = @Now
        WHERE SystemPageID = @SystemPageID;

        COMMIT TRANSACTION;

        SELECT 1 AS Affected;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* =============================================================
   9. usp_SystemNavigation_GetActions
   ============================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_SystemNavigation_GetActions
    @Search        NVARCHAR(200) = NULL,
    @Status        VARCHAR(20)   = NULL,
    @SortBy        VARCHAR(30)   = NULL,
    @SortDirection VARCHAR(4)    = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StatusNorm VARCHAR(20) = LOWER(ISNULL(NULLIF(LTRIM(RTRIM(@Status)),''),'active'));
    DECLARE @SortByNorm VARCHAR(30) = LOWER(ISNULL(NULLIF(LTRIM(RTRIM(@SortBy)),''),'name'));
    DECLARE @SortDir    VARCHAR(4)  = UPPER(ISNULL(NULLIF(LTRIM(RTRIM(@SortDirection)),''),'ASC'));
    DECLARE @SearchLike NVARCHAR(202) =
        CASE WHEN @Search IS NULL OR LTRIM(RTRIM(@Search)) = '' THEN NULL
             ELSE N'%' + LTRIM(RTRIM(@Search)) + N'%' END;

    IF @SortDir NOT IN ('ASC','DESC') SET @SortDir = 'ASC';

    SELECT
        ActionID,
        ActionGUID,
        ActionKey,
        ActionCode,
        ActionName,
        Description,
        SortOrder,
        IsSystemAction,
        IsActive,
        IsDeleted,
        CreatedBy,
        CreatedDate,
        UpdatedBy,
        UpdatedDate,
        RowVersion
    FROM dbo.SystemActions
    WHERE
        (
            @StatusNorm = 'all'
            OR (@StatusNorm = 'active'   AND IsActive = 1 AND IsDeleted = 0)
            OR (@StatusNorm = 'inactive' AND IsActive = 0 AND IsDeleted = 0)
            OR (@StatusNorm = 'deleted'  AND IsDeleted = 1)
        )
        AND (
            @SearchLike IS NULL
            OR ActionCode LIKE @SearchLike
            OR ActionName LIKE @SearchLike
        )
    ORDER BY
        CASE WHEN @SortByNorm='name'        AND @SortDir='ASC'  THEN ActionName  END ASC,
        CASE WHEN @SortByNorm='name'        AND @SortDir='DESC' THEN ActionName  END DESC,
        CASE WHEN @SortByNorm='code'        AND @SortDir='ASC'  THEN ActionCode  END ASC,
        CASE WHEN @SortByNorm='code'        AND @SortDir='DESC' THEN ActionCode  END DESC,
        CASE WHEN @SortByNorm='createddate' AND @SortDir='ASC'  THEN CreatedDate END ASC,
        CASE WHEN @SortByNorm='createddate' AND @SortDir='DESC' THEN CreatedDate END DESC,
        CASE WHEN @SortByNorm='updateddate' AND @SortDir='ASC'  THEN UpdatedDate END ASC,
        CASE WHEN @SortByNorm='updateddate' AND @SortDir='DESC' THEN UpdatedDate END DESC,
        SortOrder ASC;
END
GO

/* =============================================================
   10. usp_SystemNavigation_CreateAction
   ============================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_SystemNavigation_CreateAction
    @ActionCode     VARCHAR(50),
    @ActionName     NVARCHAR(150),
    @Description    NVARCHAR(500) = NULL,
    @SortOrder      INT = 0,
    @IsActive       BIT = 1,
    @IsSystemAction BIT = 0,
    @CreatedBy      INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @ActionCode IS NULL OR LTRIM(RTRIM(@ActionCode)) = ''
        THROW 50060, 'ActionCode is required.', 1;
    IF @ActionName IS NULL OR LTRIM(RTRIM(@ActionName)) = ''
        THROW 50061, 'ActionName is required.', 1;
    IF @CreatedBy IS NULL OR @CreatedBy <= 0
        THROW 50062, 'CreatedBy is required.', 1;

    SET @ActionCode = UPPER(LTRIM(RTRIM(@ActionCode)));
    DECLARE @ActionKey VARCHAR(100) = LOWER(@ActionCode);

    IF EXISTS (SELECT 1 FROM dbo.SystemActions WHERE ActionCode = @ActionCode AND IsDeleted = 0)
        THROW 50063, 'ActionCode already exists.', 1;
    IF EXISTS (SELECT 1 FROM dbo.SystemActions WHERE ActionKey = @ActionKey AND IsDeleted = 0)
        THROW 50064, 'ActionKey already exists.', 1;

    INSERT INTO dbo.SystemActions
    (ActionGUID, ActionKey, ActionCode, ActionName, Description,
     SortOrder, IsSystemAction, IsActive, IsDeleted, CreatedBy, CreatedDate)
    VALUES
    (NEWID(), @ActionKey, @ActionCode, @ActionName, @Description,
     ISNULL(@SortOrder,0), ISNULL(@IsSystemAction,0), ISNULL(@IsActive,1), 0,
     @CreatedBy, SYSUTCDATETIME());

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS ActionID;
END
GO

/* =============================================================
   11. usp_SystemNavigation_GetAction
   ============================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_SystemNavigation_GetAction
    @ActionID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @ActionID IS NULL OR @ActionID <= 0
        THROW 50070, 'ActionID is required.', 1;

    SELECT
        ActionID, ActionGUID, ActionKey, ActionCode, ActionName, Description,
        SortOrder, IsSystemAction, IsActive, IsDeleted,
        CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, RowVersion
    FROM dbo.SystemActions
    WHERE ActionID = @ActionID;
END
GO

/* =============================================================
   12. usp_SystemNavigation_UpdateAction
   ============================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_SystemNavigation_UpdateAction
    @ActionID    INT,
    @ActionName  NVARCHAR(150),
    @Description NVARCHAR(500) = NULL,
    @SortOrder   INT = 0,
    @IsActive    BIT = 1,
    @RowVersion  VARBINARY(8) = NULL,
    @UpdatedBy   INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @ActionID IS NULL OR @ActionID <= 0
        THROW 50071, 'ActionID is required.', 1;
    IF @ActionName IS NULL OR LTRIM(RTRIM(@ActionName)) = ''
        THROW 50072, 'ActionName is required.', 1;
    IF @UpdatedBy IS NULL OR @UpdatedBy <= 0
        THROW 50073, 'UpdatedBy is required.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.SystemActions WHERE ActionID = @ActionID AND IsDeleted = 0)
        THROW 50074, 'Action not found.', 1;

    IF @RowVersion IS NOT NULL
       AND EXISTS (SELECT 1 FROM dbo.SystemActions
                   WHERE ActionID = @ActionID AND RowVersion <> @RowVersion)
        THROW 50075, 'The record was modified by another user. Please refresh and try again.', 1;

    UPDATE dbo.SystemActions
    SET ActionName  = @ActionName,
        Description = @Description,
        SortOrder   = ISNULL(@SortOrder,0),
        IsActive    = ISNULL(@IsActive,1),
        UpdatedBy   = @UpdatedBy,
        UpdatedDate = SYSUTCDATETIME()
    WHERE ActionID = @ActionID;

    SELECT 1 AS Affected;
END
GO

/* =============================================================
   13. usp_SystemNavigation_DeleteAction
   ============================================================= */
CREATE OR ALTER PROCEDURE dbo.usp_SystemNavigation_DeleteAction
    @ActionID   INT,
    @RowVersion VARBINARY(8) = NULL,
    @DeletedBy  INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @ActionID IS NULL OR @ActionID <= 0
        THROW 50080, 'ActionID is required.', 1;
    IF @DeletedBy IS NULL OR @DeletedBy <= 0
        THROW 50081, 'DeletedBy is required.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.SystemActions WHERE ActionID = @ActionID AND IsDeleted = 0)
        THROW 50082, 'Action not found.', 1;

    IF EXISTS (SELECT 1 FROM dbo.SystemPageActions WHERE ActionID = @ActionID AND IsDeleted = 0)
        THROW 50083, 'Action is assigned to one or more pages.', 1;

    IF EXISTS (SELECT 1 FROM dbo.RolePageActionPermissions rp
               INNER JOIN dbo.SystemPageActions pa ON pa.PageActionID = rp.PageActionID
               WHERE pa.ActionID = @ActionID AND rp.IsDeleted = 0)
        THROW 50084, 'Action is referenced by role permissions.', 1;

    IF EXISTS (SELECT 1 FROM dbo.SubscriptionPageActionPermissions sp
               INNER JOIN dbo.SystemPageActions pa ON pa.PageActionID = sp.PageActionID
               WHERE pa.ActionID = @ActionID AND sp.IsDeleted = 0)
        THROW 50085, 'Action is referenced by subscription permissions.', 1;

    IF @RowVersion IS NOT NULL
       AND EXISTS (SELECT 1 FROM dbo.SystemActions
                   WHERE ActionID = @ActionID AND RowVersion <> @RowVersion)
        THROW 50086, 'The record was modified by another user. Please refresh and try again.', 1;

    UPDATE dbo.SystemActions
    SET IsDeleted   = 1,
        IsActive    = 0,
        DeletedBy   = @DeletedBy,
        DeletedDate = SYSUTCDATETIME(),
        UpdatedBy   = @DeletedBy,
        UpdatedDate = SYSUTCDATETIME()
    WHERE ActionID = @ActionID;

    SELECT 1 AS Affected;
END
GO
