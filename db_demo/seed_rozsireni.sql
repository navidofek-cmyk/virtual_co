-- ============================================================
-- Rozšíření seed dat – nové role a zaměstnanci
-- ============================================================

-- Nová role: HR_STAFF (řadový HR bez manažerských práv)
INSERT INTO roles (id, name, description) VALUES
  ('role-hr-staff', 'HR_STAFF', 'HR pracovník – eviduje docházku a základní záznamy');

-- HR_STAFF oprávnění (méně než HR_MANAGER)
INSERT INTO permissions (id, code, description) VALUES
  ('perm-17', 'hr.read.basic',   'Číst základní HR záznamy (bez mezd)'),
  ('perm-18', 'hr.write.basic',  'Editovat docházku a kontaktní údaje');

INSERT INTO role_permissions (role_id, permission_id) VALUES
  ('role-hr-staff', 'perm-01'),        -- agents.run
  ('role-hr-staff', 'perm-17'),        -- hr.read.basic
  ('role-hr-staff', 'perm-18');        -- hr.write.basic

-- Noví zaměstnanci
INSERT INTO users (id, organization_id, department_id, email, full_name, branch_id, region_id) VALUES
  -- HR pracovník (bez manažera)
  ('u-kratochvilova', 'org-bm', 'dep-hr',
   'marie.kratochvilova@banka-morava.cz', 'Marie Kratochvílová', NULL, NULL),

  -- Druhý teller Praha
  ('u-pospisil',  'org-bm', 'dep-retail',
   'jan.pospisil@banka-morava.cz',       'Jan Pospíšil',       'praha-smichov', 'cechy'),

  -- Branch Manager Praha
  ('u-kovarova',  'org-bm', 'dep-mgmt',
   'hana.kovarova@banka-morava.cz',      'Hana Kovářová',      'praha-smichov', 'cechy'),

  -- Risk analytik (junior, vidí jen Moravu)
  ('u-stransky',  'org-bm', 'dep-risk',
   'petr.stransky@banka-morava.cz',      'Petr Stránský',      NULL, 'morava');

INSERT INTO user_roles (user_id, role_id) VALUES
  ('u-kratochvilova', 'role-hr-staff'),
  ('u-pospisil',      'role-teller'),
  ('u-kovarova',      'role-manager'),
  ('u-stransky',      'role-risk');

-- Data access rule pro HR_STAFF: základní záznamy, bez mezd
INSERT INTO data_access_rules
  (id, organization_id, subject_type, subject_id, resource_type, resource_id,
   access_level, row_filter, column_filter, priority)
VALUES
  ('rule-12', 'org-bm', 'role', 'role-hr-staff', 'data_source', 'ds-hr', 'read',
   '{}',
   '{"exclude": ["salary", "salary_history", "bonus", "performance_rating"]}',
   10);

-- Data access rule pro junior risk (jen region Morava)
INSERT INTO data_access_rules
  (id, organization_id, subject_type, subject_id, resource_type, resource_id,
   access_level, row_filter, column_filter, priority)
VALUES
  ('rule-13', 'org-bm', 'user', 'u-stransky', 'data_source', 'ds-transactions', 'read',
   '{"region_id": "morava"}',
   '{"exclude": ["client_name", "client_id", "iban", "birth_number"]}',
   20);
