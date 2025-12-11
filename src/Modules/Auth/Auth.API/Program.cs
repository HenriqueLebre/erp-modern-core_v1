using Auth.Application;
using Auth.Domain.Entities;
using Auth.Domain.Interfaces;
using Auth.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();

// Infra + Application do módulo Auth
builder.Services.AddAuthInfrastructure();
builder.Services.AddAuthApplication();

// Swagger (para testar mais fácil)
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// SEED: criar usuário admin/admin em memória
using (var scope = app.Services.CreateScope())
{
    var userRepo = scope.ServiceProvider.GetRequiredService<IUserRepository>();
    var passwordHasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher>();

    var existing = await userRepo.GetByUsernameAsync("admin");
    if (existing is null)
    {
        var user = new User(
            username: "admin",
            passwordHash: passwordHasher.HashPassword("admin"),
            email: "admin@local",
            role: "Admin"
        );

        await userRepo.AddAsync(user);
    }
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();