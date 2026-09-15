using ERPTemplate.API.Controllers;
using ERPTemplate.API.Helpers;
using ERPTemplate.API.Services;
using ERPTemplate.API.Services.System;

namespace ERPTemplate.API.Extensions
{
    public static class ServiceExtensions
    {
        public static IServiceCollection AddApplicationServices(
            this IServiceCollection services)
        {
            // HTTP Context
            services.AddHttpContextAccessor();

            // Helpers
            services.AddScoped<DbHelper>();
            services.AddScoped<SecurityHelper>();
            services.AddScoped<TenantHelper>();
            services.AddScoped<PermissionHelper>();
            services.AddScoped<AuditHelper>();
            services.AddScoped<ActivityLogHelper>();
            services.AddScoped<ErrorLogHelper>();

            // Services
            services.AddScoped<NavigationService>();

            return services;
        }
    }
}
