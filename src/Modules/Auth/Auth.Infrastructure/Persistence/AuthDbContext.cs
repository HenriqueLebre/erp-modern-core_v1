using Auth.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Auth.Infrastructure.Persistence;

/// <summary>
/// DbContext do módulo de autenticação (por enquanto usando InMemory).
/// </summary>
public class AuthDbContext : DbContext
{
    public DbSet<User> Users => Set<User>();

    public AuthDbContext(DbContextOptions<AuthDbContext> options)
        : base(options)
    {
    }
}