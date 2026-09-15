/**
 * Production environment.
 * The API is expected to be served behind the same host/reverse proxy, therefore the
 * relative base URL is preferred. Change only with team agreement (see DEVELOPMENT-GUIDELINES.md).
 */
export const environment = {
  production: true,
  apiBaseUrl: '/api/v1'
};
