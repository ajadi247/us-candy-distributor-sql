SELECT 'total_sales_lines' AS check_name, COUNT(*) AS result FROM candy_sales
UNION ALL SELECT 'distinct_order_ids', COUNT(DISTINCT order_id) FROM candy_sales
UNION ALL SELECT 'distinct_customers', COUNT(DISTINCT customer_id) FROM candy_sales
UNION ALL SELECT 'earliest_order', MIN(order_date) FROM candy_sales
UNION ALL SELECT 'latest_order', MAX(order_date) FROM candy_sales
UNION ALL SELECT 'us_lines', COUNT(*) FROM us_sales
UNION ALL SELECT 'canada_lines', COUNT(*) FROM candy_sales WHERE country_region = 'Canada'
UNION ALL SELECT 'products', COUNT(*) FROM candy_products
UNION ALL SELECT 'divisions', COUNT(DISTINCT division) FROM candy_products
UNION ALL SELECT 'factories', COUNT(*) FROM candy_factories
UNION ALL SELECT 'target_rows', COUNT(*) FROM candy_targets
UNION ALL SELECT 'foreign_key_violations', COUNT(*) FROM pragma_foreign_key_check
UNION ALL SELECT 'integrity_errors', COUNT(*) FROM pragma_integrity_check WHERE integrity_check <> 'ok'
UNION ALL SELECT 'duplicate_row_ids', COUNT(*) - COUNT(DISTINCT row_id) FROM candy_sales
UNION ALL SELECT 'gross_profit_mismatches', COUNT(*) FROM candy_sales
    WHERE sales_cents - cost_cents <> gross_profit_cents
UNION ALL SELECT 'catalog_label_mismatches', COUNT(*) FROM candy_sales AS s
    JOIN candy_products AS p USING (product_id)
    WHERE s.source_division <> p.division OR s.source_product_name <> p.product_name
UNION ALL SELECT 'nonpositive_units_or_sales', COUNT(*) FROM candy_sales WHERE units <= 0 OR sales_cents <= 0
UNION ALL SELECT 'ship_before_order', COUNT(*) FROM candy_sales WHERE ship_date < order_date
UNION ALL SELECT 'ship_after_last_order_year', COUNT(*) FROM candy_sales WHERE ship_date >= '2025-01-01'
UNION ALL SELECT 'us_id_with_matching_product_suffix', COUNT(*) FROM us_sales
    WHERE substr(order_id, -(length(product_id) + 1)) = '-' || product_id
UNION ALL SELECT 'us_order_id_prefixes', COUNT(DISTINCT substr(order_id, 1, length(order_id) - length(product_id) - 1))
    FROM us_sales WHERE substr(order_id, -(length(product_id) + 1)) = '-' || product_id;

