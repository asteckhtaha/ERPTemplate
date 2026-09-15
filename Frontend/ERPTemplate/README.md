# ERPTemplate — Angular frontend

Angular 19 (standalone components) workspace for the ERPTemplate ERP.

For project-wide rules and the locked folder structure read
[../../DEVELOPMENT-GUIDELINES.md](../../DEVELOPMENT-GUIDELINES.md) first.

## Commands

```bash
npm install            # install dependencies
npm start              # ng serve        -> http://localhost:4200
npm run build          # production build -> dist/erptemplate
npm run watch          # development build with watch
npm test               # unit tests (Karma + Jasmine)
```

## Layout (locked)

```text
src/
├── app/
│   ├── core/          # app-wide singletons: guards, interceptors, models, services, constants
│   ├── shared/        # reusable UI + utilities (no business logic, no API calls)
│   ├── layout/        # application shell: main-layout, sidebar, header, error pages
│   ├── features/      # ERP modules, lazy loaded, one folder per module
│   ├── app.component.*
│   ├── app.config.ts
│   └── app.routes.ts
├── environments/      # environment.ts (+ .development / .production replacements)
├── styles/            # global SCSS: _variables, _theme, _mixins, styles.scss
├── index.html
└── main.ts
```

Every feature folder follows one shape only:

```text
features/<module>/
├── pages/        # route targets (list, form, details)
├── components/   # components private to this feature
├── models/       # feature DTO/model interfaces
├── services/     # feature API service (only place calling the module endpoints)
└── <module>.routes.ts
```

## Environment configuration

`src/environments/environment.ts` is the default; Angular CLI swaps it per build configuration
(`environment.development.ts` for `ng serve`, `environment.production.ts` for `ng build`).
Set `apiBaseUrl` there — never hardcode URLs in services.
