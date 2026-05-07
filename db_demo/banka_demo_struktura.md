# Demo Structure – Banka Morava a.s.

Simulation of a real bank for testing the Private AI Agent Platform.

---

## Organizational Structure of the Bank

```
Banka Morava a.s. (Headquarters – Prague)
│
├── Central Departments
│   ├── Risk Management
│   ├── Compliance
│   ├── HR
│   ├── Finance & Controlling
│   └── IT
│
├── Region Moravia
│   ├── Branch Brno – Centre
│   ├── Branch Brno – Královo Pole
│   └── Branch Olomouc
│
└── Region Bohemia
    ├── Branch Prague – Smíchov
    └── Branch Prague – Vinohrady
```

---

## Employees – Who They Are and What They Do

### Headquarters

| Name | Position | Department | Data Access |
|---|---|---|---|
| Ing. Petra Horáčková | CEO | Board | aggregated reports from all regions |
| Mgr. Tomáš Veselý | Risk Manager | Risk | all transactions without PII |
| JUDr. Alena Marková | Compliance Officer | Compliance | audit logs, compliance reports |
| Bc. Jana Procházková | HR Manager | HR | all employee records |
| Ing. Martin Novák | CFO | Finance | financial results from all branches |

---

### Region Moravia

| Name | Position | Branch | Data Access |
|---|---|---|---|
| Ing. Pavel Horák | Regional Director | Region Moravia | all Moravia branches |
| Bc. Lucie Svobodová | Branch Manager | Brno – Centre | entire Brno Centre branch |
| Bc. Ondřej Beneš | Branch Manager | Brno – Kr. Pole | entire Brno Kr. Pole branch |

---

### Tellers – Brno Centre

| Name | Position | Data Access |
|---|---|---|
| Jana Nováková | Teller | only their assigned clients |
| Karel Dvořák | Teller | only their assigned clients |
| Eva Blahová | Senior Teller | their client group + substitution coverage |

---

## Roles and Their Permissions

### TELLER
```text
Can:
  ✓ agents.run              – run an agent
  ✓ documents.read          – read their clients' documents
  ✓ clients.read.own        – view their assigned clients

Cannot:
  ✗ analytics.read          – no reports
  ✗ clients.read.branch     – other branch clients
  ✗ users.manage            – user management
  ✗ audit.read              – audit logs
```

### BRANCH_MANAGER
```text
Can:
  ✓ agents.run
  ✓ documents.read
  ✓ clients.read.branch     – all branch clients
  ✓ analytics.read.branch   – their branch reports
  ✓ agents.configure        – configure agents for the branch

Cannot:
  ✗ clients.read.region     – other branches
  ✗ hr.read                 – HR records
  ✗ audit.read              – audit logs
  ✗ finance.read            – financial results
```

### REGIONAL_DIRECTOR
```text
Can:
  ✓ agents.run
  ✓ analytics.read.region   – reports for the entire region
  ✓ clients.read.region     – clients across the entire region
  ✓ agents.configure

Cannot:
  ✗ hr.read
  ✗ audit.read
  ✗ finance.global
```

### RISK_MANAGER
```text
Can:
  ✓ agents.run
  ✓ risk.read               – all transactions (without client names)
  ✓ analytics.read.global   – aggregated data from all branches
  ✓ fraud.read              – fraud flags

Cannot:
  ✗ clients.read            – no names, no personal data
  ✗ hr.read
  ✗ users.manage
```

### COMPLIANCE_OFFICER
```text
Can:
  ✓ agents.run
  ✓ audit.read              – full access to audit logs
  ✓ documents.read.global   – all documents

Cannot:
  ✗ clients.read            – client personal data
  ✗ finance.read
```

### HR_MANAGER
```text
Can:
  ✓ agents.run
  ✓ hr.read                 – all employee records
  ✓ hr.write                – editing HR records
  ✓ users.manage.hr         – HR system management

Cannot:
  ✗ clients.read            – client data
  ✗ transactions.read       – transactions
  ✗ audit.read
```

### CFO
```text
Can:
  ✓ agents.run
  ✓ finance.read.global     – financial results from all branches
  ✓ analytics.read.global   – aggregated reports

Cannot:
  ✗ clients.read            – personal data
  ✗ hr.read                 – HR records
  ✗ audit.read
```

### CEO
```text
Can:
  ✓ agents.run
  ✓ analytics.read.global   – aggregated results
  ✓ finance.read.global

Cannot:
  ✗ clients.read            – client personal data
  ✗ hr.read                 – employee personal records
  ✗ audit.read              – audit is for Compliance only
```

---

## What Each Role Sees for the Same Query

Query: **"What was the turnover this month?"**

| Who is asking | What they receive |
|---|---|
| Jana Nováková (Teller) | `Access denied` |
| Lucie Svobodová (Brno Manager) | Turnover for Brno Centre branch |
| Pavel Horák (Region Moravia) | Turnover for all Moravian branches |
| Ing. Martin Novák (CFO) | Bank-wide turnover + comparison with last year |
| Ing. Petra Horáčková (CEO) | Aggregated overview of the entire bank |

---

Query: **"Who are our most valuable clients?"**

| Who is asking | What they receive |
|---|---|
| Jana Nováková (Teller) | Her assigned clients |
| Lucie Svobodová (Manager) | Top clients of the branch |
| Tomáš Veselý (Risk) | `Access denied` (Risk cannot see PII) |
| Martin Novák (CFO) | `Access denied` (CFO cannot see client data) |
| Alena Marková (Compliance) | `Access denied` |

---

## SQL Seed Data for Demo

```sql
-- Organization
INSERT INTO organizations (id, name, slug) VALUES
  ('org-bm', 'Banka Morava a.s.', 'banka-morava');

-- Departments
INSERT INTO departments (id, organization_id, name) VALUES
  ('dep-retail',      'org-bm', 'Retail Banking'),
  ('dep-risk',        'org-bm', 'Risk Management'),
  ('dep-compliance',  'org-bm', 'Compliance'),
  ('dep-hr',          'org-bm', 'Human Resources'),
  ('dep-finance',     'org-bm', 'Finance & Controlling'),
  ('dep-it',          'org-bm', 'IT'),
  ('dep-mgmt',        'org-bm', 'Management');

-- Roles
INSERT INTO roles (id, name, description) VALUES
  ('role-teller',    'TELLER',             'Teller'),
  ('role-sr-teller', 'SENIOR_TELLER',      'Senior Teller'),
  ('role-manager',   'BRANCH_MANAGER',     'Branch Manager'),
  ('role-regional',  'REGIONAL_DIRECTOR',  'Regional Director'),
  ('role-risk',      'RISK_MANAGER',       'Risk Manager'),
  ('role-compliance','COMPLIANCE_OFFICER', 'Compliance Officer'),
  ('role-hr',        'HR_MANAGER',         'HR Manager'),
  ('role-cfo',       'CFO',               'Chief Financial Officer'),
  ('role-ceo',       'CEO',               'Chief Executive Officer'),
  ('role-admin',     'ADMIN',             'System Administrator');

-- Users
INSERT INTO users (id, organization_id, department_id, email, full_name) VALUES
  ('u-novakova',  'org-bm', 'dep-retail',     'jana.novakova@banka-morava.cz',    'Jana Nováková'),
  ('u-dvorak',    'org-bm', 'dep-retail',     'karel.dvorak@banka-morava.cz',     'Karel Dvořák'),
  ('u-blahova',   'org-bm', 'dep-retail',     'eva.blahova@banka-morava.cz',      'Eva Blahová'),
  ('u-svobodova', 'org-bm', 'dep-mgmt',       'lucie.svobodova@banka-morava.cz',  'Lucie Svobodová'),
  ('u-horak',     'org-bm', 'dep-mgmt',       'pavel.horak@banka-morava.cz',      'Pavel Horák'),
  ('u-vesely',    'org-bm', 'dep-risk',       'tomas.vesely@banka-morava.cz',     'Tomáš Veselý'),
  ('u-markova',   'org-bm', 'dep-compliance', 'alena.markova@banka-morava.cz',    'Alena Marková'),
  ('u-prochazkova','org-bm', 'dep-hr',        'jana.prochazkova@banka-morava.cz', 'Jana Procházková'),
  ('u-novak-m',   'org-bm', 'dep-finance',    'martin.novak@banka-morava.cz',     'Martin Novák'),
  ('u-horackova', 'org-bm', 'dep-mgmt',       'petra.horackova@banka-morava.cz',  'Petra Horáčková');

-- Role assignments
INSERT INTO user_roles (user_id, role_id) VALUES
  ('u-novakova',   'role-teller'),
  ('u-dvorak',     'role-teller'),
  ('u-blahova',    'role-sr-teller'),
  ('u-svobodova',  'role-manager'),
  ('u-horak',      'role-regional'),
  ('u-vesely',     'role-risk'),
  ('u-markova',    'role-compliance'),
  ('u-prochazkova','role-hr'),
  ('u-novak-m',    'role-cfo'),
  ('u-horackova',  'role-ceo');

-- Data sources
INSERT INTO data_sources (id, organization_id, name, type) VALUES
  ('ds-transactions', 'org-bm', 'Transaction Database', 'postgresql'),
  ('ds-clients',      'org-bm', 'Client Database',      'postgresql'),
  ('ds-hr',           'org-bm', 'HR System',            'postgresql'),
  ('ds-finance',      'org-bm', 'Financial System',     'postgresql'),
  ('ds-documents',    'org-bm', 'Document Server',      'sharepoint');

-- Data access rules
INSERT INTO data_access_rules
  (organization_id, subject_type, subject_id, resource_type, resource_id, access_level, row_filter, column_filter)
VALUES
  -- Teller: only their own clients, without sensitive columns
  ('org-bm', 'role', 'role-teller', 'data_source', 'ds-transactions', 'read',
   '{"assigned_teller": "{{user.id}}", "branch_id": "{{user.branch_id}}"}',
   '{"exclude": ["internal_score", "fraud_flag", "account_balance_total"]}'),

  -- Branch Manager: entire branch
  ('org-bm', 'role', 'role-manager', 'data_source', 'ds-transactions', 'read',
   '{"branch_id": "{{user.branch_id}}"}',
   '{"exclude": ["fraud_flag"]}'),

  ('org-bm', 'role', 'role-manager', 'data_source', 'ds-clients', 'read',
   '{"branch_id": "{{user.branch_id}}"}',
   '{}'),

  -- Regional Director: entire region
  ('org-bm', 'role', 'role-regional', 'data_source', 'ds-transactions', 'read',
   '{"region_id": "{{user.region_id}}"}',
   '{"exclude": ["fraud_flag"]}'),

  -- Risk Manager: everything, but without PII
  ('org-bm', 'role', 'role-risk', 'data_source', 'ds-transactions', 'read',
   '{}',
   '{"exclude": ["client_name", "client_id", "iban", "birth_number"]}'),

  -- Compliance: audit logs only
  ('org-bm', 'role', 'role-compliance', 'data_source', 'ds-documents', 'read',
   '{}', '{}'),

  -- HR: HR system only
  ('org-bm', 'role', 'role-hr', 'data_source', 'ds-hr', 'read',
   '{}', '{}'),

  -- CFO: finance
  ('org-bm', 'role', 'role-cfo', 'data_source', 'ds-finance', 'read',
   '{}', '{}'),

  -- CEO: aggregated reports (finance + analytics, without personal data)
  ('org-bm', 'role', 'role-ceo', 'data_source', 'ds-finance', 'read',
   '{}', '{"exclude": ["employee_salary", "client_name"]}');
```

---

## The Bank Agent – What It Can Do

```text
FinanceBot
│
├── Tools
│   ├── query_transactions   – query transactions
│   ├── query_clients        – query clients
│   ├── generate_report      – generate a report
│   ├── search_documents     – search documents
│   └── query_analytics      – analytical queries
│
└── What the agent returns depends on who is asking
    → the backend applies data_access_rules BEFORE
      the agent receives any data
```

---

## Summary

```text
One bank.
10 employees.
10 different views of the data.
1 agent.

Everyone gets exactly what they are entitled to.
Nothing more.
```
