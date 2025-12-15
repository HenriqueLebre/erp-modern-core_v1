using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Auth.Infrastructure.Persistence;

public sealed class AuthDbContextFactory : IDesignTimeDbContextFactory<AuthDbContext>
{
    public AuthDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<AuthDbContext>();

        // Connection string design-time (dev local)
        optionsBuilder.UseNpgsql(
            "Host=127.0.0.1;Port=5433;Database=erp_auth;Username=postgres;Password=postgres"
        );

        return new AuthDbContext(optionsBuilder.Options);
    }
}