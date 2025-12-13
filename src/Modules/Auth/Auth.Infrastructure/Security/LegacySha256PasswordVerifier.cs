using System.Security.Cryptography;
using System.Text;

namespace Auth.Infrastructure.Security;

public static class LegacySha256PasswordVerifier
{
    public static bool Verify(string password, string storedHash)
    {
        if (string.IsNullOrWhiteSpace(storedHash)) return false;

        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(password));

        var hex = Convert.ToHexString(bytes).ToLowerInvariant();

        return TimingSafeEquals(hex, storedHash.Trim().ToLowerInvariant());
    }

    private static bool TimingSafeEquals(string a, string b)
    {
        var ba = Encoding.UTF8.GetBytes(a);
        var bb = Encoding.UTF8.GetBytes(b);
        return CryptographicOperations.FixedTimeEquals(ba, bb);
    }
}