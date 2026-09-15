using System.Security.Cryptography;
using System.Text;

namespace ERPTemplate.API.Helpers;

/// <summary>
/// Password hashing and verification only.
/// Matches approved storage: PasswordHash, PasswordSalt, PasswordAlgorithm, PasswordIterations.
/// </summary>
public static class PasswordHelper
{
    public const string DefaultAlgorithm = "PBKDF2-SHA256";
    public const int DefaultIterations = 100_000;

    private const int SaltSize = 32;
    private const int HashSize = 32;

    public static PasswordHashResult HashPassword(string password, int? iterations = null)
    {
        if (string.IsNullOrEmpty(password))
        {
            throw new ArgumentException("Password is required.", nameof(password));
        }

        var iterationCount = iterations ?? DefaultIterations;
        if (iterationCount <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(iterations));
        }

        var salt = RandomNumberGenerator.GetBytes(SaltSize);
        var hash = Derive(password, salt, iterationCount);

        return new PasswordHashResult(hash, salt, DefaultAlgorithm, iterationCount);
    }

    public static bool VerifyPassword(
        string password,
        byte[] storedHash,
        byte[] storedSalt,
        string algorithm,
        int iterations)
    {
        if (string.IsNullOrEmpty(password) ||
            storedHash is null || storedHash.Length == 0 ||
            storedSalt is null || storedSalt.Length == 0 ||
            string.IsNullOrEmpty(algorithm) ||
            iterations <= 0)
        {
            return false;
        }

        if (!string.Equals(algorithm, DefaultAlgorithm, StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        var computed = Derive(password, storedSalt, iterations);

        return CryptographicOperations.FixedTimeEquals(computed, storedHash);
    }

    private static byte[] Derive(string password, byte[] salt, int iterations)
    {
        using var deriveBytes = new Rfc2898DeriveBytes(
            Encoding.UTF8.GetBytes(password),
            salt,
            iterations,
            HashAlgorithmName.SHA256);

        return deriveBytes.GetBytes(HashSize);
    }
}

public sealed record PasswordHashResult(
    byte[] Hash,
    byte[] Salt,
    string Algorithm,
    int Iterations);
