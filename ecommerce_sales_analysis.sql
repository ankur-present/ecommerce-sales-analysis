 
USE sales_project;
 
 
SELECT * FROM order_details LIMIT 5;
SELECT * FROM order_list LIMIT 5;
SELECT * FROM sales_target LIMIT 5;
 
SELECT * 
FROM order_list
JOIN order_details ON order_details.`Order ID` = order_list.`Order ID`;
 
SELECT 
    Category,
    SUM(Quantity)                           AS total_quantity,
    SUM(Amount)                             AS total_amount,
    SUM(Profit)                             AS total_profit,
    ROUND(SUM(Profit) / SUM(Amount) * 100, 2) AS profit_percentage
FROM order_details
GROUP BY Category
ORDER BY profit_percentage DESC;
 
 
SELECT 
    Category,
    SUM(Amount)                                             AS total_sales,
    ROUND(SUM(Amount) * 100.0 / SUM(SUM(Amount)) OVER(), 2) AS contribution_percent
FROM order_details
GROUP BY Category;
 
 

SELECT Category, `Sub-Category`, total_sales
FROM (
    SELECT 
        Category,
        `Sub-Category`,
        SUM(Amount) AS total_sales,
        RANK() OVER (PARTITION BY Category ORDER BY SUM(Amount) DESC) AS rnk
    FROM order_details
    GROUP BY Category, `Sub-Category`
) t
WHERE rnk = 1;
 
 
SELECT 
    `Sub-Category`,
    SUM(Profit) AS total_profit
FROM order_details
GROUP BY `Sub-Category`
HAVING total_profit < 0
ORDER BY total_profit ASC;
 
 

SELECT 
    o.CustomerName,
    SUM(d.Amount) AS total_amount
FROM order_details d
JOIN order_list o ON d.`Order ID` = o.`Order ID`
GROUP BY o.CustomerName
ORDER BY total_amount DESC
LIMIT 5;
 
 
SELECT 
    o.CustomerName,
    SUM(d.Amount) AS total_spent,
    CASE 
        WHEN SUM(d.Amount) > 5000 THEN 'High Value'
        WHEN SUM(d.Amount) > 2000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM order_details d
JOIN order_list o ON d.`Order ID` = o.`Order ID`
GROUP BY o.CustomerName
ORDER BY total_spent DESC;
 
 
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'New Customer' 
        ELSE 'Repeat Customer' 
    END AS customer_type,
    COUNT(*) AS customer_count
FROM (
    SELECT 
        o.CustomerName, 
        COUNT(DISTINCT o.`Order ID`) AS order_count
    FROM order_details d
    JOIN order_list o ON d.`Order ID` = o.`Order ID`
    GROUP BY o.CustomerName
) t
GROUP BY customer_type;
 
 
SELECT 
    o.CustomerName,
    COUNT(DISTINCT o.`Order ID`) AS order_count
FROM order_details d
JOIN order_list o ON d.`Order ID` = o.`Order ID`
GROUP BY o.CustomerName
HAVING order_count > 1
ORDER BY order_count DESC;
 
 
SELECT 
    o.State,
    SUM(d.Amount)                               AS total_amount,
    SUM(d.Profit)                               AS total_profit,
    ROUND(SUM(d.Profit) / SUM(d.Amount) * 100, 2) AS profit_margin
FROM order_details d
JOIN order_list o ON d.`Order ID` = o.`Order ID`
GROUP BY o.State
ORDER BY total_amount DESC;
 
 
SELECT 
    o.State, 
    d.Category, 
    SUM(d.Amount)                                   AS total_amount,
    RANK() OVER  (PARTITION BY o.State ORDER BY SUM(d.Amount) DESC)      AS rank_by_sales,
    SUM(d.Profit)                                   AS total_profit,
    RANK() OVER (PARTITION BY o.State  ORDER BY SUM(d.Profit) DESC)       AS rank_by_profit,
    ROUND(SUM(d.Profit) / SUM(d.Amount) * 100, 2)  AS profit_margin
FROM order_details d
JOIN order_list o ON d.`Order ID` = o.`Order ID`
GROUP BY o.State, d.Category;
 
 

SELECT 
    DATE_FORMAT(STR_TO_DATE(o.`Order Date`, '%d-%m-%Y'), '%Y-%m') AS month,
    SUM(d.Amount) AS total_sales
FROM order_details d
JOIN order_list o ON d.`Order ID` = o.`Order ID`
GROUP BY month
ORDER BY month;
 
 
SELECT 
    DATE_FORMAT(STR_TO_DATE(o.`Order Date`, '%d-%m-%Y'), '%Y-%m') AS month,
    SUM(d.Profit) AS total_profit
FROM order_details d
JOIN order_list o ON d.`Order ID` = o.`Order ID`
GROUP BY month
ORDER BY month;
 
 
SELECT 
    month,
    total_sales,
    LAG(total_sales) OVER (ORDER BY month)      AS prev_month_sales,
    ROUND(COALESCE(
        (total_sales - LAG(total_sales) OVER (ORDER BY month))
        / LAG(total_sales) OVER (ORDER BY month) * 100,
    0), 2)                                      AS growth_percent
FROM (
    SELECT 
        DATE_FORMAT(STR_TO_DATE(o.`Order Date`, '%d-%m-%Y'), '%Y-%m') AS month,
        SUM(d.Amount) AS total_sales
    FROM order_details d
    JOIN order_list o ON d.`Order ID` = o.`Order ID`
    GROUP BY month
) t;
 
 

SELECT Category, month, total_sales
FROM (
    SELECT 
        d.Category,
        DATE_FORMAT(STR_TO_DATE(o.`Order Date`, '%d-%m-%Y'), '%Y-%m') AS month,
        SUM(d.Amount) AS total_sales,
        RANK() OVER (PARTITION BY d.Category ORDER BY SUM(d.Amount) DESC) AS rnk
    FROM order_details d
    JOIN order_list o ON d.`Order ID` = o.`Order ID`
    GROUP BY d.Category, month
) t
WHERE rnk = 1;
 
 

SELECT 
    COUNT(DISTINCT o.`Order ID`)                        AS total_orders,
    COUNT(DISTINCT o.CustomerName)                      AS total_customers,
    SUM(d.Amount)                                       AS total_revenue,
    SUM(d.Profit)                                       AS total_profit,
    ROUND(SUM(d.Amount) / COUNT(DISTINCT o.`Order ID`), 2) AS avg_order_value,
    ROUND(SUM(d.Profit) / SUM(d.Amount) * 100, 2)      AS overall_profit_margin
FROM order_details d
JOIN order_list o ON d.`Order ID` = o.`Order ID`;
 
 

SELECT 
    DATE_FORMAT(STR_TO_DATE(o.`Order Date`, '%d-%m-%Y'), '%Y-%m') AS month,
    d.Category,
    SUM(d.Amount)                       AS actual_sales,
    MAX(t.Target)                       AS target_sales,
    SUM(d.Amount) - MAX(t.Target)       AS difference,
    CASE 
        WHEN SUM(d.Amount) >= MAX(t.Target) THEN 'Target Met'
        ELSE 'Target Missed'
    END AS status
FROM order_details d
JOIN order_list o ON d.`Order ID` = o.`Order ID`
JOIN sales_target t 
    ON d.Category = t.Category 
    AND DATE_FORMAT(STR_TO_DATE(o.`Order Date`, '%d-%m-%Y'), '%b-%y') = t.`Month of Order Date`
GROUP BY month, d.Category
ORDER BY month, d.Category;


