# Demo struktura – Banka Morava a.s.

Simulace reálné banky pro testování Private AI Agent Platformy.

---

## Organizační struktura banky

```
Banka Morava a.s. (Ústředí – Praha)
│
├── Ústřední oddělení
│   ├── Risk Management
│   ├── Compliance
│   ├── HR
│   ├── Finance & Controlling
│   └── IT
│
├── Region Morava
│   ├── Pobočka Brno – Centrum
│   ├── Pobočka Brno – Královo Pole
│   └── Pobočka Olomouc
│
└── Region Čechy
    ├── Pobočka Praha – Smíchov
    └── Pobočka Praha – Vinohrady
```

---

## Zaměstnanci – kdo jsou a co dělají

### Ústředí

| Jméno | Pozice | Oddělení | Přístup k datům |
|---|---|---|---|
| Ing. Petra Horáčková | CEO | Board | agregované reporty všech regionů |
| Mgr. Tomáš Veselý | Risk Manager | Risk | všechny transakce bez PII |
| JUDr. Alena Marková | Compliance Officer | Compliance | audit logy, compliance reporty |
| Bc. Jana Procházková | HR Manager | HR | všechny záznamy zaměstnanců |
| Ing. Martin Novák | CFO | Finance | finanční výsledky všech poboček |

---

### Region Morava

| Jméno | Pozice | Pobočka | Přístup k datům |
|---|---|---|---|
| Ing. Pavel Horák | Regionální ředitel | Region Morava | všechny pobočky Moravy |
| Bc. Lucie Svobodová | Branch Manager | Brno – Centrum | celá pobočka Brno Centrum |
| Bc. Ondřej Beneš | Branch Manager | Brno – Kr. Pole | celá pobočka Brno Kr. Pole |

---

### Přepážkoví pracovníci – Brno Centrum

| Jméno | Pozice | Přístup k datům |
|---|---|---|
| Jana Nováková | Teller | jen své přidělené klienty |
| Karel Dvořák | Teller | jen své přidělené klienty |
| Eva Blahová | Senior Teller | svoji skupinu klientů + zastupování |

---

## Role a jejich práva

### TELLER
```text
Může:
  ✓ agents.run              – spustit agenta
  ✓ documents.read          – číst dokumenty svých klientů
  ✓ clients.read.own        – vidět své přidělené klienty

Nemůže:
  ✗ analytics.read          – žádné reporty
  ✗ clients.read.branch     – ostatní klienty pobočky
  ✗ users.manage            – správa uživatelů
  ✗ audit.read              – audit logy
```

### BRANCH_MANAGER
```text
Může:
  ✓ agents.run
  ✓ documents.read
  ✓ clients.read.branch     – všichni klienti pobočky
  ✓ analytics.read.branch   – reporty své pobočky
  ✓ agents.configure        – nastavit agenty pro pobočku

Nemůže:
  ✗ clients.read.region     – jiné pobočky
  ✗ hr.read                 – HR záznamy
  ✗ audit.read              – audit logy
  ✗ finance.read            – finanční výsledky
```

### REGIONAL_DIRECTOR
```text
Může:
  ✓ agents.run
  ✓ analytics.read.region   – reporty celého regionu
  ✓ clients.read.region     – klienti celého regionu
  ✓ agents.configure

Nemůže:
  ✗ hr.read
  ✗ audit.read
  ✗ finance.global
```

### RISK_MANAGER
```text
Může:
  ✓ agents.run
  ✓ risk.read               – všechny transakce (bez jmen klientů)
  ✓ analytics.read.global   – agregovaná data ze všech poboček
  ✓ fraud.read              – fraud flags

Nemůže:
  ✗ clients.read            – žádná jména, žádné osobní údaje
  ✗ hr.read
  ✗ users.manage
```

### COMPLIANCE_OFFICER
```text
Může:
  ✓ agents.run
  ✓ audit.read              – plný přístup k audit logům
  ✓ documents.read.global   – všechny dokumenty

Nemůže:
  ✗ clients.read            – osobní data klientů
  ✗ finance.read
```

### HR_MANAGER
```text
Může:
  ✓ agents.run
  ✓ hr.read                 – všechny záznamy zaměstnanců
  ✓ hr.write                – editace HR záznamů
  ✓ users.manage.hr         – správa HR systému

Nemůže:
  ✗ clients.read            – klientská data
  ✗ transactions.read       – transakce
  ✗ audit.read
```

### CFO
```text
Může:
  ✓ agents.run
  ✓ finance.read.global     – finanční výsledky všech poboček
  ✓ analytics.read.global   – agregované reporty

Nemůže:
  ✗ clients.read            – osobní data
  ✗ hr.read                 – HR záznamy
  ✗ audit.read
```

### CEO
```text
Může:
  ✓ agents.run
  ✓ analytics.read.global   – agregované výsledky
  ✓ finance.read.global

Nemůže:
  ✗ clients.read            – osobní data klientů
  ✗ hr.read                 – osobní záznamy zaměstnanců
  ✗ audit.read              – audit jsou jen pro Compliance
```

---

## Co každý uvidí na stejný dotaz

Dotaz: **"Jaký byl obrat tento měsíc?"**

| Kdo se ptá | Co dostane |
|---|---|
| Jana Nováková (Teller) | `Přístup zamítnut` |
| Lucie Svobodová (Manager Brno) | Obrat pobočky Brno Centrum |
| Pavel Horák (Region Morava) | Obrat všech moravských poboček |
| Ing. Martin Novák (CFO) | Obrat celé banky + srovnání s loňskem |
| Ing. Petra Horáčková (CEO) | Agregovaný přehled celé banky |

---

Dotaz: **"Kdo jsou naši nejhodnotnější klienti?"**

| Kdo se ptá | Co dostane |
|---|---|
| Jana Nováková (Teller) | Její přidělení klienti |
| Lucie Svobodová (Manager) | Top klienti pobočky |
| Tomáš Veselý (Risk) | `Přístup zamítnut` (Risk nevidí PII) |
| Martin Novák (CFO) | `Přístup zamítnut` (CFO nevidí klientská data) |
| Alena Marková (Compliance) | `Přístup zamítnut` |

---

## SQL seed data pro demo

```sql
-- Organizace
INSERT INTO organizations (id, name, slug) VALUES
  ('org-bm', 'Banka Morava a.s.', 'banka-morava');

-- Oddělení
INSERT INTO departments (id, organization_id, name) VALUES
  ('dep-retail',      'org-bm', 'Retail Banking'),
  ('dep-risk',        'org-bm', 'Risk Management'),
  ('dep-compliance',  'org-bm', 'Compliance'),
  ('dep-hr',          'org-bm', 'Human Resources'),
  ('dep-finance',     'org-bm', 'Finance & Controlling'),
  ('dep-it',          'org-bm', 'IT'),
  ('dep-mgmt',        'org-bm', 'Management');

-- Role
INSERT INTO roles (id, name, description) VALUES
  ('role-teller',    'TELLER',             'Přepážkový pracovník'),
  ('role-sr-teller', 'SENIOR_TELLER',      'Senior přepážkový pracovník'),
  ('role-manager',   'BRANCH_MANAGER',     'Manažer pobočky'),
  ('role-regional',  'REGIONAL_DIRECTOR',  'Regionální ředitel'),
  ('role-risk',      'RISK_MANAGER',       'Risk manažer'),
  ('role-compliance','COMPLIANCE_OFFICER', 'Compliance officer'),
  ('role-hr',        'HR_MANAGER',         'HR manažer'),
  ('role-cfo',       'CFO',               'Finanční ředitel'),
  ('role-ceo',       'CEO',               'Generální ředitel'),
  ('role-admin',     'ADMIN',             'Systémový administrátor');

-- Uživatelé
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

-- Přiřazení rolí
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

-- Datové zdroje
INSERT INTO data_sources (id, organization_id, name, type) VALUES
  ('ds-transactions', 'org-bm', 'Transakční databáze', 'postgresql'),
  ('ds-clients',      'org-bm', 'Klientská databáze',  'postgresql'),
  ('ds-hr',           'org-bm', 'HR systém',           'postgresql'),
  ('ds-finance',      'org-bm', 'Finanční systém',     'postgresql'),
  ('ds-documents',    'org-bm', 'Dokumentový server',  'sharepoint');

-- Data access rules
INSERT INTO data_access_rules
  (organization_id, subject_type, subject_id, resource_type, resource_id, access_level, row_filter, column_filter)
VALUES
  -- Teller: jen vlastní klienti, bez citlivých sloupců
  ('org-bm', 'role', 'role-teller', 'data_source', 'ds-transactions', 'read',
   '{"assigned_teller": "{{user.id}}", "branch_id": "{{user.branch_id}}"}',
   '{"exclude": ["internal_score", "fraud_flag", "account_balance_total"]}'),

  -- Branch Manager: celá pobočka
  ('org-bm', 'role', 'role-manager', 'data_source', 'ds-transactions', 'read',
   '{"branch_id": "{{user.branch_id}}"}',
   '{"exclude": ["fraud_flag"]}'),

  ('org-bm', 'role', 'role-manager', 'data_source', 'ds-clients', 'read',
   '{"branch_id": "{{user.branch_id}}"}',
   '{}'),

  -- Regional Director: celý region
  ('org-bm', 'role', 'role-regional', 'data_source', 'ds-transactions', 'read',
   '{"region_id": "{{user.region_id}}"}',
   '{"exclude": ["fraud_flag"]}'),

  -- Risk Manager: vše, ale bez PII
  ('org-bm', 'role', 'role-risk', 'data_source', 'ds-transactions', 'read',
   '{}',
   '{"exclude": ["client_name", "client_id", "iban", "birth_number"]}'),

  -- Compliance: pouze audit logy
  ('org-bm', 'role', 'role-compliance', 'data_source', 'ds-documents', 'read',
   '{}', '{}'),

  -- HR: pouze HR systém
  ('org-bm', 'role', 'role-hr', 'data_source', 'ds-hr', 'read',
   '{}', '{}'),

  -- CFO: finance
  ('org-bm', 'role', 'role-cfo', 'data_source', 'ds-finance', 'read',
   '{}', '{}'),

  -- CEO: agregované reporty (finance + analytics, bez osobních dat)
  ('org-bm', 'role', 'role-ceo', 'data_source', 'ds-finance', 'read',
   '{}', '{"exclude": ["employee_salary", "client_name"]}');
```

---

## Agent pro banku – co umí

```text
FinanceBot
│
├── Nástroje (tools)
│   ├── query_transactions   – dotaz na transakce
│   ├── query_clients        – dotaz na klienty
│   ├── generate_report      – generování reportu
│   ├── search_documents     – hledání v dokumentech
│   └── query_analytics      – analytické dotazy
│
└── Co dostane závisí na tom, kdo se ptá
    → backend aplikuje data_access_rules PŘED tím
      než agent dostane jakákoliv data
```

---

## Shrnutí

```text
Jedna banka.
10 zaměstnanců.
10 různých pohledů na data.
1 agent.

Každý dostane přesně to, na co má právo.
Nic víc.
```
