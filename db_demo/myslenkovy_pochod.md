# Thought Process – Private AI Agent Platform

---

## Where We Start From (from the meeting with Jirka)

Jirka put it simply:

```text
Companies will have their own databases, documentation, emails.
We will connect to them.
But at the same time we need our own database —
where we know who is logged in, what permissions they have, what they are allowed to do.
```

---

## Two Worlds in One System

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│   OUR DATABASE               CLIENT'S DATABASE     │
│   (always the same)          (each client differs) │
│                                                     │
│   - who the user is          - production data     │
│   - their role               - transactions        │
│   - what they can do         - documents           │
│   - audit logs               - emails              │
│   - agent configuration      - their own systems   │
│                                                     │
│         ↓                         ↓                │
│              AI Agent receives                      │
│         only filtered data from both sources       │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Concrete Client Examples (from the meeting)

### Raiffeisen Bank
```text
Who logs in?
→ teller, branch manager, risk analyst, HR

What do they want to know?
→ their clients' transactions, branch reports, risk analyses

What must they not see?
→ a teller must not see colleagues' salaries
→ the Brno manager must not see Prague
```

### Steel Mill
```text
Who logs in?
→ production foreman, technologist, salesperson, director

What do they want to know?
→ production status, orders, complaints, material quality

What must they not see?
→ the foreman must not see commercial contracts
→ the salesperson must not see production costs
```

---

## Our Database – What It Must Be Able to Do

### 1. Identify the User
```text
Who are you?
→ email + password, or SSO (Microsoft, Google)
→ which company (organization)
→ which department (department)
```

### 2. Know What They Are Allowed to Do
```text
What can you do?
→ run an agent? (agents.run)
→ upload a document? (documents.write)
→ view analytics? (analytics.read)
→ manage users? (users.manage)
```

### 3. Determine Which Data They Will See
```text
Which data does the AI receive?
→ only transactions from the Brno branch
→ only HR records (without salaries)
→ only production from the past week
```

### 4. Remember Everything That Happened
```text
What happened?
→ who asked
→ what they asked
→ what the AI received
→ what it replied
```

---

## How the User Experiences It (from the perspective of a teller at the counter)

```
1. They log in
   → enter email and password

2. They open the agent
   → "FinanceBot" or "ProductionBot"

3. They type a query
   → "How many transactions did I process today?"

4. The system behind the scenes
   → verifies them
   → determines their permissions
   → pulls only their data from the database
   → sends it to the agent

5. They receive an answer
   → "You processed 12 transactions today."

6. No magic — just secure work with data
```

---

## What We Build First (plan from the meeting)

```
STEP 1 – Database (now)
  PostgreSQL schema
  organizations, users, roles, permissions
  agents, data_sources, data_access_rules
  audit_logs

STEP 2 – Test Data
  We create a fictional company (e.g. "Banka Morava")
  Add users with different roles
  Add data_access_rules

STEP 3 – Langflow
  Connect agents
  Link to the database via a secure API

STEP 4 – Local Testing
  Jirka's Mac Pro over SSH

STEP 5 – Render
  Deploy to the cloud
  Show to clients
```

---

## Questions We Must Answer

```
□ How exactly to apply row_filter for each user?
  → dynamically based on user.branch_id?
  → or store statically in the rule?

□ What if a user has multiple roles?
  → union of permissions? or intersection?
  → who wins in case of conflict?

□ How to connect Langflow to our database securely?
  → via a FastAPI endpoint?
  → or a direct connection?

□ How to verify that the user belongs to the correct company?
  → organization_id must be present on every query

□ How to show the client a demo?
  → a test company with realistic-looking data
  → multiple login accounts (teller, manager, admin)
```

---

## Team and Roles (from the meeting)

| Person | Role | Focus |
|---|---|---|
| Jirka Lamos | Lead / Architect | overall design, clients, Austria |
| Ivan (you) | Developer | database, Python, backend |
| Tony | Developer (Austria) | components, testing |

**Communication:** English (because of Tony)
**Meetings:** 2x per week, 1.5 hours
**Pace:** ~10 days for the basic version

---

## The Core Idea of the Entire Project

```text
Companies have data.
Companies want AI.
But they are afraid that AI will see more than it should.

We give them an AI that sees exactly what it should —
and nothing more.

That is our product.
```
