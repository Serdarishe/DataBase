CREATE DATABASE transfers

CREATE TABLE customers (
                           customer_id SERIAL PRIMARY KEY,
                           iin VARCHAR(12) UNIQUE NOT NULL,
                           full_name VARCHAR(255) NOT NULL,
                           phone VARCHAR(15),
                           email VARCHAR(255) UNIQUE,
                           status VARCHAR(10) CHECK (status IN ('active', 'blocked', 'frozen')) NOT NULL DEFAULT 'active',
                           created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                           daily_limit_kzt NUMERIC DEFAULT 1000000
);

CREATE TABLE accounts (
                          account_id SERIAL PRIMARY KEY,
                          customer_id INT REFERENCES customers(customer_id) ON DELETE CASCADE,
                          account_number VARCHAR(34) UNIQUE NOT NULL,
                          currency VARCHAR(3) CHECK (currency IN ('KZT', 'USD', 'EUR', 'RUB')) NOT NULL,
                          balance NUMERIC DEFAULT 0,
                          is_active BOOLEAN DEFAULT TRUE,
                          opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                          closed_at TIMESTAMP
);

CREATE TABLE transactions (
                              transaction_id SERIAL PRIMARY KEY,
                              from_account_id INT REFERENCES accounts(account_id) ON DELETE CASCADE,
                              to_account_id INT REFERENCES accounts(account_id) ON DELETE CASCADE,
                              amount NUMERIC NOT NULL,
                              currency VARCHAR(3) CHECK (currency IN ('KZT', 'USD', 'EUR', 'RUB')) NOT NULL,
                              exchange_rate NUMERIC,
                              amount_kzt NUMERIC NOT NULL,
                              type VARCHAR(10) CHECK (type IN ('transfer', 'deposit', 'withdrawal')) NOT NULL,
                              status VARCHAR(10) CHECK (status IN ('pending', 'completed', 'failed', 'reversed')) NOT NULL DEFAULT 'pending',
                              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                              completed_at TIMESTAMP,
                              description TEXT
);

CREATE TABLE exchange_rates (
                                rate_id SERIAL PRIMARY KEY,
                                from_currency VARCHAR(3) CHECK (from_currency IN ('KZT', 'USD', 'EUR', 'RUB')) NOT NULL,
                                to_currency VARCHAR(3) CHECK (to_currency IN ('KZT', 'USD', 'EUR', 'RUB')) NOT NULL,
                                rate NUMERIC NOT NULL,
                                valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                valid_to TIMESTAMP
);

CREATE TABLE audit_log (
                           log_id SERIAL PRIMARY KEY,
                           table_name VARCHAR(50) NOT NULL,
                           record_id INT NOT NULL,
                           action VARCHAR(10) CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')) NOT NULL,
                           old_values JSONB,
                           new_values JSONB,
                           changed_by VARCHAR(255) NOT NULL,
                           changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                           ip_address INET
);

INSERT INTO customers (iin, full_name, phone, email, status, daily_limit_kzt)
VALUES
    ('123456789012', 'Ivan Ivanov', '87780001122', 'ivanov@example.com', 'active', 500000),
    ('987654321098', 'Maria Petrova', '87780003344', 'petrova@example.com', 'active', 1000000);

INSERT INTO accounts (customer_id, account_number, currency, balance, is_active)
VALUES
    (1, 'KZ123456789012345678901234567890', 'KZT', 100000, TRUE),
    (2, 'KZ987654321098765432109876543210', 'USD', 5000, TRUE);

INSERT INTO exchange_rates (from_currency, to_currency, rate, valid_from, valid_to)
VALUES
    ('USD', 'KZT', 420, CURRENT_TIMESTAMP, NULL),
    ('EUR', 'KZT', 480, CURRENT_TIMESTAMP, NULL);

INSERT INTO transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, created_at, description)
VALUES
    (1, 2, 100, 'USD', 420, 42000, 'transfer', 'completed', CURRENT_TIMESTAMP, 'Transfer USD to Maria');

--Task1
CREATE VIEW customer_balance_summary AS
SELECT
    c.customer_id,
    c.full_name,
    a.account_number,
    a.balance,
    (a.balance * er.rate) AS total_balance_kzt,
    c.daily_limit_kzt,
    (a.balance * er.rate) / c.daily_limit_kzt * 100 AS daily_limit_utilization
FROM customers c
         JOIN accounts a ON c.customer_id = a.customer_id
         LEFT JOIN exchange_rates er ON a.currency = er.from_currency AND er.to_currency = 'KZT'
WHERE er.valid_from <= CURRENT_DATE AND er.valid_to >= CURRENT_DATE;


--Task2
CREATE VIEW daily_transaction_report AS
WITH daily_agg AS (
    SELECT
        created_at::date AS transaction_date,
        type,
        COUNT(*) AS transaction_count,
        SUM(amount) AS total_volume,
        AVG(amount) AS avg_amount
    FROM transactions
    GROUP BY created_at::date, type
)
SELECT
    transaction_date,
    type,
    transaction_count,
    total_volume,
    avg_amount,
    SUM(total_volume) OVER (PARTITION BY type ORDER BY transaction_date) AS running_total,
    CASE
        WHEN LAG(total_volume) OVER (PARTITION BY type ORDER BY transaction_date) > 0
            THEN ROUND(
                (total_volume - LAG(total_volume) OVER (PARTITION BY type ORDER BY transaction_date)) * 100.0 /
                LAG(total_volume) OVER (PARTITION BY type ORDER BY transaction_date), 2
                 )
        ELSE NULL
        END AS day_over_day_growth_pct
FROM daily_agg
ORDER BY transaction_date, type;


--Task3
--b-tree index
CREATE INDEX idx_account_balance ON accounts(balance);
--hash index
CREATE INDEX idx_account_number_hash ON accounts USING hash(account_number);
--gin index
CREATE INDEX idx_audit_log_jsonb ON audit_log USING gin(old_values jsonb_path_ops);
--partial index
CREATE INDEX idx_active_accounts ON accounts(account_id) WHERE is_active = TRUE;
--composite index
CREATE INDEX idx_customer_status_limit ON customers(iin, status);


--Task4
CREATE OR REPLACE FUNCTION process_salary_batch(
    company_account_number TEXT,
    payments JSONB
)
    RETURNS TABLE(successful_count INT, failed_count INT, failed_details JSONB) AS $$
DECLARE
    company_account RECORD;
    payment RECORD;
    total_amount NUMERIC := 0;
    success_count INT := 0;
    fail_count INT := 0;
    failed_details JSONB := '[]'::jsonb;
BEGIN
    SELECT * INTO company_account FROM accounts WHERE account_number = company_account_number;

    IF company_account.balance < (SELECT SUM((payment->>'amount')::NUMERIC) FROM jsonb_array_elements(payments) AS payment) THEN
        RAISE EXCEPTION 'error: insufficient balance for salary batch';
    END IF;

    FOR payment IN SELECT * FROM jsonb_array_elements(payments) AS p
        LOOP
            BEGIN
                UPDATE accounts SET balance = balance - (payment->>'amount')::NUMERIC WHERE account_number = company_account_number;
                INSERT INTO transactions(from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, created_at, description)
                VALUES (company_account.account_id, (payment->>'iin')::NUMERIC, (payment->>'amount')::NUMERIC, 'KZT', 1, (payment->>'amount')::NUMERIC, 'salary', 'completed', CURRENT_TIMESTAMP, 'Salary Payment');

                success_count := success_count + 1;
            EXCEPTION
                WHEN OTHERS THEN
                    fail_count := fail_count + 1;
                    failed_details := failed_details || jsonb_build_object('iin', payment->>'iin', 'error', SQLERRM);
            END;
        END LOOP;

    RETURN QUERY SELECT success_count, fail_count, failed_details;
END;
$$ LANGUAGE plpgsql;
