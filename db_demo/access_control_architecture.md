# Access Control Architecture – AI Agent Platform

## Vysvětlení pro babku za přepážkou

Paní Marta pracuje 20 let v bance za přepážkou v Brně.

Ráno přijde do práce, zadá heslo do počítače — systém ví, že je to ona.
Otevře se jí obrazovka **jen s jejími klienty** z brněnské pobočky.
Praha tam není. Mzdové listy kolegů tam nejsou. Audit logy tam nejsou.

Teď má banka nového pomocníka — **AI asistenta**. Paní Marta se ho může ptát:
`"Kolik transakcí jsem dnes vyřídila?"`

AI asistent se zeptá systému — a systém mu dá **přesně ta samá data, která by viděla paní Marta na obrazovce**.
Nic víc. Nic míň.

Ředitel pobočky pan Novák se může zeptat:
`"Jaký byl obrat pobočky tento týden?"`

AI asistent mu odpoví — ale zobrazí **celou brněnskou pobočku**, protože pan Novák má na to právo.
Praha mu ale taky neukáže. To je jiná pobočka.

**Klíčová myšlenka:** AI asistent je jako nový chytrý kolega.
Vidí přesně to, co mu systém dovolí — ne víc, i kdyby se ptal sebelépe.

---

## Vysvětlení pro malé dítě

Představ si školní jídelnu.

Každý žák dostane **průkazku**, na které je napsáno jeho jméno a třída.
Paní kuchařka se podívá na průkazku a vydá mu **jen to, co mu patří** — jeho oběd, ne oběd spolužáka.

Náš systém funguje stejně:

- **průkazka** = přihlášení (kdo jsi)
- **paní kuchařka** = backend (co smíš vidět)
- **oběd** = data z databáze
- **AI agent** = kamarád, kterému průkazku ukážeš — ale dostane jen tvůj oběd, ne oběd celé školy

Paní kuchařka **nikdy** nevydá celý hrnec. Vždy jen to, co danému žákovi patří.

---

## Problém

Stejný agent, stejný dotaz:

```text
"Ukaž mi transakce za tento měsíc"

Teller       → vidí jen své klienty z Brna
Manager      → vidí celou brněnskou pobočku
Risk Analyst → vidí všechny transakce, ale bez jmen klientů
```

---

# Schéma databázových vztahů

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

## Schéma datových zdrojů

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
│ data_access_rules│  ← propojuje uživatele/role s datovými zdroji
│──────────────────│
│ subject (user/   │
│         role)    │
│ resource         │
│ row_filter       │
│ column_filter    │
└──────────────────┘
```

---

## Schéma toku kontroly přístupu

```
 REQUEST
    │
    ▼
┌───────────┐   ne    ┌──────────┐
│ Auth OK?  │────────►│  401     │
└─────┬─────┘         └──────────┘
      │ ano
      ▼
┌───────────────┐  ne  ┌──────────┐
│ agents.run    │──────►│  403     │
│ permission?   │       └──────────┘
└──────┬────────┘
       │ ano
       ▼
┌───────────────────┐  ne  ┌──────────┐
│ data_source rule  │──────►│  403     │
│ exists?           │       └──────────┘
└────────┬──────────┘
         │ ano
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
│ audit_log zápis      │
└──────────────────────┘
```

---

# Tři úrovně kontroly

## Úroveň 1 — Smí vůbec použít agenta?

```text
user → user_roles → roles → role_permissions → permissions
                                                    ↓
                                              agents.run ?
```

Jednoduchý RBAC check před čímkoliv jiným.

---

## Úroveň 2 — Smí přistoupit k tomuto datovému zdroji?

```sql
data_access_rules
  subject_type  = 'user' | 'role'
  subject_id    = user.id | role.id
  resource_type = 'data_source' | 'table' | 'document'
  resource_id   = data_sources.id
  access_level  = 'read' | 'write' | 'none'
```

Teller nemá pravidlo pro HR data_source → přístup zamítnut.

---

## Úroveň 3 — Která konkrétní data vidí?

```sql
data_access_rules
  row_filter    = {"branch_id": "brno_01"}
  column_filter = {"exclude": ["salary", "ssn", "account_number"]}
```

Toto se přeloží na SQL podmínky **před** tím, než data jdou do LLM.

---

# Jak to backend aplikuje v praxi

```python
# 1. Zjisti pravidla pro tohoto uživatele
rules = get_access_rules(user_id, data_source_id)

# 2. Postav bezpečný SQL dotaz
query = base_query
if rules.row_filter:
    query = query.where(branch_id == user.branch_id)
if rules.column_filter:
    query = query.exclude_columns(rules.column_filter)

# 3. AŽ TEĎ pošli data do LLM
context = query.fetch()
llm.ask(context, user_question)
```

LLM nikdy nevidí dotaz bez filtrů — dostane jen hotová, ořezaná data.

---

# Klíčová tabulka `data_access_rules`

```sql
CREATE TABLE data_access_rules (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id),

    -- kdo
    subject_type    TEXT NOT NULL,  -- 'user' nebo 'role'
    subject_id      UUID NOT NULL,

    -- co
    resource_type   TEXT NOT NULL,  -- 'data_source', 'table', 'document'
    resource_id     UUID NOT NULL,

    -- jak
    access_level    TEXT NOT NULL,  -- 'read', 'write', 'none'
    row_filter      JSONB,          -- {"branch_id": "brno_01"}
    column_filter   JSONB,          -- {"exclude": ["salary"]}

    priority        INT DEFAULT 0,  -- vyšší číslo = silnější pravidlo

    created_at      TIMESTAMP DEFAULT now()
);
```

---

# Hierarchie pravidel

```text
Konkrétnější pravidlo vždy vyhraje:

role=MANAGER    → vidí celou pobočku
user=jan.novak  → speciálně omezen jen na risk data

Jan Novak dostane průnik obou pravidel.
```

Sloupec `priority` řeší konflikty — vyšší číslo vyhraje.

---

# Příklad visibility matice

| Role | Sales Data | HR Data | Finance Data |
|---|---|---|---|
| Employee | Partial | No | No |
| Manager | Yes | Partial | Partial |
| HR | No | Full | No |
| Admin | Full | Full | Full |

---

# Audit logging

Každý dotaz musí zalogovat co LLM skutečně dostalo:

```json
{
  "user_id": "jan.novak",
  "action": "agent_query",
  "data_source": "transactions_db",
  "applied_filters": {
    "row_filter": {"branch_id": "brno_01"},
    "column_filter": {"excluded": ["salary"]}
  },
  "prompt": "Ukaž mi transakce za tento měsíc",
  "rows_returned": 47
}
```

Compliance tým vidí přesně — co LLM dostalo, ne jen že se někdo ptal.

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

# Celkový tok

```text
User asks AI Agent
        ↓
Backend authenticates user
        ↓
RBAC check — smí použít agenta? (úroveň 1)
        ↓
Data source check — smí přistoupit k zdroji? (úroveň 2)
        ↓
Row + column filtering — jaká data přesně? (úroveň 3)
        ↓
Filtrovaná data → LLM
        ↓
Audit log — co dostalo, co vrátilo
        ↓
Response returned to user
```

---

# Simulace zaměstnanců a jejich přístupu k agentovi

Scénář: Banka Morava a.s., pobočka Brno a pobočka Praha.
Agent: **FinanceBot** — odpovídá na dotazy o transakcích, klientech a reportech.

---

## Zaměstnanec 1 — Jana Nováková, Teller, Brno

```json
{
  "user_id": "jana.novakova",
  "organization_id": "banka_morava",
  "department": "retail",
  "role": "TELLER",
  "branch_id": "brno_01"
}
```

**Práva:**
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

**Dotaz agentovi:** `"Kolik transakcí proběhlo dnes?"`

**Co agent dostane:**
```sql
SELECT COUNT(*) FROM transactions
WHERE branch_id = 'brno_01'
  AND assigned_teller = 'jana.novakova'
  AND date = TODAY;
-- výsledek: 12 transakcí (jen její klienti)
```

**Co agent odpoví:**
```
Dnes jsi zpracovala 12 transakcí.
```

**Co agent NEODPOVÍ** (nemá data):
```
Celá pobočka Brno dnes zpracovala 847 transakcí.  ✗
```

---

## Zaměstnanec 2 — Pavel Horák, Branch Manager, Brno

```json
{
  "user_id": "pavel.horak",
  "organization_id": "banka_morava",
  "department": "management",
  "role": "MANAGER",
  "branch_id": "brno_01"
}
```

**Práva:**
```text
agents.run          ✓
documents.read      ✓
analytics.read      ✓
users.manage        ✗  ← nemůže spravovat HR
audit.read          ✗  ← nemůže vidět audit logy
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

**Dotaz agentovi:** `"Jaký byl obrat pobočky tento týden?"`

**Co agent dostane:**
```sql
SELECT SUM(amount) FROM transactions
WHERE branch_id = 'brno_01'
  AND date >= THIS_WEEK;
-- výsledek: 4 200 000 Kč (celá brněnská pobočka)
```

**Co agent NEODPOVÍ** (jiná pobočka):
```
Praha tento týden: 6 800 000 Kč  ✗
```

---

## Zaměstnanec 3 — Martina Křížková, HR Specialistka

```json
{
  "user_id": "martina.krizkova",
  "organization_id": "banka_morava",
  "department": "hr",
  "role": "HR",
  "branch_id": null
}
```

**Práva:**
```text
agents.run          ✓
documents.read      ✓  ← jen HR dokumenty
analytics.read      ✗
users.manage        ✓  ← jen HR záznamy
audit.read          ✗
```

**Data access rules:**
```text
data_source: hr_db
  row_filter:    {}              ← vidí všechny zaměstnance
  column_filter: {}              ← plný HR přístup
  access_level:  read

data_source: transactions_db
  access_level:  none            ← žádný přístup k transakcím
```

**Dotaz agentovi:** `"Kolik zaměstnanců nastoupilo letos?"`

**Co agent dostane:**
```sql
SELECT COUNT(*) FROM employees
WHERE hire_date >= '2026-01-01';
-- výsledek: 23 nových zaměstnanců
```

**Dotaz agentovi:** `"Jaký byl obrat pobočky Praha?"`

**Co agent odpoví:**
```
K tomuto dotazu nemáš přístup.
```

---

## Zaměstnanec 4 — Tomáš Veselý, Risk Analyst

```json
{
  "user_id": "tomas.vesely",
  "organization_id": "banka_morava",
  "department": "risk",
  "role": "RISK_ANALYST",
  "branch_id": null
}
```

**Práva:**
```text
agents.run          ✓
documents.read      ✓
analytics.read      ✓  ← všechny pobočky
risk.read           ✓
audit.read          ✗  ← stále ne
```

**Data access rules:**
```text
data_source: transactions_db
  row_filter:    {}                         ← všechny pobočky
  column_filter: { "exclude": ["client_name", "client_id", "iban"] }
  access_level:  read
```

**Dotaz agentovi:** `"Které transakce jsou podezřelé?"`

**Co agent dostane:**
```sql
SELECT amount, type, fraud_flag, branch_id
FROM transactions
WHERE fraud_flag = true;
-- BEZ jmen klientů, BEZ IBAN
```

**Co agent odpoví:**
```
Nalezeno 7 podezřelých transakcí.
Pobočka Brno: 3, Praha: 4.
Průměrná částka: 280 000 Kč.
(Jména klientů nejsou dostupná.)
```

---

## Zaměstnanec 5 — Admin systému

```json
{
  "user_id": "admin.system",
  "organization_id": "banka_morava",
  "role": "ADMIN"
}
```

**Práva:**
```text
agents.run          ✓
agents.write        ✓  ← může konfigurovat agenty
users.manage        ✓
audit.read          ✓
analytics.read      ✓
```

**Data access rules:**
```text
Všechny data_sources: access_level = read (plný přístup)
Žádné row_filter ani column_filter
```

**Ale pozor:** Admin vidí data — neprovádí bankovní operace.
Princip nejmenšího privilegia platí i pro adminy.

---

## Srovnávací tabulka — stejný dotaz, různé odpovědi

Dotaz: `"Kolik transakcí proběhlo tento týden?"`

| Zaměstnanec | Role | Vidí |
|---|---|---|
| Jana Nováková | Teller | jen své transakce (12) |
| Pavel Horák | Manager | celá pobočka Brno (847) |
| Martina Křížková | HR | `403 – přístup zamítnut` |
| Tomáš Veselý | Risk Analyst | všechny pobočky, bez jmen (2 341) |
| Admin | Admin | vše (2 341 + detaily) |

---

## Seed data pro testování

```sql
-- Organizace
INSERT INTO organizations (id, name, slug)
VALUES ('org-001', 'Banka Morava a.s.', 'banka-morava');

-- Role
INSERT INTO roles (id, name) VALUES
  ('role-teller',   'TELLER'),
  ('role-manager',  'MANAGER'),
  ('role-hr',       'HR'),
  ('role-risk',     'RISK_ANALYST'),
  ('role-admin',    'ADMIN');

-- Uživatelé
INSERT INTO users (id, organization_id, email, full_name) VALUES
  ('u-001', 'org-001', 'jana.novakova@banka-morava.cz',  'Jana Nováková'),
  ('u-002', 'org-001', 'pavel.horak@banka-morava.cz',    'Pavel Horák'),
  ('u-003', 'org-001', 'martina.krizkova@banka-morava.cz','Martina Křížková'),
  ('u-004', 'org-001', 'tomas.vesely@banka-morava.cz',   'Tomáš Veselý'),
  ('u-005', 'org-001', 'admin@banka-morava.cz',          'Systémový Admin');

-- Přiřazení rolí
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
  -- Jana: jen své transakce
  ('org-001', 'user', 'u-001', 'data_source', 'ds-transactions', 'read',
   '{"branch_id": "brno_01", "assigned_teller": "u-001"}',
   '{"exclude": ["internal_score", "fraud_flag"]}'),

  -- Manager role: celá pobočka (aplikuje se přes roli)
  ('org-001', 'role', 'role-manager', 'data_source', 'ds-transactions', 'read',
   '{"branch_id": "{{user.branch_id}}"}',
   '{"exclude": ["fraud_flag"]}'),

  -- HR: jen HR databáze
  ('org-001', 'role', 'role-hr', 'data_source', 'ds-hr', 'read', '{}', '{}'),

  -- Risk Analyst: vše, ale bez PII
  ('org-001', 'role', 'role-risk', 'data_source', 'ds-transactions', 'read',
   '{}',
   '{"exclude": ["client_name", "client_id", "iban"]}'),

  -- Admin: plný přístup
  ('org-001', 'role', 'role-admin', 'data_source', 'ds-transactions', 'read', '{}', '{}'),
  ('org-001', 'role', 'role-admin', 'data_source', 'ds-hr',           'read', '{}', '{}');
```

---

# Klíčový princip

```text
Access control musí proběhnout PŘED tím, než LLM dostane data.
```

LLM není důvěryhodná entita — je to výstupní vrstva, ne rozhodovací.
