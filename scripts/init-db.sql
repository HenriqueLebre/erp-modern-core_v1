-- ==================================
-- PostgreSQL Initialization Script
-- ==================================
-- This script runs automatically when the container starts
-- The database 'erp_auth' is already created by POSTGRES_DB env variable

-- Enable extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create basic schema (EF Core will handle migrations)
-- This is just to ensure the database is ready

-- Log successful initialization
SELECT 'Database erp_auth initialized successfully!' AS status;
