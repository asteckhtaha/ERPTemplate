/**
 * Default environment (used by production builds unless replaced).
 * Angular CLI replaces this file at build time:
 *   - `development` configuration -> environment.development.ts
 *   - `production`  configuration -> environment.production.ts
 *
 * Never put secrets in these files: everything here is shipped to the browser.
 */
export const environment = {
  production: true,
  /** Base URL of the ERPTemplate API. Relative URL = same origin (recommended behind a reverse proxy). */
  apiBaseUrl: '/api/v1'
};
