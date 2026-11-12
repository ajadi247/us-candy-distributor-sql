PRAGMA foreign_keys = ON;

CREATE TABLE candy_factories (
    factory TEXT PRIMARY KEY NOT NULL,
    latitude REAL NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude REAL NOT NULL CHECK (longitude BETWEEN -180 AND 180)
);

CREATE TABLE candy_targets (
    division TEXT PRIMARY KEY NOT NULL,
    target_cents INTEGER NOT NULL CHECK (target_cents >= 0)
);

CREATE TABLE candy_products (
    product_id TEXT PRIMARY KEY NOT NULL,
    product_name TEXT NOT NULL,
    division TEXT NOT NULL,
    factory TEXT NOT NULL REFERENCES candy_factories(factory),
    unit_price_cents INTEGER NOT NULL,
    unit_cost_cents INTEGER NOT NULL
);

CREATE TABLE candy_sales (
    row_id INTEGER PRIMARY KEY,
    order_id TEXT NOT NULL,
    order_date TEXT NOT NULL CHECK (date(order_date, '+0 days') IS order_date),
    ship_date TEXT NOT NULL CHECK (date(ship_date, '+0 days') IS ship_date),
    ship_mode TEXT NOT NULL,
    customer_id INTEGER NOT NULL,
    country_region TEXT NOT NULL,
    city TEXT NOT NULL,
    state_province TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    source_division TEXT NOT NULL,
    region TEXT NOT NULL,
    product_id TEXT NOT NULL REFERENCES candy_products(product_id),
    source_product_name TEXT NOT NULL,
    sales_cents INTEGER NOT NULL,
    units INTEGER NOT NULL,
    gross_profit_cents INTEGER NOT NULL,
    cost_cents INTEGER NOT NULL
);

CREATE INDEX sales_country_date ON candy_sales(country_region, order_date);
CREATE INDEX sales_product ON candy_sales(product_id);

CREATE VIEW us_sales AS
SELECT s.*, p.division, p.product_name
FROM candy_sales AS s
JOIN candy_products AS p USING (product_id)
WHERE s.country_region = 'United States';

