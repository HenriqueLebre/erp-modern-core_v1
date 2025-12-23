# 🚀 Quick Test - Docker Setup

## Opção 1: Script Automatizado (Recomendado)

### Linux/Mac:
```bash
cd erp-modern-core
chmod +x test-docker.sh
./test-docker.sh
```

### Windows (PowerShell):
```powershell
cd erp-modern-core
.\test-docker.ps1
```

---

## Opção 2: Manual (Passo a Passo)

### 1. Preparar ambiente
```bash
cd erp-modern-core
cp .env.example .env
```

### 2. Build e Start
```bash
# Build das imagens
docker-compose build

# Iniciar serviços
docker-compose up -d

# Ver logs
docker-compose logs -f
```

### 3. Aguardar serviços ficarem prontos
```bash
# Aguardar ~30-60 segundos para inicialização

# Verificar status
docker-compose ps

# Verificar health
curl http://localhost:5281/health
```

### 4. Testar API
```bash
# Test 1: Health Check
curl http://localhost:5281/health

# Test 2: Login
curl -X POST http://localhost:5281/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'

# Test 3: Swagger (abrir no navegador)
# http://localhost:5281/swagger
```

---

## ✅ Checklist de Verificação

- [ ] Docker Desktop está rodando
- [ ] Porta 5281 está livre
- [ ] Porta 5433 está livre
- [ ] `docker compose ps` mostra containers saudáveis
- [ ] `/health` retorna sucesso
- [ ] `/swagger` abre no navegador
- [ ] Login funciona

---

## 🐛 Troubleshooting Rápido

### Problema: Porta em uso
```bash
# Verificar o que está usando a porta
# Windows:
netstat -ano | findstr :5281

# Linux/Mac:
lsof -i :5281

# Solução: Mudar porta no .env
AUTH_API_PORT=5282
```

### Problema: Container não inicia
```bash
# Ver logs detalhados
docker-compose logs auth-api

# Rebuild completo
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

### Problema: Database error
```bash
# Recriar banco
docker-compose down -v
docker-compose up -d postgres
# Aguardar 30s
docker-compose up -d auth-api
```

---

## 📊 Comandos Úteis

```bash
# Ver todos os logs
docker-compose logs -f

# Ver apenas API
docker-compose logs -f auth-api

# Parar tudo
docker-compose stop

# Remover tudo (incluindo dados)
docker-compose down -v

# Entrar no container
docker-compose exec auth-api bash

# Conectar ao PostgreSQL
docker-compose exec postgres psql -U postgres -d erp_auth
```

---

## 🎯 Teste Bem-Sucedido

Se tudo funcionou, você verá:

✅ 2 containers rodando (postgres + auth-api)  
✅ `/health` retorna: `Healthy`  
✅ `/swagger` mostra documentação da API  
✅ Login retorna token JWT  
✅ Logs sem erros críticos

**Próximo passo:** Testar integração com sistema legado xHarbour!
