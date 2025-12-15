using System.Security.Cryptography;
using System.Text;

namespace Auth.Application.Security;

public static class LegacySha256PasswordVerifier
{
    // compatível com o legado atual: SHA256 -> Base64
    public static bool Verify(string storedHashBase64, string providedPassword)
    {
        using var sha256 = SHA256.Create();
        var bytes = Encoding.UTF8.GetBytes(providedPassword);
        var hash = sha256.ComputeHash(bytes);
        var providedHashBase64 = Convert.ToBase64String(hash);

        return storedHashBase64 == providedHashBase64;
    }
}