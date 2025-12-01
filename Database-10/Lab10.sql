-- Task 1: Basic Transaction with COMMIT
BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
COMMIT;

-- Task 2: Using ROLLBACK
BEGIN;
UPDATE accounts SET balance = balance - 500.00 WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';

-- Task 3: Working with SAVEPOINTs
BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Wally';
COMMIT;

-- Task 4: Isolation Level Demonstration
-- Scenario A: READ COMMITTED
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to make changes and COMMIT
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

-- Scenario B: SERIALIZABLE
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

-- Task 5: Phantom Read Demonstration
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop';
SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

-- Task 6: Dirty Read Demonstration
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
SELECT * FROM products WHERE shop = 'Joe''s Shop';
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

-- Independent Exercise 1: Transfer $200 from Bob to Wally
DO $$
    BEGIN
        IF (SELECT balance FROM accounts WHERE name = 'Bob') >= 200 THEN
            UPDATE accounts SET balance = balance - 200 WHERE name = 'Bob';
            UPDATE accounts SET balance = balance + 200 WHERE name = 'Wally';
            COMMIT;
        ELSE
            ROLLBACK;
        END IF;
    END $$;


-- Independent Exercise 2: Transaction with Multiple Savepoints
BEGIN;
INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop', 'Sprite', 4.00);
SAVEPOINT sp1;
UPDATE products SET price = 5.00 WHERE product = 'Sprite';
SAVEPOINT sp2;
DELETE FROM products WHERE product = 'Sprite';
ROLLBACK TO sp1;
COMMIT;

-- Independent Exercise 3: Banking Scenario with Concurrent Withdrawals
-- Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice';
COMMIT;

-- Terminal 2:
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice';
COMMIT;

-- Independent Exercise 4: MAX < MIN Problem with Transactions
-- Sally's query without transaction:
SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop';
-- Joe's query with transaction:
BEGIN;
SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop';
COMMIT;
