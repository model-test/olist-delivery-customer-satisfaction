-- 02_create_dashboard_summary_tables.sql
-- Builds the dashboard-level summary tables from order_level_summary.

DROP TABLE IF EXISTS arrival_status_summary;

CREATE TABLE arrival_status_summary AS
SELECT
    arrival_status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_classified_orders
FROM order_level_summary
WHERE arrival_status IS NOT NULL
GROUP BY arrival_status
ORDER BY order_count DESC;


DROP TABLE IF EXISTS review_score_by_arrival_status;

CREATE TABLE review_score_by_arrival_status AS
SELECT
    arrival_status,
    COUNT(*) AS reviewed_order_count,
    ROUND(AVG(avg_review_score), 2) AS avg_review_score,
    ROUND(AVG(delivery_time_days), 2) AS avg_delivery_time_days,
    ROUND(AVG(delivery_delay_days), 2) AS avg_delivery_delay_days
FROM order_level_summary
WHERE arrival_status IS NOT NULL
    AND avg_review_score IS NOT NULL
GROUP BY arrival_status;


DROP TABLE IF EXISTS state_delivery_review_summary;

CREATE TABLE state_delivery_review_summary AS
SELECT
    customer_state,
    COUNT(*) AS classified_order_count,
    COUNT(CASE WHEN arrival_status = 'Late' THEN 1 END) AS late_order_count,
    ROUND(COUNT(CASE WHEN arrival_status = 'Late' THEN 1 END) * 100.0 / COUNT(*), 2) AS late_delivery_rate,
    COUNT(avg_review_score) AS reviewed_order_count,
    ROUND(AVG(avg_review_score), 2) AS avg_review_score
FROM order_level_summary
WHERE arrival_status IS NOT NULL
GROUP BY customer_state
HAVING COUNT(*) >= 300
ORDER BY classified_order_count DESC;


DROP TABLE IF EXISTS monthly_delivery_review_summary;

CREATE TABLE monthly_delivery_review_summary AS
SELECT
    strftime('%Y-%m', purchase_date) AS purchase_month,
    COUNT(*) AS classified_order_count,
    COUNT(CASE WHEN arrival_status = 'Late' THEN 1 END) AS late_order_count,
    ROUND(COUNT(CASE WHEN arrival_status = 'Late' THEN 1 END) * 100.0 / COUNT(*), 2) AS late_delivery_rate,
    COUNT(avg_review_score) AS reviewed_order_count,
    ROUND(AVG(avg_review_score), 2) AS avg_review_score,
    ROUND(AVG(delivery_time_days), 2) AS avg_delivery_time_days,
    ROUND(AVG(delivery_delay_days), 2) AS avg_delivery_delay_days
FROM order_level_summary
WHERE arrival_status IS NOT NULL
GROUP BY purchase_month
ORDER BY purchase_month ASC;
