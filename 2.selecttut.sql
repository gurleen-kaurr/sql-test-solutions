-- SQL Test Solutions
-- Below are detailed explanations for each query to clarify reasoning and assumptions.

-- Assumptions: All timestamps are UTC and stored as TIMESTAMP type.

-- 1. Count of purchases per month (excluding refunded purchases)
-- We remove refunded purchases because the question asks only for valid completed purchases.
-- DATE_TRUNC('month', purchase_time) extracts the month bucket.
-- We simply group counts per month.
 Count of purchases per month (excluding refunded purchases)
SELECT DATE_TRUNC('month', purchase_time) AS month,
       COUNT(*) AS purchase_count
FROM transactions
WHERE refund_item IS NULL
GROUP BY 1
ORDER BY 1;

-- 2. How many stores receive at least 5 orders in October 2020?
-- We filter transactions to October 2020 using DATE_TRUNC.
-- Grouping by store_id allows counting per store.
-- HAVING ensures we return stores with at least 5 transactions.
 How many stores receive at least 5 orders in October 2020?
SELECT store_id,
       COUNT(*) AS total_orders
FROM transactions
WHERE DATE_TRUNC('month', purchase_time) = '2020-10-01'
GROUP BY store_id
HAVING COUNT(*) >= 5;

-- 3. Shortest interval (minutes) from purchase to refund per store
-- We compute the interval only where refund_item is not NULL.
-- EXTRACT(EPOCH FROM ...) returns seconds. Dividing by 60 converts to minutes.
-- MIN gives the shortest processing time per store.
 Shortest interval (minutes) from purchase to refund per store
SELECT store_id,
       MIN(EXTRACT(EPOCH FROM (refund_item - purchase_time)) / 60) AS min_minutes
FROM transactions
WHERE refund_item IS NOT NULL
GROUP BY store_id;

-- 4. Gross transaction value of each store's first order
-- We use ROW_NUMBER per store ordered by purchase_time to find the first order.
-- rn = 1 indicates the earliest order for each store.
-- We then select the gross_transaction_value for these orders.
 Gross transaction value of each store's first order
WITH first_order AS (
   SELECT *,
          ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY purchase_time) AS rn
   FROM transactions
)
SELECT store_id, gross_transaction_value
FROM first_order
WHERE rn = 1;

-- 5. Most popular item name buyers order on their first purchase
-- We join transactions with items to get item_name.
-- ROW_NUMBER identifies the first purchase per buyer.
-- We count which item_name appears most as the first purchase.
-- LIMIT 1 gives the most frequent item.
 Most popular item on buyers' first purchase
WITH first_buy AS (
   SELECT t.*, i.item_name,
          ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rn
   FROM transactions t
   JOIN items i ON t.item_id = i.item_id
)
SELECT item_name, COUNT(*) AS cnt
FROM first_buy
WHERE rn = 1
GROUP BY item_name
ORDER BY cnt DESC
LIMIT 1;

-- 6. Refund flag processed only if refund happens within 72 hours of purchase
-- A refund is valid only when refund timestamp <= purchase_time + 72 hours.
-- CASE returns 1 if processed, 0 otherwise.
 Refund flag processed only if refund happens within 72 hours
SELECT *,
   CASE WHEN refund_item IS NOT NULL
        AND refund_item <= purchase_time + INTERVAL '72 hours'
        THEN 1 ELSE 0 END AS refund_processed
FROM transactions;

-- 7. Rank purchases by buyer_id and return only second valid purchase (ignore refunds)
-- We remove refunded purchases by filtering refund_item IS NULL.
-- ROW_NUMBER ranks purchases chronologically.
-- rn = 2 isolates the second purchase per buyer.
 Rank purchases by buyer_id and return only second valid purchase (ignore refunds)
WITH ranked AS (
   SELECT *,
          ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rn
   FROM transactions
   WHERE refund_item IS NULL
)
SELECT *
FROM ranked
WHERE rn = 2;

-- 8. Second transaction time per buyer
-- Unlike Q7, here we do NOT ignore refunds.
-- We assume all buyers have multiple transactions.
-- ROW_NUMBER ensures rn=2 corresponds to the second transaction chronologically.
 Second transaction time per buyer (assume more than two exist)
WITH ranked AS (
   SELECT *,
          ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rn
   FROM transactions
)
SELECT buyer_id, purchase_time AS second_purchase_time
FROM ranked
WHERE rn = 2;
