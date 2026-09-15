using System.Security.Claims;
using Microsoft.AspNetCore.Http;

namespace ERPTemplate.API.Helpers;

/// <summary>
/// Small technical security utility that reads from the authenticated request.
/// Does not perform authorization decisions.
/// </summary>
public sealed class SecurityHelper
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public SecurityHelper(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor ?? throw new ArgumentNullException(nameof(httpContextAccessor));
    }

    public ClaimsPrincipal? Principal => _httpContextAccessor.HttpContext?.User;

    public bool IsAuthenticated => Principal?.Identity?.IsAuthenticated ?? false;

    public int? UserId
        => GetIntClaim("UserID")
           ?? GetIntClaim(ClaimTypes.NameIdentifier)
           ?? GetIntClaim("sub");

    public string? UserName
        => Principal?.Identity?.Name
           ?? GetStringClaim(ClaimTypes.Name)
           ?? GetStringClaim("unique_name");

    public string? GetStringClaim(string claimType)
    {
        if (string.IsNullOrWhiteSpace(claimType))
        {
            return null;
        }

        return Principal?.FindFirst(claimType)?.Value;
    }

    public int? GetIntClaim(string claimType)
    {
        var raw = GetStringClaim(claimType);
        return int.TryParse(raw, out var value) ? value : null;
    }

    public string? ClientIpAddress
    {
        get
        {
            var context = _httpContextAccessor.HttpContext;
            if (context is null)
            {
                return null;
            }

            var forwarded = context.Request.Headers["X-Forwarded-For"].ToString();
            if (!string.IsNullOrWhiteSpace(forwarded))
            {
                var first = forwarded.Split(',', 2)[0].Trim();
                if (!string.IsNullOrWhiteSpace(first))
                {
                    return first;
                }
            }

            return context.Connection.RemoteIpAddress?.ToString();
        }
    }

    public string? UserAgent
    {
        get
        {
            var value = _httpContextAccessor.HttpContext?.Request.Headers.UserAgent.ToString();
            return string.IsNullOrWhiteSpace(value) ? null : Truncate(value, 1000);
        }
    }

    public string? RequestUrl
    {
        get
        {
            var request = _httpContextAccessor.HttpContext?.Request;
            if (request is null)
            {
                return null;
            }

            var url = $"{request.Scheme}://{request.Host}{request.Path}{request.QueryString}";
            return Truncate(url, 1000);
        }
    }

    public string? RequestMethod
        => _httpContextAccessor.HttpContext?.Request.Method;

    private static string Truncate(string value, int maxLength)
        => value.Length <= maxLength ? value : value[..maxLength];
}
