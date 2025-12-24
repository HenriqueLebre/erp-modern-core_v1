using System.Net.Http.Json;
using System.Text.Json;
using ERP.Blazor.Models;
using Microsoft.AspNetCore.Components.Server.ProtectedBrowserStorage;

namespace ERP.Blazor.Services;

/// <summary>
/// Serviço de autenticação que integra com a Auth API
/// </summary>
public class AuthService : IAuthService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ProtectedSessionStorage _sessionStorage;
    private readonly ILogger<AuthService> _logger;
    private const string TOKEN_KEY = "auth_token";
    private const string USER_KEY = "auth_user";

    public AuthService(
        IHttpClientFactory httpClientFactory,
        ProtectedSessionStorage sessionStorage,
        ILogger<AuthService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _sessionStorage = sessionStorage;
        _logger = logger;
    }

    public async Task<LoginResult> LoginAsync(string username, string password)
    {
        try
        {
            var client = _httpClientFactory.CreateClient("AuthAPI");
            
            var request = new AuthRequest
            {
                Username = username,
                Password = password
            };

            _logger.LogInformation("Attempting login for user: {Username}", username);

            var response = await client.PostAsJsonAsync("/auth/login", request);

            if (response.IsSuccessStatusCode)
            {
                var authResponse = await response.Content.ReadFromJsonAsync<AuthResponse>();

                if (authResponse != null)
                {
                    var loginResult = new LoginResult
                    {
                        Success = true,
                        Token = authResponse.Token,
                        Username = authResponse.Username,
                        UserId = authResponse.UserId,
                        Role = authResponse.Role,
                        ExpiresAt = authResponse.ExpiresAt
                    };

                    // Armazenar token e informações do usuário
                    await _sessionStorage.SetAsync(TOKEN_KEY, authResponse.Token);
                    await _sessionStorage.SetAsync(USER_KEY, loginResult);

                    _logger.LogInformation("Login successful for user: {Username}", username);

                    return loginResult;
                }
            }
            else
            {
                var errorContent = await response.Content.ReadAsStringAsync();
                _logger.LogWarning("Login failed for user: {Username}. Status: {Status}, Error: {Error}",
                    username, response.StatusCode, errorContent);

                return new LoginResult
                {
                    Success = false,
                    ErrorMessage = response.StatusCode switch
                    {
                        System.Net.HttpStatusCode.Unauthorized => "Usuário ou senha inválidos",
                        System.Net.HttpStatusCode.BadRequest => "Dados de login inválidos",
                        _ => $"Erro ao realizar login: {response.StatusCode}"
                    }
                };
            }
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "HTTP error during login for user: {Username}", username);
            return new LoginResult
            {
                Success = false,
                ErrorMessage = "Erro de conexão com o servidor. Verifique se a API está rodando."
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error during login for user: {Username}", username);
            return new LoginResult
            {
                Success = false,
                ErrorMessage = "Erro inesperado ao realizar login"
            };
        }

        return new LoginResult
        {
            Success = false,
            ErrorMessage = "Resposta inválida do servidor"
        };
    }

    public async Task LogoutAsync()
    {
        try
        {
            _logger.LogInformation("Logging out user");
            await _sessionStorage.DeleteAsync(TOKEN_KEY);
            await _sessionStorage.DeleteAsync(USER_KEY);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during logout");
        }
    }

    public async Task<bool> IsAuthenticatedAsync()
    {
        try
        {
            var tokenResult = await _sessionStorage.GetAsync<string>(TOKEN_KEY);
            return tokenResult.Success && !string.IsNullOrEmpty(tokenResult.Value);
        }
        catch
        {
            return false;
        }
    }

    public async Task<string?> GetTokenAsync()
    {
        try
        {
            var result = await _sessionStorage.GetAsync<string>(TOKEN_KEY);
            return result.Success ? result.Value : null;
        }
        catch
        {
            return null;
        }
    }

    public async Task<LoginResult?> GetCurrentUserAsync()
    {
        try
        {
            var result = await _sessionStorage.GetAsync<LoginResult>(USER_KEY);
            return result.Success ? result.Value : null;
        }
        catch
        {
            return null;
        }
    }
}
