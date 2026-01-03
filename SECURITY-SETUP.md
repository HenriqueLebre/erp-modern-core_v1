# 🔒 Security Configuration Guide

## ⚠️ CRITICAL: Environment Variables Setup

This application **REQUIRES** environment variables for security-sensitive configuration.

### 🚨 Security Vulnerabilities Fixed

✅ **Fixed Issues:**
- JWT secret moved from hardcoded to environment variables
- Database passwords moved to environment variables
- `.env` file excluded from git
- Validation for minimum key length (32 chars)

---

## 📋 Setup Instructions

### 1. Local Development

```bash
# Copy the example file
cp .env.example .env

# Generate a secure JWT secret
openssl rand -base64 64

# Edit .env and replace JWT_SECRET_KEY with generated value
nano .env
```

**Minimum `.env` for local development:**
```bash
JWT_SECRET_KEY=your-generated-secret-here-min-32-chars
AUTH_DB_CONNECTION_STRING_DEV=Host=127.0.0.1;Port=5433;Database=erp_auth;Username=postgres;Password=postgres
```

### 2. Docker Compose

Environment variables are loaded from `.env` file automatically.

```bash
# Start services
docker-compose up -d

# Check logs
docker-compose logs auth-api
```

### 3. Production (AWS ECS)

**NEVER hardcode secrets in production!**

Use **AWS Secrets Manager** or **Parameter Store**:

```bash
# Store JWT secret
aws secretsmanager create-secret \
  --name /erp-modern/prod/jwt-secret \
  --secret-string "$(openssl rand -base64 64)"

# Store DB connection string
aws secretsmanager create-secret \
  --name /erp-modern/prod/db-connection \
  --secret-string "Host=prod-rds.aws.com;Port=5432;Database=erp_auth;Username=app_user;Password=STRONG_PASSWORD"
```

**ECS Task Definition:**
```json
{
  "secrets": [
    {
      "name": "JWT_SECRET_KEY",
      "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT:secret:/erp-modern/prod/jwt-secret"
    },
    {
      "name": "AUTH_DB_CONNECTION_STRING",
      "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT:secret:/erp-modern/prod/db-connection"
    }
  ]
}
```

---

## 🔐 Required Environment Variables

### Critical (P0)

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `JWT_SECRET_KEY` | JWT signing key (min 32 chars) | `openssl rand -base64 64` | ✅ YES |
| `AUTH_DB_CONNECTION_STRING` | PostgreSQL connection | `Host=...;Database=...` | ✅ YES |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `JWT_ISSUER` | JWT issuer claim | `erp-modern-core` |
| `JWT_AUDIENCE` | JWT audience claim | `erp-modern-core-clients` |
| `JWT_EXPIRATION_HOURS` | Token validity (hours) | `8` |
| `ASPNETCORE_ENVIRONMENT` | Environment name | `Production` |

---

## ✅ Validation

The application validates configuration on startup:

```csharp
// Program.cs performs these checks:
✅ JWT_SECRET_KEY exists and is >= 32 characters
✅ AUTH_DB_CONNECTION_STRING is set
✅ Throws InvalidOperationException if validation fails
```

**Startup Errors:**
```
❌ JWT Secret Key must be set via JWT_SECRET_KEY environment variable and be at least 32 characters long.
❌ Database connection string must be set via AUTH_DB_CONNECTION_STRING environment variable.
```

---

## 🔍 Security Checklist

### Before Committing Code

- [ ] `.env` file is in `.gitignore`
- [ ] No secrets in `appsettings.json` or `appsettings.Development.json`
- [ ] `.env.example` has placeholder values only

### Before Deploying to Production

- [ ] Secrets stored in AWS Secrets Manager
- [ ] JWT key is at least 64 characters (use `openssl rand -base64 64`)
- [ ] Database password is strong (min 16 chars, mixed case, numbers, symbols)
- [ ] Environment variables configured in ECS Task Definition
- [ ] Connection strings use SSL/TLS (`SslMode=Require`)
- [ ] Secrets rotation policy configured (90 days)

### Monitoring

- [ ] CloudWatch logs do NOT contain secrets
- [ ] Exception messages do NOT leak connection strings
- [ ] Health check endpoints do NOT expose sensitive data

---

## 🛡️ Best Practices

### JWT Secret Key

```bash
# ✅ GOOD: Strong, random, 64+ chars
JWT_SECRET_KEY=$(openssl rand -base64 64)

# ❌ BAD: Short, predictable
JWT_SECRET_KEY=mysecret123
```

### Database Passwords

```bash
# ✅ GOOD: Strong password
Password=Xk9$mP2#vL8@qR5!nW7&hT3

# ❌ BAD: Weak password
Password=postgres
```

### Connection String Security

```bash
# ✅ GOOD: Use environment variable
AUTH_DB_CONNECTION_STRING=Host=...;SslMode=Require;...

# ❌ BAD: Hardcoded in appsettings.json
"ConnectionStrings": {
  "AuthDb": "Host=...;Password=secret;..."
}
```

---

## 🚨 Security Incidents

If secrets are accidentally committed:

1. **Rotate immediately:**
   ```bash
   # Generate new JWT secret
   aws secretsmanager update-secret \
     --secret-id /erp-modern/prod/jwt-secret \
     --secret-string "$(openssl rand -base64 64)"
   
   # Restart ECS service
   aws ecs update-service --cluster erp-prod --service auth-api --force-new-deployment
   ```

2. **Invalidate all JWTs:**
   - Users must re-login after key rotation

3. **Remove from git history:**
   ```bash
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch .env" --prune-empty --tag-name-filter cat -- --all
   ```

---

## 📚 References

- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [AWS Secrets Manager Best Practices](https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html)
- [.NET Configuration in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/)

---

## ✅ Verification

Test your configuration:

```bash
# Should fail (no env vars)
dotnet run --project src/Modules/Auth/Auth.API

# Should succeed (with env vars)
export JWT_SECRET_KEY="test-key-min-32-chars-abcdefghijklmnop"
export AUTH_DB_CONNECTION_STRING_DEV="Host=localhost;Port=5433;Database=erp_auth;Username=postgres;Password=postgres"
dotnet run --project src/Modules/Auth/Auth.API
```

---

**Last Updated:** 2026-01-03  
**Version:** 1.0.0
