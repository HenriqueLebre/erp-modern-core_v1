-- ==================================
-- PostgreSQL Initialization Script
-- ==================================
-- This script runs automatically when the container starts

-- Ensure database exists
CREATE DATABASE IF NOT EXISTS erp_auth;

-- Connect to the database
\c erp_auth;

-- Enable extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create basic schema (EF Core will handle migrations)
-- This is just to ensure the database is ready

-- Log successful initialization
SELECT 'Database erp_auth initialized successfully!' AS status;
