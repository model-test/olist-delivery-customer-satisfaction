-- 01_create_order_level_summary.sql
-- Builds the main one-row-per-order table used for dashboard analysis.
-- Assumes the raw Olist tables have already been loaded into SQLite.

DROP TABLE IF EXISTS order_reviews_summary;

CREATE TABLE order_reviews_summary AS
SELECT
    o.order_id,
    AVG(orw.review_score) AS avg_review_score,
    COUNT(orw.review_id) AS review_count,
    MIN(orw.review_score) AS min_review_score,
    MAX(orw.review_score) AS max_review_score
FROM orders AS o
LEFT JOIN order_reviews AS orw
    ON o.order_id = orw.order_id
GROUP BY o.order_id;


DROP TABLE IF EXISTS order_items_summary;

CREATE TABLE order_items_summary AS
SELECT
    oi.order_id,
    COUNT(*) AS item_count,
    COUNT(DISTINCT COALESCE(ct.product_category_name_english, 'Unknown')) AS distinct_category_count,
    GROUP_CONCAT(DISTINCT COALESCE(ct.product_category_name_english, 'Unknown')) AS category_list,
    ROUND(SUM(oi.price), 2) AS total_item_price,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_value,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_item_value
FROM order_items AS oi
LEFT JOIN products AS p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation AS ct
    ON p.product_category_name = ct.product_category_name
GROUP BY oi.order_id;


DROP TABLE IF EXISTS order_level_summary;

CREATE TABLE order_level_summary AS
WITH grouped_data AS (
    SELECT
        o.order_id,
        o.customer_id,
        c.customer_unique_id,
        c.customer_state,
        c.customer_city,
        DATE(o.order_purchase_timestamp) AS purchase_date,
        DATE(o.order_delivered_customer_date) AS delivered_date,
        DATE(o.order_estimated_delivery_date) AS estimated_delivery_date,
        ROUND(julianday(DATE(o.order_delivered_customer_date)) - julianday(DATE(o.order_estimated_delivery_date)), 1) AS delivery_delay_days,
        ROUND(julianday(DATE(o.order_delivered_customer_date)) - julianday(DATE(o.order_purchase_timestamp)), 1) AS delivery_time_days,
        o.order_status,
        ors.avg_review_score,
        COALESCE(ors.review_count, 0) AS review_count,
        ors.min_review_score,
        ors.max_review_score,
        COALESCE(ois.item_count, 0) AS item_count,
        COALESCE(ois.distinct_category_count, 0) AS distinct_category_count,
        COALESCE(ois.category_list, 'No Item Data') AS category_list,
        COALESCE(ois.total_item_price, 0) AS total_item_price,
        COALESCE(ois.total_freight_value, 0) AS total_freight_value,
        COALESCE(ois.total_item_value, 0) AS total_item_value
    FROM orders AS o
    LEFT JOIN order_items_summary AS ois
        ON o.order_id = ois.order_id
    LEFT JOIN order_reviews_summary AS ors
        ON o.order_id = ors.order_id
    LEFT JOIN customers AS c
        ON o.customer_id = c.customer_id
)

SELECT
    order_id,
    customer_id,
    customer_unique_id,
    customer_state,
    customer_city,
    purchase_date,
    delivered_date,
    estimated_delivery_date,
    delivery_delay_days,
    delivery_time_days,
    order_status,
    CASE
        WHEN order_status = 'delivered' AND delivery_delay_days < 0 THEN 'Early'
        WHEN order_status = 'delivered' AND delivery_delay_days = 0 THEN 'On Time'
        WHEN order_status = 'delivered' AND delivery_delay_days > 0 THEN 'Late'
        ELSE NULL
    END AS arrival_status,
    avg_review_score,
    review_count,
    min_review_score,
    max_review_score,
    item_count,
    distinct_category_count,
    category_list,
    total_item_price,
    total_freight_value,
    total_item_value
FROM grouped_data;
