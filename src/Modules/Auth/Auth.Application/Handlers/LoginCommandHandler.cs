using Auth.Application.Commands;
using Auth.Application.Security;   // só para LegacySha256PasswordVerifier
using Auth.Domain.Interfaces;      // aqui vem o IPasswordHasher correto
using MediatR;
using SharedKernel.Application.Interfaces;

namespace Auth.Application.Handlers;

public class LoginCommandHandler : IRequestHandler<LoginCommand, LoginResponse>
{
    private readonly IUserRepository _userRepository;
    private readonly IPasswordHasher _passwordHasher; 
    private readonly IJwtTokenGenerator _jwtTokenGenerator;

    public LoginCommandHandler(
        IUserRepository userRepository,
        IPasswordHasher passwordHasher,
        IJwtTokenGenerator jwtTokenGenerator)
    {
        _userRepository = userRepository;
        _passwordHasher = passwordHasher;
        _jwtTokenGenerator = jwtTokenGenerator;
    }

    public async Task<LoginResponse> Handle(LoginCommand request, CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetByUsernameAsync(request.Username, cancellationToken);

        if (user is null || !user.IsActive)
            return new LoginResponse(false, null, null, null, null, "Invalid credentials or inactive user.");

        var storedHash = user.PasswordHash;
        var providedPassword = request.Password;

        // Detecta se é o formato novo
        var isPbkdf2 = storedHash.StartsWith("pbkdf2$", StringComparison.OrdinalIgnoreCase);

        bool passwordOk;

        if (isPbkdf2)
        {
            // Novo: PBKDF2 (via IPasswordHasher)
            passwordOk = _passwordHasher.VerifyPassword(storedHash, providedPassword);
        }
        else
        {
            // Legado: SHA256 Base64 (compatível com o PasswordHasher atual)
            passwordOk = LegacySha256PasswordVerifier.Verify(storedHash, providedPassword);

            // Migração automática: se o legado passar, rehash PBKDF2 e salva
            if (passwordOk)
            {
                var newHash = _passwordHasher.HashPassword(providedPassword);
                user.UpdatePasswordHash(newHash);

                await _userRepository.UpdateAsync(user, cancellationToken);
            }
        }

        if (!passwordOk)
            return new LoginResponse(false, null, null, null, null, "Invalid credentials.");

        var token = _jwtTokenGenerator.GenerateToken(user.Id, user.Username, user.Role);

        return new LoginResponse(true, token, user.Username, user.Id, user.Role, "Login successful.");
    }
}