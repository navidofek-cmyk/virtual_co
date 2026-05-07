# Virtual Co – Private AI Agent Platform

A secure multi-tenant platform for AI agents in enterprise environments.
Demonstrates how to properly implement access control **before** the LLM receives any data.

---

## What is it

Companies want AI, but fear data exposure. This platform ensures every employee sees exactly the data they are authorized to see — nothing more.

```
Bank teller      → sees only their own clients
Branch manager   → sees the entire branch
Risk analyst     → sees everything, but without client names
HR               → sees employees, not transactions
```

---

## Architecture

```
User
    ↓
CLI / Browser
    ↓
FastAPI  (auth → RBAC → data filtering)
    ↓
Agent loop  (Claude decides which tools to call)
    ↓
claude -p  (Max subscription, no API key required)
    ↓
Response saved to DB (conversations + agent_runs)
```

---

## Quick Start

### Requirements
- Docker
- Python 3.12+
- [uv](https://github.com/astral-sh/uv)
- Claude Code CLI

### 1. Start the database
```bash
docker run --name virtual-co-db \
  -e POSTGRES_PASSWORD=savanah123 \
  -e POSTGRES_DB=savanah \
  -p 5432:5432 -d postgres:16
```

### 2. Create schema and seed data
```bash
docker exec -i virtual-co-db psql -U postgres -d savanah < db_demo/schema.sql
docker exec -i virtual-co-db psql -U postgres -d savanah < db_demo/schema_banking.sql
docker exec -i virtual-co-db psql -U postgres -d savanah < db_demo/seed_banka_morava.sql
docker exec -i virtual-co-db psql -U postgres -d savanah < db_demo/seed_rozsireni.sql
docker exec -i virtual-co-db psql -U postgres -d savanah < db_demo/seed_praha.sql
docker exec -i virtual-co-db psql -U postgres -d savanah < db_demo/seed_banking.sql
```

### 3. Start the API
```bash
cd api
uv sync
uv run python -m uvicorn main:app --port 8000
```

### 4. Run the CLI client
```bash
uv run python cli.py
```

### 5. Or run the agent with tools
```bash
uv run python agent.py
```

---

## Demo – Banka Morava a.s.

21 employees, 5 branches, 11 roles, 10 clients, real transactions and loans.

---

### Who has access to what

> 🟢 full access &nbsp; 🟡 partial / masked &nbsp; 🔴 denied

| Role | Clients | Accounts | Transactions | Loans | HR | Finance | Audit |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **TELLER** | 🟡 own | 🟡 masked | 🟡 limited | 🔴 | 🔴 | 🔴 | 🔴 |
| **BRANCH_MANAGER** | 🟡 branch | 🟢 branch | 🟢 branch | 🔴 | 🔴 | 🟡 branch | 🔴 |
| **REGIONAL_DIRECTOR** | 🟡 region | 🟢 region | 🟢 region | 🔴 | 🔴 | 🟡 region | 🔴 |
| **RISK_MANAGER** | 🔴 no PII | 🟡 no PII | 🟢 no PII | 🟢 scoring | 🔴 | 🔴 | 🔴 |
| **COMPLIANCE_OFFICER** | 🟡 KYC/AML | 🔴 | 🟡 suspicious | 🔴 | 🔴 | 🔴 | 🟢 |
| **HR_MANAGER** | 🔴 | 🔴 | 🔴 | 🔴 | 🟢 full | 🔴 | 🔴 |
| **HR_STAFF** | 🔴 | 🔴 | 🔴 | 🔴 | 🟡 no salary | 🔴 | 🔴 |
| **CFO** | 🔴 | 🔴 | 🔴 | 🔴 | 🔴 | 🟢 full | 🔴 |
| **CEO** | 🔴 | 🔴 | 🔴 | 🔴 | 🔴 | 🟡 aggregate | 🔴 |
| **ADMIN** | 🔴 | 🔴 | 🔴 | 🔴 | 🔴 | 🔴 | 🟢 system |

---

### What each role can see

**TELLER** (Jana Nováková, Karel Dvořák)
- ✅ Basic info about their assigned clients
- ✅ Account status (masked account number)
- ✅ Transactions of their own clients only
- ❌ National ID, full transaction history, other clients

**BRANCH_MANAGER** (Lucie Svobodová – Brno)
- ✅ All clients in their branch
- ✅ Branch reports and analytics
- ✅ Team performance overview
- ❌ Other branches, HR records, salaries

**REGIONAL_DIRECTOR** (Pavel Horák – Morava)
- ✅ Aggregated reports for the entire region
- ✅ Performance of all branches in the region
- ❌ Detailed client data, other regions

**RISK_MANAGER** (Tomáš Veselý)
- ✅ All transactions across the bank
- ✅ Fraud scores, risk profiles, loan scoring
- ❌ Client name, account number, IBAN (all masked)

**COMPLIANCE_OFFICER** (Alena Marková)
- ✅ KYC/AML client status
- ✅ Suspicious transactions for AML
- ✅ Full access to audit logs
- ❌ Regular transactions, balances

**HR_MANAGER** (Jana Procházková)
- ✅ Complete employee records including salaries
- ❌ Any client or financial data

**HR_STAFF** (Marie Kratochvílová)
- ✅ Basic HR records, attendance, contact info
- ❌ Salaries, bonuses, performance ratings

**CFO** (Martin Novák)
- ✅ Financial results for the entire bank, all branches
- ❌ Personal client or employee data

**CEO** (Petra Horáčková)
- ✅ Aggregated KPIs and financial overview
- ❌ Personal client data, detailed employee records

---

### Test accounts

| Email | Role | Location |
|---|---|---|
| jana.novakova@banka-morava.cz | TELLER | Brno centrum |
| lucie.svobodova@banka-morava.cz | BRANCH_MANAGER | Brno centrum |
| pavel.horak@banka-morava.cz | REGIONAL_DIRECTOR | Region Morava |
| tomas.vesely@banka-morava.cz | RISK_MANAGER | Headquarters |
| alena.markova@banka-morava.cz | COMPLIANCE_OFFICER | Headquarters |
| jana.prochazkova@banka-morava.cz | HR_MANAGER | Headquarters |
| marie.kratochvilova@banka-morava.cz | HR_STAFF | Headquarters |
| martin.novak@banka-morava.cz | CFO | Headquarters |
| petra.horackova@banka-morava.cz | CEO | Headquarters |

---

## Project Structure

```
virtual_co/
├── api/
│   ├── main.py                  # FastAPI backend
│   ├── cli.py                   # CLI client with conversation history
│   ├── agent.py                 # Agent loop (Claude selects tools)
│   ├── langflow_setup.py        # Creates flow in Langflow
│   └── claude_cli_component.py  # Custom Langflow component
└── db_demo/
    ├── schema.sql               # DDL – 13 core tables
    ├── schema_banking.sql       # DDL – banking tables + views
    ├── seed_banka_morava.sql    # Base seed data
    ├── seed_rozsireni.sql       # HR Staff, extended roles
    ├── seed_praha.sql           # Prague branches
    ├── seed_banking.sql         # Clients, accounts, transactions, loans
    └── schema_grafika.md        # Mermaid diagrams
```

---

## Key Principle

> Access control must happen **before** the LLM receives any data.

The LLM is not a trusted entity — it only receives safe, filtered, authorized data.

---

## Tech Stack

- **FastAPI** – backend, auth, RBAC
- **PostgreSQL** – database with access rules and banking data
- **Claude** – LLM via `claude -p` (Max subscription)
- **Langflow** – agent flow orchestration
- **uv** – Python package manager
- **Docker** – PostgreSQL + Langflow
