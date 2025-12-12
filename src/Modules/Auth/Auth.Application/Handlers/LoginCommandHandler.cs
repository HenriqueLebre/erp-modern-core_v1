using Auth.Application.Commands;
using Auth.Domain.Interfaces;
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

        if (!_passwordHasher.VerifyPassword(user.PasswordHash, request.Password))
            return new LoginResponse(false, null, null, null, null, "Invalid credentials.");

        var token = _jwtTokenGenerator.GenerateToken(user.Id, user.Username, user.Role);

        return new LoginResponse(true, token, user.Username, user.Id, user.Role, "Login successful.");
    }
}