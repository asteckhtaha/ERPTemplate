# ERPTemplate — Proposed Project Structure & Guidelines

> **STATUS: ✅ APPROVED AND IMPLEMENTED** (2026-09-15) — the structure described here was approved and
> created; it is now **LOCKED**.
>
> * **Rules / current architecture → [../DEVELOPMENT-GUIDELINES.md](../DEVELOPMENT-GUIDELINES.md)** (source of truth)
> * **This file → historical record** of the proposal and the decisions taken during approval (§6).
>
> Section 1 describes the repository **before** the structure was created; §6 records the approved
> decisions (single API project, Dapper, single database with `CompanyId`/`BranchId`, move-the-scaffold).

---

## 1. Inspection of the current project (Step 1 — done)

Repository: `asteckhtaha/ERPTemplate` — branch `arena/01a0a5af-erptemplate` (base commit `a8e3c30` "Initial ERPTemplate structure").

### 1.1 What exists today

| Item | Path | State |
|---|---|---|
| API solution | `API/ERPTemplate.sln` | Default VS solution, 1 project |
| API project | `API/ERPTemplate/ERPTemplate.csproj` | `net8.0`, `Microsoft.NET.Sdk.Web`, `Nullable`+`ImplicitUsings` enabled, only `Swashbuckle.AspNetCore 6.6.2` |
| API entry point | `API/ERPTemplate/Program.cs` | Stock template: `AddControllers`, Swagger, `UseHttpsRedirection`, `UseAuthorization`, `MapControllers` |
| API sample code | `Controllers/WeatherForecastController.cs`, `WeatherForecast.cs`, `ERPTemplate.http` | Unmodified Visual Studio template sample (no business value) |
| API config | `appsettings.json`, `Properties/launchSettings.json` | Default; **no connection string, no JWT settings, no CORS** |
| Angular app | `Frontend/` (workspace root is `Frontend` itself) | Angular **19.2** standalone, CLI `@angular/cli 19.2.27`, TypeScript 5.7, Karma/Jasmine |
| Angular source | `Frontend/src/app/` | Only `app.component.*`, `app.config.ts` (empty routes), `app.routes.ts` (empty), `main.ts` |
| Angular styles | `Frontend/src/styles.css` | **Plain CSS**, no `src/styles/` folder |
| Angular assets | `Frontend/public/` | Angular 17+ convention (`public/` replaces legacy `src/assets/`) |
| Angular envs | — | **No `src/environments/` folder exists** |
| Angular `/app` subfolders | — | **None** (no `core`, `shared`, `layout`, `features`) |
| Root `.gitignore` | `.gitignore` | Good coverage: `.vs/`, `bin/`, `obj/`, `node_modules/`, `dist/`, `.angular/`, logs, `.env`, `appsettings.Development.json` |
| Root `.editorconfig` | — | Missing (only `Frontend/.editorconfig` exists) |
| Root `README.md` | — | Missing |
| `DEVELOPMENT-GUIDELINES.md` | — | **Does not exist — created only after approval** |
| `docs/` folder | — | **Does not exist** (this proposal is the first file proposed for it) |
| Tests | — | No API test project; Angular spec scaffolding present |
| Database layer | — | No data access of any kind, no schema scripts, no stored procedures |
| Auth | — | None (no JWT, no Identity, no authorization policies) |

### 1.2 Conclusion

The repository is a **freshly scaffolded template**: two default starter apps (ASP.NET Core Web API + Angular 19) with **no ERP code, no database layer, no authentication and no documentation**.

* Nothing needs to be preserved except the default scaffolds themselves.
* Two naming/path mismatches exist versus your target tree (§6 Q1/Q2 — now decided: **move now**).
* No business logic exists that could be broken by adding the approved structure.

### 1.3 Environment check (this sandbox)

| Tool | Available |
|---|---|
| `node` / `npm` | ✅ v22.22.3 / 10.9.8 |
| Angular CLI | via `npx @angular/cli` (dependencies not installed yet) |
| .NET SDK 8 | ❌ not installed in this sandbox (code can be written, not compiled here) |
| SQL Server | ❌ not available here (no DB work in this task anyway) |

---

## 2. Proposed root structure

```text
ERPTemplate/
│
├── API/                                  # all .NET backend code (solution + project)
│   ├── ERPTemplate.sln
│   └── ERPTemplate.API/
│
├── Frontend/                             # all Angular code
│   └── ERPTemplate/                      # Angular workspace root (angular.json lives here)
│
├── docs/                                 # supporting documentation (never business code)
│   └── PROPOSED-STRUCTURE.md             # this file
│
├── .gitignore                            # single root ignore file
├── .editorconfig                         # unified C# + TS formatting rules
├── DEVELOPMENT-GUIDELINES.md             # the development contract (created after APPROVED)
└── README.md                             # what the project is, how to run API + Frontend
```

| Item | Purpose |
|---|---|
| `API/` | Everything .NET: solution file + API project. Nothing else at this level. |
| `Frontend/` | Everything Angular. One workspace per application; future extra apps would be siblings here. |
| `docs/` | Long-form docs supporting the guidelines: schema notes, API endpoint catalog, ERD, changelog. **Rules stay in `DEVELOPMENT-GUIDELINES.md`; `docs/` holds detail.** |
| `.gitignore` | One root ignore file for .NET + Angular + IDE + secrets. |
| `.editorconfig` | So C# (`dotnet format`) and TS (prettier/IDE) share one formatting baseline. |
| `DEVELOPMENT-GUIDELINES.md` | Primary contract, single source of truth for architecture rules. |
| `README.md` | Onboarding: prerequisites, run commands, pointer to the guidelines. |

---

## 3. Proposed API structure (updated for your Dapper choice)

### 3.1 One API project — no extra layers

```text
API/
├── ERPTemplate.sln
│
└── ERPTemplate.API/
    ├── Controllers/                      # thin HTTP endpoints only
    ├── Middleware/                       # cross-cutting request pipeline
    ├── Extensions/                       # service + pipeline registration helpers
    ├── Helpers/                          # small static utilities & constants
    ├── Models/                           # request/response DTOs (never DB row classes)
    │   ├── Common/                       # ApiResponse<T>, PagedResult<T>, PagingRequest, LookupDto
    │   └── <Feature>/                    # e.g. Users/, Products/ (added when that feature starts)
    ├── Entities/                         # POCO classes mapped from SQL result sets
    ├── Services/                         # business logic + Dapper data access per feature
    ├── Data/                             # everything database-related except business rules
    │   ├── SqlConnectionFactory.cs       # single place that creates IDbConnection
    │   ├── Queries/                      # static SQL text per feature (ProductQueries.cs)
    │   ├── StoredProcedures/             # .sql sources for report SPs (source of truth, in git)
    │   └── Scripts/                      # numbered DDL + seed scripts, applied in order
    ├── Configuration/                    # strongly-typed settings classes (JwtSettings, ...)
    ├── Properties/
    │   └── launchSettings.json
    ├── Program.cs
    ├── appsettings.json
    ├── appsettings.Development.json
    └── ERPTemplate.API.http
```

### 3.2 Purpose of each folder

| Folder | Purpose | Rules |
|---|---|---|
| `Controllers/` | Maps HTTP → service call → HTTP response. One controller per resource (`ProductsController`). | No business logic, no SQL, no `IDbConnection`, max ~15 lines per action. |
| `Services/` | All business rules, validation beyond DTO attributes, company/branch scoping, transactions, calling Dapper. | Only place that orchestrates SQL + rules. Returns DTOs, never raw rows to the client. |
| `Data/` | Connection factory, SQL text, stored-procedure sources, DDL/seed scripts. | Only `Services/` uses it. Controllers never touch it. |
| `Data/Queries/` | Parameterized SQL kept as static constants grouped by feature. | Always parameterized, always `Async`, no string concatenation of user input. |
| `Data/StoredProcedures/` | `.sql` files for report/heavy set-based procedures — committed to git. | Naming `usp_<Module>_<Action>`; used for reports and bulk work, not for simple CRUD. |
| `Data/Scripts/` | Numbered, ordered schema scripts (`01_Tables.sql`, `02_Indexes.sql`, `03_Seed.sql` …). | DB schema changes are versioned scripts in git — never ad-hoc manual changes only on a server. |
| `Entities/` | POCO classes that mirror table/result shapes for Dapper mapping. | Audit/`IsActive`/`CompanyId`/`BranchId` fields where applicable; never exposed over HTTP directly. |
| `Models/` | DTOs for requests/responses + shared envelope types. | One file per DTO. Entities are not API contracts. |
| `Middleware/` | `ExceptionHandlingMiddleware` (+ later request logging / tenant checks). | Pipeline-level concerns only. |
| `Extensions/` | `AddApplicationServices()`, `AddDatabase()`, `AddJwtAuthentication()`, `AddSwaggerWithAuth()`, `ConfigureDatabase()` (connection factory + optional Dapper type maps). | Keeps `Program.cs` short. Wiring only, no logic. |
| `Helpers/` | Small static helpers and constants (`Roles`, `Permissions`, `SqlErrorHelper`). | Static, stateless, unit-testable. |
| `Configuration/` | Strongly-typed `IOptions` classes bound from `appsettings.json`. | No connection strings hardcoded, no secrets in git. |
| `Properties/` | Visual Studio launch profiles. | Dev only, no secrets. |

### 3.3 Deliberately **not** included

❌ `Repository` / `GenericRepository` / `UnitOfWork` — Dapper + `SqlConnectionFactory` **is** the data-access path.
❌ EF Core / `DbContext` / migrations — superseded by your choice of Dapper + versioned SQL scripts.
❌ CQRS / MediatR / AutoMapper-by-default.
❌ Extra projects (`Core`, `Infrastructure`, `Domain`, `Persistence`) — one deployable API project.
❌ Interface-per-service boilerplate (see §6 Q5).
❌ Empty placeholder folders — a folder is created when it has real content.

### 3.4 Optional alternative — 3 projects (not recommended now)

`API/ERPTemplate.API` + `API/ERPTemplate.Core` + `API/ERPTemplate.Infrastructure`. Adds project references, DI wiring and file hops with **zero** functional gain for a single-team ERP. Trigger to revisit: a second consumer (mobile app / worker service) needs the same business logic. Still requires your approval.

---

## 4. Proposed Angular structure

### 4.1 Tree

```text
Frontend/
└── ERPTemplate/                          # Angular workspace root (angular.json, package.json)
    ├── src/
    │   ├── app/
    │   │   ├── core/                     # app-wide singletons, loaded once at startup
    │   │   │   ├── guards/               # authGuard, permissionGuard, dirtyFormGuard
    │   │   │   ├── interceptors/         # authInterceptor, errorInterceptor, loadingInterceptor
    │   │   │   ├── models/               # ApiResponse<T>, PagedResult<T>, UserSession, LookupItem
    │   │   │   ├── services/             # ApiService (base HTTP), AuthService, PermissionService,
    │   │   │   │                         #   CompanyContextService, NotificationService, LoadingService
    │   │   │   └── constants/            # API base/endpoints, permission keys, storage keys
    │   │   ├── shared/                   # reusable UI + utilities with no business logic
    │   │   │   ├── components/           # DataTableComponent, ConfirmDialogComponent, PageHeaderComponent,
    │   │   │   │                         #   FormFieldComponent, EmptyStateComponent, LoadingSpinnerComponent
    │   │   │   ├── directives/           # HasPermissionDirective
    │   │   │   ├── pipes/                # DateFormatPipe, MoneyPipe, StatusBadgePipe
    │   │   │   └── validators/           # shared reactive-form validators
    │   │   ├── layout/                   # the application shell (not a feature)
    │   │   │   ├── main-layout/          # sidebar + header + <router-outlet> (authenticated shell)
    │   │   │   ├── sidebar/
    │   │   │   ├── header/               # user menu, company/branch switcher placeholder
    │   │   │   └── pages/                # not-found, forbidden, server-error
    │   │   ├── features/                 # ERP modules — lazy loaded, one folder each
    │   │   │   ├── auth/                 # login (public routes, no shell)
    │   │   │   ├── dashboard/
    │   │   │   ├── companies/
    │   │   │   ├── users/
    │   │   │   ├── roles/
    │   │   │   ├── products/
    │   │   │   ├── sales/
    │   │   │   ├── purchases/
    │   │   │   └── reports/
    │   │   ├── app.component.ts | .html | .css
    │   │   ├── app.config.ts
    │   │   └── app.routes.ts
    │   ├── environments/                 # environment.ts, environment.development.ts, environment.production.ts
    │   ├── styles/                       # _variables.scss, _mixins.scss, _theme.scss, styles.scss
    │   └── index.html, main.ts
    ├── public/                           # static files (favicon, logos, icons)
    ├── angular.json · package.json · tsconfig.json · tsconfig.app.json · tsconfig.spec.json
    ├── .editorconfig
    └── README.md
```

### 4.2 Purpose of each folder

| Folder | Purpose | Key rule |
|---|---|---|
| `core/` | App-wide singletons: base HTTP service, auth, permissions, guards, interceptors, global models, constants. | Imported by everyone; **never imports from `features/`**. |
| `shared/` | Genuinely reusable UI + utilities (dumb components, pipes, directives, validators). | **No** API calls, no business rules, no feature imports. |
| `layout/` | Application shell: navigation, header, sidebar, error pages. | Layout only — no business logic. |
| `features/` | One folder per ERP module; lazy-loaded; owns its pages, routes, models, API service. | Features never import another feature's private folders. |
| `environments/` | Per-environment `apiBaseUrl` and feature flags. | No secrets in Angular — everything shipped to the browser is public. |
| `styles/` | Global SCSS: design tokens, theme, typography, utility classes. | Component styles stay in the component; only global tokens live here. |

### 4.3 Standard shape of every feature folder (the only allowed internal pattern)

```text
features/products/
├── pages/                        # route targets
│   ├── product-list/             # product-list.component.ts | .html | .scss
│   └── product-form/             # add/edit (create & update share one form)
├── components/                   # components private to this feature only
├── models/                       # feature interfaces/DTOs (mirrors API contracts)
├── services/                     # product.service.ts — the only place calling /api/v1/products
└── products.routes.ts            # feature routes, lazy loaded from app.routes.ts
```

Consistency rules: one folder per feature named after the ERP module; a feature component moves to `shared/` only when a **second** feature genuinely reuses it; no duplicated table/form/validation logic.

### 4.4 Deviations from your sketch (need your confirmation)

| Your sketch | Proposed | Reason |
|---|---|---|
| `Frontend/ERPTemplate/…` | Same — but today the workspace **is** `Frontend/` itself | Matches your target tree; you approved the one-time move (§6 Q2). |
| `src/assets/` | Keep Angular 19 default `public/` for static files | Angular 17+ replaced `src/assets/` with `public/`. |
| `src/styles/` | `src/styles/` with **SCSS** | Small `angular.json` change; sass is already supported by Angular CLI. |
| Example `features/` list | Same list, created **only when the feature starts** | Avoids 8 empty folders that drift out of sync. |

---

## 5. What will be added to `DEVELOPMENT-GUIDELINES.md`

> Not created yet — this is the **preview of contents** for review.
> One file, 34 numbered sections matching your outline, becoming the project contract.
> Adjusted for your decisions: **Dapper + SQL Server scripts**, **single DB with CompanyId/BranchId**.

| # | Section | Proposed content (summary) |
|---|---|---|
| 1 | Project Overview | What ERPTemplate is; two applications (API, Frontend) + SQL Server; design goal = simple, maintainable, extensible ERP. |
| 2 | Technology Stack | .NET 8 / C# 12, ASP.NET Core Web API, **Dapper** for SQL Server access, Angular 19 + TypeScript 5.7, SQL Server, JWT auth, Swagger, VS/VS Code. Locked versions; upgrade = approval. |
| 3 | Approved Project Structure | The approved trees from §2–§4 with the LOCKED banner and the change-control rule. |
| 4 | API Folder Structure | Purpose + rules of every API folder (§3.2) and the "no extra layers" list. |
| 5 | Angular Folder Structure | Purpose + rules of `core`/`shared`/`layout`/`features`; the feature-folder template (§4.3). |
| 6 | Folder Structure Lock Rules | LOCKED statement; pre-approved growth patterns; the STOP→explain→approve→update→re-lock flow; never silently move/rename/create alternatives. |
| 7 | Architecture Principles | Simple first; one obvious way to do a thing; command flow = Controller → Service → Dapper/SQL; no abstraction without a second real use case. |
| 8 | Coding Standards | PascalCase/camelCase/`_camelCase`, `Async` suffix, one type per file, file name = type name, nullable enabled, 4-space C# / 2-space TS, comments explain *why*. |
| 9 | API Development Rules | REST conventions, `api/v1/[controller]`, plural resources, verbs/status mapping, controller ≤15 lines, DTO in/out, `async` + `CancellationToken`, paging/filter/sort params (`page`, `pageSize`, `search`, `sortBy`, `sortDir`), no entity in responses. |
| 10 | Angular Development Rules | File naming (`product-list.component.ts`), standalone components only, `inject()` over constructors, lazy `loadChildren`/`loadComponent`, signals for local state, reactive forms, no `HttpClient` in components. |
| 11 | Database Development Rules | Naming, PK/FK/index/unique conventions, audit fields, soft delete, `IsActive`, tenant/branch columns, **ordered DDL scripts in git**, SP naming, transaction rules, data types (`decimal(18,4)`, `datetime2(0)` UTC, sized `nvarchar`). |
| 12 | Authentication & Authorization Rules | JWT bearer, access + refresh, password hashing, claims (`userId`, `companyId`, `branchId`, roles, permissions), permission policies, 401 vs 403, login lockout; nothing from the client is trusted. |
| 13 | Multi-Tenant / Company Isolation Rules | Every company-scoped query filtered by server-resolved `CompanyId`; client-sent company/branch IDs ignored unless validated against the user's allowed list (single DB + `CompanyId`/`BranchId`). |
| 14 | Error Handling | `ExceptionHandlingMiddleware` → standard envelope, exception→status map, SQL error mapping (duplicate → 409), no stack traces to clients, correlation id in logs. |
| 15 | Validation | DataAnnotations on request DTOs + service-level rules for multi-field/DB-dependent checks; `[ApiController]` 400 shaped to the envelope; validation messages user-readable; client validation is never trusted. |
| 16 | Logging | `ILogger<T>` structured logs, log levels, mandatory events (auth failures, permission denials, exceptions, tenant mismatches), never log passwords/tokens/connection strings/PII; **no logging of SQL parameters containing sensitive data**. |
| 17 | Security Rules | Never trust UI permissions, hidden buttons, route guards, or client-sent company/branch/user IDs; HTTPS; CORS allow-list; login rate limiting; secrets in user-secrets/env, never in git; **always parameterized SQL**; input/file validation. |
| 18 | Reusable Code Rules | Exact wording: *"Reusable code means reducing duplicate code while keeping the implementation simple, readable and easy to maintain."* Prefer simple helper/service/component/model; forbid generic frameworks, deep inheritance, speculative abstraction. |
| 19 | Naming Conventions | C#, TypeScript, SQL objects, API routes, Angular files, permissions (`Products.View`, `Products.Create`), DB columns, booleans (`Is*`, `Has*`). |
| 20 | API Response Standards | Success/failure envelope, paged result shape, status-code table, no raw rows/entities, error codes the UI can map. |
| 21 | Angular HTTP/API Rules | Feature service per resource, typed `ApiResponse<T>`, interceptors for token + errors + loading, `environment.apiBaseUrl`, no component-level `HttpClient`, `takeUntilDestroyed`, retry rules. |
| 22 | Component Rules | One responsibility; ≤ ~200 lines TS; smart page vs dumb presentational split; typed inputs/outputs; `OnPush`; no logic in templates; no API calls in dumb components. |
| 23 | Service Rules | Business logic in services; one responsibility; no 20-method god-service; no duplicate service per feature; `inject()`; `providedIn: 'root'` only for singletons; feature services scoped to feature routes; **concrete classes, interfaces only where genuinely needed** (per §6 Q5). |
| 24 | State Management Rules | No NgRx/signals store by default; component state + feature services + `signal()`; shared session state in `core`; a store would require approval. |
| 25 | UI/UX Consistency Rules | One design system in `styles/`; shared table/form/button/dialog components; consistent spacing/typography/colors; the standard list-page pattern (filter → table → paging → actions); mandatory loading/empty/error states; keyboard + responsive behaviour. |
| 26 | Performance Rules | All DB calls async; pagination everywhere; no N+1 queries (no query inside a loop); index filtered/joined columns; `CommandTimeout` awareness for reports; `OnPush` + `trackBy`; lazy-loaded features. |
| 27 | File Creation Rules | Search existing first; correct folder per approved structure; naming per conventions; no duplicate/`*2`/`*New` files; one type per file; no new root folders; delete replaced files instead of leaving dead code. |
| 28 | Duplicate Code Prevention | Mandatory search-before-create checklist; extend existing implementation; extract to helper/shared component on the **third** repetition; never fork a component to make a small variant. |
| 29 | Testing Rules | xUnit for API (service tests + integration via `WebApplicationFactory` with a test DB script set), Karma/Jasmine (or Vitest) for Angular; `Method_Scenario_ExpectedResult` naming; test business rules, tenant isolation, validation; test project slot reserved at `API/ERPTemplate.API.Tests/` (created with the first test). |
| 30 | Git Rules | Meaningful commits (`feat(products): add product list endpoint`), feature branches, no secrets/passwords/`appsettings.Development.json`/connection strings, no `node_modules`/`bin`/`obj`/`dist`, maintained `.gitignore`, PR + review, no force-push on shared branches. |
| 31 | Documentation Rules | `DEVELOPMENT-GUIDELINES.md` is the source of truth; record every architectural decision there when agreed; `docs/` for detail (endpoint catalog, schema notes, ERD); README kept runnable; docs updated in the same change as the code. |
| 32 | Change Approval Rules | What needs explicit approval (new root folders, new project, new library/NuGet, new pattern, schema redesign, API contract break, moving files) vs what does not (adding a page/feature folder per approved template). |
| 33 | Forbidden Patterns | Repository/UoW/GenericRepository, CQRS/MediatR, EF Core introduction without approval, `SELECT *`, string-concatenated SQL, business logic in controllers/components, try/catch in every controller, client-trusting authorization, `UserServiceNew`-style duplicates, empty placeholder layers, magic strings/numbers, `async void`, `.Result`/`.Wait()`. |
| 34 | Final Development Checklist | Copy-paste checklist per change: reuse searched → correct folders → DTOs validated → service rules → tenant/branch enforced server-side → permissions checked → parameterized SQL → standard response → error handling → logs → tests → Angular reuses shared UI → loading/empty/error states → docs updated → commit message. |

### 5.1 Concrete rule samples (so you can judge the writing style)

**API response envelope (Section 20)**

```json
// 200 / 201
{ "success": true, "data": { "id": 15, "code": "P-001" }, "message": null, "errors": [] }

// 400 / 409
{ "success": false, "data": null, "message": "Product code already exists.", "errors": ["Code 'P-001' is already used."] }

// paged
{ "success": true, "data": { "items": [], "page": 1, "pageSize": 20, "totalCount": 0 }, "message": null, "errors": [] }
```

**Status codes (Sections 9/20):** 200 read/update · 201 create (+`Location`) · 204 delete · 400 validation · 401 not authenticated · 403 authenticated but not permitted · 404 not found (or not in your company) · 409 business conflict/duplicate · 500 unexpected.

**Database conventions (Section 11)**

```text
Table        : Company, Product, SalesOrder        (singular, PascalCase)
Primary key  : CompanyId, ProductId                (identity int)
Foreign key  : CompanyId, BranchId                 (same name as referenced PK)
Index        : IX_Product_CompanyId_Code
Unique       : UQ_Product_CompanyId_Code
FK           : FK_Product_Company
Stored proc  : usp_Report_TrialBalance             (module prefix; reports/heavy set-based work only)
Scripts      : 01_Tables.sql → 02_Indexes.sql → 03_Seed.sql   (ordered, in git, one change per script set)
Audit fields : CreatedBy, CreatedDate, UpdatedBy, UpdatedDate (UTC), IsActive
Soft delete  : IsDeleted (only where history must survive)
Money        : decimal(18,4)   ·  Dates: datetime2(0) UTC   ·  Strings: nvarchar(n) always sized
Tenant       : CompanyId NOT NULL on every company-scoped table; BranchId where branch-scoped
```

**Dapper rules (Sections 9/11/26)**

```csharp
// Data/Queries/ProductQueries.cs — SQL lives here, parameterized, never concatenated
public static class ProductQueries
{
    public const string GetPaged = """
        SELECT ProductId, Code, Name, IsActive
        FROM Product
        WHERE CompanyId = @CompanyId
          AND (@Search IS NULL OR Code LIKE @Search + '%' OR Name LIKE @Search + '%')
        ORDER BY Name
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
        """;
}

// Services/ProductService.cs — company id comes from the authenticated user, never the request
var rows = await conn.QueryAsync<Product>(ProductQueries.GetPaged,
    new { CompanyId = currentUser.CompanyId, Search, Offset, PageSize });
```

**Service interface policy (Section 23 — see Q5):** services are registered and injected as concrete types (`AddScoped<ProductService>()`). An interface is added only for a real second implementation or an external boundary (e-mail/SMS/payment provider, current-user accessor, file storage).

**Security rule (Sections 12/13/17), exact wording:**

> Never trust: Angular UI permissions, hidden buttons, route guards alone, client-side company ID, client-side branch ID, client-side user ID. The API enforces authorization and tenant isolation server-side. Every protected request validates the authenticated user's **User, Company, Branch, Role, Permission, Status** as applicable, using values resolved from the token/DB — never from the request body or query string.

---

## 6. Decisions recorded (from your answers)

| # | Decision | Your choice |
|---|---|---|
| Q1 | API project layout | ✅ **Single project `API/ERPTemplate.API/`** — no Core/Infrastructure split |
| Q2 | Existing scaffold | ✅ **Move now + remove template samples** — `API/ERPTemplate/` → `API/ERPTemplate.API/`, `Frontend/*` → `Frontend/ERPTemplate/*`, `WeatherForecast*` and Angular welcome markup removed via `git mv`/clean edit (history preserved) |
| Q3 | Data access | ✅ **Dapper + stored procedures** — no EF Core, no DbContext, no migrations; schema via ordered SQL scripts in `Data/Scripts/`, reports/heavy work via `usp_*` procedures in `Data/StoredProcedures/` |
| Q4 | Multi-company isolation | ✅ **Single database with `CompanyId` / `BranchId`** columns, enforced server-side; query filters in SQL + validated against the user's allowed companies/branches |

**Defaults I will apply unless you say otherwise** (items 1–7 of §6.5 of the previous revision, unchanged):
1. Root `.editorconfig` for unified C#/TS formatting.
2. Merge `Frontend/.gitignore` into the root `.gitignore`; keep a short `Frontend/README.md`.
3. Convert `styles.css` → `src/styles/` + SCSS and update `angular.json`.
4. Add `src/environments/` (`environment.ts`, `environment.development.ts`, `environment.production.ts`) with `apiBaseUrl` — files only.
5. Keep `public/` as the static folder (Angular 17+ default) instead of `src/assets/`.
6. Create root `README.md`.
7. Reserve `API/ERPTemplate.API.Tests/` only when the first test is written (not now).

**One remaining choice (Q5) — service interfaces:** default is **concrete service classes, interfaces only where genuinely needed** (matches your "no excessive interfaces" rule). Say so if you prefer `IXxxService` everywhere.

---

## 7. What will NOT be created in this task

❌ No business features ❌ No CRUD ❌ No authentication/authorization code ❌ No database tables, scripts or seed data ❌ No API endpoints ❌ No Angular pages, components, services or guards ❌ No new NuGet/npm packages beyond what the empty structure needs ❌ No lock until you approve.

**After you say `APPROVED`, exactly this happens:**

1. `git mv` the scaffold into the approved paths (Q1/Q2) and remove the template samples.
2. Create the approved folder skeleton (`.gitkeep` only where Git would otherwise lose a folder).
3. Merge root `.gitignore`, add root `.editorconfig`, add `README.md`, apply the Angular style/environment defaults.
4. Write the full `DEVELOPMENT-GUIDELINES.md` (34 sections, `STATUS: LOCKED` on §3–§5, the exact reusability definition, the no-silent-architecture-change flow).
5. Commit as `chore(structure): establish approved API and Angular folder structure` — **no feature code in that commit**.
6. Report the final tree and lock the structure.

---

## STATUS: WAITING FOR APPROVAL

Reply `APPROVED` (optionally with changes to §6) and I will build it. Until then the repository stays **exactly** as inspected in §1 — no files added, moved, deleted or modified.
