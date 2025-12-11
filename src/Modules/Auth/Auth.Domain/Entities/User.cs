namespace Auth.Domain.Entities;

/// <summary>
/// Usuário do sistema (será autenticado via /auth/login).
/// </summary>

public class User
{
    public Guid Id { get; private set; }
    public string Username { get; private set; } = default!;
    public string PasswordHash { get; private set; } = default!;
    public string Email { get; private set; } = default!;
    public string Role { get; private set; } = default!;
    public bool IsActive { get; private set; }

    public User(Guid id, string username, string passwordHash, string email, string role, bool isActive)
    {
        Id = Guid.NewGuid();
        Username = username;
        PasswordHash = passwordHash;
        Email = email;
        Role = role;
        IsActive = true;
    }

    private User() { }

    public void UpdatePasswordHash(string newPasswordHash)
    {
        if (string.IsNullOrWhiteSpace(newPasswordHash))
            throw new ArgumentException("New password hash cannot be null or empty.", nameof(newPasswordHash));

        PasswordHash = newPasswordHash;
    }

    public void Deactivate() => IsActive = false;
    public void Activate() => IsActive = true;

    public void UpdateRole(string newRole)
    {
        if (string.IsNullOrWhiteSpace(newRole))
            throw new ArgumentException("New role cannot be null or empty.", nameof(newRole));
        Role = newRole;
    }

    public void UpdateEmail(string newEmail)
    {
        if (string.IsNullOrWhiteSpace(newEmail))
            throw new ArgumentException("New email cannot be null or empty.", nameof(newEmail));
        Email = newEmail;
    }   

}
