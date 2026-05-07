-- ============================================================
-- Pobočka Praha – Vinohrady + Region Čechy
-- ============================================================

-- Regionální ředitel pro Čechy
INSERT INTO users (id, organization_id, department_id, email, full_name, branch_id, region_id) VALUES
  ('u-cerny',      'org-bm', 'dep-mgmt',
   'milan.cerny@banka-morava.cz',        'Milan Černý',        NULL,            'cechy'),

  -- Branch Manager Praha Vinohrady
  ('u-blazkova',   'org-bm', 'dep-mgmt',
   'sarka.blazkova@banka-morava.cz',     'Šárka Blažková',     'praha-vinohrady','cechy'),

  -- Teller Praha Vinohrady
  ('u-ruzicka',    'org-bm', 'dep-retail',
   'roman.ruzicka@banka-morava.cz',      'Roman Růžička',      'praha-vinohrady','cechy'),

  ('u-horakova',   'org-bm', 'dep-retail',
   'tereza.horakova@banka-morava.cz',    'Tereza Horáková',    'praha-vinohrady','cechy'),

  -- Senior Teller Praha Smíchov
  ('u-malek',      'org-bm', 'dep-retail',
   'ondrej.malek@banka-morava.cz',       'Ondřej Málek',       'praha-smichov', 'cechy'),

  -- Teller Olomouc (Morava)
  ('u-novotna',    'org-bm', 'dep-retail',
   'petra.novotna@banka-morava.cz',      'Petra Novotná',      'olomouc',       'morava'),

  -- Branch Manager Olomouc
  ('u-fiala',      'org-bm', 'dep-mgmt',
   'jakub.fiala@banka-morava.cz',        'Jakub Fiala',        'olomouc',       'morava');

INSERT INTO user_roles (user_id, role_id) VALUES
  ('u-cerny',    'role-regional'),
  ('u-blazkova', 'role-manager'),
  ('u-ruzicka',  'role-teller'),
  ('u-horakova', 'role-teller'),
  ('u-malek',    'role-sr-teller'),
  ('u-novotna',  'role-teller'),
  ('u-fiala',    'role-manager');
