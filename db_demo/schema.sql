-- ============================================================
-- Private AI Agent Platform – Database Schema
-- ============================================================

-- ORGANIZATIONS
CREATE TABLE organizations (
    id          TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    slug        TEXT UNIQUE NOT NULL,
    created_at  TIMESTAMP DEFAULT now()
);

-- DEPARTMENTS
CREATE TABLE departments (
    id              TEXT PRIMARY KEY,
    organization_id TEXT REFERENCES organizations(id),
    name            TEXT NOT NULL
);

-- USERS
CREATE TABLE users (
    id              TEXT PRIMARY KEY,
    organization_id TEXT REFERENCES organizations(id),
    department_id   TEXT REFERENCES departments(id),
    email           TEXT UNIQUE NOT NULL,
    full_name       TEXT,
    branch_id       TEXT,
    region_id       TEXT,
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMP DEFAULT now()
);

-- ROLES
CREATE TABLE roles (
    id          TEXT PRIMARY KEY,
    name        TEXT UNIQUE NOT NULL,
    description TEXT
);

-- PERMISSIONS
CREATE TABLE permissions (
    id          TEXT PRIMARY KEY,
    code        TEXT UNIQUE NOT NULL,
    description TEXT
);

-- USER <-> ROLES
CREATE TABLE user_roles (
    user_id TEXT REFERENCES users(id),
    role_id TEXT REFERENCES roles(id),
    PRIMARY KEY (user_id, role_id)
);

-- ROLE <-> PERMISSIONS
CREATE TABLE role_permissions (
    role_id       TEXT REFERENCES roles(id),
    permission_id TEXT REFERENCES permissions(id),
    PRIMARY KEY (role_id, permission_id)
);

-- AGENTS
CREATE TABLE agents (
    id              TEXT PRIMARY KEY,
    organization_id TEXT REFERENCES organizations(id),
    name            TEXT NOT NULL,
    description     TEXT,
    system_prompt   TEXT,
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMP DEFAULT now()
);

-- DATA SOURCES
CREATE TABLE data_sources (
    id              TEXT PRIMARY KEY,
    organization_id TEXT REFERENCES organizations(id),
    name            TEXT NOT NULL,
    type            TEXT NOT NULL,
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMP DEFAULT now()
);

-- DATA ACCESS RULES
CREATE TABLE data_access_rules (
    id              TEXT PRIMARY KEY,
    organization_id TEXT REFERENCES organizations(id),
    subject_type    TEXT NOT NULL,   -- 'user' nebo 'role'
    subject_id      TEXT NOT NULL,
    resource_type   TEXT NOT NULL,   -- 'data_source'
    resource_id     TEXT NOT NULL,
    access_level    TEXT NOT NULL,   -- 'read', 'write', 'none'
    row_filter      JSONB,
    column_filter   JSONB,
    priority        INT DEFAULT 0,
    created_at      TIMESTAMP DEFAULT now()
);

-- CONVERSATIONS
CREATE TABLE conversations (
    id              TEXT PRIMARY KEY,
    organization_id TEXT REFERENCES organizations(id),
    user_id         TEXT REFERENCES users(id),
    agent_id        TEXT REFERENCES agents(id),
    title           TEXT,
    created_at      TIMESTAMP DEFAULT now()
);

-- AGENT RUNS
CREATE TABLE agent_runs (
    id              TEXT PRIMARY KEY,
    conversation_id TEXT REFERENCES conversations(id),
    user_id         TEXT REFERENCES users(id),
    agent_id        TEXT REFERENCES agents(id),
    question        TEXT NOT NULL,
    answer          TEXT,
    status          TEXT DEFAULT 'completed',
    created_at      TIMESTAMP DEFAULT now()
);

-- AUDIT LOGS
CREATE TABLE audit_logs (
    id              TEXT PRIMARY KEY,
    organization_id TEXT REFERENCES organizations(id),
    user_id         TEXT REFERENCES users(id),
    action          TEXT NOT NULL,
    entity_type     TEXT,
    entity_id       TEXT,
    details         JSONB,
    created_at      TIMESTAMP DEFAULT now()
);
