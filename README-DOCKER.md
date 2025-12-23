# 🐳 Docker Setup - ERP Modern Core

Este guia explica como executar o projeto usando Docker e Docker Compose.

---

## 📋 Pré-requisitos

- **Docker** 20.10+ ([Instalar Docker](https://docs.docker.com/get-docker/))
- **Docker Compose** 2.0+ (incluído no Docker Desktop)
- **Git** (para clonar o repositório)

---

## 🚀 Quick Start

### 1. Configurar Variáveis de Ambiente

```bash
# Copiar template de configuração
cp .env.example .env

# Editar .env com suas configurações (opcional para dev)
nano .env
```

### 2. Iniciar Todos os Serviços

```bash
# Build e start em um comando
docker-compose up -d --build

# Ou separado:
docker-compose build
docker-compose up -d
```

### 3. Verificar Status

```bash
# Ver logs em tempo real
docker-compose logs -f

# Ver apenas logs da API
docker-compose logs -f auth-api

# Ver status dos containers
docker-compose ps
```

### 4. Aplicar Migrations

```bash
# Executar migrations do EF Core
docker-compose exec auth-api dotnet ef database update

# Ou se precisar criar migration nova:
docker-compose exec auth-api dotnet ef migrations add InitialCreate
```

### 5. Testar a API

```bash
# Health check
curl http://localhost:5281/health

# Swagger UI
# Abrir no navegador: http://localhost:5281/swagger

# Login (credenciais padrão: admin/admin)
curl -X POST http://localhost:5281/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'
```

---

## 🛠️ Comandos Úteis

### Gerenciamento de Containers

```bash
# Parar todos os serviços
docker-compose stop

# Parar e remover containers
docker-compose down

# Parar e remover containers + volumes (CUIDADO: apaga dados!)
docker-compose down -v

# Reiniciar apenas a API
docker-compose restart auth-api

# Rebuild apenas a API
docker-compose up -d --build auth-api
```

### Logs e Debug

```bash
# Ver logs de todos os serviços
docker-compose logs

# Ver últimas 100 linhas
docker-compose logs --tail=100

# Ver logs com timestamp
docker-compose logs -t

# Entrar no container da API
docker-compose exec auth-api bash

# Entrar no PostgreSQL
docker-compose exec postgres psql -U postgres -d erp_auth
```

### Database

```bash
# Backup do banco
docker-compose exec postgres pg_dump -U postgres erp_auth > backup.sql

# Restore do banco
docker-compose exec -T postgres psql -U postgres erp_auth < backup.sql

# Conectar ao PostgreSQL via CLI
docker-compose exec postgres psql -U postgres -d erp_auth
```

---

## 🔧 Serviços Disponíveis

| Serviço | Porta | URL | Descrição |
|---------|-------|-----|-----------|
| **Auth API** | 5281 | http://localhost:5281 | API de Autenticação (.NET 8) |
| **Swagger** | 5281 | http://localhost:5281/swagger | Documentação interativa |
| **PostgreSQL** | 5433 | localhost:5433 | Banco de dados |
| **pgAdmin** | 5050 | http://localhost:5050 | Interface de gerenciamento DB |

### Credenciais Padrão (Development)

**API:**
- Username: `admin`
- Password: `admin`

**PostgreSQL:**
- Host: `localhost`
- Port: `5433`
- Database: `erp_auth`
- User: `postgres`
- Password: `postgres`

**pgAdmin (opcional):**
- Email: `admin@erp-modern.local`
- Password: `admin`

---

## 🎯 Perfis Docker Compose

### Perfil Padrão (Development)
```bash
docker-compose up -d
```
Inicia: PostgreSQL + Auth API

### Perfil com Ferramentas
```bash
docker-compose --profile tools up -d
```
Inicia: PostgreSQL + Auth API + pgAdmin

---

## 🏗️ Estrutura de Arquivos Docker

```
erp-modern-core/
├── docker-compose.yml              # Configuração principal
├── docker-compose.override.yml     # Overrides para dev
├── .env.example                    # Template de variáveis
├── .env                           # Suas variáveis (não commitado)
├── .dockerignore                  # Arquivos ignorados no build
├── scripts/
│   └── init-db.sql                # Inicialização do DB
└── src/
    └── Modules/
        └── Auth/
            └── Auth.API/
                └── Dockerfile      # Build da API
```

---

## 🐛 Troubleshooting

### Problema: Container não inicia

```bash
# Ver logs detalhados
docker-compose logs auth-api

# Verificar configuração
docker-compose config

# Remover containers antigos
docker-compose down -v
docker-compose up -d --build
```

### Problema: Porta já em uso

```bash
# Editar .env e mudar a porta
AUTH_API_PORT=5282  # ou outra porta livre

# Ou parar processo que está usando a porta
# Windows:
netstat -ano | findstr :5281
taskkill /PID <PID> /F

# Linux/Mac:
lsof -ti:5281 | xargs kill -9
```

### Problema: Erro de conexão com PostgreSQL

```bash
# Verificar se PostgreSQL está saudável
docker-compose ps

# Reiniciar serviço
docker-compose restart postgres

# Ver logs do PostgreSQL
docker-compose logs postgres

# Aguardar health check (pode levar ~30s)
```

### Problema: Migration falha

```bash
# Limpar banco e recriar
docker-compose down -v
docker-compose up -d postgres
# Aguardar ~30 segundos
docker-compose up -d auth-api
```

---

## 🔒 Segurança (Produção)

⚠️ **IMPORTANTE:** As configurações padrão são para **desenvolvimento local apenas**!

Para produção, você DEVE:

1. **Gerar JWT Secret forte:**
```bash
openssl rand -base64 32
```

2. **Usar secrets externos:**
```yaml
# docker-compose.prod.yml
services:
  auth-api:
    secrets:
      - jwt_key
      - db_password
secrets:
  jwt_key:
    external: true
  db_password:
    external: true
```

3. **Não expor PostgreSQL:**
```yaml
postgres:
  ports: []  # Remover mapeamento de porta
```

4. **Usar HTTPS:**
```yaml
auth-api:
  environment:
    - ASPNETCORE_URLS=https://+:443;http://+:80
  volumes:
    - ./certs:/https:ro
```

---

## 📊 Monitoramento

### Health Checks

```bash
# API Health
curl http://localhost:5281/health

# Database Health
docker-compose exec postgres pg_isready -U postgres

# Container Health
docker inspect --format='{{.State.Health.Status}}' erp-auth-api
```

### Logs Estruturados

```bash
# Ver logs JSON estruturados
docker-compose logs auth-api | jq

# Filtrar por nível de log
docker-compose logs auth-api | grep "ERROR"
```

---

## 🚢 Deploy para Produção

Veja nosso guia completo de CI/CD: [CI/CD Guide](./README-CICD.md)

Deploy sugerido:
- **AWS ECS Fargate** (recomendado)
- **Azure Container Apps**
- **Google Cloud Run**
- **Kubernetes** (para scale maior)

---

## 📚 Links Úteis

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [.NET Docker Images](https://hub.docker.com/_/microsoft-dotnet)
- [PostgreSQL Docker Image](https://hub.docker.com/_/postgres)

---

## 💬 Suporte

Problemas? Abra uma issue no repositório ou consulte nossa documentação completa.

**Happy Dockerizing! 🐳**
