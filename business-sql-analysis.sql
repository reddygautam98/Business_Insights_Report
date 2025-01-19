-- Create the business_insights table
CREATE TABLE business_insights (
    id SERIAL PRIMARY KEY,
    sales_person VARCHAR(100),
    geography VARCHAR(50),
    product VARCHAR(100),
    sale_date DATE,
    sales DECIMAL(10,2),
    boxes INTEGER
);

-- Index creation for better query performance
CREATE INDEX idx_sales_person ON business_insights(sales_person);
CREATE INDEX idx_geography ON business_insights(geography);
CREATE INDEX idx_product ON business_insights(product);
CREATE INDEX idx_sale_date ON business_insights(sale_date);

-- 1. Product Analysis

-- Top performing products by total sales
SELECT 
    product,
    ROUND(SUM(sales), 2) as total_sales,
    SUM(boxes) as total_boxes,
    ROUND(AVG(sales), 2) as avg_sale_per_transaction,
    COUNT(*) as number_of_transactions,
    ROUND(SUM(sales)/SUM(boxes), 2) as revenue_per_box
FROM business_insights
GROUP BY product
ORDER BY total_sales DESC;

-- Monthly product performance
SELECT 
    DATE_TRUNC('month', sale_date) as month,
    product,
    ROUND(SUM(sales), 2) as monthly_sales,
    SUM(boxes) as monthly_boxes,
    COUNT(*) as transaction_count
FROM business_insights
GROUP BY DATE_TRUNC('month', sale_date), product
ORDER BY month, monthly_sales DESC;

-- 2. Geographic Analysis

-- Sales performance by geography
SELECT 
    geography,
    ROUND(SUM(sales), 2) as total_sales,
    SUM(boxes) as total_boxes,
    COUNT(DISTINCT sales_person) as number_of_sales_people,
    COUNT(*) as number_of_transactions,
    ROUND(AVG(sales), 2) as avg_sale_per_transaction
FROM business_insights
GROUP BY geography
ORDER BY total_sales DESC;

-- Monthly geographic performance
SELECT 
    DATE_TRUNC('month', sale_date) as month,
    geography,
    ROUND(SUM(sales), 2) as monthly_sales,
    COUNT(*) as transaction_count,
    ROUND(AVG(sales), 2) as avg_sale
FROM business_insights
GROUP BY DATE_TRUNC('month', sale_date), geography
ORDER BY month, monthly_sales DESC;

-- 3. Sales Team Analysis

-- Overall sales person performance
SELECT 
    sales_person,
    ROUND(SUM(sales), 2) as total_sales,
    SUM(boxes) as total_boxes,
    COUNT(*) as number_of_transactions,
    ROUND(AVG(sales), 2) as avg_sale_per_transaction,
    COUNT(DISTINCT geography) as number_of_regions,
    COUNT(DISTINCT product) as number_of_products
FROM business_insights
GROUP BY sales_person
ORDER BY total_sales DESC;

-- Sales person performance by product
SELECT 
    sales_person,
    product,
    ROUND(SUM(sales), 2) as total_sales,
    SUM(boxes) as total_boxes,
    COUNT(*) as number_of_transactions
FROM business_insights
GROUP BY sales_person, product
ORDER BY sales_person, total_sales DESC;

-- 4. Time-based Analysis

-- Monthly sales trends
SELECT 
    DATE_TRUNC('month', sale_date) as month,
    ROUND(SUM(sales), 2) as monthly_sales,
    SUM(boxes) as monthly_boxes,
    COUNT(*) as number_of_transactions,
    COUNT(DISTINCT sales_person) as active_sales_people
FROM business_insights
GROUP BY DATE_TRUNC('month', sale_date)
ORDER BY month;

-- Day of week analysis
SELECT 
    EXTRACT(DOW FROM sale_date) as day_of_week,
    ROUND(AVG(sales), 2) as avg_daily_sales,
    ROUND(SUM(sales), 2) as total_sales,
    COUNT(*) as number_of_transactions
FROM business_insights
GROUP BY EXTRACT(DOW FROM sale_date)
ORDER BY day_of_week;

-- 5. Advanced Analysis

-- Top product by geography
WITH RankedProducts AS (
    SELECT 
        geography,
        product,
        ROUND(SUM(sales), 2) as total_sales,
        RANK() OVER (PARTITION BY geography ORDER BY SUM(sales) DESC) as rank
    FROM business_insights
    GROUP BY geography, product
)
SELECT 
    geography,
    product,
    total_sales
FROM RankedProducts
WHERE rank = 1
ORDER BY total_sales DESC;

-- Sales person efficiency
SELECT 
    sales_person,
    ROUND(SUM(sales), 2) as total_sales,
    SUM(boxes) as total_boxes,
    COUNT(*) as number_of_transactions,
    ROUND(SUM(sales)/SUM(boxes), 2) as revenue_per_box,
    ROUND(SUM(sales)/COUNT(*), 2) as revenue_per_transaction
FROM business_insights
GROUP BY sales_person
ORDER BY revenue_per_box DESC;

-- Product combination analysis
SELECT 
    b1.product as product1,
    b2.product as product2,
    COUNT(*) as combination_count,
    ROUND(SUM(b1.sales + b2.sales), 2) as combined_sales
FROM business_insights b1
JOIN business_insights b2 
    ON b1.sales_person = b2.sales_person 
    AND b1.sale_date = b2.sale_date 
    AND b1.product < b2.product
GROUP BY b1.product, b2.product
HAVING COUNT(*) > 10
ORDER BY combination_count DESC;

-- 6. Performance Metrics

-- Monthly growth rates
WITH MonthlyStats AS (
    SELECT 
        DATE_TRUNC('month', sale_date) as month,
        SUM(sales) as monthly_sales
    FROM business_insights
    GROUP BY DATE_TRUNC('month', sale_date)
)
SELECT 
    month,
    monthly_sales,
    LAG(monthly_sales) OVER (ORDER BY month) as prev_month_sales,
    ROUND(
        ((monthly_sales - LAG(monthly_sales) OVER (ORDER BY month)) 
        / LAG(monthly_sales) OVER (ORDER BY month) * 100), 2
    ) as growth_rate
FROM MonthlyStats
ORDER BY month;

-- Sales person performance quartiles
WITH SalesStats AS (
    SELECT 
        sales_person,
        SUM(sales) as total_sales,
        COUNT(*) as transaction_count
    FROM business_insights
    GROUP BY sales_person
)
SELECT 
    sales_person,
    total_sales,
    transaction_count,
    NTILE(4) OVER (ORDER BY total_sales) as sales_quartile
FROM SalesStats
ORDER BY total_sales DESC;

-- 7. Data Quality Checks

-- Check for unusual sales patterns
SELECT 
    sales_person,
    sale_date,
    sales,
    boxes,
    ROUND(sales/boxes, 2) as price_per_box
FROM business_insights
WHERE sales/boxes > (
    SELECT AVG(sales/boxes) + 2*STDDEV(sales/boxes)
    FROM business_insights
)
ORDER BY price_per_box DESC;

-- Transaction frequency analysis
SELECT 
    sales_person,
    MIN(sale_date) as first_sale,
    MAX(sale_date) as last_sale,
    COUNT(*) as total_transactions,
    ROUND(
        COUNT(*)::NUMERIC / 
        (EXTRACT(EPOCH FROM (MAX(sale_date) - MIN(sale_date)))/(24*60*60)),
        2
    ) as transactions_per_day
FROM business_insights
GROUP BY sales_person
ORDER BY transactions_per_day DESC;

-- Export summary views
CREATE VIEW product_summary AS
SELECT 
    product,
    ROUND(SUM(sales), 2) as total_sales,
    SUM(boxes) as total_boxes,
    COUNT(*) as transaction_count,
    COUNT(DISTINCT sales_person) as number_of_sales_people,
    ROUND(AVG(sales), 2) as avg_sale
FROM business_insights
GROUP BY product;

CREATE VIEW geography_summary AS
SELECT 
    geography,
    ROUND(SUM(sales), 2) as total_sales,
    SUM(boxes) as total_boxes,
    COUNT(*) as transaction_count,
    COUNT(DISTINCT sales_person) as number_of_sales_people,
    ROUND(AVG(sales), 2) as avg_sale
FROM business_insights
GROUP BY geography;

CREATE VIEW salesperson_summary AS
SELECT 
    sales_person,
    ROUND(SUM(sales), 2) as total_sales,
    SUM(boxes) as total_boxes,
    COUNT(*) as transaction_count,
    COUNT(DISTINCT product) as number_of_products,
    COUNT(DISTINCT geography) as number_of_regions,
    ROUND(AVG(sales), 2) as avg_sale
FROM business_insights
GROUP BY sales_person;