# Access Control Architecture – AI Agent Platform

## Explanation for the Bank Teller at the Counter

Mrs. Marta has worked at a bank branch in Brno for 20 years.

She arrives at work in the morning, enters her password at the computer — the system knows it's her.
Her screen opens showing **only her clients** from the Brno branch.
Prague is not there. Her colleagues' payslips are not there. Audit logs are not there.

Now the bank has a new assistant — an **AI agent**. Mrs. Marta can ask it:
`"How many transactions did I process today?"`

The AI agent queries the system — and the system gives it **exactly the same data that Mrs. Marta would see on her screen**.
Nothing more. Nothing less.

The branch director, Mr. Novák, can ask:
`"What was the branch turnover this week?"`

The AI agent will respond — but will show **the entire Brno branch**, because Mr. Novák has that right.
But it won't show him Prague either. That's a different branch.

**Key idea:** The AI agent is like a new smart colleague.
It sees exactly what the system allows it to — no more, even if you ask it very cleverly.

---

## Explanation for a Small Child

Imagine a school cafeteria.

Every pupil gets a **card** with their name and class written on it.
The cafeteria lady looks at the card and gives them **only what belongs to them** — their lunch, not their classmate's.

Our system works the same way:

- **card** = login (who you are)
- **cafeteria lady** = backend (what you are allowed to see)
- **lunch** = data from the database
- **AI agent** = a friend you show your card to — but they only get your lunch, not the whole school's

The cafeteria lady **never** hands out the entire pot. Always only what belongs to that particular pupil.

---

## The Problem

Same agent, same query:

```text
"Show me transactions for this month"

Teller       → sees only their own clients from Brno
Manager      → sees the entire Brno branch
Risk Analyst → sees all transactions, but without client names
```

---

# Database Relationship Schema

```
┌─────────────────┐       ┌─────────────────┐
│  organizations  │       │   departments   │
│─────────────────│       │─────────────────│
│ id (PK)         │◄──┐   │ id (PK)         │
│ name            │   │   │ organization_id │──►organizations
│ slug            │   │   │ name            │
└─────────────────┘   │   └─────────────────┘
                       │            ▲
                       │            │
                  ┌────┴────────────┴───┐
                  │        users        │
                  │─────────────────────│
                  │ id (PK)             │
                  │ organization_id (FK)│
                  │ department_id (FK)  │
                  │ email               │
                  │ full_name           │
                  │ password_hash       │
                  │ is_active           │
                  └──────────┬──────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
     ┌────────────┐  ┌─────────────┐  ┌──────────────────┐
     │ user_roles │  │conversations│  │  data_access_rules│
     │────────────│  │─────────────│  │──────────────────│
     │ user_id(FK)│  │ user_id (FK)│  │ subject_type     │
     │ role_id(FK)│  │ agent_id(FK)│  │ subject_id       │
     └─────┬──────┘  └──────┬──────┘  │ resource_type    │
           │                │         │ resource_id      │
           ▼                ▼         │ access_level     │
     ┌──────────┐    ┌────────────┐   │ row_filter (JSON)│
     │  roles   │    │ agent_runs │   │ col_filter (JSON)│
     │──────────│    │────────────│   │ priority         │
     │ id (PK)  │    │ question   │   └──────────────────┘
     │ name     │    │ answer     │
     └────┬─────┘    │ status     │
          │          └─────┬──────┘
          ▼                ▼
  ┌──────────────┐  ┌───────────────────┐
  │role_perms    │  │  agent_run_steps  │
  │──────────────│  │───────────────────│
  │ role_id (FK) │  │ step_order        │
  │ perm_id (FK) │  │ tool_name         │
  └──────┬───────┘  │ input  (JSON)     │
         │          │ output (JSON)     │
         ▼          └───────────────────┘
  ┌─────────────┐
  │ permissions │
  │─────────────│
  │ id (PK)     │
  │ code        │   ← agents.run, documents.read...
  │ description │
  └─────────────┘
```

---

## Data Sources Schema

```
┌──────────────────┐       ┌───────────────┐
│   data_sources   │       │   documents   │
│──────────────────│       │───────────────│
│ id (PK)          │◄──────│ data_source_id│
│ organization_id  │       │ title         │
│ name             │       │ file_name     │
│ type             │       │ content_type  │
│ connection_config│       │ storage_path  │
│ is_active        │       │ metadata      │
└──────────────────┘       └───────────────┘
         ▲
         │
┌────────┴─────────┐
│ data_access_rules│  ← links users/roles with data sources
│──────────────────│
│ subject (user/   │
│         role)    │
│ resource         │
│ row_filter       │
│ column_filter    │
└──────────────────┘
```

---

## Access Control Flow Schema

```
 REQUEST
    │
    ▼
┌───────────┐   no    ┌──────────┐
│ Auth OK?  │────────►│  401     │
└─────┬─────┘         └──────────┘
      │ yes
      ▼
┌───────────────┐  no  ┌──────────┐
│ agents.run    │──────►│  403     │
│ permission?   │       └──────────┘
└──────┬────────┘
       │ yes
       ▼
┌───────────────────┐  no  ┌──────────┐
│ data_source rule  │──────►│  403     │
│ exists?           │       └──────────┘
└────────┬──────────┘
         │ yes
         ▼
┌──────────────────────┐
│ apply row_filter     │  WHERE branch_id = 'brno_01'
│ apply column_filter  │  EXCLUDE salary, ssn
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ filtered data → LLM  │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ audit_log write      │
└──────────────────────┘
```

---

# Three Levels of Control

## Level 1 — Is the user allowed to use the agent at all?

```text
user → user_roles → roles → role_permissions → permissions
                                                    ↓
                                              agents.run ?
```

Simple RBAC check before anything else.

---

## Level 2 — Is the user allowed to access this data source?

```sql
data_access_rules
  subject_type  = 'user' | 'role'
  subject_id    = user.id | role.id
  resource_type = 'data_source' | 'table' | 'document'
  resource_id   = data_sources.id
  access_level  = 'read' | 'write' | 'none'
```

Teller has no rule for the HR data_source → access denied.

---

## Level 3 — Which specific data does the user see?

```sql
data_access_rules
  row_filter    = {"branch_id": "brno_01"}
  column_filter = {"exclude": ["salary", "ssn", "account_number"]}
```

This is translated into SQL conditions **before** the data is sent to the LLM.

---

# How the Backend Applies This in Practice

```python
# 1. Retrieve rules for this user
rules = get_access_rules(user_id, data_source_id)

# 2. Build a safe SQL query
query = base_query
if rules.row_filter:
    query = query.where(branch_id == user.branch_id)
if rules.column_filter:
    query = query.exclude_columns(rules.column_filter)

# 3. ONLY NOW send the data to the LLM
context = query.fetch()
llm.ask(context, user_question)
```

The LLM never sees an unfiltered query — it only receives ready, trimmed data.

---

# The Key Table `data_access_rules`

```sql
CREATE TABLE data_access_rules (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id),

    -- who
    subject_type    TEXT NOT NULL,  -- 'user' or 'role'
    subject_id      UUID NOT NULL,

    -- what
    resource_type   TEXT NOT NULL,  -- 'data_source', 'table', 'document'
    resource_id     UUID NOT NULL,

    -- how
    access_level    TEXT NOT NULL,  -- 'read', 'write', 'none'
    row_filter      JSONB,          -- {"branch_id": "brno_01"}
    column_filter   JSONB,          -- {"exclude": ["salary"]}

    priority        INT DEFAULT 0,  -- higher number = stronger rule

    created_at      TIMESTAMP DEFAULT now()
);
```

---

# Rule Hierarchy

```text
More specific rule always wins:

role=MANAGER    → sees the entire branch
user=jan.novak  → specially restricted to risk data only

Jan Novak receives the intersection of both rules.
```

The `priority` column resolves conflicts — higher number wins.

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

Every query must log what the LLM actually received:

```json
{
  "user_id": "jan.novak",
  "action": "agent_query",
  "data_source": "transactions_db",
  "applied_filters": {
    "row_filter": {"branch_id": "brno_01"},
    "column_filter": {"excluded": ["salary"]}
  },
  "prompt": "Show me transactions for this month",
  "rows_returned": 47
}
```

The compliance team sees exactly — what the LLM received, not just that someone asked.

```sql
CREATE TABLE audit_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id),
    user_id         UUID REFERENCES users(id),
    action          TEXT NOT NULL,
    entity_type     TEXT,
    entity_id       UUID,
    details         JSONB,
    created_at      TIMESTAMP DEFAULT now()
);
```

---

# Overall Flow

```text
User asks AI Agent
        ↓
Backend authenticates user
        ↓
RBAC check — is the user allowed to use the agent? (level 1)
        ↓
Data source check — is the user allowed to access the source? (level 2)
        ↓
Row + column filtering — which exact data? (level 3)
        ↓
Filtered data → LLM
        ↓
Audit log — what it received, what it returned
        ↓
Response returned to user
```

---

# Employee Simulation and Their Access to the Agent

Scenario: Banka Morava a.s., Brno branch and Prague branch.
Agent: **FinanceBot** — answers questions about transactions, clients, and reports.

---

## Employee 1 — Jana Nováková, Teller, Brno

```json
{
  "user_id": "jana.novakova",
  "organization_id": "banka_morava",
  "department": "retail",
  "role": "TELLER",
  "branch_id": "brno_01"
}
```

**Permissions:**
```text
agents.run          ✓
documents.read      ✓
analytics.read      ✗
users.manage        ✗
audit.read          ✗
```

**Data access rules:**
```text
data_source: transactions_db
  row_filter:    { "branch_id": "brno_01", "assigned_teller": "jana.novakova" }
  column_filter: { "exclude": ["internal_score", "fraud_flag"] }
  access_level:  read
```

**Query to agent:** `"How many transactions were processed today?"`

**What the agent receives:**
```sql
SELECT COUNT(*) FROM transactions
WHERE branch_id = 'brno_01'
  AND assigned_teller = 'jana.novakova'
  AND date = TODAY;
-- result: 12 transactions (her clients only)
```

**What the agent responds:**
```
You processed 12 transactions today.
```

**What the agent will NOT respond** (no data):
```
The entire Brno branch processed 847 transactions today.  ✗
```

---

## Employee 2 — Pavel Horák, Branch Manager, Brno

```json
{
  "user_id": "pavel.horak",
  "organization_id": "banka_morava",
  "department": "management",
  "role": "MANAGER",
  "branch_id": "brno_01"
}
```

**Permissions:**
```text
agents.run          ✓
documents.read      ✓
analytics.read      ✓
users.manage        ✗  ← cannot manage HR
audit.read          ✗  ← cannot see audit logs
```

**Data access rules:**
```text
data_source: transactions_db
  row_filter:    { "branch_id": "brno_01" }
  column_filter: { "exclude": ["fraud_flag"] }
  access_level:  read

data_source: analytics_db
  row_filter:    { "branch_id": "brno_01" }
  access_level:  read
```

**Query to agent:** `"What was the branch turnover this week?"`

**What the agent receives:**
```sql
SELECT SUM(amount) FROM transactions
WHERE branch_id = 'brno_01'
  AND date >= THIS_WEEK;
-- result: 4,200,000 CZK (entire Brno branch)
```

**What the agent will NOT respond** (different branch):
```
Prague this week: 6,800,000 CZK  ✗
```

---

## Employee 3 — Martina Křížková, HR Specialist

```json
{
  "user_id": "martina.krizkova",
  "organization_id": "banka_morava",
  "department": "hr",
  "role": "HR",
  "branch_id": null
}
```

**Permissions:**
```text
agents.run          ✓
documents.read      ✓  ← HR documents only
analytics.read      ✗
users.manage        ✓  ← HR records only
audit.read          ✗
```

**Data access rules:**
```text
data_source: hr_db
  row_filter:    {}              ← sees all employees
  column_filter: {}              ← full HR access
  access_level:  read

data_source: transactions_db
  access_level:  none            ← no access to transactions
```

**Query to agent:** `"How many employees joined this year?"`

**What the agent receives:**
```sql
SELECT COUNT(*) FROM employees
WHERE hire_date >= '2026-01-01';
-- result: 23 new employees
```

**Query to agent:** `"What was the Prague branch turnover?"`

**What the agent responds:**
```
You do not have access to this query.
```

---

## Employee 4 — Tomáš Veselý, Risk Analyst

```json
{
  "user_id": "tomas.vesely",
  "organization_id": "banka_morava",
  "department": "risk",
  "role": "RISK_ANALYST",
  "branch_id": null
}
```

**Permissions:**
```text
agents.run          ✓
documents.read      ✓
analytics.read      ✓  ← all branches
risk.read           ✓
audit.read          ✗  ← still no
```

**Data access rules:**
```text
data_source: transactions_db
  row_filter:    {}                         ← all branches
  column_filter: { "exclude": ["client_name", "client_id", "iban"] }
  access_level:  read
```

**Query to agent:** `"Which transactions are suspicious?"`

**What the agent receives:**
```sql
SELECT amount, type, fraud_flag, branch_id
FROM transactions
WHERE fraud_flag = true;
-- WITHOUT client names, WITHOUT IBAN
```

**What the agent responds:**
```
7 suspicious transactions found.
Brno branch: 3, Prague: 4.
Average amount: 280,000 CZK.
(Client names are not available.)
```

---

## Employee 5 — System Admin

```json
{
  "user_id": "admin.system",
  "organization_id": "banka_morava",
  "role": "ADMIN"
}
```

**Permissions:**
```text
agents.run          ✓
agents.write        ✓  ← can configure agents
users.manage        ✓
audit.read          ✓
analytics.read      ✓
```

**Data access rules:**
```text
All data_sources: access_level = read (full access)
No row_filter or column_filter
```

**Note:** Admin can view data — but does not perform banking operations.
The principle of least privilege applies to admins as well.

---

## Comparison Table — Same Query, Different Responses

Query: `"How many transactions were processed this week?"`

| Employee | Role | Sees |
|---|---|---|
| Jana Nováková | Teller | only her transactions (12) |
| Pavel Horák | Manager | entire Brno branch (847) |
| Martina Křížková | HR | `403 – access denied` |
| Tomáš Veselý | Risk Analyst | all branches, without names (2,341) |
| Admin | Admin | everything (2,341 + details) |

---

## Seed Data for Testing

```sql
-- Organization
INSERT INTO organizations (id, name, slug)
VALUES ('org-001', 'Banka Morava a.s.', 'banka-morava');

-- Roles
INSERT INTO roles (id, name) VALUES
  ('role-teller',   'TELLER'),
  ('role-manager',  'MANAGER'),
  ('role-hr',       'HR'),
  ('role-risk',     'RISK_ANALYST'),
  ('role-admin',    'ADMIN');

-- Users
INSERT INTO users (id, organization_id, email, full_name) VALUES
  ('u-001', 'org-001', 'jana.novakova@banka-morava.cz',  'Jana Nováková'),
  ('u-002', 'org-001', 'pavel.horak@banka-morava.cz',    'Pavel Horák'),
  ('u-003', 'org-001', 'martina.krizkova@banka-morava.cz','Martina Křížková'),
  ('u-004', 'org-001', 'tomas.vesely@banka-morava.cz',   'Tomáš Veselý'),
  ('u-005', 'org-001', 'admin@banka-morava.cz',          'System Admin');

-- Role assignments
INSERT INTO user_roles (user_id, role_id) VALUES
  ('u-001', 'role-teller'),
  ('u-002', 'role-manager'),
  ('u-003', 'role-hr'),
  ('u-004', 'role-risk'),
  ('u-005', 'role-admin');

-- Data access rules
INSERT INTO data_access_rules
  (organization_id, subject_type, subject_id, resource_type, resource_id, access_level, row_filter, column_filter)
VALUES
  -- Jana: her transactions only
  ('org-001', 'user', 'u-001', 'data_source', 'ds-transactions', 'read',
   '{"branch_id": "brno_01", "assigned_teller": "u-001"}',
   '{"exclude": ["internal_score", "fraud_flag"]}'),

  -- Manager role: entire branch (applied via role)
  ('org-001', 'role', 'role-manager', 'data_source', 'ds-transactions', 'read',
   '{"branch_id": "{{user.branch_id}}"}',
   '{"exclude": ["fraud_flag"]}'),

  -- HR: HR database only
  ('org-001', 'role', 'role-hr', 'data_source', 'ds-hr', 'read', '{}', '{}'),

  -- Risk Analyst: everything, but without PII
  ('org-001', 'role', 'role-risk', 'data_source', 'ds-transactions', 'read',
   '{}',
   '{"exclude": ["client_name", "client_id", "iban"]}'),

  -- Admin: full access
  ('org-001', 'role', 'role-admin', 'data_source', 'ds-transactions', 'read', '{}', '{}'),
  ('org-001', 'role', 'role-admin', 'data_source', 'ds-hr',           'read', '{}', '{}');
```

---

# Key Principle

```text
Access control must happen BEFORE the LLM receives the data.
```

The LLM is not a trusted entity — it is the output layer, not the decision-making layer.
