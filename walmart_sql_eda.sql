-- 🛒 Walmart Business Intelligence Analysis (MySQL Version)
-- Objective: Strategic problem-solving using cleaned retail transactional data.

-- ====================================================================
-- Q1: Payment Method Popularity
-- Reason: Identifying the most used channels helps prioritize digital vs. cash infrastructure 
-- and negotiate better processing fees with payment vendors.
-- ====================================================================
SELECT 
    payment_method,
    COUNT(*) AS transaction_count,
    SUM(quantity) AS total_units_sold
FROM walmart_data
GROUP BY payment_method
ORDER BY transaction_count DESC;



-- ====================================================================
-- Q2: Highest Rated Category per Branch
-- Reason: Pinpointing the "Hero Category" for each branch allows for localized 
-- marketing and inventory stocking tailored to regional preferences.
-- ====================================================================

SELECT branch, category, average_rating
FROM (
    SELECT 
        branch,
        category,
        AVG(rating) AS average_rating,
        RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) AS category_rank
    FROM walmart_data
    GROUP BY branch, category
) AS ranked_table
WHERE category_rank = 1;


-- ====================================================================
-- Q3: Busiest Day for Each Branch
-- Reason: peaks in volume help managers optimize labor costs. 
-- For example, scheduling 20% more staff on a branch's peak day.
-- ====================================================================
SELECT branch, day_name, transaction_volume
FROM (
    SELECT 
        branch,
        DATE_FORMAT(STR_TO_DATE(date, '%d/%m/%y'), '%W') AS day_name,
        COUNT(*) AS transaction_volume,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS day_rank
    FROM walmart_data
    GROUP BY branch, day_name
) AS ranked_days
WHERE day_rank = 1;

-- ====================================================================
-- Q4: Total Quantity Sold by Payment Method
-- Reason: This analysis reveals "Basket Size" trends. If customers using digital 
-- methods (like E-wallets or Cards) purchase higher quantities than cash users, 
-- Walmart can implement "Bulk-Buy" digital coupons to further drive up the 
-- Average Order Value (AOV).
-- ====================================================================
SELECT 
    payment_method,
    SUM(quantity) AS total_quantity_sold
FROM walmart_data
GROUP BY payment_method
ORDER BY total_quantity_sold DESC;


-- ====================================================================
-- Q5: Category Ratings by City (Quality Audit)
-- Reason: Low ratings in specific cities signal localized issues like supply 
-- chain damage or a need for regional staff training.
-- ====================================================================
SELECT 
    city,
    category,
    MIN(rating) AS lowest_rating,
    MAX(rating) AS highest_rating,
    AVG(rating) AS mean_rating
FROM walmart_data
GROUP BY city, category
ORDER BY city, mean_rating DESC;


-- ====================================================================
-- Q6: Profit Analysis by Category (Financial Performance)
-- Reason: Profit margin dictates business health. This helps decide which 
-- categories to scale and which to optimize.
-- ====================================================================
SELECT 
    category,
    SUM(total) AS gross_revenue,
    SUM(total * profit_margin) AS net_profit
FROM walmart_data
GROUP BY category
ORDER BY net_profit DESC;

-- ====================================================================
-- Q7: Most Common Payment Method per Branch
-- Reason: This identifies regional payment preferences. If a branch has a high 
-- 'Cash' preference, it requires more physical security and frequent cash pickups. 
-- High 'E-wallet' branches are ideal candidates for testing new digital-only 
-- promotions or self-checkout kiosks.
-- ====================================================================

WITH branch_payment_meta AS (
    SELECT 
        branch,
        payment_method,
        COUNT(*) AS transaction_count,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS payment_rank
    FROM walmart_data
    GROUP BY branch, payment_method
)
SELECT 
    branch, 
    payment_method AS preferred_payment_method,
    transaction_count
FROM branch_payment_meta
WHERE payment_rank = 1;

-- ====================================================================
-- Q8: Shift Analysis (Staffing Strategy)
-- Reason: Identifying the peak "Afternoon" rush proves that restocking 
-- should happen in the "Morning" to avoid shelf outages during traffic.
-- ====================================================================

SELECT
    branch,
    CASE 
        WHEN HOUR(time) < 12 THEN 'Morning'
        WHEN HOUR(time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS business_shift,
    COUNT(*) AS total_invoices
FROM walmart_data
GROUP BY branch, business_shift
ORDER BY branch, total_invoices DESC;


-- ====================================================================
-- Q9: Revenue Churn / Growth Analysis (2022 vs 2023)
-- Reason: identifies locations losing market share. 
-- Note: MySQL uses different date extraction and division handling.
-- ====================================================================
WITH rev_2022 AS (
    SELECT branch, SUM(total) AS revenue
    FROM walmart_data
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%y')) = 2022
    GROUP BY branch
),
rev_2023 AS (
    SELECT branch, SUM(total) AS revenue
    FROM walmart_data
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%y')) = 2023
    GROUP BY branch
)
SELECT 
    prev.branch,
    prev.revenue AS revenue_2022,
    curr.revenue AS revenue_2023,
    ROUND(
        ((prev.revenue - curr.revenue) / NULLIF(prev.revenue, 0)) * 100, 
        2
    ) AS revenue_decrease_percentage
FROM rev_2022 AS prev
JOIN rev_2023 AS curr ON prev.branch = curr.branch
WHERE prev.revenue > curr.revenue
ORDER BY revenue_decrease_percentage DESC
LIMIT 5;