CREATE DATABASE supplychain;
USE supplychain;

 ## Data Cleaning
 
 ##EDA
 -- to see if unitprice  are off
UPDATE order_items
SET TotalItemPrice_NGN = Quantity * UnitPriceAtPurchase_NGN
WHERE TotalItemPrice_NGN IS NULL;

 -- there were 1591 such values which have been fixed
 

/* blank order dates, ship date, expected and actual delivery dates where orders are cancelled */
-- SELECT OrderDate,ShipDate, ExpectedDeliveryDate, ActualDeliveryDate, PaymentStatus 
-- FROM orders -- there are 170 such values and 247 if we exclude          
-- WHERE ShipDate IS NULL 
-- AND ExpectedDeliveryDate IS NULL
-- AND ActualDeliveryDate IS NULL
-- AND OrderDate IS NULL
-- AND OrderStatus ='cancelled';     

-- Profiling Missing Dates
SELECT OrderStatus,
COUNT(*) AS missing_delivery_dates
FROM orders
WHERE ActualDeliveryDate IS NULL 
OR ExpectedDeliveryDate IS NULL
GROUP BY OrderStatus;

-- Replacing Blank Values in Supplier Ratings to 0
UPDATE supplier
SET SupplierRating = 0.0 
WHERE SupplierRating IS NULL; -- 2 rows affected


-- Standardizing the category Column from the product table
UPDATE products
SET Category = TRIM(Category); -- removing extra spaces 4 rows affected

UPDATE products
SET category = 
    CASE
        WHEN LOWER(TRIM(category)) = 'local crafts' THEN 'Local Crafts'
        WHEN LOWER(TRIM(category)) = 'health & beauty' THEN 'Health & Beauty'
        WHEN category = 'Automotive Parts (old)' THEN 'Automotive Parts' 
        ELSE category -- standadardizing names
    END; -- 2 rows affected

-- Checking Blank Negative and 0 StockQuantity
SELECT
    ProductId,
    ProductName,
    StockQuantity
FROM products
WHERE StockQuantity IS NULL OR StockQuantity <= 0; -- 29 values retuned 

desc products;

## Criteria 1
-- 1. Pinpoint Key Product Availability Gaps: 
-- Identify which of the 200 products are most frequently out of stock or are major contributors to Cancelled orders, 
-- especially for shipments to Port Harcourt and surrounding areas, despite the high order volume

-- 1.1 Top Products Most Frequently Out of Stock 
SELECT
	  ProductId,
      ProductName,
      Category,
      StockQuantity AS OutOfStockCount
FROM products 
WHERE ProductStatus = 'outofstock' 
ORDER BY StockQuantity DESC ; -- 53 Products out of 200 of them are out of stock

-- 1.2  Products Cancelled due to Stockout issues and high order volume
 SELECT 
    p.ProductName,
    p.Category,
    COUNT(DISTINCT o.OrderID) AS CancelledOrders
FROM products p
JOIN  order_items oi ON p.ProductID = oi.ProductID
JOIN orders o ON oi.OrderID = o.OrderID
WHERE o.OrderStatus = 'cancelled'
    AND o.ShippingCity = 'Port Harcourt'
    AND p.ProductStatus = 'outofStock'
GROUP BY p.ProductName, p.Category
HAVING CancelledOrders >100
ORDER BY CancelledOrders  DESC; -- There are 46 such Products which are major contributors for stock inavailability;
    
-- 1.3 Total orders vs Cancelled orders in Port Harcourt
SELECT COUNT(*) AS TotalOrders,
COUNT(CASE WHEN OrderStatus='cancelled' THEN OrderStatus END) AS CancelledOrders
FROM orders
WHERE ShippingCity = 'Port Harcourt';

-- 1.4 How often do Stockout  happen for top selling products in Port Harcourt?

-- 1.5 Average Stock Quantity Available in Port Harcourt
WITH average_stock_ph AS (
SELECT 
    ROUND(AVG(p.StockQuantity),2)AS avg_stock
FROM products p
JOIN order_items oi ON p.ProductId = oi.ProductId
JOIN orders o ON oi.OrderID = o.OrderID
WHERE o.ShippingCity = 'Port Harcourt' )

SELECT avg_stock from average_stock_ph;

## Criteria 2
-- 2. Assess Impact on Recent Customer Cohorts: 
--    Determine if fulfillment issues (e.g., significant delays where 
--    ActualDeliveryDate far exceeds ExpectedDeliveryDate, or high cancellation rates) are disproportionately affecting 
--    customers acquired  since March 2024 (RegistrationDate > 2024-03-01),
--    and if this correlates with lower initial repeat purchase rates from these new customers
 
 -- 2.1 Customers Acquired since March 2024
 WITH new_customers AS (
  SELECT 
  CustomerID AS customers_acquired_since_march_2024
 FROM customers
 WHERE RegistrationDate >='2024-03-01')
 
SELECT COUNT(*) AS customer_acquired_2024 FROM new_customers;


-- SELECT 
-- COUNT(*) AS total_customer_count, -- total customers
-- COUNT(CASE WHEN RegistrationDate >='2024-03-01' THEN 1 END) AS customers_acquired_since_march_2024, -- customers since march 2024
-- COUNT(CASE WHEN RegistrationDate <'2024-03-01' THEN 1 END) AS customers_acquired_till_march_2024 FROM customers; -- customers till march 2024
  
 -- 2.2 Finding Delivery Delay where Actual Delivery date exceeds Expected Delivery date affecting newly acquired customers
-- Delivery delay (includes outliers)
 SELECT 
  ShippingMethod, -- Trying to find Average delivery delay according to Shipping Method
  ROUND(AVG(DATEDIFF(ActualDeliveryDate, ExpectedDeliveryDate)),2) AS avg_delivery_delay,
  ROUND(STDDEV(DATEDIFF(ActualDeliveryDate, ExpectedDeliveryDate)),2) AS stddev_delivery_delay
FROM Orders
WHERE 
     ActualDeliveryDate IS NOT NULL 
  AND ExpectedDeliveryDate IS NOT NULL
GROUP BY ShippingMethod;

-- key takeaway: There are outliers present when tried to find average delivery delay either the orders 
-- way too early or too late. This can be a sign of data entry error or inventory issue

-- Cancellation rate for Port Harcourt new customers
WITH Cancellation_rate AS (
 SELECT 
  ROUND(COUNT(CASE WHEN o.OrderStatus = 'cancelled' THEN 1 END) * 100.0 / COUNT(*), 2) AS cancellation_rate
FROM orders o
JOIN customers c ON o.CustomerID = c.CustomerID
WHERE o.ShippingCity = 'Port Harcourt'
  AND c.RegistrationDate >= '2024-03-01')

SELECT * FROM Cancellation_rate;

-- Delivery Delay Distribution by Buckets
SELECT 
  CASE -- Bucketed Delivery Delay vs OrderStatus
    WHEN delivery_delay <= 0 THEN 'On time / Early'
    WHEN delivery_delay <= 3 THEN '0-3 days late'
    WHEN delivery_delay <= 7 THEN '4-7 days late'
    ELSE '8+ days late'
  END AS delay_bucket,
  OrderStatus,
  COUNT(*) AS total_orders
FROM (
  SELECT 
    o.OrderStatus,
    DATEDIFF(o.ActualDeliveryDate, o.ExpectedDeliveryDate) AS delivery_delay
  FROM orders o
  JOIN customers c ON o.CustomerID = c.CustomerID
  WHERE c.RegistrationDate >= '2024-03-01'
    AND o.ShippingCity = 'Port Harcourt'
    AND o.ExpectedDeliveryDate IS NOT NULL
    AND o.ActualDeliveryDate IS NOT NULL
) sub
GROUP BY delay_bucket, OrderStatus;

-- check for outliers
SELECT 
  DATEDIFF(ActualDeliveryDate, ExpectedDeliveryDate) AS delivery_delay,
  COUNT(*) AS frequency
FROM Orders
WHERE 
  ActualDeliveryDate IS NOT NULL 
  AND ExpectedDeliveryDate IS NOT NULL
GROUP BY delivery_delay
ORDER BY frequency DESC;


--  using a cutoff of 30± to finally handle outliers
SELECT
  ShippingMethod,
  ROUND(AVG(CASE 
        WHEN ABS(DATEDIFF(ActualDeliveryDate, ExpectedDeliveryDate)) <= 30 
        THEN DATEDIFF(ActualDeliveryDate, ExpectedDeliveryDate) 
        ELSE NULL 
      END),2) AS avg_delay_capped,
  ROUND(STDDEV(CASE 
           WHEN ABS(DATEDIFF(ActualDeliveryDate, ExpectedDeliveryDate)) <= 30 
           THEN DATEDIFF(ActualDeliveryDate, ExpectedDeliveryDate) 
           ELSE NULL 
         END),2) AS stddev_delay_capped
FROM Orders
WHERE 
  ActualDeliveryDate IS NOT NULL AND ExpectedDeliveryDate IS NOT NULL
GROUP BY ShippingMethod;
 
 -- 2.3 Finding if Delivery Delay correlates with initial purchase repeat rates from new customers
-- Calculating customer purchase repeat rate
-- Repeat Purchase Rate (RPR) = (Number of Repeat Customers / Total Number of Customers) * 100

-- Main correlation logic between delivery delay and repeat purchase rate
WITH new_customers AS (
  SELECT CustomerID
  FROM customers c
  WHERE c.RegistrationDate >= '2024-03-01'

),

customer_order_counts AS (
  SELECT 
    o.CustomerID,
    COUNT(*) AS total_orders
  FROM orders o
  JOIN new_customers nc ON o.CustomerID = nc.CustomerID
  WHERE o.ShippingCity = 'Port Harcourt'
  GROUP BY o.CustomerID
),

new_customer_orders AS (
  SELECT 
    o.OrderID,
    o.CustomerID,
    DATEDIFF(o.ActualDeliveryDate, o.ExpectedDeliveryDate) AS delivery_delay
  FROM orders o
  JOIN new_customers nc ON o.CustomerID = nc.CustomerID
  WHERE 
    o.OrderStatus IN ('delivered', 'shipped')
    AND o.ActualDeliveryDate IS NOT NULL 
    AND o.ExpectedDeliveryDate IS NOT NULL
),

delayed_flagged_customers AS (
  SELECT 
    CustomerID,
    MAX(CASE WHEN delivery_delay >3 THEN 1 ELSE 0 END) AS had_delay
  FROM new_customer_orders
  GROUP BY CustomerID
)

SELECT 
  d.had_delay,
  COUNT(*) AS total_customers,
  COUNT(CASE WHEN c.total_orders > 1 THEN 1 END) AS repeat_customers,
  ROUND(COUNT(CASE WHEN c.total_orders > 1 THEN 1 END) * 100.0 / COUNT(*), 2) AS repeat_purchase_rate
FROM customer_order_counts c
JOIN delayed_flagged_customers d ON c.CustomerID = d.CustomerID
GROUP BY d.had_delay;

##Insights
/*
 Surprisingly, customers who had delayed deliveries had a higher repeat 
 purchase rate (76.8%) compared to those with on-time deliveries (65.8%).

 Cancellation rate for new customers was ~22.08%, nearly equal to old customers and to other cities — 
 suggesting Port Harcourt and new customers were not disproportionately cancelling due to fulfillment delays. */

## Criteria 3
/* 3. Identify Top Supplier-Related Fulfillment Constraints: 
      For the limited set of 15 suppliers, determine which ones are linked to the products experiencing 
      the most severe availability gaps or quality issues (inferred from ReturnStatus) 
      that impede smooth order fulfillment to the Port Harcourt market.  */

SELECT
    s.SupplierID,
    s.SupplierName,
    COUNT(DISTINCT p.ProductID) AS ProductsSupplied,
    
    -- AVAILABILITY GAPS
    SUM(CASE WHEN p.ProductStatus = 'OutOfStock' THEN 1 ELSE 0 END) AS ProductsOutOfStock,
    SUM(CASE WHEN p.StockQuantity < 0 THEN 1 ELSE 0 END) AS NegativeStockCases,
    
    -- FULFILLMENT ISSUES
    COUNT(CASE WHEN o.OrderStatus = 'Cancelled' THEN 1 END) AS CancelledOrders,
    COUNT(CASE WHEN p.ProductStatus = 'OutOfStock' AND o.OrderStatus = 'Cancelled' THEN 1 END) AS CancelledDueToStockout,
    COUNT(CASE 
        WHEN o.ActualDeliveryDate > o.ExpectedDeliveryDate 
             AND o.OrderStatus = 'Cancelled' THEN 1 
        END) AS CancelledDueToDelay,
    
    -- QUALITY ISSUES (returns)
    COUNT(CASE WHEN oi.ReturnStatus IN ('Approved', 'Completed') THEN 1 END) AS TotalReturns,
    COUNT(CASE WHEN oi.ReturnStatus = 'Approved' THEN 1 END) AS ApprovedReturns,
    COUNT(CASE WHEN oi.ReturnStatus = 'Completed' THEN 1 END) AS CompletedReturns

FROM supplier s
JOIN products p ON s.SupplierID = p.SupplierID
JOIN order_items oi ON p.ProductID = oi.ProductID
JOIN orders o ON oi.OrderID = o.OrderID
JOIN customers c ON c.CustomerId = o.CustomerId

WHERE 
    o.ShippingCity = 'Port Harcourt'
     AND c.RegistrationDate >= '2024-03-01'
GROUP BY 
    s.SupplierID, s.SupplierName

ORDER BY 
    CancelledDueToStockout DESC,
    ProductsOutOfStock DESC;
    
##Insights:
# S009 (Bowers and Sons):
-- Supplies 6 products, but has 5301 out-of-stock events and 1162 negative stock cases.
-- 1,206 out of 1,254 cancellations were due to stockouts — nearly 96% stockout-driven!

# S002 (Nguyen–Matthews):
-- While it supplies 9 products, it accounts for 3114 cancelled orders and 4195 negative stock entries — a huge inventory reliability concern.

# S004 (Brown Group) and S011 (Moore Group) also show serious quality and fulfillment issues through return counts and stockouts.

select distinct paymentstatus;
-- payment status missing
 SELECT OrderStatus,
         COUNT(*) AS Count
     FROM orders
     WHERE PaymentStatus IS NULL
     GROUP BY OrderStatus
     ORDER BY COUNT(*) DESC;
     
select * from customers;
select * from supplier;
select * from products;
