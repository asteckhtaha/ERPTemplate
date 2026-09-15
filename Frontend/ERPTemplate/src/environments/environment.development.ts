/**
 * Local development environment (used by `ng serve` / `ng build --configuration development`).
 * Must match the API launch profile in API/ERPTemplate.API/Properties/launchSettings.json
 * (or the URL of the Angular dev-server proxy).
 */
export const environment = {
  production: false,
  /** Local ASP.NET Core API (https profile). */
  apiBaseUrl: 'https://localhost:7258/api/v1'
};
