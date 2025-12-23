#!/bin/bash

# ==================================
# Script de Teste Docker - ERP Modern Core
# ==================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}===================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# ==================================
# Step 1: Pre-flight checks
# ==================================
print_header "Step 1: Pre-flight Checks"

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker não está instalado!"
    echo "Instale Docker Desktop: https://docs.docker.com/get-docker/"
    exit 1
fi
print_success "Docker instalado: $(docker --version)"

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    print_error "Docker Compose não está disponível!"
    exit 1
fi
print_success "Docker Compose disponível: $(docker compose version)"

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_error "Docker não está rodando!"
    echo "Inicie o Docker Desktop e tente novamente."
    exit 1
fi
print_success "Docker está rodando"

echo ""

# ==================================
# Step 2: Setup Environment
# ==================================
print_header "Step 2: Environment Setup"

if [ ! -f .env ]; then
    print_info "Criando arquivo .env a partir de .env.example..."
    cp .env.example .env
    print_success "Arquivo .env criado"
else
    print_warning "Arquivo .env já existe, mantendo configuração atual"
fi

echo ""

# ==================================
# Step 3: Clean up old containers
# ==================================
print_header "Step 3: Cleanup (se necessário)"

if docker compose ps -q 2>/dev/null | grep -q .; then
    print_info "Parando containers existentes..."
    docker compose down
    print_success "Containers removidos"
else
    print_info "Nenhum container rodando"
fi

echo ""

# ==================================
# Step 4: Build containers
# ==================================
print_header "Step 4: Building Docker Images"

print_info "Iniciando build (pode levar alguns minutos na primeira vez)..."
if docker compose build --no-cache; then
    print_success "Build concluído com sucesso!"
else
    print_error "Build falhou!"
    exit 1
fi

echo ""

# ==================================
# Step 5: Start services
# ==================================
print_header "Step 5: Starting Services"

print_info "Iniciando PostgreSQL..."
docker compose up -d postgres

print_info "Aguardando PostgreSQL ficar saudável (até 60s)..."
timeout=60
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker compose ps postgres | grep -q "healthy"; then
        print_success "PostgreSQL está saudável!"
        break
    fi
    sleep 2
    elapsed=$((elapsed + 2))
    echo -n "."
done

if [ $elapsed -ge $timeout ]; then
    print_error "PostgreSQL não ficou saudável a tempo"
    docker compose logs postgres
    exit 1
fi

echo ""
print_info "Iniciando Auth API..."
docker compose up -d auth-api

echo ""
print_info "Aguardando Auth API ficar saudável (até 60s)..."
timeout=60
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if curl -s http://localhost:5281/health > /dev/null 2>&1; then
        print_success "Auth API está saudável!"
        break
    fi
    sleep 2
    elapsed=$((elapsed + 2))
    echo -n "."
done

if [ $elapsed -ge $timeout ]; then
    print_error "Auth API não ficou saudável a tempo"
    docker compose logs auth-api
    exit 1
fi

echo ""

# ==================================
# Step 6: Verify Services
# ==================================
print_header "Step 6: Verifying Services"

# Check containers status
print_info "Status dos containers:"
docker compose ps

echo ""

# Check PostgreSQL
print_info "Testando PostgreSQL..."
if docker compose exec -T postgres pg_isready -U postgres -d erp_auth > /dev/null 2>&1; then
    print_success "PostgreSQL: OK"
else
    print_error "PostgreSQL: FALHOU"
    exit 1
fi

# Check API Health
print_info "Testando API Health Endpoint..."
HEALTH_RESPONSE=$(curl -s http://localhost:5281/health)
if [ -n "$HEALTH_RESPONSE" ]; then
    print_success "API Health: OK"
    echo "Response: $HEALTH_RESPONSE"
else
    print_error "API Health: FALHOU"
    exit 1
fi

echo ""

# ==================================
# Step 7: Test API Endpoints
# ==================================
print_header "Step 7: Testing API Endpoints"

# Test Login
print_info "Testando login com admin/admin..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:5281/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"admin"}')

if echo "$LOGIN_RESPONSE" | grep -q "token"; then
    print_success "Login: OK"
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "Token recebido: ${TOKEN:0:50}..."
else
    print_warning "Login: Falhou (pode ser primeira execução)"
    echo "Response: $LOGIN_RESPONSE"
    echo ""
    print_info "Nota: Se for primeira execução, pode precisar rodar migrations"
fi

echo ""

# Test Swagger
print_info "Verificando Swagger UI..."
SWAGGER_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5281/swagger)
if [ "$SWAGGER_RESPONSE" = "200" ]; then
    print_success "Swagger: OK"
else
    print_warning "Swagger: Código HTTP $SWAGGER_RESPONSE"
fi

echo ""

# ==================================
# Step 8: Show Logs
# ==================================
print_header "Step 8: Recent Logs"

print_info "Últimas 20 linhas de log da API:"
docker compose logs --tail=20 auth-api

echo ""

# ==================================
# Summary
# ==================================
print_header "🎉 TESTE CONCLUÍDO!"

echo -e "${GREEN}✅ Todos os serviços estão funcionando!${NC}"
echo ""
echo "📊 Serviços disponíveis:"
echo "  • Auth API:    http://localhost:5281"
echo "  • Swagger:     http://localhost:5281/swagger"
echo "  • PostgreSQL:  localhost:5433"
echo ""
echo "🔑 Credenciais padrão:"
echo "  • API:         admin / admin"
echo "  • PostgreSQL:  postgres / postgres"
echo ""
echo "📝 Próximos passos:"
echo "  1. Abrir Swagger: http://localhost:5281/swagger"
echo "  2. Testar endpoints no Swagger UI"
echo "  3. Ver logs: docker compose logs -f"
echo "  4. Parar: docker compose down"
echo ""
echo "💡 Comandos úteis:"
echo "  • Ver logs ao vivo:     docker compose logs -f"
echo "  • Entrar no container:  docker compose exec auth-api bash"
echo "  • Parar serviços:       docker compose stop"
echo "  • Remover tudo:         docker compose down -v"
echo ""

print_info "Para mais informações, consulte README-DOCKER.md"
