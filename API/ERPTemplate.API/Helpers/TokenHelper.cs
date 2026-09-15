using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace ERPTemplate.API.Helpers;

/// <summary>
/// JWT token generation only. No login/permission/tenant business logic.
/// </summary>
public sealed class TokenHelper
{
    private readonly IConfiguration _configuration;

    public TokenHelper(IConfiguration configuration)
    {
        _configuration = configuration ?? throw new ArgumentNullException(nameof(configuration));
    }

    public string GenerateToken(TokenClaims claims, TimeSpan? lifetime = null)
    {
        ArgumentNullException.ThrowIfNull(claims);

        var section = _configuration.GetSection("JwtSettings");

        var key = section["SecretKey"] ?? section["Key"]
            ?? throw new InvalidOperationException("JWT signing key is not configured (JwtSettings:SecretKey).");

        var issuer = section["Issuer"];
        var audience = section["Audience"];

        var expiryMinutes = TryGetInt(section["ExpiryMinutes"])
            ?? TryGetInt(section["DurationInMinutes"])
            ?? 60;

        var effectiveLifetime = lifetime ?? TimeSpan.FromMinutes(expiryMinutes);

        var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
        var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

        var tokenClaims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, claims.UserId.ToString()),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new("UserID", claims.UserId.ToString())
        };

        if (!string.IsNullOrWhiteSpace(claims.UserName))
        {
            tokenClaims.Add(new Claim(JwtRegisteredClaimNames.UniqueName, claims.UserName));
            tokenClaims.Add(new Claim(ClaimTypes.Name, claims.UserName));
        }

        if (claims.CompanyId.HasValue)
        {
            tokenClaims.Add(new Claim("CompanyID", claims.CompanyId.Value.ToString()));
        }

        if (claims.BranchId.HasValue)
        {
            tokenClaims.Add(new Claim("BranchID", claims.BranchId.Value.ToString()));
        }

        if (claims.RoleId.HasValue)
        {
            tokenClaims.Add(new Claim("RoleID", claims.RoleId.Value.ToString()));
        }

        if (claims.UserTypeId.HasValue)
        {
            tokenClaims.Add(new Claim("UserTypeID", claims.UserTypeId.Value.ToString()));
        }

        var now = DateTime.UtcNow;

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: tokenClaims,
            notBefore: now,
            expires: now.Add(effectiveLifetime),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static int? TryGetInt(string? value)
        => int.TryParse(value, out var result) ? result : null;
}

public sealed record TokenClaims(
    int UserId,
    string? UserName,
    int? CompanyId = null,
    int? BranchId = null,
    int? RoleId = null,
    int? UserTypeId = null);
