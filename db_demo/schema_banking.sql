-- ============================================================
-- Bankovní entity – skutečné tabulky (ne simulace)
-- ============================================================

-- KLIENTI
CREATE TABLE customers (
    id              TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    organization_id TEXT REFERENCES organizations(id),
    branch_id       TEXT,

    full_name       TEXT NOT NULL,
    birth_date      DATE,
    national_id_hash TEXT,              -- rodné číslo zahashované
    phone_masked    TEXT,               -- +420 *** *** 123
    email_masked    TEXT,               -- j***@gmail.com
    risk_level      TEXT DEFAULT 'LOW', -- LOW, MEDIUM, HIGH
    kyc_status      TEXT DEFAULT 'VERIFIED', -- VERIFIED, PENDING, FAILED

    assigned_teller TEXT REFERENCES users(id),

    created_at      TIMESTAMP DEFAULT now()
);

-- ÚČTY
CREATE TABLE accounts (
    id                   TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    customer_id          TEXT REFERENCES customers(id),
    organization_id      TEXT REFERENCES organizations(id),
    branch_id            TEXT,

    account_number_masked TEXT,         -- CZ65 **** **** **** 1234
    account_type         TEXT,          -- CURRENT, SAVINGS, BUSINESS
    balance              NUMERIC(15,2),
    currency             TEXT DEFAULT 'CZK',
    status               TEXT DEFAULT 'ACTIVE',

    created_at           TIMESTAMP DEFAULT now()
);

-- TRANSAKCE
CREATE TABLE transactions (
    id                  TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    account_id          TEXT REFERENCES accounts(id),
    organization_id     TEXT REFERENCES organizations(id),
    branch_id           TEXT,

    amount              NUMERIC(15,2) NOT NULL,
    currency            TEXT DEFAULT 'CZK',
    transaction_date    TIMESTAMP DEFAULT now(),
    counterparty_masked TEXT,           -- příjemce/plátce maskovaně
    category            TEXT,           -- SALARY, RENT, SHOPPING, TRANSFER...
    fraud_score         NUMERIC(3,2) DEFAULT 0.0, -- 0.0 - 1.0

    created_at          TIMESTAMP DEFAULT now()
);

-- ÚVĚRY
CREATE TABLE loans (
    id                TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    customer_id       TEXT REFERENCES customers(id),
    organization_id   TEXT REFERENCES organizations(id),

    loan_type         TEXT,             -- MORTGAGE, CONSUMER, BUSINESS
    principal         NUMERIC(15,2),
    remaining_balance NUMERIC(15,2),
    interest_rate     NUMERIC(5,2),
    status            TEXT DEFAULT 'ACTIVE', -- ACTIVE, PAID, DEFAULT
    risk_score        NUMERIC(3,2) DEFAULT 0.0,

    created_at        TIMESTAMP DEFAULT now()
);

-- VIEWS – agent čte views, ne přímo tabulky
-- ============================================================

-- TELLER: základní info o vlastním klientovi
CREATE VIEW v_customer_basic AS
SELECT
    id, branch_id, assigned_teller,
    full_name, phone_masked, email_masked, kyc_status
FROM customers;

-- BRANCH MANAGER: přehled pobočky
CREATE VIEW v_customer_branch AS
SELECT
    id, branch_id,
    full_name, risk_level, kyc_status,
    phone_masked, email_masked
FROM customers;

-- RISK: transakce bez PII
CREATE VIEW v_transactions_risk AS
SELECT
    t.id, t.branch_id, t.amount, t.currency,
    t.transaction_date, t.category, t.fraud_score
FROM transactions t;

-- COMPLIANCE: podezřelé transakce
CREATE VIEW v_transactions_suspicious AS
SELECT
    t.id, t.branch_id, t.amount, t.currency,
    t.transaction_date, t.category, t.fraud_score,
    c.kyc_status, c.risk_level
FROM transactions t
JOIN accounts a ON t.account_id = a.id
JOIN customers c ON a.customer_id = c.id
WHERE t.fraud_score > 0.5 OR c.risk_level = 'HIGH';

-- DATA ANALYST: anonymizovaná agregovaná data
CREATE VIEW v_transactions_anonymized AS
SELECT
    category, currency,
    COUNT(*)            AS pocet,
    AVG(amount)         AS prumer,
    SUM(amount)         AS celkem,
    DATE_TRUNC('week', transaction_date) AS tyden
FROM transactions
GROUP BY category, currency, DATE_TRUNC('week', transaction_date);
