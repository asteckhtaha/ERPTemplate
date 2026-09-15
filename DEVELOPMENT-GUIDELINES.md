# DEVELOPMENT-GUIDELINES.md

**Project:** ERPTemplate — multi-company / multi-branch ERP
**Status:** ✅ **APPROVED & LOCKED** — API structure locked, Angular structure locked
**Applies to:** everyone (human or AI agent) writing code, SQL, or documentation in this repository.

> This document is the **single source of truth** for how ERPTemplate is built.
> If a rule here conflicts with a chat message, a ticket, or a habit — this document wins.
> If a rule has to change, change it **here first** (see §32 Change Approval Rules).

**Locked sections:** §3 Approved Project Structure · §4 API Folder Structure · §5 Angular Folder Structure · §6 Folder Structure Lock Rules.

---

## Table of contents

1. [Project Overview](#1-project-overview)
2. [Technology Stack](#2-technology-stack)
3. [Approved Project Structure](#3-approved-project-structure)
4. [API Folder Structure](#4-api-folder-structure)
5. [Angular Folder Structure](#5-angular-folder-structure)
6. [Folder Structure Lock Rules](#6-folder-structure-lock-rules)
7. [Architecture Principles](#7-architecture-principles)
8. [Coding Standards](#8-coding-standards)
9. [API Development Rules](#9-api-development-rules)
10. [Angular Development Rules](#10-angular-development-rules)
11. [Database Development Rules](#11-database-development-rules)
12. [Authentication & Authorization Rules](#12-authentication--authorization-rules)
13. [Multi-Tenant / Company Isolation Rules](#13-multi-tenant--company-isolation-rules)
14. [Error Handling](#14-error-handling)
15. [Validation](#15-validation)
16. [Logging](#16-logging)
17. [Security Rules](#17-security-rules)
18. [Reusable Code Rules](#18-reusable-code-rules)
19. [Naming Conventions](#19-naming-conventions)
20. [API Response Standards](#20-api-response-standards)
21. [Angular HTTP/API Rules](#21-angular-httpapi-rules)
22. [Component Rules](#22-component-rules)
23. [Service Rules](#23-service-rules)
24. [State Management Rules](#24-state-management-rules)
25. [UI/UX Consistency Rules](#25-uiux-consistency-rules)
26. [Performance Rules](#26-performance-rules)
27. [File Creation Rules](#27-file-creation-rules)
28. [Duplicate Code Prevention](#28-duplicate-code-prevention)
29. [Testing Rules](#29-testing-rules)
30. [Git Rules](#30-git-rules)
31. [Documentation Rules](#31-documentation-rules)
32. [Change Approval Rules](#32-change-approval-rules)
33. [Forbidden Patterns](#33-forbidden-patterns)
34. [Final Development Checklist](#34-final-development-checklist)
- [Appendix A — Behaviour rules for contributors and AI agents](#appendix-a--behaviour-rules-for-contributors-and-ai-agents)
- [Appendix B — Decision log](#appendix-b--decision-log)

---

## 1. Project Overview

ERPTemplate is the starting point for an ERP system used by **multiple companies** (tenants) and
**multiple branches per company**.

| Aspect | Decision |
|---|---|
| Product | Multi-company, multi-branch ERP (template + evolving business modules) |
| Applications | `API` (ASP.NET Core 8 Web API) and `Frontend` (Angular 19 SPA) |
| Database | SQL Server (single database, `CompanyId` / `BranchId` isolation) |
| Users | Company users with roles + granular permissions, scoped to company/branch |
| Auth | JWT bearer tokens issued by the API; the API is the only authority on access |

**Design goals, in priority order**

1. **Simple** — the smallest structure that correctly supports the current ERP.
2. **Maintainable** — one obvious place for every kind of code.
3. **Extensible** — new ERP modules are added by following the existing pattern, not by inventing a new one.
4. **Consistent** — the same problem is solved the same way everywhere.
5. **Reusable** — duplication is removed, but never at the cost of (1).

**Explicit non-goals:** maximum abstraction, maximum number of layers, generic frameworks,
speculative architecture for hypothetical future requirements.

---

## 2. Technology Stack

| Layer | Technology | Version | Notes |
|---|---|---|---|
| Backend runtime | .NET / ASP.NET Core Web API | **8.0** | `net8.0`, nullable + implicit usings enabled |
| Backend language | C# | 12 | |
| Data access | **Dapper** (micro-ORM) over `Microsoft.Data.SqlClient` | 2.x / 5.x | No EF Core, no DbContext, no migrations |
| Database | SQL Server | 2019+ | Schema versioned as ordered SQL scripts |
| API docs | Swashbuckle (Swagger / OpenAPI) | 6.6.x | Development builds; JWT bearer enabled |
| Auth | JWT bearer (`Microsoft.AspNetCore.Authentication.JwtBearer`) | 8.x | Access + refresh tokens |
| Frontend framework | Angular (standalone components, signals) | **19.2** | CLI 19.2.x |
| Frontend language | TypeScript | 5.7 | `strict`, `strictTemplates` |
| Styling | SCSS | — | Global tokens in `src/styles/`, component styles local |
| Forms | Angular Reactive Forms | — | Typed forms only |
| State | Component state + `signal()` + feature services | — | No NgRx unless approved (§24) |
| Frontend tests | Karma + Jasmine (existing scaffold) | — | See §29 |
| Backend tests | xUnit (+ `WebApplicationFactory` for integration) | 2.x | Test project added with the first test (§29) |
| IDE | Visual Studio 2022 / VS Code | — | `.editorconfig` at root is authoritative |
| VCS | Git + GitHub | — | Feature branches, PR review (§30) |

**Package policy:** every new NuGet/npm dependency requires approval (§32) and must be added to this
table in the same pull request. Prefer the platform (BCL, Angular, `HttpClient`) over a package.

**Packages intentionally NOT in this project:** EF Core, MediatR, CQRS libraries, AutoMapper,
FluentValidation (DataAnnotations are used until a real limitation appears), NgRx, PrimeNG/Material
unless explicitly approved, any "generic repository" library.

---

## 3. Approved Project Structure

> 🔒 **STATUS: LOCKED** — approved by the project owner. Do not add, move, rename or remove
> top-level folders without approval (§6, §32).

```text
ERPTemplate/
│
├── API/                                   # 🔒 all .NET backend code
│   ├── ERPTemplate.sln
│   └── ERPTemplate.API/                   # single API project (see §4)
│
├── Frontend/
│   └── ERPTemplate/                       # 🔒 Angular workspace (see §5)
│
├── docs/                                  # supporting documentation (no code)
│   └── PROPOSED-STRUCTURE.md              # approved proposal + recorded decisions
│
├── .editorconfig                          # formatting rules for C#, TS, SQL
├── .gitignore                             # single ignore file for both apps
├── DEVELOPMENT-GUIDELINES.md              # this contract
└── README.md                              # onboarding + run instructions
```

**Root-level rules**

* The repository root contains **only** the items listed above. No new root folders or root files
  without approval.
* `API/` contains .NET only; `Frontend/` contains Angular only. Never mix.
* `docs/` holds explanations and evidence — **rules belong in this file**, not in `docs/`.
* One solution (`API/ERPTemplate.sln`) and one Angular workspace (`Frontend/ERPTemplate`).

---

## 4. API Folder Structure

> 🔒 **STATUS: LOCKED**

```text
API/
├── ERPTemplate.sln
└── ERPTemplate.API/
    ├── Controllers/          # HTTP endpoints only
    ├── Middleware/           # exception handling, request logging, tenant checks
    ├── Extensions/           # service registration / pipeline wiring helpers
    ├── Helpers/              # small static helpers + shared constants
    ├── Models/               # request/response DTOs (API contracts)
    │   ├── Common/           # ApiResponse<T>, PagedResult<T>, PagingRequest, LookupDto
    │   └── <Feature>/        # created per feature: Users/, Products/, Sales/ ...
    ├── Entities/             # POCO classes mapped from SQL result sets
    ├── Services/             # business logic + Dapper data access
    ├── Data/                 # database plumbing and SQL assets
    │   ├── SqlConnectionFactory.cs
    │   ├── Queries/          # parameterized SQL text per feature
    │   ├── StoredProcedures/ # .sql sources for report/heavy procedures
    │   └── Scripts/          # ordered DDL + seed scripts (01_, 02_, ...)
    ├── Configuration/        # strongly-typed settings classes (JwtSettings, ...)
    ├── Properties/           # launchSettings.json (local only)
    ├── Program.cs
    ├── appsettings.json
    └── appsettings.Development.json   # local only, git-ignored, never committed
```

**Folder responsibilities**

| Folder | Allowed content | Must NOT contain |
|---|---|---|
| `Controllers/` | Route attributes, model binding, call to one service method, return `ActionResult` | Business rules, SQL, `IDbConnection`, mapping loops, `try/catch` |
| `Services/` | Business rules, permission/tenant enforcement, transactions, Dapper calls, mapping entity→DTO | HTTP concerns (`HttpContext` for anything but current-user values), `IActionResult` |
| `Data/` | Connection factory, SQL constants, SP sources, schema/seed scripts | Business rules |
| `Entities/` | POCOs mirroring tables/result sets | API-only shapes, validation attributes for API contracts |
| `Models/` | DTOs + shared envelopes | DB-only fields that must not leak to clients |
| `Middleware/` | Exception handling, request/correlation logging | Feature logic |
| `Extensions/` | `AddApplicationServices()`, `AddDatabase()`, `AddJwtAuthentication()`, `ConfigureApiPipeline()` | Logic, queries |
| `Helpers/` | Static, stateless utilities, constant classes (`Permissions`, `Roles`) | Stateful services, DI dependencies |
| `Configuration/` | `IOptions` classes bound from appsettings | Hardcoded values, secrets |

**Rules**

1. **One project.** No `Core`/`Infrastructure`/`Domain` split until a real second consumer exists and
   the split is approved (§32).
2. **No repository / unit-of-work / generic-repository layer.** `SqlConnectionFactory` + Dapper in
   `Services/` **is** the data access path.
3. New feature sub-folders (`Models/<Feature>/`, `Data/Queries/<Feature>Queries.cs`) follow the
   approved pattern and do not need separate approval — they are part of the locked structure.
4. A folder with no content is not committed; `.gitkeep` marks an approved-but-empty folder.
5. `Program.cs` stays a short composition root (target: well under 100 lines); wiring lives in `Extensions/`.

---

## 5. Angular Folder Structure

> 🔒 **STATUS: LOCKED**

```text
Frontend/ERPTemplate/
├── src/
│   ├── app/
│   │   ├── core/                   # application-wide singletons
│   │   │   ├── guards/             # authGuard, permissionGuard, dirtyFormGuard
│   │   │   ├── interceptors/       # authInterceptor, errorInterceptor, loadingInterceptor
│   │   │   ├── models/             # ApiResponse<T>, PagedResult<T>, UserSession, LookupItem
│   │   │   ├── services/           # ApiService, AuthService, PermissionService,
│   │   │   │                       # CompanyContextService, NotificationService, LoadingService
│   │   │   └── constants/          # API endpoints, permission keys, storage keys
│   │   ├── shared/                 # reusable UI + utilities (no business logic)
│   │   │   ├── components/         # DataTable, ConfirmDialog, PageHeader, FormField, EmptyState...
│   │   │   ├── directives/         # HasPermissionDirective
│   │   │   ├── pipes/              # DateFormat, Money, StatusBadge
│   │   │   └── validators/         # shared reactive-form validators
│   │   ├── layout/                 # application shell (NOT a feature)
│   │   │   ├── main-layout/        # sidebar + header + <router-outlet>
│   │   │   ├── sidebar/
│   │   │   ├── header/
│   │   │   └── pages/              # not-found, forbidden, server-error
│   │   ├── features/               # ERP modules, lazy loaded
│   │   │   └── <module>/           # auth, dashboard, companies, users, roles,
│   │   │                           # products, sales, purchases, reports ...
│   │   ├── app.component.ts|html|scss
│   │   ├── app.config.ts
│   │   └── app.routes.ts
│   ├── environments/               # environment.ts + .development / .production
│   ├── styles/                     # styles.scss, _variables.scss, _theme.scss, _mixins.scss
│   ├── index.html
│   └── main.ts
├── public/                         # static files (favicon, logos, icons)
├── angular.json
├── package.json
├── tsconfig.json · tsconfig.app.json · tsconfig.spec.json
└── README.md
```

**The one and only feature pattern** (every module, without exception):

```text
features/<module>/
├── pages/              # route targets: <name>-list, <name>-form, <name>-details
├── components/         # components used only by this module
├── models/             # feature interfaces mirroring API DTOs
├── services/           # <module>.service.ts — the only place calling the module's endpoints
└── <module>.routes.ts  # routes, lazy loaded from app.routes.ts
```

**Rules**

1. `core/` may be imported by everyone; **`core/` must never import from `features/`**.
2. `shared/` contains only genuinely reusable, business-free UI/utilities; no HTTP calls, no feature imports.
3. `layout/` contains the shell parts only (navigation, header, error pages) — no business logic.
4. `features/` folders are created **when the module starts**, not in advance.
5. Features never import another feature's `pages/`, `components/` or `services/`. If something is
   needed by two features, move it to `shared/` (if UI) or `core/` (if infrastructure) — as part of
   an approved change (§32) because it affects shared code.
6. `environments/` holds configuration only — **no secrets** (everything here ships to the browser).
7. Global styling lives in `src/styles/`; component styling stays in the component's `.scss`.

---

## 6. Folder Structure Lock Rules

### 6.1 What is locked

* Root folders: `API/`, `Frontend/`, `docs/` (+ the root files listed in §3).
* API project layout: `API/ERPTemplate.API/` and the folder set in §4.
* Angular workspace layout: `Frontend/ERPTemplate/src/{app,environments,styles}` and the
  `core / shared / layout / features` split in §5.
* The **one feature pattern** in §5 (a second pattern is not allowed).

### 6.2 What is pre-approved (do NOT ask, just follow the pattern)

* Adding a new feature folder: `features/<module>/…` (Angular) and `Services/<Feature>Service.cs`,
  `Models/<Feature>/…`, `Data/Queries/<Feature>Queries.cs` (API).
* Adding a new file to an existing approved folder.
* Adding a new shared component/pipe/directive/validator in `shared/` **when a second consumer
  genuinely exists** (§28).
* Adding a new stored procedure under `Data/StoredProcedures/` with the `usp_` naming rule (§11).
* Adding a new DDL script to `Data/Scripts/` using the next sequence number.

### 6.3 What requires explicit approval (STOP first)

* Creating, renaming, moving or deleting folders in §3/§4/§5.
* Adding a new .NET project or a new Angular workspace/library.
* Adding a new runtime dependency (NuGet/npm) or a new framework (state management, UI kit, ORM).
* Introducing a second architectural pattern for the same concern (e.g. a repository layer, CQRS,
  a second HTTP base service, a second layout pattern).
* Changing the API response envelope, the status-code mapping, the auth flow, or the tenant model.
* Any change that would break existing API contracts.

### 6.4 Mandatory check before creating a folder

1. Can this fit an **existing approved folder**? → use it.
2. Can an existing **shared/core** component or service be reused? → reuse/extend it.
3. Is a new folder **genuinely** necessary? → if yes, **STOP and request approval**; if no, don't create it.

### 6.5 Change-control flow

```text
APPROVED STRUCTURE
        ↓
      LOCKED
        ↓
Development continues
        ↓
Need structural change?
        ↓
STOP → explain the reason → request approval
        ↓
   Approved? ── YES ──> update structure → update DEVELOPMENT-GUIDELINES.md → LOCK again
        └────── NO ──> keep the existing structure (no silent changes)
```

**Never silently:** move files, rename folders, create duplicate/alternative folders, introduce a
second pattern, or reorganise the project.

---

## 7. Architecture Principles

1. **Simple first.** Build the smallest thing that solves today's problem correctly.
2. **One obvious way.** For any concern (HTTP call, validation, table rendering, response shape)
   there is exactly one approved way — the one in this document.
3. **Fixed request flow.** `Controller → Service → Dapper/SQL`. No layer that only forwards calls.
4. **No abstraction without a second real use case.** Two concrete usages justify an abstraction;
   one does not.
5. **Explicit over clever.** Readable code beats compact code.
6. **Data ownership.** SQL text lives in `Data/Queries` or `Data/StoredProcedures`; business rules
   live in `Services/`; HTTP lives in `Controllers/`.
7. **The server decides.** Authorization, tenant scope, and validation are enforced server-side (§12, §17).
8. **Additive changes.** Extending an existing service/component is preferred over creating a parallel one (§28).
9. **No speculative reuse.** Do not build a framework for "all future modules".
10. **No continuous optimisation.** Do not restructure the project because another pattern "looks cleaner".

---

## 8. Coding Standards

### 8.1 General

* `.editorconfig` at the repository root is authoritative for formatting (UTF-8, LF, final newline, no trailing spaces).
* One public type per file; the file name equals the type name (`ProductService.cs`, `product-list.component.ts`).
* No commented-out code; no dead code; delete instead of "keeping it for later".
* Comments explain **why**, not **what**. Any non-obvious business rule gets a short comment.
* No magic numbers/strings: use `const`, enums, or constant classes (`Permissions`, `Roles`).
* Public members: XML doc comment when the intent is not obvious from the name.

### 8.2 C#

* `PascalCase` for types, methods, properties, constants; `camelCase` for parameters/locals;
  `_camelCase` for private fields. No abbreviations except well-known ones (`Id`, `Dto`, `Sql`).
* Async methods end with `Async`; async all the way (`async`/`await`), never `.Result`/`.Wait()`/`async void`.
* `var` only when the type is obvious from the right-hand side.
* Nullable reference types are enabled: `?` where null is possible; validate nulls at service boundaries.
* Prefer expression-bodied members for one-liners; prefer `switch` expressions over long `if/else` chains.
* `using` directives: `System.*` first, then others, alphabetical; remove unused usings.
* `sealed` on classes that are not designed for inheritance (most services and DTOs).
* C# collections: return `IReadOnlyList<T>`/`IEnumerable<T>` from services where mutation is not intended.
* No regions to hide long code — split the class instead.

### 8.3 TypeScript / Angular

* `PascalCase` for classes/components/interfaces, `camelCase` for members/variables,
  `kebab-case` for file names (Angular convention).
* Explicit return types on public methods and standalone functions.
* `const` by default; `let` only when reassigned; never `var`.
* Prefer `readonly`, `interface` for data shapes, `type` for unions/aliases.
* No `any` (use `unknown` + narrowing when necessary); no non-null assertion (`!`) to silence errors.
* Strict mode and `strictTemplates` are enabled — do not weaken compiler options to make code compile.
* Template syntax: use the new control flow (`@if`, `@for` with `track`) instead of `*ngIf`/`*ngFor`.

### 8.4 SQL

* Keywords uppercase, identifiers in the database's own PascalCase, one clause per line for non-trivial queries.
* Always specify the column list — `SELECT *` is forbidden (§33).
* Always pass parameters; never concatenate user input into SQL.

---

## 9. API Development Rules

### 9.1 REST conventions

| Concern | Convention |
|---|---|
| Base route | `api/v1/[controller]` → `GET /api/v1/products` |
| Resources | Plural nouns (`products`, `sales-orders`); lowercase in URLs |
| Sub-resources | `/api/v1/companies/{companyId}/branches` |
| Actions | Only when not expressible as a resource: `/api/v1/products/{id}/activate` (POST) |
| Versioning | URL segment `v1`; breaking change = `v2` + approval (§32) |

### 9.2 HTTP verb / status mapping

| Operation | Verb | Success |
|---|---|---|
| List (paged) | `GET /resource` | 200 + paged envelope |
| Get one | `GET /resource/{id}` | 200, else 404 |
| Create | `POST /resource` | 201 + `Location` header |
| Update | `PUT /resource/{id}` | 200 (or 204) |
| Partial update | `PATCH /resource/{id}` | 200 |
| Delete / deactivate | `DELETE /resource/{id}` | 204 |

Status codes: 400 validation · 401 not authenticated · 403 authenticated but not permitted ·
404 not found **or not in your company** · 409 business conflict/duplicate · 422 not used ·
500 unexpected. Never return 200 with `success: false`.

### 9.3 Controller responsibilities (strict)

* Receive the request, call **one** service method, return `ActionResult`.
* Maximum ~15 lines per action body; no `if` pyramids, no loops, no SQL, no mapping logic.
* `[ApiController]` + attribute routing; `[Authorize]` at controller level unless the endpoint is public.
* Always accept `CancellationToken` and pass it to the service.
* Never expose `Entities/` classes: accept request DTOs, return response DTOs.

```csharp
[ApiController]
[Route("api/v1/[controller]")]
[Authorize]
public sealed class ProductsController(IProductService products) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResult<ProductListItemDto>>>> GetPaged(
        [FromQuery] PagingRequest request, CancellationToken cancellationToken)
        => Ok(await products.GetPagedAsync(request, cancellationToken));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<ProductDto>>> GetById(int id, CancellationToken cancellationToken)
        => Ok(await products.GetByIdAsync(id, cancellationToken));
}
```

### 9.4 Service responsibilities

* Own all business rules, tenant scoping, validation that needs the database, transactions, and SQL calls.
* Return **DTOs or `ApiResponse<T>`**; throw domain exceptions (`NotFoundException`, `BusinessRuleException`)
  that the middleware maps to status codes — do not return `IActionResult`.
* Never call another controller; call another service or share code in a helper.
* One service per feature area; split when a service exceeds ~15 public methods.
* Accept and forward `CancellationToken` to every Dapper call.

### 9.5 DTO / model rules

* Request DTOs: only what the client is allowed to send (**never** `CompanyId`, `CreatedBy`, `IsActive`
  or similar server-owned fields).
* Response DTOs: only what the client needs; no password hashes, no audit internals beyond what is
  intentionally displayed.
* Separate read models from write models when their shapes genuinely differ.
* Validation attributes live on request DTOs (§15).

### 9.6 Data access rules (Dapper)

* `SqlConnectionFactory` creates connections from configuration; services never build connection strings.
* SQL text is a `const string` in `Data/Queries/<Feature>Queries.cs` (raw string literals welcome).
* Every query is parameterized and every query is `Async`.
* List endpoints must be paged (`OFFSET … FETCH NEXT`) and filtered server-side.
* Multi-statement operations that must be atomic use an explicit transaction (`BeginTransactionAsync`).
* Stored procedures are used for reports and heavy set-based work only (§11.6).
* No query inside a loop (N+1). Fetch the set once and join/filter in SQL or in memory.

### 9.7 Paging, filtering, sorting

| Parameter | Meaning |
|---|---|
| `page` | 1-based page number (default 1) |
| `pageSize` | Rows per page (default 20, max 200) |
| `search` | Optional free-text search |
| `sortBy` | Whitelisted column key (never raw SQL) |
| `sortDir` | `asc` / `desc` |
| Feature filters | e.g. `companyId`, `branchId`, `isActive` — validated against the caller's access |

`sortBy` values are mapped through a server-side whitelist — never interpolated into SQL directly.

### 9.8 Configuration & connection strings

* Configuration classes live in `Configuration/` and are bound with `IOptions<T>` in `Extensions/`.
* Connection strings come from configuration (`ConnectionStrings:Default`) and, in development, from
  `appsettings.Development.json` (git-ignored) or user secrets/environment variables.
* **Never** commit a connection string with a password (§17, §30).
* Fail fast on startup if required configuration is missing.

---

## 10. Angular Development Rules

### 10.1 General

* Standalone components only (Angular 19 default). No NgModules except when a library requires one.
* `inject()` in field initialisers for dependencies; constructor injection only where `inject()` is impossible.
* `ChangeDetectionStrategy.OnPush` on components (default for new pages/components).
* `provideRouter`, `provideHttpClient(withInterceptors([...]))` configured in `app.config.ts`.
* Typed reactive forms; no template-driven forms for business forms.
* `strict` TypeScript + `strictTemplates`; fix template type errors, never loosen the config.

### 10.2 File / symbol naming

| Item | Convention | Example |
|---|---|---|
| Component file | `<name>.component.ts` | `product-list.component.ts` |
| Component class | `<Name>Component` | `ProductListComponent` |
| Component selector | `app-<name>` | `app-product-list` |
| Service file/class | `<name>.service.ts` / `<Name>Service` | `product.service.ts` / `ProductService` |
| Guard | `<name>.guard.ts` → `authGuard` | `permission.guard.ts` |
| Interceptor | `<name>.interceptor.ts` → `authInterceptor` | `auth.interceptor.ts` |
| Model/interface | `<name>.model.ts` (plural file for a set) | `product.model.ts` |
| Feature routes | `<module>.routes.ts` | `products.routes.ts` |

### 10.3 Folder and import rules

* Follow §5 exactly; a component belongs where it is used, not where it "might" be used.
* Relative imports inside a feature; `shared`/`core` imports across features.
* No barrel files (`index.ts`) — they hide cycles and bloat bundles.
* No circular imports between `core`, `shared`, `layout` and `features`.

### 10.4 Routing

* `app.routes.ts` contains only: layout routes, public routes (login), lazy feature routes, wildcard.
* Every feature is lazy loaded: `loadChildren: () => import('./features/products/products.routes').then(m => m.PRODUCT_ROUTES)`
  or `loadComponent` for single pages.
* Route guards are UX only; the API re-checks everything (§12).
* Route data declares what the page needs (e.g. `data: { permission: 'Products.View' }`).
* Lazy loading of features is mandatory; eager loading requires a documented reason.

### 10.5 Guards, interceptors, tokens, API URLs

* Guards: `authGuard` (authenticated), `permissionGuard` (permission/role), dirty-form guard for
  unsaved-changes flows. Guards must be small and delegate to `AuthService`/`PermissionService`.
* Interceptors: `authInterceptor` (attach bearer token, handle 401 → logout redirect),
  `errorInterceptor` (map API errors to user messages via `NotificationService`),
  `loadingInterceptor` (global busy indicator).
* Token storage: in-memory session in `AuthService`; persistence in `localStorage`/`sessionStorage`
  only through `AuthService` (never accessed directly from components).
* API URLs: always `environment.apiBaseUrl` + endpoint constant; **never** hardcode a host in a service.

### 10.6 Forms, validation, error/loading states

* Reactive forms with typed `FormGroup`; validation rules on the form model, mirrored by server rules.
* Show validation messages per field through the shared form-field component.
* Every list page handles four states: loading, empty, error, data.
* Every submit button disables while the request is in flight; prevent double submits.
* Server validation errors are displayed next to the relevant field when the API returns field errors.

### 10.7 Permission-based UI

* Hiding/showing UI uses `PermissionService` (`*appHasPermission` directive or `can(permission)`).
* **UI permissions are cosmetic.** Every protected operation must also be protected on the API (§12).

---

## 11. Database Development Rules

### 11.1 Naming conventions

| Object | Convention | Example |
|---|---|---|
| Table | Singular `PascalCase` | `Product`, `SalesOrder`, `Company` |
| Column | `PascalCase` | `ProductCode`, `CreatedDate` |
| Primary key | `<Table>Id` | `ProductId` |
| Foreign key column | Same name as referenced PK | `CompanyId`, `BranchId` |
| Primary key constraint | `PK_<Table>` | `PK_Product` |
| Foreign key constraint | `FK_<Table>_<ReferencedTable>` | `FK_Product_Company` |
| Unique constraint | `UQ_<Table>_<Columns>` | `UQ_Product_CompanyId_Code` |
| Index | `IX_<Table>_<Columns>` | `IX_Product_CompanyId_Name` |
| Default constraint | `DF_<Table>_<Column>` | `DF_Product_IsActive` |
| Stored procedure | `usp_<Module>_<Action>` | `usp_Report_TrialBalance` |

### 11.2 Keys, constraints, indexes

* Every table has a single-column surrogate primary key (`int IDENTITY` unless there is a real reason).
* Foreign keys are always enforced by real `FOREIGN KEY` constraints — no "logical only" relationships.
* Unique constraints are enforced in the database (e.g. `UQ_Product_CompanyId_Code`), not just in code.
* Index every column used for filtering/joining: `CompanyId`, `BranchId`, foreign keys, status flags,
  document numbers, and date columns used by reports.
* Prefer covering indexes for the hottest list/report queries; avoid index spam (write cost).
* No unindexed queries in list endpoints.

### 11.3 Standard columns (audit)

Every business table contains:

| Column | Type | Notes |
|---|---|---|
| `CompanyId` | `int NOT NULL` | Tenant column — present on **every** company-scoped table |
| `BranchId` | `int NULL` | Required where the data is branch-scoped |
| `IsActive` | `bit NOT NULL DEFAULT 1` | Enable/disable without deleting |
| `CreatedBy` | `int NOT NULL` | User id of the creator (server-side) |
| `CreatedDate` | `datetime2(0) NOT NULL` | UTC |
| `UpdatedBy` | `int NULL` | User id of the last update |
| `UpdatedDate` | `datetime2(0) NULL` | UTC |
| `IsDeleted` | `bit NOT NULL DEFAULT 0` | Only where history must be preserved |

* Audit values are set **server-side** from the authenticated user — never accepted from the client.
* All dates/times are stored in **UTC**; conversion to local time happens in the UI only.

### 11.4 Soft delete / IsActive rules

* Master data (companies, users, products, chart of accounts, warehouses …) is **deactivated**
  (`IsActive = 0`), not physically deleted.
* `IsDeleted` (soft delete) is used only where the record must disappear from lists but be kept for
  history/reporting (e.g. posted documents that were voided).
* All list queries filter `IsDeleted = 0` (and optionally `IsActive = 1`) unless the screen
  intentionally shows inactive records.

### 11.5 Multi-company / multi-branch isolation

* `CompanyId` is mandatory on every company-scoped table; `BranchId` where branch-scoped.
* Every query filters by the **server-resolved** `CompanyId`/`BranchId` (§13).
* Composite unique constraints include `CompanyId` (the same code may exist in two companies).
* Reports/aggregations group and filter by `CompanyId` first.

### 11.6 Stored procedure rules

* Used for reports, bulk operations and heavy set-based work — not for simple CRUD.
* Naming `usp_<Module>_<Action>`; parameters prefixed `@`; no dynamic SQL unless unavoidable and then
  always parameterized (`sp_executesql`) — never string concatenation.
* Transaction boundaries are owned by the caller (service) unless the procedure is self-contained and documented.
* Source `.sql` files live in `Data/StoredProcedures/` and are committed (the database is not the source of truth).
* `SET NOCOUNT ON;` at the top; explicit column lists; no `SELECT *`.

### 11.7 Scripts, changes and transactions

* Schema changes are made through **ordered scripts** in `Data/Scripts/`:
  `01_Tables.sql`, `02_Indexes.sql`, `03_Constraints.sql`, `04_Seed.sql`, and later additive scripts
  (`05_Add_Product_Barcode.sql`, …) — never by ad-hoc manual changes only on a server.
* Every script is idempotent where practical (`IF NOT EXISTS (...)`) and reviewed like code.
* Seed data: system roles, permissions, default company/branch, admin user — no production data.
* Data-changing operations that touch more than one table run in a transaction (`BEGIN TRAN` in SQL,
  `BeginTransactionAsync` in Dapper) and roll back on failure.
* Deleting/changing a column that is still used requires approval and a migration path (no silent breaking changes).

### 11.8 Data types

| Data | Type |
|---|---|
| Money / rates | `decimal(18,4)`; quantities `decimal(18,3)` where needed |
| Dates/times | `datetime2(0)` UTC (never `datetime`) |
| Booleans | `bit NOT NULL` with default |
| Strings | `nvarchar(n)` — always sized; `nvarchar(max)` only for real free text (notes, descriptions) |
| Identifiers (user/business codes) | `nvarchar(30)`–`nvarchar(50)`; unique per company |
| Enumerations | `tinyint`/`smallint` mapped to C# enums via constants, values documented |
| Files | stored by path/reference, never as blobs in business tables |

### 11.9 Data validation at the database level

* `NOT NULL`, `UNIQUE`, `CHECK` and `FOREIGN KEY` constraints enforce what the business requires —
  the application validates too, but the database is the last line of defence.
* Amount/quantity `CHECK` constraints where negative values are invalid (unless negative values are
  genuinely meaningful, e.g. credit notes).

---

## 12. Authentication & Authorization Rules

### 12.1 Authentication

* JWT bearer tokens issued by the API (`/api/v1/auth/login`), validated with the shared signing key from configuration.
* Access token: short-lived (15–30 minutes). Refresh token: longer-lived, stored hashed server-side and revocable.
* Passwords hashed with a strong algorithm (ASP.NET Core Identity `PasswordHasher`/PBKDF2 or BCrypt) — never stored or logged.
* Login response contains user profile, company/branch context, roles and permissions — never the password hash or internal flags.
* Failed-login lockout after N attempts; login responses do not reveal whether the user name exists.

### 12.2 Claims carried by the token

| Claim | Meaning |
|---|---|
| `sub` / `userId` | Authenticated user |
| `companyId` | Company the session is scoped to |
| `branchId` | Branch scope (when applicable) |
| `role` | Role key(s) |
| `permission` | Granted permission keys (`Products.View`, `Products.Create`, …) |
| `name`, `email` | Display only |

### 12.3 Authorization

* Policies/attributes per endpoint: `[Authorize]` plus permission checks (`[HasPermission(Permissions.Products.View)]`).
* Roles group permissions; **permissions** are what endpoints check (a role can change without touching code).
* 401 = not authenticated (no/invalid token); 403 = authenticated but not permitted. Never leak which one
  the caller "almost" had.
* Users with `IsActive = 0` are rejected at every request (status check inside the auth pipeline), not only at login.
* Super-admin capabilities (cross-company) are explicit, named permissions — not "everyone in the Admin role can see all companies".

### 12.4 Explicit trust model

> **Never trust:** Angular UI permissions · hidden buttons · route guards alone · client-side company
> ID · client-side branch ID · client-side user ID.
>
> The API enforces authorization and tenant isolation **server-side**. Every protected request
> validates the authenticated user's **User, Company, Branch, Role, Permission, Status** — as
> applicable — using values resolved from the token/database, **never** from the request body, query
> string, or header.

---

## 13. Multi-Tenant / Company Isolation Rules

**Model (approved):** one database, `CompanyId` (+ `BranchId` where branch-scoped) columns.

1. `CompanyId` and `BranchId` are resolved on the server from the authenticated session.
2. Any `companyId`/`branchId` sent by the client is **ignored** unless it is validated against the
   user's allowed companies/branches — and even then it is only used to *narrow* the server scope.
3. Every SQL statement that reads or writes business data includes the tenant filter in the `WHERE`
   clause (and in `UPDATE`/`DELETE` statements, not just in a pre-check). Belt and braces: check + filter.
4. Every insert sets `CompanyId`/`BranchId` from the server session, never from the request body.
5. Users belong to one or more companies; a user may additionally be restricted to a subset of branches.
6. Cross-company access (super admin, consolidated reports) requires an explicit permission and must be
   visible in the query (e.g. an explicit `@CompanyId IS NULL` path for consolidated reports).
7. A record from another company must behave exactly like a non-existent record (404), never 403,
   to avoid leaking existence.
8. Company/branch isolation gets a test for every new module (list, get-by-id, update, delete).
9. Reports and exports are tenant-scoped by default; consolidated reports are a distinct, permission-gated screen.

---

## 14. Error Handling

* One `ExceptionHandlingMiddleware` converts every unhandled exception into the standard error
  envelope (§20) with the correct status code; controllers contain **no** `try/catch`.
* Domain exceptions in `Helpers`/`Services`:

| Exception | Status |
|---|---|
| `ValidationException` (field errors) | 400 |
| `NotFoundException` | 404 |
| `BusinessRuleException` | 409 (or 400 when it is not a conflict) |
| `ForbiddenException` | 403 |
| `UnauthorizedException` | 401 |
| anything else | 500 |

* SQL errors are mapped: unique-index violation → 409 with a readable message; FK violation → 400/409.
  Raw SQL error text is never returned to the client.
* In production, error responses contain a message + correlation id; **no stack traces, no SQL, no
  internal type names**.
* Never swallow exceptions silently; log with context before converting (§16).
* Frontend: `errorInterceptor` maps API errors to user-friendly notifications; unexpected errors show a
  generic message plus the correlation id for support.

---

## 15. Validation

* **Client validation is convenience only.** The API validates everything again.
* Request DTO validation uses `DataAnnotations` (`[Required]`, `[StringLength]`, `[Range]`,
  `[RegularExpression]`, custom attributes in `Helpers`).
* Service-level validation covers rules that need the database or multiple fields
  (uniqueness per company, date ranges, status transitions, closing balances, stock availability).
* `[ApiController]` automatic 400 responses are shaped into the standard envelope (a small
  `InvalidModelStateResponseFactory` in `Extensions/`) so the frontend gets one error format.
* Messages are written for end users ("Product code is already used in this company."), not for developers.
* Validation errors identify the field so the Angular form can display them inline.
* Never validate by throwing generic exceptions; return field-level errors.
* Numeric/date ranges are validated against the data type limits (`decimal(18,4)` etc.) to avoid SQL overflow.

---

## 16. Logging

* Use `ILogger<T>` with structured logging (message templates + named properties), never string concatenation.
* Log levels: `Trace` (never in committed code) · `Debug` (dev diagnosis) · `Information` (business
  milestones: login success, document posted, import finished) · `Warning` (validation failures,
  permission denials, retries) · `Error` (unhandled exceptions, failed integrations) · `Critical` (startup
  failure, DB unavailable).
* **Always log:** authentication failures, authorization failures, tenant/branch mismatch attempts,
  unhandled exceptions (with correlation id), long-running report executions, scheduled job results.
* **Never log:** passwords, password hashes, tokens (access/refresh/JWT), connection strings, full credit
  card/bank details, or complete personal data payloads.
* SQL parameters may be logged for diagnosis **only** when they contain no sensitive values.
* Every request gets a correlation id (generated or forwarded) that appears in logs and in error responses.
* No `Console.WriteLine` in committed code.

---

## 17. Security Rules

1. **Server-side authority.** UI permissions, hidden buttons and route guards are never security (§12.4).
2. **Tenant isolation is enforced in SQL** on read *and* write, using server-resolved values (§13).
3. **Parameterized SQL always.** No string concatenation/interpolation of user input into SQL — including
   `ORDER BY` and dynamic filters (whitelist mapping only).
4. **Secrets never in git.** JWT keys, connection-string passwords and API keys come from user secrets,
   environment variables or a secret store. `appsettings.Development.json`, `.env`, certificates and
   `*.pfx` are git-ignored.
5. **HTTPS only** in every non-local environment; HSTS enabled; no sensitive data in query strings.
6. **CORS is an explicit allow-list** of the frontend origins (no `AllowAnyOrigin` with credentials).
7. **Input limits.** Validate file type/size on upload; cap `pageSize`; reject oversized bodies; validate
   IDs belong to the current company before use.
8. **Rate limiting** on authentication endpoints (and exports) to slow brute-force/abuse.
9. **Least privilege.** The SQL login used by the API has only the rights it needs (no `sysadmin`).
10. **No sensitive data in the browser.** Tokens only through `AuthService`; no secrets in
    `environment*.ts` (it ships to clients).
11. **Errors do not leak internals** (§14); Swagger is enabled in Development only.
12. **Dependencies are kept patched**; adding a package requires approval (§32).
13. **Session invalidation** on password change/deactivate; refresh tokens are revocable server-side.

---

## 18. Reusable Code Rules

> **Reusable code means reducing duplicate code while keeping the implementation simple, readable and
> easy to maintain.**

Reuse is a means to fewer bugs, not a goal in itself. The project must **not** become complicated
merely to achieve reuse.

**Prefer:**

```text
simple reusable helper          →  Helpers/DateRangeHelper.cs
simple shared service           →  core/services/notification.service.ts
simple shared component         →  shared/components/data-table
simple common model             →  Models/Common/PagedResult<T>
```

**Avoid:**

```text
complex abstraction             →  IRepository<T> + BaseRepository<T> + UnitOfWork
generic framework               →  "engine" that dynamically builds every screen's CRUD
multiple unnecessary interfaces →  IProductService + IProductServiceFactory
deep inheritance                →  BaseEntityPage → BaseListPage → BaseCrudPage → ProductListPage
unnecessary design patterns     →  factories/builders/mediators with one implementation
```

**Practical rules**

1. Extract shared code on the **third** repetition, not the first (§28).
2. A shared piece must be genuinely general ("paged table", "date formatting"), not one screen's logic
   with flags.
3. Shared components stay dumb — no API calls, no business rules (§22).
4. When extending a shared piece risks breaking other consumers, add a well-named option instead of
   forking a copy.
5. New generic infrastructure requires approval (§32) and a sentence in this document explaining why.

---

## 19. Naming Conventions

### 19.1 C# / API

| Element | Convention | Example |
|---|---|---|
| Namespace | `ERPTemplate.API.<Folder>` | `ERPTemplate.API.Services` |
| Class / interface | PascalCase (`I` prefix for interfaces) | `ProductService`, `ICurrentUserService` |
| Method | PascalCase, verb-first, `Async` suffix | `GetPagedAsync`, `DeactivateAsync` |
| Property | PascalCase | `ProductCode` |
| Private field | `_camelCase` | `_connectionFactory` |
| Constant | PascalCase | `DefaultPageSize` |
| DTO | `<Feature><Purpose>Dto` | `ProductCreateDto`, `ProductListItemDto` |
| Request model | `<Feature><Action>Request` when not a DTO | `ProductSearchRequest` |
| Enum | PascalCase, singular | `DocumentStatus.Posted` |
| Route | `api/v1/<plural-resource>` | `api/v1/sales-orders` |

### 19.2 TypeScript / Angular

| Element | Convention | Example |
|---|---|---|
| File | kebab-case with type suffix | `product-list.component.ts` |
| Class | PascalCase + suffix | `ProductListComponent`, `ProductService` |
| Selector | `app-` prefix | `app-product-list` |
| Interface / model | PascalCase (no `I` prefix) | `Product`, `PagedResult<T>`, `ApiResponse<T>` |
| Method / property | camelCase | `loadProducts()`, `selectedProduct` |
| Signal | noun, `readonly` | `products = signal<Product[]>([])` |
| Constant | `UPPER_SNAKE_CASE` / camelCase object | `PERMISSIONS`, `API_ENDPOINTS` |
| CSS class | kebab-case, feature-prefixed when component-specific | `product-list__toolbar` |

### 19.3 Database

See §11.1 (tables, columns, keys, indexes, procedures).

### 19.4 Permissions

`<Module>.<Action>` — `Products.View`, `Products.Create`, `Products.Edit`, `Products.Delete`,
`Sales.Post`, `Reports.TrialBalance`. Permission keys are constants (`Permissions` class on the API,
`PERMISSIONS` object in `core/constants`) — never raw strings at call sites.

---

## 20. API Response Standards

**Every** endpoint returns the same envelope — success or failure.

```jsonc
// Single item / operation result
{
  "success": true,
  "data": { "id": 15, "code": "P-001", "name": "Widget" },
  "message": null,
  "errors": []
}

// Paged list
{
  "success": true,
  "data": {
    "items": [ { "id": 15, "code": "P-001" } ],
    "page": 1,
    "pageSize": 20,
    "totalCount": 137
  },
  "message": null,
  "errors": []
}

// Validation / business error
{
  "success": false,
  "data": null,
  "message": "Product code already exists.",
  "errors": [ "Code 'P-001' is already used in this company." ],
  "correlationId": "0HN5...:00000001"
}
```

Rules:

* `data` is `null` on failure; `errors` is empty on success; `message` is a user-readable sentence.
* Never return raw `Entities/` classes or database column names that are not part of the contract.
* Lists are always paged; "return everything" is forbidden.
* Field-level validation errors carry the field name so the UI can highlight it
  (`"errors": [{ "field": "code", "message": "..." }]` when field mapping is needed).
* The envelope type is `ApiResponse<T>` in `Models/Common`; the frontend mirrors it in `core/models`.
* HTTP status codes follow §9.2 — the envelope never contradicts the status code.

---

## 21. Angular HTTP/API Rules

1. One HTTP entry point style: feature services use `HttpClient` through `ApiService` (in `core/services`),
   which applies the base URL, and the interceptors apply token/errors/loading.
2. **Components never call `HttpClient` directly** — always through a service.
3. Every service method returns a typed `Observable<ApiResponse<T>>` (or the unwrapped `T` when the
   service unwraps `data` consistently — pick one and keep it per service).
4. Endpoint paths come from `core/constants` (`API_ENDPOINTS.products`) — no inline URL strings.
5. Loading/error handling is centralised in interceptors; feature code only reacts to business results.
6. Subscriptions in components use `takeUntilDestroyed()` (or `async` pipe) — no leaked subscriptions.
7. Never subscribe inside `subscribe` (no nested subscriptions) — use `switchMap`/`forkJoin`/`combineLatest`.
8. Cancel/ignore stale responses on filter and search screens (`switchMap` + debounce for search inputs).
9. Search/typing triggers HTTP only with debounce (≥300 ms).
10. Mutations (create/update/delete) refresh or update the local list explicitly; no full page reloads.
11. Errors from the API are shown through `NotificationService` (and inline for validation errors) —
    never `console.error` only.
12. Never send `CompanyId`/`BranchId`/`UserId` as an authority — the server decides (§13).

---

## 22. Component Rules

* One responsibility per component; if a component needs a "and" to describe it, split it.
* Target ≤ 200 lines of TypeScript and ≤ 150 lines of template; beyond that, extract child components.
* Two kinds of components:
  * **Page (smart)** — in `features/<module>/pages/`: talks to services, owns route state.
  * **Presentational (dumb)** — in `shared/` or feature `components/`: `input()`/`output()` only,
    no HTTP, no business rules.
* Inputs/outputs are typed signals (`input.required<T>()`, `output<T>()`); no `any`.
* `ChangeDetectionStrategy.OnPush`; use `@for` with `track`.
* No DOM manipulation (`document.querySelector`) — use template bindings or `viewChild()`.
* No business logic in templates (no calculations, no method calls in bindings).
* Loading, empty, error and success states are all handled (§25).
* Unsubscribe properly (§21.6); components must not keep long-lived subscriptions they do not manage.
* Delete unused components instead of leaving them orphaned.

---

## 23. Service Rules

* **Business logic lives in services**, not in components or controllers.
* One service = one responsibility (`ProductService`, `AuthService`, `PermissionService`).
* Registered as concrete types (`AddScoped<ProductService>()` in the API,
  `providedIn: 'root'` only for genuine singletons in Angular).
* **Interfaces are added only when genuinely needed:** a real second implementation, an external
  boundary (e-mail/SMS/payment/file storage, current-user accessor), or a testing seam that cannot be
  achieved otherwise. No `IXxxService` boilerplate per class, no service factories.
* Methods are small and named for what they do; no service with 20+ public methods — split by sub-area.
* Services do not call controllers or components; they may call other services or shared helpers.
* Tenant/permission context is passed explicitly (a `CurrentUser` object) or injected via
  `ICurrentUserService` — services must never read `HttpContext` directly, and they **never** trust a
  company/branch id supplied by the caller.
* Avoid stateful singletons that cache per-user data; scoped lifetimes only.
* Never duplicate an existing service under a new name (§28).

---

## 24. State Management Rules

* **Default:** component state with signals + feature services for data. No global store.
* Shared session state (current user, permissions, selected company/branch) lives in `core/services`
  as singleton services exposing signals — one obvious source.
* Pass data between parent/child with inputs/outputs; use route parameters/`resolve` for page data.
* Keep state local to the page that owns it; do not push page state into a global service.
* Caching: a feature service may cache lookups for the session; invalidation must be explicit
  (after a mutation that affects them).
* **Adding NgRx, Akita, Elf, or a signals store requires explicit approval** (§32) and a written
  justification (a concrete scale problem that signals + services cannot handle).

---

## 25. UI/UX Consistency Rules

* One design system: tokens in `src/styles/_variables.scss`, applied in `_theme.scss`; components use
  the tokens — never hardcoded colors, spacing or font sizes.
* Reuse the shared building blocks instead of re-styling per page: table, pager, page header, form field,
  buttons, dialogs, toasts, empty state, loading spinner.
* **Standard list-page layout** (all modules): page header (title + primary action) → filter bar →
  data table (sortable, paged) → row actions → empty/loading/error states.
* **Standard form layout:** grouped sections, labels above fields, required markers, inline validation
  messages, save/cancel in a fixed footer.
* Consistent feedback: success toast, error toast, confirmation dialog for destructive actions.
* Every action that takes time shows progress and blocks double submission.
* Tables show a "no records found" state (not an empty grid) and a translated paging summary.
* Keyboard support: forms submittable with Enter, dialogs closable with Esc, focus visible.
* Responsive: layouts must work from 1280px down to 360px; tables scroll horizontally rather than break.
* Confirmation before deleting/deactivating; explicit undo is not required.
* Dates and numbers are formatted through shared pipes (`date`, `money`) — never ad-hoc formatting in templates.

---

## 26. Performance Rules

### API / SQL

* All data access is async; never `.Result`/`.Wait()`.
* Lists are paged and filtered server-side; never return an unbounded result set.
* No query inside a loop; batch with `IN`/table-valued parameters or a single join.
* Index the columns you filter, join and sort by (§11.2); check the execution plan for slow reports.
* Keep result sets small: select only needed columns (no `SELECT *`).
* Reports/aggregations are the only place for stored procedures and must use set-based SQL.
* Set a sane `CommandTimeout` (default 30s; explicit longer value only for reports).
* Avoid chatty APIs: return the data a screen needs in one call where practical.

### Angular

* Lazy load every feature route; keep the initial bundle small.
* `OnPush` everywhere; `track` in every `@for`.
* Avoid heavy work in getters/template bindings; compute once in signals or on data load.
* Debounce search inputs; cancel stale requests.
* Virtualise/limit rows for large tables (paging first; virtual scroll only with a real need).
* Respect the build budgets in `angular.json`; investigate warnings instead of raising budgets.

---

## 27. File Creation Rules

Before creating any file:

1. Search the project for existing implementations of the same thing (§28).
2. Confirm the correct folder from §4/§5 — never invent a folder.
3. Confirm the name follows §19.
4. Confirm the file is genuinely new (no `*2`, `*New`, `*V2`, `*Temp` files).
5. One type/component per file; file name = type name (Angular: kebab-case + suffix).

Additional rules

* No new root-level files/folders without approval; no placeholder folders without `.gitkeep`.
* Do not commit generated output (`bin`, `obj`, `dist`, `.angular`, coverage).
* Removing replaced code is part of the change — leave no dead files behind; use `git rm`, not "keep for reference".
* A migration/DDL script is a new numbered file (never edit executed scripts in place) — new script,
  same effect, applied in order.
* Every file starts without a BOM, with UTF-8 encoding and a final newline (`.editorconfig`).

---

## 28. Duplicate Code Prevention

**Before creating anything new:**

1. Search the existing project (API: `Services`, `Helpers`, `Data/Queries`; Angular: `shared`, `core`, other features).
2. Check whether the functionality already exists.
3. Reuse the existing implementation if appropriate.
4. Extend the existing implementation if appropriate.
5. Only then create new code.

**Never create:**

```text
UserService2 · UserServiceNew · CommonHelper2 · AuthServiceNew · SharedComponent2
```

just because the existing implementation needs improvement.

Rules

* If the existing implementation has a problem: **fix it in place**, or extend it with a clearly named
  option. Do not fork it.
* Extract shared code on the third repetition (rule of three); write it a second time only when the
  duplication is trivial and local.
* Duplicated SQL is a defect: put it in `Data/Queries` and share it.
* Duplicated validation is a defect: put it in a DTO attribute or a shared validator.
* Duplicated table/form markup is a defect: use/extend the shared component.
* Never copy a feature to bootstrap a new module; create the new module's folders and follow §5.

---

## 29. Testing Rules

* Test business rules, validation, tenant isolation and calculations — not framework plumbing.
* Backend: **xUnit**. Naming `Method_Scenario_ExpectedResult`, e.g. `GetPagedAsync_OtherCompany_ReturnsEmpty`.
* Backend test project: `API/ERPTemplate.API.Tests/` (reserved slot, added to the solution with the
  first test). Integration tests use `WebApplicationFactory` against a disposable test database seeded
  from `Data/Scripts/`.
* Frontend: Karma + Jasmine (existing scaffold) with `*.spec.ts` next to the source file.
* Cover for every module: create/update/delete happy path, validation failure, permission denial,
  cross-company access attempt (must be 404/empty), pagination boundary.
* No test may depend on production data or a shared developer database; tests create and clean their own data.
* Fix or remove failing tests before merging — do not skip/ignore permanently.
* Test data builders/helpers belong to the test project, not to `Services/`.
* Coverage is not a target; meaningful assertions are.

---

## 30. Git Rules

* **Meaningful commits** describing the *why*: `feat(products): add product list endpoint with paging`.
  Conventional prefixes: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`, `perf`.
* One logical change per commit; feature-based commits where practical; no "misc changes" commits.
* Work on feature branches; never commit directly to `main`; open a pull request; keep the branch
  up to date with `main` (rebase/merge per team convention).
* **Never commit:** secrets, JWT keys, connection strings with passwords, `appsettings.Development.json`,
  `.env` files, certificates (`*.pfx`, `*.p12`), production data dumps.
* **Never commit:** `node_modules/`, `bin/`, `obj/`, `dist/`, `.angular/`, coverage output, IDE temp
  files (`*.user`, `.vs/`, `.idea/`) — `.gitignore` covers these; fix it if something slips through.
* Never force-push a shared branch; never rewrite published history.
* DDL/seed scripts are committed with the code that needs them (schema and code move together).
* Documentation (`DEVELOPMENT-GUIDELINES.md`, `docs/`) is updated in the same pull request as the code.
* If a secret is committed by accident: rotate it immediately, then clean the history — do not "just delete the line".
* Commit messages for structure/architecture changes must state that the structure is changing and why
  (and reference the approval).

---

## 31. Documentation Rules

* `DEVELOPMENT-GUIDELINES.md` (this file) is the source of truth for architecture and rules.
* **Every major architectural decision is documented here** — decisions must not live only in chat
  history or in someone's memory.
* When a new rule is established during development, update this file in the same change.
* The documents must always reflect the **current approved architecture** — outdated sections are
  corrected, not left behind.
* `docs/` holds supporting detail: schema notes/ERD, API endpoint catalogue, module documentation,
  operational notes. New supporting documents require no approval; new folders in `docs/` are fine
  as long as they contain documentation only.
* `README.md` stays runnable and accurate (prerequisites, run commands, links).
* Code comments explain *why*; they never duplicate what the code says.
* Public API endpoints are documented for Swagger (summary, request/response types, possible status codes).
* SQL scripts carry a one-line header comment: purpose + date + author initials when useful.
* Any decision recorded in Appendix B gets a date and a short reason.

---

## 32. Change Approval Rules

### Requires explicit approval (STOP, explain, wait)

* Adding/renaming/moving/deleting folders of the locked structure (§3/§4/§5).
* Adding a .NET project, Angular workspace or library.
* Adding a runtime dependency (NuGet/npm) or framework (ORM, state management, UI kit, mapping/validation library).
* Introducing a second pattern for the same concern (repository layer, CQRS/MediatR, second HTTP base service, second layout).
* Changing the API response envelope, error format, status-code mapping, auth flow, or tenant model.
* Breaking existing API contracts or DB column/table semantics.
* Adding cross-company/consolidated access paths.
* Replacing an existing approved implementation with a different approach.

### Does not require approval (follow the approved patterns)

* Adding a feature module/page following §5 and §27.
* Adding DTOs, services, queries, validators, or shared components that follow existing patterns.
* Bug fixes, refactoring inside the same folder, tests, documentation updates.
* Adding a new numbered SQL script that is additive and non-breaking.

### Approval process

```text
APPROVED STRUCTURE (locked)
        ↓
Development continues
        ↓
Structural / architectural change needed
        ↓
STOP → explain the reason and the impact → request approval
        ↓
       Approved? ── YES ──> apply change → update DEVELOPMENT-GUIDELINES.md → LOCK again
             └──────── NO ──> keep the existing structure
```

Approval must be **explicit** ("APPROVED", a signed decision in the issue tracker, or a merged PR that
contains the guideline update). Silence, a "maybe", or a previous unrelated approval is not approval.

---

## 33. Forbidden Patterns

**Architecture**

* Repository / `GenericRepository` / UnitOfWork layers over Dapper. ❌
* CQRS / MediatR / event buses / message brokers without approval. ❌
* EF Core, DbContext, migrations (the approved data path is Dapper + SQL scripts). ❌
* Interfaces created only for symmetry (`IXxxService` with one implementation). ❌
* Base classes that exist "to be inherited". Deep inheritance hierarchies. ❌
* Empty placeholder layers/projects ("for later"). ❌

**Code**

* `SELECT *`, string-concatenated SQL, interpolated SQL, dynamic `ORDER BY` from user input. ❌
* Business logic in controllers or Angular components. ❌
* `try/catch` in every controller/action; swallowing exceptions; logging and rethrowing the same error twice. ❌
* `async void`, `.Result`, `.Wait()`, `Thread.Sleep`. ❌
* Magic strings/numbers at call sites (write them as constants). ❌
* `any`, non-null assertion `!` to silence errors, `// @ts-ignore`. ❌
* Commented-out code, dead files, `*2`/`*New`/`*Temp` duplicates. ❌
* Trusting client-provided `companyId`/`branchId`/`userId`, UI permissions, hidden buttons or route guards. ❌
* Committing secrets, connection-string passwords, tokens, production data, `bin`/`obj`/`dist`/`node_modules`. ❌
* Editing an already-applied SQL script instead of adding a new numbered one. ❌
* Introducing a second way to do something that already has an approved way. ❌

**Behaviour**

* Silently moving/renaming folders or introducing a new architecture. ❌
* "Optimising" the architecture without an accepted need. ❌
* Copying an existing module to bootstrap a new one. ❌
* Leaving the guidelines out of date after a decision. ❌

---

## 34. Final Development Checklist

Copy this checklist into the pull request / task and tick every line before requesting review.

**Discovery**

- [ ] Searched the project for an existing implementation and reused/extended it (§28)
- [ ] Confirmed the correct folders from §4/§5 — no new folders, no second pattern
- [ ] Confirmed no approval is required for this change (§32)

**API**

- [ ] Controller action is thin; all logic is in a service (§9.3) — no SQL, no business rules in the controller
- [ ] Request DTO contains no server-owned fields (`CompanyId`, `BranchId`, `CreatedBy`, `IsActive`)
- [ ] DTO validation attributes added; service-level rules implemented (§15)
- [ ] `CompanyId`/`BranchId` resolved server-side and applied to **every** read **and** write (§13)
- [ ] Permissions checked on the endpoint; active-user status enforced (§12)
- [ ] SQL is parameterized, in `Data/Queries` (or `usp_` for reports), async, paged, no N+1 (§9.6)
- [ ] Response uses the standard envelope and the correct status code (§20)
- [ ] Errors flow through the middleware; no controller `try/catch`; no internal details leaked (§14)
- [ ] Logging added where required; no sensitive data logged (§16)
- [ ] CancellationToken accepted and forwarded

**Database**

- [ ] New tables/columns follow §11 naming, PK/FK, index, audit-column, and data-type rules
- [ ] Tenant columns present (`CompanyId`, `BranchId` where applicable)
- [ ] Change delivered as a new numbered script in `Data/Scripts/` (never edited in place)
- [ ] Unique/FK/CHECK constraints added where the business requires them
- [ ] Multi-table changes wrapped in a transaction

**Angular**

- [ ] Feature folder follows the single pattern in §5 (`pages`, `components`, `models`, `services`, routes)
- [ ] Route is lazy loaded; guard/permission data declared where needed (§10.4)
- [ ] HTTP calls only through services using `ApiService` + endpoint constants (§21)
- [ ] Typed reactive form with validation; server validation errors displayed inline (§10.6)
- [ ] Loading, empty, error and success states handled; no double submit (§25)
- [ ] Shared components/table/pipes reused instead of new copies (§18, §28)
- [ ] `OnPush`, `track` in loops, unsubscribe via `takeUntilDestroyed`/`async` pipe (§22)
- [ ] Permissions used for UI only; nothing security-critical relies on the client (§12.4)

**Tests & docs**

- [ ] Tests added for business rules, validation, permission denial, cross-company access (§29)
- [ ] Existing tests still pass
- [ ] Swagger/XML comments updated for new endpoints
- [ ] `DEVELOPMENT-GUIDELINES.md` (and `docs/`) updated if anything architectural changed (§31)

**Git**

- [ ] Meaningful commit message; no secrets; no generated output committed (§30)
- [ ] Structure unchanged, or the change was explicitly approved and documented

---

## Appendix A — Behaviour rules for contributors and AI agents

1. **Do not restructure** the project because another pattern "looks cleaner".
2. **Do not introduce complexity** for hypothetical future requirements.
3. Build the smallest structure that properly supports the current ERP.
4. **Never make architectural changes silently** — moving folders, renaming roots, redrawing project
   boundaries, adding frameworks/libraries/ORMs, or changing API patterns all require explicit approval.
5. When in doubt: **reuse or extend** existing code, and follow the closest existing example.
6. Do the simplest thing that satisfies the requirement and this document.
7. Future expansion must remain possible **without** paying for unnecessary architecture today.
8. Keep this document current — if a rule changes, the file changes in the same work item.
9. Prefer deleting duplicated code over adding a new abstraction layer.
10. If a request contradicts these guidelines, **stop and ask** instead of silently violating or
    silently "improving" them.

---

## Appendix B — Decision log

| Date | Decision | Reason |
|---|---|---|
| 2026-09-15 | Two applications at root: `API/` and `Frontend/`; Angular workspace nested as `Frontend/ERPTemplate` | Matches the approved target layout; keeps one workspace per app |
| 2026-09-15 | **Single** API project `API/ERPTemplate.API/` (no Core/Infrastructure split) | No over-engineering; one deployable, one team; revisit only with a real second consumer |
| 2026-09-15 | **Dapper + SQL Server** as the data access approach (no EF Core, no migrations) | Explicit owner choice; full SQL control with a thin mapping layer |
| 2026-09-15 | **Single database** with `CompanyId` / `BranchId` columns | Simplest operationally, database-level constraints and cross-company reporting stay possible |
| 2026-09-15 | **Concrete service classes**; interfaces only where genuinely needed | Avoids `IXxxService` boilerplate; matches "no excessive interfaces" |
| 2026-09-15 | Angular: `core` / `shared` / `layout` / `features`, one feature pattern, lazy loaded | Predictable placement of every new file; no per-component folder sprawl |
| 2026-09-15 | API responses use a single `ApiResponse<T>` envelope with `PagedResult<T>` for lists | One contract the frontend can handle generically |
| 2026-09-15 | Global SCSS in `src/styles/` (tokens + theme), SCSS for component styles | Consistent visual system; overridable design tokens |
| 2026-09-15 | Root `.editorconfig` and a single root `.gitignore` | One formatting/ignore baseline for both applications |
| 2026-09-15 | Structure **LOCKED** (this document, §3–§6) | Prevent silent architecture drift; changes need approval and a guideline update |

---

**End of guidelines.** If something here blocks you, the answer is usually: *reuse what exists, keep it
simple, and ask before changing the structure.*
