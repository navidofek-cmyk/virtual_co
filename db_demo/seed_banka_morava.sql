-- ============================================================
-- Seed data – Banka Morava a.s.
-- ============================================================

-- ORGANIZACE
INSERT INTO organizations (id, name, slug) VALUES
  ('org-bm', 'Banka Morava a.s.', 'banka-morava');

-- ODDĚLENÍ
INSERT INTO departments (id, organization_id, name) VALUES
  ('dep-retail',     'org-bm', 'Retail Banking'),
  ('dep-risk',       'org-bm', 'Risk Management'),
  ('dep-compliance', 'org-bm', 'Compliance'),
  ('dep-hr',         'org-bm', 'Human Resources'),
  ('dep-finance',    'org-bm', 'Finance & Controlling'),
  ('dep-mgmt',       'org-bm', 'Management');

-- ROLE
INSERT INTO roles (id, name, description) VALUES
  ('role-teller',     'TELLER',             'Přepážkový pracovník'),
  ('role-sr-teller',  'SENIOR_TELLER',      'Senior přepážkový pracovník'),
  ('role-manager',    'BRANCH_MANAGER',     'Manažer pobočky'),
  ('role-regional',   'REGIONAL_DIRECTOR',  'Regionální ředitel'),
  ('role-risk',       'RISK_MANAGER',       'Risk manažer'),
  ('role-compliance', 'COMPLIANCE_OFFICER', 'Compliance officer'),
  ('role-hr',         'HR_MANAGER',         'HR manažer'),
  ('role-cfo',        'CFO',                'Finanční ředitel'),
  ('role-ceo',        'CEO',                'Generální ředitel'),
  ('role-admin',      'ADMIN',              'Systémový administrátor');

-- OPRÁVNĚNÍ
INSERT INTO permissions (id, code, description) VALUES
  ('perm-01', 'agents.run',              'Spustit agenta'),
  ('perm-02', 'agents.configure',        'Konfigurovat agenty'),
  ('perm-03', 'documents.read',          'Číst dokumenty'),
  ('perm-04', 'documents.write',         'Nahrávat dokumenty'),
  ('perm-05', 'clients.read.own',        'Číst vlastní klienty'),
  ('perm-06', 'clients.read.branch',     'Číst klienty pobočky'),
  ('perm-07', 'clients.read.region',     'Číst klienty regionu'),
  ('perm-08', 'analytics.read.branch',   'Analytika pobočky'),
  ('perm-09', 'analytics.read.region',   'Analytika regionu'),
  ('perm-10', 'analytics.read.global',   'Analytika celé banky'),
  ('perm-11', 'risk.read',               'Risk data'),
  ('perm-12', 'compliance.read',         'Compliance a audit logy'),
  ('perm-13', 'hr.read',                 'HR záznamy'),
  ('perm-14', 'hr.write',                'Editace HR'),
  ('perm-15', 'finance.read.global',     'Finanční výsledky'),
  ('perm-16', 'users.manage',            'Správa uživatelů');

-- ROLE -> OPRÁVNĚNÍ
INSERT INTO role_permissions (role_id, permission_id) VALUES
  -- TELLER
  ('role-teller', 'perm-01'),
  ('role-teller', 'perm-03'),
  ('role-teller', 'perm-05'),
  -- SENIOR TELLER
  ('role-sr-teller', 'perm-01'),
  ('role-sr-teller', 'perm-03'),
  ('role-sr-teller', 'perm-05'),
  ('role-sr-teller', 'perm-06'),
  -- BRANCH MANAGER
  ('role-manager', 'perm-01'),
  ('role-manager', 'perm-02'),
  ('role-manager', 'perm-03'),
  ('role-manager', 'perm-06'),
  ('role-manager', 'perm-08'),
  -- REGIONAL DIRECTOR
  ('role-regional', 'perm-01'),
  ('role-regional', 'perm-02'),
  ('role-regional', 'perm-03'),
  ('role-regional', 'perm-07'),
  ('role-regional', 'perm-09'),
  -- RISK MANAGER
  ('role-risk', 'perm-01'),
  ('role-risk', 'perm-11'),
  ('role-risk', 'perm-10'),
  -- COMPLIANCE OFFICER
  ('role-compliance', 'perm-01'),
  ('role-compliance', 'perm-12'),
  ('role-compliance', 'perm-03'),
  -- HR MANAGER
  ('role-hr', 'perm-01'),
  ('role-hr', 'perm-13'),
  ('role-hr', 'perm-14'),
  -- CFO
  ('role-cfo', 'perm-01'),
  ('role-cfo', 'perm-15'),
  ('role-cfo', 'perm-10'),
  -- CEO
  ('role-ceo', 'perm-01'),
  ('role-ceo', 'perm-10'),
  ('role-ceo', 'perm-15'),
  -- ADMIN
  ('role-admin', 'perm-01'),
  ('role-admin', 'perm-02'),
  ('role-admin', 'perm-16');

-- UŽIVATELÉ
INSERT INTO users (id, organization_id, department_id, email, full_name, branch_id, region_id) VALUES
  ('u-novakova',   'org-bm', 'dep-retail',     'jana.novakova@banka-morava.cz',    'Jana Nováková',    'brno-centrum',  'morava'),
  ('u-dvorak',     'org-bm', 'dep-retail',     'karel.dvorak@banka-morava.cz',     'Karel Dvořák',     'brno-centrum',  'morava'),
  ('u-blahova',    'org-bm', 'dep-retail',     'eva.blahova@banka-morava.cz',      'Eva Blahová',      'brno-centrum',  'morava'),
  ('u-svobodova',  'org-bm', 'dep-mgmt',       'lucie.svobodova@banka-morava.cz',  'Lucie Svobodová',  'brno-centrum',  'morava'),
  ('u-horak',      'org-bm', 'dep-mgmt',       'pavel.horak@banka-morava.cz',      'Pavel Horák',      NULL,            'morava'),
  ('u-vesely',     'org-bm', 'dep-risk',       'tomas.vesely@banka-morava.cz',     'Tomáš Veselý',     NULL,            NULL),
  ('u-markova',    'org-bm', 'dep-compliance', 'alena.markova@banka-morava.cz',    'Alena Marková',    NULL,            NULL),
  ('u-prochazkova','org-bm', 'dep-hr',         'jana.prochazkova@banka-morava.cz', 'Jana Procházková', NULL,            NULL),
  ('u-novak-m',    'org-bm', 'dep-finance',    'martin.novak@banka-morava.cz',     'Martin Novák',     NULL,            NULL),
  ('u-horackova',  'org-bm', 'dep-mgmt',       'petra.horackova@banka-morava.cz',  'Petra Horáčková',  NULL,            NULL);

-- PŘIŘAZENÍ ROLÍ
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

-- DATOVÉ ZDROJE
INSERT INTO data_sources (id, organization_id, name, type) VALUES
  ('ds-transactions', 'org-bm', 'Transakční databáze', 'postgresql'),
  ('ds-clients',      'org-bm', 'Klientská databáze',  'postgresql'),
  ('ds-hr',           'org-bm', 'HR systém',           'postgresql'),
  ('ds-finance',      'org-bm', 'Finanční systém',     'postgresql'),
  ('ds-documents',    'org-bm', 'Dokumentový server',  'sharepoint');

-- DATA ACCESS RULES
INSERT INTO data_access_rules
  (id, organization_id, subject_type, subject_id, resource_type, resource_id, access_level, row_filter, column_filter, priority)
VALUES
  -- Teller: jen vlastní klienti
  ('rule-01', 'org-bm', 'role', 'role-teller', 'data_source', 'ds-transactions', 'read',
   '{"assigned_teller": "{{user.id}}", "branch_id": "{{user.branch_id}}"}',
   '{"exclude": ["internal_score", "fraud_flag"]}', 10),

  -- Senior Teller: celá skupina + zastupování
  ('rule-02', 'org-bm', 'role', 'role-sr-teller', 'data_source', 'ds-transactions', 'read',
   '{"branch_id": "{{user.branch_id}}"}',
   '{"exclude": ["internal_score", "fraud_flag"]}', 10),

  -- Branch Manager: celá pobočka
  ('rule-03', 'org-bm', 'role', 'role-manager', 'data_source', 'ds-transactions', 'read',
   '{"branch_id": "{{user.branch_id}}"}',
   '{"exclude": ["fraud_flag"]}', 10),

  ('rule-04', 'org-bm', 'role', 'role-manager', 'data_source', 'ds-clients', 'read',
   '{"branch_id": "{{user.branch_id}}"}',
   '{}', 10),

  -- Regional Director: celý region
  ('rule-05', 'org-bm', 'role', 'role-regional', 'data_source', 'ds-transactions', 'read',
   '{"region_id": "{{user.region_id}}"}',
   '{"exclude": ["fraud_flag"]}', 10),

  ('rule-06', 'org-bm', 'role', 'role-regional', 'data_source', 'ds-clients', 'read',
   '{"region_id": "{{user.region_id}}"}',
   '{}', 10),

  -- Risk Manager: vše ale bez PII
  ('rule-07', 'org-bm', 'role', 'role-risk', 'data_source', 'ds-transactions', 'read',
   '{}',
   '{"exclude": ["client_name", "client_id", "iban", "birth_number"]}', 10),

  -- Compliance: dokumenty a audit
  ('rule-08', 'org-bm', 'role', 'role-compliance', 'data_source', 'ds-documents', 'read',
   '{}', '{}', 10),

  -- HR: pouze HR
  ('rule-09', 'org-bm', 'role', 'role-hr', 'data_source', 'ds-hr', 'read',
   '{}', '{}', 10),

  -- CFO: finance
  ('rule-10', 'org-bm', 'role', 'role-cfo', 'data_source', 'ds-finance', 'read',
   '{}', '{}', 10),

  -- CEO: finance + anonymní agregace
  ('rule-11', 'org-bm', 'role', 'role-ceo', 'data_source', 'ds-finance', 'read',
   '{}', '{"exclude": ["employee_salary", "client_name"]}', 10);

-- AGENT
INSERT INTO agents (id, organization_id, name, description, system_prompt) VALUES
  ('agent-financebot', 'org-bm', 'FinanceBot',
   'Bankovní AI asistent',
   'Jsi bankovní asistent. Odpovídáš pouze na základě dat, která dostaneš. Nikdy nevymýšlíš data. Nikdy neodhaluješ data jiných uživatelů.');
