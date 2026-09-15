using System.Globalization;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace ERPTemplate.API.Helpers
{
    /// <summary>
    /// JWT access-token creation only.
    /// Signing key, issuer, audience and lifetime come from configuration (<c>Jwt</c> section) — nothing
    /// is hardcoded and no secret is stored in this class.
    /// <para>
    /// It creates the token; it never decides whether a user may perform an operation (that is
    /// <see cref="PermissionHelper"/> plus the API's authorization pipeline), and it does no database work.
    /// </para>
    /// <para>Thread-safe: the signing key/credentials are immutable after construction.</para>
    /// </summary>
    public sealed class TokenHelper
    {
        /// <summary>
        /// Required keys: <c>Jwt:Key</c>, <c>Jwt:Issuer</c>, <c>Jwt:Audience</c>.
        /// Optional: <c>Jwt:AccessTokenMinutes</c> (default 30).
        /// </summary>
        public const string AccessTokenMinutesKey = "Jwt:AccessTokenMinutes";

        /// <summary>HS256 requires a key of at least 256 bits (32 bytes).</summary>
        public const int MinimumSigningKeyBytes = 32;

        private const int DefaultAccessTokenMinutes = 30;

        private readonly string _issuer;
        private readonly string _audience;
        private readonly SigningCredentials _signingCredentials;
        private readonly int _accessTokenMinutes;

        /// <exception cref="InvalidOperationException">Thrown when JWT configuration is missing or the signing key is too short.</exception>
        public TokenHelper(IConfiguration configuration)
        {
            ArgumentNullException.ThrowIfNull(configuration);

            var signingKey = configuration["Jwt:Key"];
            if (string.IsNullOrWhiteSpace(signingKey))
            {
                throw new InvalidOperationException("Configuration 'Jwt:Key' is not set.");
            }

            var signingKeyBytes = Encoding.UTF8.GetBytes(signingKey);
            if (signingKeyBytes.Length < MinimumSigningKeyBytes)
            {
                throw new InvalidOperationException(
                    $"'Jwt:Key' must be at least {MinimumSigningKeyBytes} bytes (256 bits) for HS256 signing.");
            }

            _issuer = configuration["Jwt:Issuer"]
                ?? throw new InvalidOperationException("Configuration 'Jwt:Issuer' is not set.");
            _audience = configuration["Jwt:Audience"]
                ?? throw new InvalidOperationException("Configuration 'Jwt:Audience' is not set.");

            var configuredMinutes = configuration.GetValue<int?>(AccessTokenMinutesKey);
            _accessTokenMinutes = configuredMinutes is > 0 ? configuredMinutes.Value : DefaultAccessTokenMinutes;

            _signingCredentials = new SigningCredentials(
                new SymmetricSecurityKey(signingKeyBytes), SecurityAlgorithms.HmacSha256);
        }

        /// <summary>Configured access-token lifetime in minutes (used to persist session expiry).</summary>
        public int AccessTokenMinutes => _accessTokenMinutes;

        /// <summary>
        /// Creates a signed access token for the supplied authenticated context.
        /// Claims written here are read back by <see cref="TenantHelper"/> /
        /// <see cref="SecurityHelper"/> using <see cref="SecurityHelper.AppClaims"/>, so the JWT bearer
        /// setup must not remap inbound claim names (set <c>MapInboundClaims = false</c>).
        /// </summary>
        public TokenResult GenerateAccessToken(TenantContext context)
        {
            ArgumentNullException.ThrowIfNull(context);

            var issuedAtUtc = DateTimeHelper.UtcNow;
            var expiresUtc = issuedAtUtc.AddMinutes(_accessTokenMinutes);

            var claims = new List<Claim>
            {
                new(SecurityHelper.AppClaims.UserId, context.UserId.ToString(CultureInfo.InvariantCulture)),
                new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString("N"))
            };

            if (!string.IsNullOrWhiteSpace(context.UserName))
            {
                claims.Add(new Claim(SecurityHelper.AppClaims.UserName, context.UserName));
            }

            AddClaim(claims, SecurityHelper.AppClaims.CompanyId, context.CompanyId);
            AddClaim(claims, SecurityHelper.AppClaims.BranchId, context.BranchId);
            AddClaim(claims, SecurityHelper.AppClaims.RoleId, context.RoleId);
            AddClaim(claims, SecurityHelper.AppClaims.UserTypeId, context.UserTypeId);

            var token = new JwtSecurityToken(
                issuer: _issuer,
                audience: _audience,
                claims: claims,
                notBefore: issuedAtUtc,
                expires: expiresUtc,
                signingCredentials: _signingCredentials);

            return new TokenResult(new JwtSecurityTokenHandler().WriteToken(token), expiresUtc);
        }

        private static void AddClaim(ICollection<Claim> claims, string claimType, int? value)
        {
            if (value.HasValue)
            {
                claims.Add(new Claim(claimType, value.Value.ToString(CultureInfo.InvariantCulture)));
            }
        }

        /// <summary>Issued access token plus its UTC expiry (for <c>UserSessions.ExpiryDate</c>).</summary>
        public sealed record TokenResult(string AccessToken, DateTime ExpiresUtc);
    }
}
