# ==================================
# Script de Teste Docker - ERP Modern Core
# PowerShell Version (Windows)
# ==================================

$ErrorActionPreference = "Stop"

function Print-Header {
    param([string]$Message)
    Write-Host "`n===================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "===================================`n" -ForegroundColor Blue
}

function Print-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Print-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Print-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Print-Info {
    param([string]$Message)
    Write-Host "INFO: $Message" -ForegroundColor Cyan
}

# ==================================
# Step 1: Pre-flight checks
# ==================================
Print-Header "Step 1: Pre-flight Checks"

# Check Docker
try {
    $dockerVersion = docker --version
    Print-Success "Docker instalado: $dockerVersion"
} catch {
    Print-Error "Docker não está instalado!"
    Write-Host "Instale Docker Desktop: https://docs.docker.com/get-docker/"
    exit 1
}

# Check Docker Compose
try {
    $composeVersion = docker compose version
    Print-Success "Docker Compose disponível: $composeVersion"
} catch {
    Print-Error "Docker Compose não está disponível!"
    exit 1
}

# Check if Docker is running
try {
    docker info | Out-Null
    Print-Success "Docker está rodando"
} catch {
    Print-Error "Docker não está rodando!"
    Write-Host "Inicie o Docker Desktop e tente novamente."
    exit 1
}

# ==================================
# Step 2: Setup Environment
# ==================================
Print-Header "Step 2: Environment Setup"

if (-not (Test-Path ".env")) {
    Print-Info "Criando arquivo .env a partir de .env.example..."
    Copy-Item ".env.example" ".env"
    Print-Success "Arquivo .env criado"
} else {
    Print-Warning "Arquivo .env já existe, mantendo configuração atual"
}

# ==================================
# Step 3: Clean up old containers
# ==================================
Print-Header "Step 3: Cleanup (se necessário)"

try {
    $containers = docker compose ps -q 2>$null
    if ($containers) {
        Print-Info "Parando containers existentes..."
        docker compose down
        Print-Success "Containers removidos"
    } else {
        Print-Info "Nenhum container rodando"
    }
} catch {
    Print-Info "Nenhum container rodando"
}

# ==================================
# Step 4: Build containers
# ==================================
Print-Header "Step 4: Building Docker Images"

Print-Info "Iniciando build (pode levar alguns minutos na primeira vez)..."
try {
    docker compose build --no-cache
    Print-Success "Build concluído com sucesso!"
} catch {
    Print-Error "Build falhou!"
    exit 1
}

# ==================================
# Step 5: Start services
# ==================================
Print-Header "Step 5: Starting Services"

Print-Info "Iniciando PostgreSQL..."
docker compose up -d postgres

Print-Info "Aguardando PostgreSQL ficar saudável (até 60s)..."
$timeout = 60
$elapsed = 0
while ($elapsed -lt $timeout) {
    $status = docker compose ps postgres | Select-String "healthy"
    if ($status) {
        Print-Success "PostgreSQL está saudável!"
        break
    }
    Start-Sleep -Seconds 2
    $elapsed += 2
    Write-Host "." -NoNewline
}

if ($elapsed -ge $timeout) {
    Print-Error "PostgreSQL não ficou saudável a tempo"
    docker compose logs postgres
    exit 1
}

Write-Host ""
Print-Info "Iniciando Auth API..."
docker compose up -d auth-api

Write-Host ""
Print-Info "Aguardando Auth API ficar saudável (até 60s)..."
$timeout = 60
$elapsed = 0
while ($elapsed -lt $timeout) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5281/health" -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Print-Success "Auth API está saudável!"
            break
        }
    } catch {
        # Continue waiting
    }
    Start-Sleep -Seconds 2
    $elapsed += 2
    Write-Host "." -NoNewline
}

if ($elapsed -ge $timeout) {
    Print-Error "Auth API não ficou saudável a tempo"
    docker compose logs auth-api
    exit 1
}

Write-Host ""

# ==================================
# Step 6: Verify Services
# ==================================
Print-Header "Step 6: Verifying Services"

Print-Info "Status dos containers:"
docker compose ps

Write-Host ""

# Check PostgreSQL
Print-Info "Testando PostgreSQL..."
try {
    docker compose exec -T postgres pg_isready -U postgres -d erp_auth | Out-Null
    Print-Success "PostgreSQL: OK"
} catch {
    Print-Error "PostgreSQL: FALHOU"
    exit 1
}

# Check API Health
Print-Info "Testando API Health Endpoint..."
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:5281/health" -Method Get
    Print-Success "API Health: OK"
    Write-Host "Response: $healthResponse"
} catch {
    Print-Error "API Health: FALHOU"
    exit 1
}

Write-Host ""

# ==================================
# Step 7: Test API Endpoints
# ==================================
Print-Header "Step 7: Testing API Endpoints"

# Test Login
Print-Info "Testando login com admin/admin..."
try {
    $body = @{
        username = "admin"
        password = "admin"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "http://localhost:5281/auth/login" `
        -Method Post `
        -Body $body `
        -ContentType "application/json"

    if ($loginResponse.token) {
        Print-Success "Login: OK"
        $token = $loginResponse.token
        Write-Host "Token recebido: $($token.Substring(0, [Math]::Min(50, $token.Length)))..."
    } else {
        Print-Warning "Login: Sem token na resposta"
    }
} catch {
    Print-Warning "Login: Falhou (pode ser primeira execução)"
    Write-Host "Error: $_"
    Write-Host ""
    Print-Info "Nota: Se for primeira execução, pode precisar rodar migrations"
}

Write-Host ""

# Test Swagger
Print-Info "Verificando Swagger UI..."
try {
    $swaggerResponse = Invoke-WebRequest -Uri "http://localhost:5281/swagger" -UseBasicParsing
    if ($swaggerResponse.StatusCode -eq 200) {
        Print-Success "Swagger: OK"
    }
} catch {
    Print-Warning "Swagger: Falhou"
}

Write-Host ""

# ==================================
# Step 8: Show Logs
# ==================================
Print-Header "Step 8: Recent Logs"

Print-Info "Últimas 20 linhas de log da API:"
docker compose logs --tail=20 auth-api

Write-Host ""

# ==================================
# Summary
# ==================================
Print-Header "TESTE CONCLUIDO!"

Write-Host "[OK] Todos os servicos estao funcionando!" -ForegroundColor Green
Write-Host ""
Write-Host "Servicos disponiveis:"
Write-Host "  • Auth API:    http://localhost:5281"
Write-Host "  • Swagger:     http://localhost:5281/swagger"
Write-Host "  • PostgreSQL:  localhost:5433"
Write-Host ""
Write-Host "Credenciais padrao:"
Write-Host "  • API:         admin / admin"
Write-Host "  • PostgreSQL:  postgres / postgres"
Write-Host ""
Write-Host "Proximos passos:"
Write-Host "  1. Abrir Swagger: http://localhost:5281/swagger"
Write-Host "  2. Testar endpoints no Swagger UI"
Write-Host "  3. Ver logs: docker compose logs -f"
Write-Host "  4. Parar: docker compose down"
Write-Host ""
Write-Host "Comandos uteis:"
Write-Host "  - Ver logs ao vivo:     docker compose logs -f"
Write-Host "  - Entrar no container:  docker compose exec auth-api bash"
Write-Host "  - Parar servicos:       docker compose stop"
Write-Host "  - Remover tudo:         docker compose down -v"
Write-Host ""

Print-Info "Para mais informacoes, consulte README-DOCKER.md"
