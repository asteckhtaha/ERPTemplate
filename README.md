# ERPTemplate

Multi-company ERP template — ASP.NET Core 8 Web API + Angular 19 + SQL Server.

> **Architecture status: LOCKED.**
> The folder structure below is approved and locked. Structural changes require explicit
> approval and must be reflected in [DEVELOPMENT-GUIDELINES.md](DEVELOPMENT-GUIDELINES.md).
> Read that file before writing any code.

## Repository layout

```text
ERPTemplate/
├── API/                        # .NET backend (solution + single API project)
│   ├── ERPTemplate.sln
│   └── ERPTemplate.API/        # ASP.NET Core 8 Web API
├── Frontend/
│   └── ERPTemplate/            # Angular 19 workspace
├── docs/                       # supporting documentation
├── DEVELOPMENT-GUIDELINES.md   # the development contract (read first)
├── README.md
├── .editorconfig
└── .gitignore
```

## Prerequisites

| Tool | Version |
|---|---|
| .NET SDK | 8.0 |
| Node.js | 20 LTS or 22 LTS (v22 recommended) |
| Angular CLI | 19.x (`npm i -g @angular/cli@19`) |
| SQL Server | 2019 or later (Developer/Express for local work) |
| IDE | Visual Studio 2022 or VS Code |

## Run the API

```bash
cd API/ERPTemplate.API
dotnet restore
dotnet run
```

* HTTP: `http://localhost:5105` · HTTPS: `https://localhost:7258`
* Swagger UI (Development only): `https://localhost:7258/swagger`

Local overrides (connection strings, JWT keys) belong in `appsettings.Development.json`,
which is **git-ignored** — create it locally when needed and never commit secrets.

## Run the frontend

```bash
cd Frontend/ERPTemplate
npm install
npm start          # ng serve  -> http://localhost:4200
npm run build      # production build
npm test           # unit tests (Karma/Jasmine)
```

The API base URL per environment lives in `src/environments/environment*.ts`.
The dev default is `https://localhost:7258/api/v1`.

## Status of this repository

Established in this step (structure only — no business features yet):

* approved and locked **API** and **Angular** folder structures,
* root `README.md`, `.gitignore`, `.editorconfig`,
* `DEVELOPMENT-GUIDELINES.md` (the project contract).

Not implemented yet: authentication, database schema/scripts, CRUD, dashboard, any ERP module.
Those come next, one feature at a time, following the guidelines.

## Documentation

| Document | Purpose |
|---|---|
| [DEVELOPMENT-GUIDELINES.md](DEVELOPMENT-GUIDELINES.md) | Primary development contract: structure, lock rules, coding/API/Angular/DB/security standards. |
| [docs/PROPOSED-STRUCTURE.md](docs/PROPOSED-STRUCTURE.md) | The approved structure proposal and the decisions recorded during approval. |
