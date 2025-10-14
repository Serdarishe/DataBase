CREATE DATABASE Cons;

CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);

CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0 AND
        discount_price > 0 AND
        discount_price < regular_price
    )
);


CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER,
    CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

INSERT INTO employees (employee_id, first_name, last_name, age, salary)
VALUES
(1, 'Nursultan', 'Amanzholov', 30, 50000),
(3, 'Yerlan', 'Bekturov', 17, 55000),--age < 18
(2, 'Arman', 'Arshavin', 19, 60000);

INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price)
VALUES (1, 'Laptop', 1000, 800),
       (2, 'Phone', 700, 600),
       (3, 'Tablet', 400, 500);--reg_price < disc_price

INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests)
VALUES (1, '2025-10-15', '2025-10-20', 5),
       (4, '2025-10-01', '2025-10-10', 15),--num_guests not 1<x<10
       (2, '2025-10-10', '2025-10-20', 3);

CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
VALUES (1, 'Laptop', 50, 1000, '2025-10-10 10:00:00');

INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
VALUES (2, NULL, 30, 15, '2025-10-10 10:10:00');

INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
VALUES (3, 'Keyboard', NULL, 50, '2025-10-10 10:15:00');

INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
VALUES (4, 'Monitor', 10, NULL, '2025-10-10 10:20:00');

INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated)
VALUES (5, 'Headphones', 50, 30, NULL);

INSERT INTO customers (customer_id,email,phone,registration_date)
VALUES (1,'kbtu24b@gmail.com','',current_date);

CREATE TABLE users (
    user_id INTEGER,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP
);

CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    CONSTRAINT unique_enrollment UNIQUE (student_id, course_code, semester)
);

ALTER TABLE users
ADD CONSTRAINT unique_username UNIQUE (username),
    ADD CONSTRAINT unique_email UNIQUE (email);

INSERT INTO users (user_id, username, email, created_at)
VALUES
(1, 'Nursultan', 'nursultan@gmail.com', CURRENT_TIMESTAMP),
(2, 'Ayan', 'ayan@gmail.com', CURRENT_TIMESTAMP),
(3, 'Yerlan', 'yerlan@gmail.com', CURRENT_TIMESTAMP),
(4, 'Zhansaya', 'zhansaya@gmail.com', CURRENT_TIMESTAMP),

(5, 'Zhansaya', 'zhansaya@gmail.com', CURRENT_TIMESTAMP);

CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

INSERT INTO departments (dept_id, dept_name, location)
VALUES
(1, 'HR', 'Almaty'),
(2, 'Finance', 'Astana'),
(3, 'Engineering', 'Taldyqorgan');

CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

--Both enforce uniqueness, but a primary key uniquely identifies each row and cannot be NULL,
-- while UNIQUE can allow NULLs and can be applied to multiple columns in the same table.

--Single-column PRIMARY KEY:
-- Use when one column alone can uniquely identify each row.

--Composite PRIMARY KEY:
-- Use when no single column alone is sufficient to uniquely identify a row, but a combination of columns is unique.

-- A table can have only one PRIMARY KEY because it is the main identifier for each row,
-- and it must be unique. However, a table can have multiple UNIQUE constraints
-- because they enforce uniqueness on other columns without defining the primary row identifier.

CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date)
VALUES (1, 'Nursultan Amanzholov', 1, '2025-10-10'),
       (2, 'Ayan Bekturov', 2, '2025-10-15');

INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date)
VALUES (3, 'Yerlan Tokbergenov', 999, '2025-10-20');

CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors,
    publisher_id INTEGER REFERENCES publishers,
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

INSERT INTO authors (author_id, author_name, country)
VALUES
(1, 'Nurzhan Aitmatov', 'Kazakhstan'),
(2, 'Shyngys Turov', 'Kazakhstan'),
(3, 'Aigerim Zhanat', 'Kazakhstan');

INSERT INTO publishers (publisher_id, publisher_name, city)
VALUES
(1, 'Almaty Press', 'Almaty'),
(2, 'Astana Publications', 'Nur-Sultan'),
(3, 'Kazakh Publishing House', 'Almaty');

INSERT INTO books (book_id, title, author_id, publisher_id, publication_year, isbn)
VALUES
(1, 'Journey Through the Steppe', 1, 1, 2020, '978-1234567890'),
(2, 'The Sun of the East', 2, 2, 2019, '978-0987654321'),
(3, 'Wind of the Desert', 3, 3, 2021, '978-1122334455');

CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);

INSERT INTO categories (category_id, category_name)
VALUES
(1, 'Electronics'),
(2, 'Books');

INSERT INTO products_fk (product_id, product_name, category_id)
VALUES
(1, 'Smartphone', 1),
(2, 'Laptop', 1),
(3, 'Java Programming Book', 2);

INSERT INTO orders (order_id, order_date)
VALUES
(1, '2025-10-10'),
(2, '2025-10-12');

INSERT INTO order_items (item_id, order_id, product_id, quantity)
VALUES
(1, 1, 1, 2),
(2, 1, 2, 1),
(3, 2, 3, 3);

DELETE FROM categories WHERE category_id = 1;

DELETE FROM orders WHERE order_id = 1;

DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    registration_date DATE NOT NULL,
    CHECK (length(email) > 0)
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC CHECK (price >= 0) NOT NULL,
    stock_quantity INTEGER CHECK (stock_quantity >= 0) NOT NULL
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    order_date DATE NOT NULL,
    total_amount NUMERIC CHECK (total_amount >= 0) NOT NULL,
    status TEXT CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

CREATE TABLE order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER CHECK (quantity > 0) NOT NULL,
    unit_price NUMERIC CHECK (unit_price >= 0) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);
















