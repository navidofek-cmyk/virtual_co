# Private AI Agent Platform – Database & Access Architecture

## Goal

Design a secure multi-tenant architecture for enterprise AI agents where:

- different companies use isolated environments
- users have different roles
- managers see different data than regular employees
- AI agents only receive data that the user is allowed to access

---

# Core Principles

## 1. Authentication
Identify the user.

Examples:
- email/password
- SSO
- OAuth
- Microsoft Entra ID
- Google Workspace

---

## 2. Authorization (RBAC)
Determine what the user is allowed to do.

Examples:
- run AI agents
- manage users
- upload documents
- view analytics

---

## 3. Data Access Control
Determine which company data the user can access.

This is critical.

The AI system must NEVER receive unrestricted company data.

---

# High-Level Architecture

```text
Frontend
    ↓
FastAPI Backend
    ↓
Authentication
    ↓
RBAC / Access Validation
    ↓
Data Filtering Layer
    ↓
Langflow / Agent Orchestrator
    ↓
LLM
```

---

# Important Security Principle

```text
Access control must happen BEFORE the LLM receives the data.
```

Managers and employees may use the same AI agent,
but the backend provides different data context depending on:

- role
- department
- permissions
- access rules

---

# Main Entities

## Organization
Represents a customer/company.

Examples:
- steel company
- bank
- manufacturing company

---

## Department

Examples:
- HR
- Finance
- Production
- Sales
- Engineering

---

## User

Represents a company employee.

---

## Role

Examples:
- SUPER_ADMIN
- ORG_ADMIN
- MANAGER
- EMPLOYEE
- VIEWER

---

## Permission

Examples:

```text
agents.run
agents.write
documents.read
documents.write
users.manage
audit.read
```

---

## Data Source

Represents company systems.

Examples:
- PostgreSQL
- SharePoint
- PDFs
- Emails
- APIs
- CSV files

---

## Data Resource

Represents specific accessible data.

Examples:
- table
- document
- folder
- API endpoint

---

# Recommended Database Schema

## organizations

```sql
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);
```

---

## departments

```sql
CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id),
    name TEXT NOT NULL
);
```

---

## users

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    organization_id UUID REFERENCES organizations(id),
    department_id UUID REFERENCES departments(id),

    email TEXT UNIQUE NOT NULL,
    full_name TEXT,

    password_hash TEXT,

    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMP DEFAULT now()
);
```

---

## roles

```sql
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    description TEXT
);
```

---

## permissions

```sql
CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    description TEXT
);
```

---

## user_roles

```sql
CREATE TABLE user_roles (
    user_id UUID REFERENCES users(id),
    role_id UUID REFERENCES roles(id),

    PRIMARY KEY(user_id, role_id)
);
```

---

## role_permissions

```sql
CREATE TABLE role_permissions (
    role_id UUID REFERENCES roles(id),
    permission_id UUID REFERENCES permissions(id),

    PRIMARY KEY(role_id, permission_id)
);
```

---

# AI Agents

## agents

```sql
CREATE TABLE agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    organization_id UUID REFERENCES organizations(id),

    name TEXT NOT NULL,
    description TEXT,

    langflow_flow_id TEXT,

    system_prompt TEXT,

    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMP DEFAULT now()
);
```

---

# Data Sources

## data_sources

```sql
CREATE TABLE data_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    organization_id UUID REFERENCES organizations(id),

    name TEXT NOT NULL,

    type TEXT NOT NULL,

    connection_config JSONB,

    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMP DEFAULT now()
);
```

---

# Documents

## documents

```sql
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    organization_id UUID REFERENCES organizations(id),

    data_source_id UUID REFERENCES data_sources(id),

    title TEXT,

    file_name TEXT,

    content_type TEXT,

    storage_path TEXT,

    metadata JSONB,

    created_at TIMESTAMP DEFAULT now()
);
```

---

# Conversations & Agent Runs

## conversations

```sql
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    organization_id UUID REFERENCES organizations(id),

    user_id UUID REFERENCES users(id),

    agent_id UUID REFERENCES agents(id),

    title TEXT,

    created_at TIMESTAMP DEFAULT now()
);
```

---

## agent_runs

```sql
CREATE TABLE agent_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    conversation_id UUID REFERENCES conversations(id),

    user_id UUID REFERENCES users(id),

    agent_id UUID REFERENCES agents(id),

    question TEXT NOT NULL,

    answer TEXT,

    status TEXT DEFAULT 'completed',

    error_message TEXT,

    created_at TIMESTAMP DEFAULT now()
);
```

---

# Agent Execution Steps

## agent_run_steps

```sql
CREATE TABLE agent_run_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    agent_run_id UUID REFERENCES agent_runs(id),

    step_order INT,

    step_type TEXT,

    tool_name TEXT,

    input JSONB,

    output JSONB,

    created_at TIMESTAMP DEFAULT now()
);
```

---

# Data Access Layer

## data_access_rules

```sql
CREATE TABLE data_access_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    organization_id UUID REFERENCES organizations(id),

    subject_type TEXT NOT NULL,
    subject_id UUID NOT NULL,

    resource_type TEXT NOT NULL,
    resource_id UUID NOT NULL,

    access_level TEXT NOT NULL,

    row_filter JSONB,
    column_filter JSONB,

    created_at TIMESTAMP DEFAULT now()
);
```

---

# Example Visibility Matrix

| Role | Sales Data | HR Data | Finance Data |
|---|---|---|---|
| Employee | Partial | No | No |
| Manager | Yes | Partial | Partial |
| HR | No | Full | No |
| Admin | Full | Full | Full |

---

# Audit Logging

## audit_logs

```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    organization_id UUID REFERENCES organizations(id),

    user_id UUID REFERENCES users(id),

    action TEXT NOT NULL,

    entity_type TEXT,

    entity_id UUID,

    details JSONB,

    created_at TIMESTAMP DEFAULT now()
);
```

---

# Final Concept

```text
User asks AI Agent
        ↓
Backend authenticates user
        ↓
RBAC validation
        ↓
Data access filtering
        ↓
Only allowed data is passed to AI
        ↓
LLM generates response
        ↓
Response returned to user
```

---

# Key Enterprise Principle

```text
The AI model must never receive unrestricted company data.
```
