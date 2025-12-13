using Auth.Domain.Interfaces;
using Auth.Infrastructure.Persistence;
using Auth.Infrastructure.Repositories;
using Auth.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using SharedKernel.Application.Interfaces;

namespace Auth.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddAuthInfrastructure(this IServiceCollection services)
    {
        // DbContext em memória por enquanto
        services.AddDbContext<AuthDbContext>(options =>
        {
            options.UseInMemoryDatabase("AuthDb");
        });

        // Repositório de usuário
        services.AddScoped<IUserRepository, UserRepository>();

        // Hasher de senha
        services.AddScoped<IPasswordHasher, PasswordHasher>();

        // Gerador de JWT
        services.AddSingleton<IPasswordHasher, Pbkdf2PasswordHasher>();

        return services;
    }
}