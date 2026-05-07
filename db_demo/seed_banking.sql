-- ============================================================
-- Seed data – bankovní entity (klienti, účty, transakce, úvěry)
-- ============================================================

-- KLIENTI
INSERT INTO customers (id, organization_id, branch_id, full_name, birth_date,
    national_id_hash, phone_masked, email_masked, risk_level, kyc_status, assigned_teller)
VALUES
  ('cust-01', 'org-bm', 'brno-centrum', 'Petr Svoboda',    '1985-03-12',
   'hash_abc1', '+420 *** *** 101', 'p***@gmail.com',   'LOW',    'VERIFIED', 'u-novakova'),
  ('cust-02', 'org-bm', 'brno-centrum', 'Marie Horáková',  '1972-07-28',
   'hash_abc2', '+420 *** *** 102', 'm***@seznam.cz',   'LOW',    'VERIFIED', 'u-novakova'),
  ('cust-03', 'org-bm', 'brno-centrum', 'Jakub Král',      '1990-11-05',
   'hash_abc3', '+420 *** *** 103', 'j***@email.cz',    'MEDIUM', 'VERIFIED', 'u-dvorak'),
  ('cust-04', 'org-bm', 'brno-centrum', 'Lenka Procházka', '1968-01-19',
   'hash_abc4', '+420 *** *** 104', 'l***@gmail.com',   'LOW',    'VERIFIED', 'u-dvorak'),
  ('cust-05', 'org-bm', 'brno-centrum', 'Tomáš Beneš',     '1995-09-30',
   'hash_abc5', '+420 *** *** 105', 't***@hotmail.com', 'HIGH',   'PENDING',  'u-blahova'),
  ('cust-06', 'org-bm', 'olomouc',      'Jana Nováčková',  '1980-06-14',
   'hash_abc6', '+420 *** *** 106', 'j***@gmail.com',   'LOW',    'VERIFIED', 'u-novotna'),
  ('cust-07', 'org-bm', 'olomouc',      'Pavel Dvořáček',  '1963-12-03',
   'hash_abc7', '+420 *** *** 107', 'p***@seznam.cz',   'MEDIUM', 'VERIFIED', 'u-novotna'),
  ('cust-08', 'org-bm', 'praha-smichov','Eva Marková',     '1988-04-22',
   'hash_abc8', '+420 *** *** 108', 'e***@gmail.com',   'LOW',    'VERIFIED', 'u-pospisil'),
  ('cust-09', 'org-bm', 'praha-smichov','Radek Horák',     '1975-08-17',
   'hash_abc9', '+420 *** *** 109', 'r***@email.cz',    'HIGH',   'FAILED',   'u-pospisil'),
  ('cust-10', 'org-bm', 'praha-vinohrady','Zuzana Blažková','1992-02-08',
   'hash_abc10','+420 *** *** 110', 'z***@gmail.com',  'LOW',    'VERIFIED', 'u-ruzicka');

-- ÚČTY
INSERT INTO accounts (id, customer_id, organization_id, branch_id,
    account_number_masked, account_type, balance, currency, status)
VALUES
  ('acc-01', 'cust-01', 'org-bm', 'brno-centrum',  'CZ65 **** **** **** 1001', 'CURRENT',  45230.00, 'CZK', 'ACTIVE'),
  ('acc-02', 'cust-01', 'org-bm', 'brno-centrum',  'CZ65 **** **** **** 1002', 'SAVINGS',  120000.00,'CZK', 'ACTIVE'),
  ('acc-03', 'cust-02', 'org-bm', 'brno-centrum',  'CZ65 **** **** **** 1003', 'CURRENT',  8750.50,  'CZK', 'ACTIVE'),
  ('acc-04', 'cust-03', 'org-bm', 'brno-centrum',  'CZ65 **** **** **** 1004', 'CURRENT',  2300.00,  'CZK', 'ACTIVE'),
  ('acc-05', 'cust-04', 'org-bm', 'brno-centrum',  'CZ65 **** **** **** 1005', 'CURRENT',  67800.00, 'CZK', 'ACTIVE'),
  ('acc-06', 'cust-05', 'org-bm', 'brno-centrum',  'CZ65 **** **** **** 1006', 'CURRENT',  -1200.00, 'CZK', 'BLOCKED'),
  ('acc-07', 'cust-06', 'org-bm', 'olomouc',       'CZ65 **** **** **** 1007', 'CURRENT',  33400.00, 'CZK', 'ACTIVE'),
  ('acc-08', 'cust-07', 'org-bm', 'olomouc',       'CZ65 **** **** **** 1008', 'BUSINESS', 890000.00,'CZK', 'ACTIVE'),
  ('acc-09', 'cust-08', 'org-bm', 'praha-smichov', 'CZ65 **** **** **** 1009', 'CURRENT',  12500.00, 'CZK', 'ACTIVE'),
  ('acc-10', 'cust-09', 'org-bm', 'praha-smichov', 'CZ65 **** **** **** 1010', 'CURRENT',  500.00,   'CZK', 'FROZEN'),
  ('acc-11', 'cust-10', 'org-bm', 'praha-vinohrady','CZ65 **** **** **** 1011','SAVINGS',  250000.00,'CZK', 'ACTIVE');

-- TRANSAKCE
INSERT INTO transactions (id, account_id, organization_id, branch_id,
    amount, currency, transaction_date, counterparty_masked, category, fraud_score)
VALUES
  -- Brno centrum – normální transakce
  ('tx-01', 'acc-01', 'org-bm', 'brno-centrum', 35000.00, 'CZK', NOW() - INTERVAL '1 day',  'Z*** s.r.o.',      'SALARY',   0.01),
  ('tx-02', 'acc-01', 'org-bm', 'brno-centrum', -12500.00,'CZK', NOW() - INTERVAL '2 days', 'B*** Reality',     'RENT',     0.02),
  ('tx-03', 'acc-01', 'org-bm', 'brno-centrum', -3200.00, 'CZK', NOW() - INTERVAL '3 days', 'A*** Supermarket',  'SHOPPING', 0.01),
  ('tx-04', 'acc-03', 'org-bm', 'brno-centrum', 28000.00, 'CZK', NOW() - INTERVAL '1 day',  'M*** a.s.',         'SALARY',   0.01),
  ('tx-05', 'acc-03', 'org-bm', 'brno-centrum', -8000.00, 'CZK', NOW() - INTERVAL '4 days', 'Č*** Energie',      'UTILITIES',0.01),
  ('tx-06', 'acc-04', 'org-bm', 'brno-centrum', -5500.00, 'CZK', NOW() - INTERVAL '1 day',  'N*** Obchod',       'SHOPPING', 0.31),
  ('tx-07', 'acc-04', 'org-bm', 'brno-centrum', -9800.00, 'CZK', NOW() - INTERVAL '6 hours','P*** Transfer',     'TRANSFER', 0.72),
  -- Podezřelé transakce
  ('tx-08', 'acc-06', 'org-bm', 'brno-centrum', -45000.00,'CZK', NOW() - INTERVAL '12 hours','N*** Unknown',     'TRANSFER', 0.91),
  ('tx-09', 'acc-10', 'org-bm', 'praha-smichov', -78000.00,'CZK',NOW() - INTERVAL '3 hours', 'X*** Offshore',    'TRANSFER', 0.95),
  -- Olomouc
  ('tx-10', 'acc-07', 'org-bm', 'olomouc',       22000.00, 'CZK', NOW() - INTERVAL '1 day',  'K*** s.r.o.',     'SALARY',   0.01),
  ('tx-11', 'acc-08', 'org-bm', 'olomouc',       450000.00,'CZK', NOW() - INTERVAL '2 days', 'D*** Export',     'BUSINESS', 0.15),
  -- Praha
  ('tx-12', 'acc-09', 'org-bm', 'praha-smichov', 31000.00, 'CZK', NOW() - INTERVAL '1 day',  'T*** Praha',      'SALARY',   0.01),
  ('tx-13', 'acc-11', 'org-bm', 'praha-vinohrady',18000.00,'CZK', NOW() - INTERVAL '3 days', 'F*** Agency',     'SALARY',   0.01),
  ('tx-14', 'acc-11', 'org-bm', 'praha-vinohrady',-95000.00,'CZK',NOW() - INTERVAL '5 hours','O*** Invest',     'INVESTMENT',0.42);

-- ÚVĚRY
INSERT INTO loans (id, customer_id, organization_id,
    loan_type, principal, remaining_balance, interest_rate, status, risk_score)
VALUES
  ('loan-01', 'cust-01', 'org-bm', 'MORTGAGE',  3500000.00, 2800000.00, 3.49, 'ACTIVE',  0.12),
  ('loan-02', 'cust-02', 'org-bm', 'CONSUMER',   150000.00,   75000.00, 8.90, 'ACTIVE',  0.21),
  ('loan-03', 'cust-03', 'org-bm', 'CONSUMER',    80000.00,   80000.00, 12.50,'ACTIVE',  0.55),
  ('loan-04', 'cust-05', 'org-bm', 'CONSUMER',    50000.00,   50000.00, 18.00,'DEFAULT', 0.88),
  ('loan-05', 'cust-07', 'org-bm', 'BUSINESS',  2000000.00, 1200000.00, 5.20, 'ACTIVE',  0.18),
  ('loan-06', 'cust-09', 'org-bm', 'MORTGAGE',  4200000.00, 4200000.00, 4.10, 'ACTIVE',  0.79);
