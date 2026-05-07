# Banking Enterprise AI Agent Architecture

## Goal

Design a secure enterprise AI architecture for banking and highly regulated environments.

The AI system must:
- support multiple user roles
- isolate departments and branches
- protect sensitive data
- enforce strict access rules
- audit all operations
- prevent unrestricted AI access to production systems

---

# Core Principle

```text
The LLM must never directly access unrestricted production data.
```

The backend is responsible for:
- authentication
- authorization
- policy enforcement
- data filtering
- audit logging

before any data is sent to the AI model.

---

# High-Level Enterprise Architecture

```text
User
↓
Frontend
↓
FastAPI Backend
↓
Authentication
↓
Policy Engine
↓
Data Filtering Layer
↓
Tool Access Validation
↓
Prompt Context Builder
↓
Langflow / Agent Orchestrator
↓
LLM
↓
Audit Logging
↓
Response
```

---

# Authentication Layer

Recommended:
- SSO
- MFA
- Active Directory
- Azure AD
- Smart Cards

---

# Identity Context

Every request should contain:

```json
{
  "user_id": "123",
  "organization_id": "bank_01",
  "department": "risk",
  "role": "manager",
  "branch_id": "brno_01"
}
```

---

# Role Examples

| Role | Access |
|---|---|
| Teller | own clients |
| Branch Manager | branch analytics |
| Risk Analyst | risk systems |
| HR | HR records |
| Compliance | audit logs |
| Admin | technical management |
| AI Admin | AI configuration |
| Executive | aggregated reports |

---

# Important Rule

Managers must NOT automatically see everything.

Example:
- Branch manager
    - cannot access HR data
    - cannot access another branch
    - cannot access security audit logs

---

# RBAC + Data Scope Model

## Authentication

```text
Who are you?
```

---

## Authorization

```text
What are you allowed to do?
```

---

## Data Scope

```text
Which data are you allowed to see?
```

---

# Example Permission Codes

```text
agents.run
agents.write

documents.read
documents.write

users.manage

audit.read

analytics.read

risk.read
```

---

# Policy Engine

The backend must validate rules such as:

```text
Can user X access datasource Y
for customer Z?
```

Recommended technologies:
- Open Policy Agent (OPA)
- ABAC
- RBAC

---

# Data Filtering Layer

Filtering must happen BEFORE the AI receives data.

---

# Correct Approach

```text
Production DB
↓
Sanitized API / Service Layer
↓
Filtered Dataset
↓
AI Agent
↓
LLM
```

---

# Incorrect Approach

```text
LLM
↓
Direct access to production database
```

---

# Example SQL Filtering

## Correct

```sql
SELECT *
FROM transactions
WHERE branch_id = current_user.branch_id;
```

---

## Incorrect

```sql
SELECT *
FROM transactions;
```

---

# Prompt Context Builder

The backend prepares a secure context for the AI.

Example:

```text
Allowed documents
+
Allowed database rows
+
Allowed tools
```

Only after filtering:
- context is generated
- data is sent to the LLM

---

# Tool Restrictions

## Employee

Allowed:
- document search
- summarization

Not allowed:
- analytics
- administration

---

## Manager

Allowed:
- analytics
- reporting
- team data

---

## Admin

Allowed:
- datasource management
- user management
- AI configuration

---

# Audit Logging

Every operation must be logged.

---

## audit_logs

Must contain:

```text
who
when
what
which datasource
which records
which prompt
which answer
```

---

# Recommended Database Entities

```text
organizations
departments
users
roles
permissions
user_roles
role_permissions

agents
data_sources
documents

conversations
agent_runs
agent_run_steps

data_access_rules

audit_logs
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

# Enterprise Security Principle

```text
Access control must happen BEFORE the LLM receives the data.
```

This is one of the most important principles of enterprise AI systems.

---

# Final Enterprise Flow

```text
User asks AI Agent
        ↓
Backend authenticates user
        ↓
RBAC validation
        ↓
Policy Engine validation
        ↓
Data access filtering
        ↓
Tool access validation
        ↓
Safe context generation
        ↓
LLM request
        ↓
Audit logging
        ↓
Response returned
```

---

# Final Concept

The AI model itself should not be trusted with unrestricted access.

The backend architecture is responsible for:
- security
- governance
- filtering
- compliance
- isolation
- auditability

The AI model should only receive:
- safe
- filtered
- authorized
data.
