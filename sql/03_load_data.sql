-- ─────────────────────────────────────────────────────────────────────
-- ITC 6050 — Week 2 Lab
-- Synthetic data loader for the shop_lab e-commerce database
-- ─────────────────────────────────────────────────────────────────────
-- Run AFTER 01_physical_schema.sql.
--
-- Generates:
--    50  categories
--   1 000 products
--  10 000 customers
-- 100 000 orders (spread over the last 2 years)
-- 500 000 order items (avg 5 per order)
--
-- Run from psql:
--   \i 03_load_data.sql
-- Or from the host shell:
--   docker exec -i itc6050_pg psql -U itc6050 -d shop_lab < 03_load_data.sql
-- ─────────────────────────────────────────────────────────────────────

SET search_path TO shop;

-- Clear any prior data so the script is re-runnable
TRUNCATE order_item, orders, address, product, category, customer
  RESTART IDENTITY CASCADE;

-- ─────────────────────────────────────────────────────────────────────
-- CATEGORIES — 50
-- ─────────────────────────────────────────────────────────────────────
INSERT INTO category (name)
SELECT 'Category ' || g
FROM   generate_series(1, 50) g;

-- ─────────────────────────────────────────────────────────────────────
-- PRODUCTS — 1 000, evenly spread across the 50 categories
-- ─────────────────────────────────────────────────────────────────────
INSERT INTO product (category_id, name, unit_price)
SELECT
  ((g - 1) % 50) + 1                          AS category_id,
  'Product ' || g                              AS name,
  ROUND((random() * 200 + 5)::numeric, 2)      AS unit_price
FROM generate_series(1, 1000) g;

-- ─────────────────────────────────────────────────────────────────────
-- CUSTOMERS — 10 000
-- ─────────────────────────────────────────────────────────────────────
INSERT INTO customer (email, first_name, last_name)
SELECT
  'cust' || g || '@example.com'  AS email,
  'First' || g                    AS first_name,
  'Last'  || g                    AS last_name
FROM generate_series(1, 10000) g;

-- ─────────────────────────────────────────────────────────────────────
-- ADDRESSES — one default address per customer
-- ─────────────────────────────────────────────────────────────────────
INSERT INTO address (customer_id, line1, city, postcode, country, is_default)
SELECT
  g,
  g || ' Sample Street',
  (ARRAY['Athens','Thessaloniki','London','Berlin','Paris','Madrid','Rome'])
    [ceil(random() * 7)],
  LPAD(((random() * 99999)::int)::text, 5, '0'),
  (ARRAY['GR','GR','UK','DE','FR','ES','IT'])[ceil(random() * 7)],
  TRUE
FROM generate_series(1, 10000) g;

-- ─────────────────────────────────────────────────────────────────────
-- ORDERS — 100 000, spread over the last 2 years
-- ─────────────────────────────────────────────────────────────────────
INSERT INTO orders (customer_id, order_date, status, total)
SELECT
  ((g - 1) % 10000) + 1                                                  AS customer_id,
  NOW() - (random() * INTERVAL '730 days')                                AS order_date,
  (ARRAY['new','paid','shipped','delivered','cancelled'])[ceil(random()*5)] AS status,
  ROUND((random() * 500 + 10)::numeric, 2)                                AS total
FROM generate_series(1, 100000) g;

-- ─────────────────────────────────────────────────────────────────────
-- ORDER_ITEMS — 500 000 (≈ 5 per order on average)
-- ─────────────────────────────────────────────────────────────────────
INSERT INTO order_item (order_id, product_id, quantity, unit_price_at_sale)
SELECT
  ((g - 1) % 100000) + 1                       AS order_id,
  ((g - 1) % 1000) + 1                          AS product_id,
  (ceil(random() * 5))::int                     AS quantity,
  ROUND((random() * 200 + 5)::numeric, 2)       AS unit_price_at_sale
FROM generate_series(1, 500000) g;

-- ─────────────────────────────────────────────────────────────────────
-- Refresh planner statistics so EXPLAIN ANALYZE has good estimates
-- ─────────────────────────────────────────────────────────────────────
ANALYZE;

-- ─────────────────────────────────────────────────────────────────────
-- Verify row counts
-- ─────────────────────────────────────────────────────────────────────
SELECT 'category'   AS table_name, COUNT(*) AS rows FROM category
UNION ALL SELECT 'product',    COUNT(*) FROM product
UNION ALL SELECT 'customer',   COUNT(*) FROM customer
UNION ALL SELECT 'address',    COUNT(*) FROM address
UNION ALL SELECT 'orders',     COUNT(*) FROM orders
UNION ALL SELECT 'order_item', COUNT(*) FROM order_item
ORDER  BY table_name;
