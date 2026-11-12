-- All measures are based on U.S. customer destinations and order date.
-- Monetary totals use integer cents before display in dollars.

-- output: overview
SELECT COUNT(*) AS sales_lines, COUNT(DISTINCT order_id) AS order_ids,
       COUNT(DISTINCT customer_id) AS customers, SUM(units) AS units,
       SUM(sales_cents) / 100.0 AS revenue,
       SUM(cost_cents) / 100.0 AS manufacturing_cost,
       SUM(gross_profit_cents) / 100.0 AS gross_profit,
       ROUND(100.0 * SUM(gross_profit_cents) / NULLIF(SUM(sales_cents), 0), 2) AS gross_margin_pct
FROM us_sales;

-- output: annual
WITH annual AS (
    SELECT substr(order_date, 1, 4) AS year, COUNT(DISTINCT order_id) AS order_ids,
           SUM(sales_cents) / 100.0 AS revenue,
           SUM(gross_profit_cents) / 100.0 AS gross_profit,
           ROUND(100.0 * SUM(gross_profit_cents) / NULLIF(SUM(sales_cents), 0), 2) AS gross_margin_pct
    FROM us_sales
    GROUP BY year
), prior AS (
    SELECT *, LAG(revenue) OVER (ORDER BY year) AS prior_revenue
    FROM annual
)
SELECT year, order_ids, revenue, gross_profit, gross_margin_pct,
       ROUND(100.0 * (revenue - prior_revenue) / NULLIF(prior_revenue, 0), 2) AS revenue_yoy_pct
FROM prior
ORDER BY year;

-- output: monthly
SELECT substr(order_date, 1, 7) AS month, COUNT(DISTINCT order_id) AS order_ids,
       SUM(sales_cents) / 100.0 AS revenue, SUM(gross_profit_cents) / 100.0 AS gross_profit,
       ROUND(100.0 * SUM(gross_profit_cents) / NULLIF(SUM(sales_cents), 0), 2) AS gross_margin_pct
FROM us_sales
GROUP BY month
ORDER BY month;

-- output: divisions
SELECT division, COUNT(DISTINCT order_id) AS order_ids, SUM(units) AS units,
       SUM(sales_cents) / 100.0 AS revenue, SUM(gross_profit_cents) / 100.0 AS gross_profit,
       ROUND(100.0 * SUM(gross_profit_cents) / NULLIF(SUM(sales_cents), 0), 2) AS gross_margin_pct
FROM us_sales
GROUP BY division
ORDER BY gross_profit DESC, division;

-- output: products
SELECT product_id, product_name, division, COUNT(DISTINCT order_id) AS order_ids, SUM(units) AS units,
       SUM(sales_cents) / 100.0 AS revenue, SUM(gross_profit_cents) / 100.0 AS gross_profit,
       ROUND(100.0 * SUM(gross_profit_cents) / NULLIF(SUM(sales_cents), 0), 2) AS gross_margin_pct
FROM us_sales
GROUP BY product_id, product_name, division
ORDER BY gross_profit DESC, product_id;

-- output: states
SELECT state_province AS state, COUNT(DISTINCT order_id) AS order_ids, SUM(units) AS units,
       SUM(sales_cents) / 100.0 AS revenue, SUM(gross_profit_cents) / 100.0 AS gross_profit,
       ROUND(100.0 * SUM(gross_profit_cents) / NULLIF(SUM(sales_cents), 0), 2) AS gross_margin_pct
FROM us_sales
GROUP BY state_province
ORDER BY revenue DESC, state;

