using System.Globalization;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace ERPTemplate.API.Helpers
{
    /// <summary>
    /// Small technical security utilities for the current request: authentication state, safe claim
    /// reading, request metadata used by the log helpers, and the hashing/token primitives required by the
    /// approved <c>UserSessions</c> design.
    /// <para>
    /// This is not an authentication or authorization system: it performs no permission calculation,
    /// queries no database and applies no business rules. It only reads what the authenticated request
    /// already contains.
    /// </para>
    /// <para>
    /// Concurrency: the instance holds only the injected <see cref="IHttpContextAccessor"/>; every value is
    /// read from the current request's context, so nothing leaks between concurrent requests.
    /// </para>
    /// </summary>
    public sealed class SecurityHelper
    {
        /// <summary>
        /// Request-item key for the correlation id. A future logging/middleware component can reuse this
        /// key so that logs and error responses share the same id.
        /// </summary>
        public const string CorrelationIdItemKey = "ERPTemplate.CorrelationId";

        private const int MaxIpAddressLength = 45;
        private const int DefaultSecureTokenBytes = 32;

        private readonly IHttpContextAccessor _httpContextAccessor;

        public SecurityHelper(IHttpContextAccessor httpContextAccessor)
        {
            _httpContextAccessor = httpContextAccessor
                ?? throw new ArgumentNullException(nameof(httpContextAccessor));
        }

        /// <summary>The current HTTP context, or <c>null</c> outside a request scope.</summary>
        public HttpContext? HttpContext => _httpContextAccessor.HttpContext;

        /// <summary>True when the current request carries a valid authenticated principal.</summary>
        public bool IsAuthenticated => HttpContext?.User.Identity?.IsAuthenticated == true;

        // ---------------------------------------------------------------------------------------------
        // Claims
        // ---------------------------------------------------------------------------------------------

        /// <summary>Reads a claim from the current authenticated request, or <c>null</c> when absent.</summary>
        public string? GetClaimValue(string claimType) => GetClaimValue(HttpContext?.User, claimType);

        /// <summary>Reads an integer claim from the current authenticated request, or <c>null</c> when absent/unparsable.</summary>
        public int? GetInt32ClaimValue(string claimType) => GetInt32ClaimValue(HttpContext?.User, claimType);

        /// <summary>Reads a claim value from the supplied principal, or <c>null</c> when absent.</summary>
        public static string? GetClaimValue(ClaimsPrincipal? principal, string claimType)
        {
            if (principal?.Identity?.IsAuthenticated != true || string.IsNullOrWhiteSpace(claimType))
            {
                return null;
            }

            var value = principal.FindFirst(claimType)?.Value;
            return string.IsNullOrWhiteSpace(value) ? null : value;
        }

        /// <summary>
        /// Reads an integer claim from the supplied principal.
        /// Returns <c>null</c> for missing or malformed values instead of throwing, so a damaged token is
        /// treated as "no value" and the request is handled as unauthenticated by the calling code.
        /// </summary>
        public static int? GetInt32ClaimValue(ClaimsPrincipal? principal, string claimType)
        {
            var value = GetClaimValue(principal, claimType);
            return int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed)
                ? parsed
                : null;
        }

        // ---------------------------------------------------------------------------------------------
        // Request metadata (used for audit/activity/error log records)
        // ---------------------------------------------------------------------------------------------

        /// <summary>Client IP address (IPv4-mapped IPv6 addresses are normalised to IPv4), or <c>null</c>.</summary>
        public string? GetClientIpAddress()
        {
            var address = HttpContext?.Connection.RemoteIpAddress;
            if (address is null)
            {
                return null;
            }

            if (address.IsIPv4MappedToIPv6)
            {
                address = address.MapToIPv4();
            }

            return TrimToLength(address.ToString(), MaxIpAddressLength);
        }

        /// <summary>User-Agent header trimmed to the <c>ActivityLogs/AuditLogs.UserAgent</c> column length.</summary>
        public string? GetUserAgent() =>
            TrimToLength(HttpContext?.Request.Headers.UserAgent.ToString(), 1000);

        /// <summary>Request path + query string trimmed to the log tables' <c>RequestURL</c> column length.</summary>
        public string? GetRequestUrl()
        {
            var request = HttpContext?.Request;
            return request is null ? null : TrimToLength($"{request.Path}{request.QueryString}", 1000);
        }

        /// <summary>HTTP method of the current request, or <c>null</c>.</summary>
        public string? GetRequestMethod() => TrimToLength(HttpContext?.Request.Method, 20);

        /// <summary>
        /// Returns the correlation id of the current request, creating and storing it in
        /// <c>HttpContext.Items</c> on first use. Stored per request (never static), so concurrent requests
        /// keep separate ids. Outside a request a new id is returned without being stored.
        /// </summary>
        public Guid GetOrCreateCorrelationId()
        {
            var context = HttpContext;
            if (context is null)
            {
                return Guid.NewGuid();
            }

            if (context.Items[CorrelationIdItemKey] is Guid existing)
            {
                return existing;
            }

            var correlationId = Guid.NewGuid();
            context.Items[CorrelationIdItemKey] = correlationId;
            return correlationId;
        }

        // ---------------------------------------------------------------------------------------------
        // Safe value handling and session-key primitives
        // ---------------------------------------------------------------------------------------------

        /// <summary>
        /// Trims a value to the maximum length of its target database column, so an oversized
        /// request-derived value cannot fail an insert with a truncation error.
        /// </summary>
        public static string? TrimToLength(string? value, int maxLength)
        {
            if (string.IsNullOrEmpty(value) || maxLength <= 0 || value.Length <= maxLength)
            {
                return string.IsNullOrEmpty(value) ? null : value;
            }

            return value[..maxLength];
        }

        /// <summary>
        /// SHA-256 hash of a UTF-8 string (32 bytes). Used for session keys so that
        /// <c>UserSessions.SessionKeyHash</c> (<c>VARBINARY(64)</c>) never stores the raw key.
        /// </summary>
        public static byte[] ComputeSha256Hash(string value)
        {
            ArgumentException.ThrowIfNullOrWhiteSpace(value);
            return SHA256.HashData(Encoding.UTF8.GetBytes(value));
        }

        /// <summary>
        /// Creates a cryptographically secure random token (URL-safe Base64) for session/refresh keys.
        /// </summary>
        public static string CreateSecureToken(int byteLength = DefaultSecureTokenBytes)
        {
            if (byteLength < 16)
            {
                throw new ArgumentOutOfRangeException(nameof(byteLength), byteLength, "At least 16 random bytes are required.");
            }

            return Convert.ToBase64String(RandomNumberGenerator.GetBytes(byteLength))
                .Replace('+', '-')
                .Replace('/', '_')
                .TrimEnd('=');
        }

        /// <summary>
        /// Claim names written by <see cref="TokenHelper"/> and read by this helper /
        /// <see cref="TenantHelper"/>. Keep both sides on these constants — never inline claim strings.
        /// </summary>
        public static class AppClaims
        {
            public const string UserId = "user_id";
            public const string UserName = "user_name";
            public const string CompanyId = "company_id";
            public const string BranchId = "branch_id";
            public const string RoleId = "role_id";
            public const string UserTypeId = "user_type_id";
        }
    }
}
