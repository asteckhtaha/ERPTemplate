using System.Security.Cryptography;
using System.Text;

namespace ERPTemplate.API.Helpers
{
    /// <summary>
    /// Password hashing and verification only.
    /// The result maps 1:1 to the approved <c>Users</c> columns
    /// (<c>PasswordHash</c>, <c>PasswordSalt</c>, <c>PasswordAlgorithm</c>, <c>PasswordIterations</c>).
    /// <para>
    /// No database access, no login logic, no token creation, no permission or tenant logic.
    /// Plain-text passwords are never stored, logged or returned.
    /// </para>
    /// <para>Pure and stateless: safe for concurrent API requests.</para>
    /// </summary>
    public static class PasswordHelper
    {
        /// <summary>Stored in <c>Users.PasswordAlgorithm</c> (<c>VARCHAR(30)</c>).</summary>
        public const string AlgorithmName = "PBKDF2-SHA256";

        /// <summary>
        /// Default PBKDF2-HMAC-SHA256 iteration count for new passwords (OWASP guidance).
        /// Raise this value over time: <see cref="NeedsRehash"/> lets the login flow upgrade old hashes.
        /// </summary>
        public const int DefaultIterations = 600_000;

        /// <summary>Salt length in bytes (fits <c>VARBINARY(256)</c>).</summary>
        public const int SaltSizeBytes = 32;

        /// <summary>Derived hash length in bytes.</summary>
        public const int HashSizeBytes = 32;

        private const int MinimumIterations = 10_000;

        /// <summary>
        /// Hashes a password with a fresh random salt.
        /// Store every returned value in the corresponding <c>Users</c> column.
        /// </summary>
        /// <exception cref="ArgumentException">Thrown when the password is empty.</exception>
        /// <exception cref="ArgumentOutOfRangeException">Thrown when the iteration count is too low.</exception>
        public static PasswordHashResult HashPassword(string password, int iterations = DefaultIterations)
        {
            if (string.IsNullOrEmpty(password))
            {
                throw new ArgumentException("Password must not be empty.", nameof(password));
            }

            if (iterations < MinimumIterations)
            {
                throw new ArgumentOutOfRangeException(
                    nameof(iterations), iterations, $"Iterations must be at least {MinimumIterations}.");
            }

            var salt = RandomNumberGenerator.GetBytes(SaltSizeBytes);
            var hash = Rfc2898DeriveBytes.Pbkdf2(password, salt, iterations, HashAlgorithmName.SHA256, HashSizeBytes);

            return new PasswordHashResult(hash, salt, AlgorithmName, iterations);
        }

        /// <summary>
        /// Verifies a password against the stored credential using a fixed-time comparison.
        /// Returns <c>false</c> for a wrong password or missing credential values;
        /// throws for an unsupported stored algorithm instead of silently reporting "no match".
        /// </summary>
        public static bool VerifyPassword(
            string password,
            byte[]? storedHash,
            byte[]? storedSalt,
            string? storedAlgorithm,
            int iterations)
        {
            if (string.IsNullOrEmpty(password) || storedHash is not { Length: > 0 } || storedSalt is not { Length: > 0 })
            {
                return false;
            }

            if (!string.Equals(storedAlgorithm, AlgorithmName, StringComparison.OrdinalIgnoreCase))
            {
                throw new NotSupportedException(
                    $"Stored password algorithm '{storedAlgorithm}' is not supported by {nameof(PasswordHelper)}.");
            }

            if (iterations < 1)
            {
                return false;
            }

            var computed = Rfc2898DeriveBytes.Pbkdf2(
                password, storedSalt, iterations, HashAlgorithmName.SHA256, storedHash.Length);

            try
            {
                return CryptographicOperations.FixedTimeEquals(computed, storedHash);
            }
            finally
            {
                CryptographicOperations.ZeroMemory(computed);
            }
        }

        /// <summary>Verifies a password against a <see cref="PasswordHashResult"/> (for example the values just hashed).</summary>
        public static bool VerifyPassword(string password, PasswordHashResult stored)
        {
            ArgumentNullException.ThrowIfNull(stored);
            return VerifyPassword(
                password, stored.PasswordHash, stored.PasswordSalt, stored.PasswordAlgorithm, stored.PasswordIterations);
        }

        /// <summary>
        /// True when the stored credential uses an outdated algorithm or iteration count and should be
        /// re-hashed (and saved) on the next successful login.
        /// </summary>
        public static bool NeedsRehash(string? storedAlgorithm, int iterations) =>
            !string.Equals(storedAlgorithm, AlgorithmName, StringComparison.OrdinalIgnoreCase)
            || iterations < DefaultIterations;

        /// <summary>
        /// Password material produced by <see cref="HashPassword"/>, shaped exactly like the approved
        /// <c>Users</c> password columns.
        /// </summary>
        public sealed record PasswordHashResult(
            byte[] PasswordHash,
            byte[] PasswordSalt,
            string PasswordAlgorithm,
            int PasswordIterations);
    }
}
