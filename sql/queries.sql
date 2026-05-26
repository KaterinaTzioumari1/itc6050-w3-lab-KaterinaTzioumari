#Q1 — Monthly revenue trend

SELECT
    date_trunc('month', order_date) AS month,
    COUNT(*)                        AS orders,
    SUM(revenue)                    AS revenue
FROM shop.orders
GROUP BY date_trunc('month', order_date)
ORDER BY month;

#Q2 — Top 10 products by revenue 

SELECT
    p.product_name,
    SUM(oi.quantity)                        AS total_qty,
    SUM(oi.quantity * oi.unit_price_at_sale) AS revenue
FROM shop.order_items oi
JOIN shop.products p ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 10;

#Q3 — Average order value by status 

SELECT
    status,
    COUNT(*)                                                    AS orders,
    ROUND(AVG(total), 2)                                        AS avg_total,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total)         AS median_total
FROM shop.orders
GROUP BY status
ORDER BY status;

#Q4 — Dormant customers

SELECT
    c.email,
    MAX(o.order_date)                        AS last_order_date,
    CURRENT_DATE - MAX(o.order_date)::date   AS days_dormant
FROM shop.customers c
JOIN shop.orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.email
HAVING MAX(o.order_date) < CURRENT_DATE - INTERVAL '90 days'
ORDER BY days_dormant DESC;

#Q5 — Top customers by lifetime spend, ranked

WITH customer_spend AS (
    SELECT
        c.email,
        SUM(o.total) AS lifetime_spend
    FROM shop.customers c
    JOIN shop.orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.email
)
SELECT
    RANK() OVER (ORDER BY lifetime_spend DESC)                              AS rank,
    email,
    lifetime_spend,
    ROUND(
        LAG(lifetime_spend) OVER (ORDER BY lifetime_spend DESC) - lifetime_spend,
    2)                                                                      AS gap_to_previous
FROM customer_spend
ORDER BY rank
LIMIT 20;