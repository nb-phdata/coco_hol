-- ========================================================
-- NORTHWINDS ANALYTICS - EXAMPLE QUERY SUITE
-- ========================================================

-- 1. INVENTORY VALUATION BY CATEGORY
-- Helps leadership understand where capital is tied up in the warehouse.
SELECT 
    c.CategoryName, 
    COUNT(p.ProductID) AS ProductCount,
    SUM(p.UnitsInStock) AS TotalUnits,
    SUM(p.UnitsInStock * p.UnitPrice) AS InventoryValue
FROM COCO_HOL_DB.NORTHWINDS.PRODUCTS p
JOIN COCO_HOL_DB.NORTHWINDS.CATEGORIES c ON p.CategoryID = c.CategoryID
GROUP BY 1
ORDER BY InventoryValue DESC;

-- 2. TOP 5 CUSTOMERS BY LIFETIME SPEND
-- Identifies VIP customers for loyalty programs or account management.
SELECT 
    c.CompanyName, 
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS TotalSpent,
    COUNT(DISTINCT o.OrderID) AS TotalOrders
FROM COCO_HOL_DB.NORTHWINDS.CUSTOMERS c
JOIN COCO_HOL_DB.NORTHWINDS.ORDERS o ON c.CustomerID = o.CustomerID
JOIN COCO_HOL_DB.NORTHWINDS.ORDER_DETAILS od ON o.OrderID = od.OrderID
GROUP BY 1
ORDER BY TotalSpent DESC
LIMIT 5;

-- 3. EMPLOYEE SALES PERFORMANCE LEAGUE
-- Ranks sales staff by total revenue generation (after discounts).
SELECT 
    e.FirstName || ' ' || e.LastName AS EmployeeName,
    COUNT(DISTINCT o.OrderID) AS OrdersHandled,
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS RevenueGenerated
FROM COCO_HOL_DB.NORTHWINDS.EMPLOYEES e
JOIN COCO_HOL_DB.NORTHWINDS.ORDERS o ON e.EmployeeID = o.EmployeeID
JOIN COCO_HOL_DB.NORTHWINDS.ORDER_DETAILS od ON o.OrderID = od.OrderID
GROUP BY 1
ORDER BY RevenueGenerated DESC;

-- 4. STOCK REORDER ALERT
-- Operational query identifying items that are below the reorder threshold.
SELECT 
    ProductName, 
    UnitsInStock, 
    UnitsOnOrder, 
    ReorderLevel
FROM COCO_HOL_DB.NORTHWINDS.PRODUCTS
WHERE Discontinued = 0 
  AND (UnitsInStock + UnitsOnOrder) <= ReorderLevel;

-- 5. AVERAGE SHIPPING DELAY BY CARRIER
-- Evaluates the logistics efficiency of different shipping partners.
SELECT 
    s.CompanyName AS ShipperName,
    ROUND(AVG(DATEDIFF('day', o.OrderDate, o.ShippedDate)), 2) AS AvgDaysToShip,
    MAX(DATEDIFF('day', o.OrderDate, o.ShippedDate)) AS MaxDelay
FROM COCO_HOL_DB.NORTHWINDS.ORDERS o
JOIN COCO_HOL_DB.NORTHWINDS.SHIPPERS s ON o.ShipVia = s.ShipperID
WHERE o.ShippedDate IS NOT NULL
GROUP BY 1;

-- 6. MONTHLY REVENUE GROWTH TREND
-- Visualizes business seasonality and monthly performance.
SELECT 
    DATE_TRUNC('MONTH', OrderDate) AS SalesMonth,
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS MonthlyRevenue
FROM COCO_HOL_DB.NORTHWINDS.ORDERS o
JOIN COCO_HOL_DB.NORTHWINDS.ORDER_DETAILS od ON o.OrderID = od.OrderID
GROUP BY 1
ORDER BY 1;

-- 7. DISCOUNT VS. SALES VOLUME ANALYSIS
-- Checks if higher discounts correlate with significantly higher volume.
SELECT 
    p.ProductName,
    od.Discount,
    COUNT(od.OrderID) AS OrderFrequency,
    SUM(od.Quantity) AS TotalQuantitySold
FROM COCO_HOL_DB.NORTHWINDS.ORDER_DETAILS od
JOIN COCO_HOL_DB.NORTHWINDS.PRODUCTS p ON od.ProductID = p.ProductID
WHERE od.Discount > 0
GROUP BY 1, 2
ORDER BY p.ProductName, od.Discount DESC;

-- 8. REGIONAL SALES STAFF COVERAGE
-- Analyzes human resource distribution across business territories.
SELECT 
    r.RegionDescription, 
    t.TerritoryDescription,
    COUNT(et.EmployeeID) AS StaffCount
FROM COCO_HOL_DB.NORTHWINDS.REGION r
JOIN COCO_HOL_DB.NORTHWINDS.TERRITORIES t ON r.RegionID = t.RegionID
LEFT JOIN COCO_HOL_DB.NORTHWINDS.EMPLOYEETERRITORIES et ON t.TerritoryID = et.TerritoryID
GROUP BY 1, 2
ORDER BY StaffCount DESC;

-- 9. ACTIVITY BY CUSTOMER DEMOGRAPHIC
-- Breaks down the customer base by demographic categorization.
SELECT 
    cd.CustomerDesc, 
    COUNT(ccd.CustomerID) AS CustomerCount
FROM COCO_HOL_DB.NORTHWINDS.CUSTOMERDEMOGRAPHICS cd
LEFT JOIN COCO_HOL_DB.NORTHWINDS.CUSTOMERCUSTOMERDEMO ccd ON cd.CustomerTypeID = ccd.CustomerTypeID
GROUP BY 1;

-- 10. BEST-SELLING PRODUCT PER CATEGORY (WINDOW FUNCTION)
-- Uses a Common Table Expression (CTE) to find the #1 product in every category.
WITH RankedProducts AS (
    SELECT 
        c.CategoryName, 
        p.ProductName,
        SUM(od.Quantity) AS TotalSold,
        RANK() OVER (PARTITION BY c.CategoryName ORDER BY SUM(od.Quantity) DESC) as SalesRank
    FROM COCO_HOL_DB.NORTHWINDS.PRODUCTS p
    JOIN COCO_HOL_DB.NORTHWINDS.CATEGORIES c ON p.CategoryID = c.CategoryID
    JOIN COCO_HOL_DB.NORTHWINDS.ORDER_DETAILS od ON p.ProductID = od.ProductID
    GROUP BY 1, 2
)
SELECT * FROM RankedProducts 
WHERE SalesRank = 1;

-- ========================================================
-- NORTHWINDS ADVANCED ANALYTICS - COMPLEX QUERY SUITE
-- ========================================================

-- 1. YEAR-OVER-YEAR (YoY) GROWTH BY CATEGORY
-- Compares category performance in 1997 vs 1998 to identify growth trends.
WITH CategorySales AS (
    SELECT 
        c.CategoryName,
        EXTRACT(YEAR FROM o.OrderDate) AS SalesYear,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS YearlyRevenue
    FROM COCO_HOL_DB.NORTHWINDS.ORDERS o
    JOIN COCO_HOL_DB.NORTHWINDS.ORDER_DETAILS od ON o.OrderID = od.OrderID
    JOIN COCO_HOL_DB.NORTHWINDS.PRODUCTS p ON od.ProductID = p.ProductID
    JOIN COCO_HOL_DB.NORTHWINDS.CATEGORIES c ON p.CategoryID = c.CategoryID
    GROUP BY 1, 2
)
SELECT 
    CategoryName,
    ROUND(SUM(CASE WHEN SalesYear = 1997 THEN YearlyRevenue ELSE 0 END), 2) AS Sales_1997,
    ROUND(SUM(CASE WHEN SalesYear = 1998 THEN YearlyRevenue ELSE 0 END), 2) AS Sales_1998,
    ROUND(((Sales_1998 - Sales_1997) / NULLIF(Sales_1997, 0)) * 100, 2) AS PercentageGrowth
FROM CategorySales
GROUP BY 1
ORDER BY PercentageGrowth DESC;

-- 2. RECURSIVE EMPLOYEE HIERARCHY (ORCHART)
-- Uses a Recursive CTE to map the reporting structure from the CEO down.
WITH RECURSIVE OrgChart AS (
    -- Anchor: Top-level managers (those who report to no one)
    SELECT EmployeeID, FirstName, LastName, Title, ReportsTo, 1 AS OrgLevel
    FROM COCO_HOL_DB.NORTHWINDS.EMPLOYEES
    WHERE ReportsTo IS NULL
    
    UNION ALL
    
    -- Recursive step: Employees reporting to the level above
    SELECT e.EmployeeID, e.FirstName, e.LastName, e.Title, e.ReportsTo, oc.OrgLevel + 1
    FROM COCO_HOL_DB.NORTHWINDS.EMPLOYEES e
    INNER JOIN OrgChart oc ON e.ReportsTo = oc.EmployeeID
)
SELECT * FROM OrgChart ORDER BY OrgLevel, LastName;

-- 3. PARETO ANALYSIS (80/20 RULE) ON PRODUCTS
-- Identifies the top products contributing to 80% of total revenue.
WITH ProductRevenue AS (
    SELECT 
        p.ProductName,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Revenue
    FROM COCO_HOL_DB.NORTHWINDS.ORDER_DETAILS od
    JOIN COCO_HOL_DB.NORTHWINDS.PRODUCTS p ON od.ProductID = p.ProductID
    GROUP BY 1
),
RunningTotals AS (
    SELECT 
        ProductName,
        Revenue,
        SUM(Revenue) OVER (ORDER BY Revenue DESC) AS CumulativeRevenue,
        SUM(Revenue) OVER () AS TotalRevenue
    FROM ProductRevenue
)
SELECT 
    ProductName, 
    Revenue,
    ROUND((CumulativeRevenue / TotalRevenue) * 100, 2) AS CumulativePercent
FROM RunningTotals
WHERE CumulativePercent <= 85 -- Showing slightly more than 80% for context
ORDER BY Revenue DESC;

-- 4. CUSTOMER RETENTION: REPEAT PURCHASE GAP
-- Calculates the average number of days between orders for each customer.
WITH OrderGaps AS (
    SELECT 
        CustomerID,
        OrderDate,
        LAG(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS PreviousOrderDate
    FROM COCO_HOL_DB.NORTHWINDS.ORDERS
)
SELECT 
    CustomerID,
    ROUND(AVG(DATEDIFF('day', PreviousOrderDate, OrderDate)), 1) AS AvgDaysBetweenOrders,
    COUNT(*) AS TotalOrders
FROM OrderGaps
WHERE PreviousOrderDate IS NOT NULL
GROUP BY 1
HAVING TotalOrders > 3
ORDER BY AvgDaysBetweenOrders ASC;

-- 5. RFM SEGMENTATION (RECENCY, FREQUENCY, MONETARY)
-- A classic marketing query to bucket customers by value.
SELECT 
    CustomerID,
    DATEDIFF('day', MAX(OrderDate), (SELECT MAX(OrderDate) FROM COCO_HOL_DB.NORTHWINDS.ORDERS)) AS Recency,
    COUNT(OrderID) AS Frequency,
    ROUND(SUM(Freight), 2) AS Monetary_Freight_Spend -- Using Freight as a proxy for engagement
FROM COCO_HOL_DB.NORTHWINDS.ORDERS
GROUP BY 1
ORDER BY Frequency DESC, Recency ASC;

-- 6. PRODUCT BUNDLE ANALYSIS (MARKET BASKET)
-- Identifies which products are most frequently bought together in the same order.
SELECT 
    p1.ProductName AS Product_A,
    p2.ProductName AS Product_B,
    COUNT(*) AS TimesBoughtTogether
FROM COCO_HOL_DB.NORTHWINDS.ORDER_DETAILS od1
JOIN COCO_HOL_DB.NORTHWINDS.ORDER_DETAILS od2 ON od1.OrderID = od2.OrderID AND od1.ProductID < od2.ProductID
JOIN COCO_HOL_DB.NORTHWINDS.PRODUCTS p1 ON od1.ProductID = p1.ProductID
JOIN COCO_HOL_DB.NORTHWINDS.PRODUCTS p2 ON od2.ProductID = p2.ProductID
GROUP BY 1, 2
HAVING TimesBoughtTogether > 5
ORDER BY TimesBoughtTogether DESC;

-- 7. ROLLING 3-MONTH AVERAGE SALES
-- Uses a window frame to smooth out monthly revenue volatility.
WITH MonthlySales AS (
    SELECT 
        DATE_TRUNC('MONTH', OrderDate) AS SalesMonth,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Revenue
    FROM COCO_HOL_DB.NORTHWINDS.ORDERS o
    JOIN COCO_HOL_DB.NORTHWINDS.ORDER_DETAILS od ON o.OrderID = od.OrderID
    GROUP BY 1
)
SELECT 
    SalesMonth,
    ROUND(Revenue, 2) AS MonthlyRevenue,
    ROUND(AVG(Revenue) OVER (ORDER BY SalesMonth ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS Rolling3MonthAvg
FROM MonthlySales;

-- 8. "DEAD" STOCK & SUPPLIER RISK
-- Finds products that haven't been ordered in over 6 months and their supplier info.
SELECT 
    p.ProductName,
    s.CompanyName AS Supplier,
    s.Phone AS SupplierContact,
    p.UnitsInStock,
    MAX(o.OrderDate) AS LastOrderedDate
FROM COCO_HOL_DB.NORTHWINDS.PRODUCTS p
JOIN COCO_HOL_DB.NORTHWINDS.SUPPLIERS s ON p.SupplierID = s.SupplierID
LEFT JOIN COCO_HOL_DB.NORTHWINDS.ORDER_DETAILS od ON p.ProductID = od.ProductID
LEFT JOIN COCO_HOL_DB.NORTHWINDS.ORDERS o ON od.OrderID = o.OrderID
GROUP BY 1, 2, 3, 4
HAVING LastOrderedDate < '1998-01-01' OR LastOrderedDate IS NULL
ORDER BY UnitsInStock DESC;

-- 9. TERRITORY REVENUE VS. REGION AVERAGE
-- Compares each territory's revenue against the average revenue for its parent region.
WITH TerritoryRevenue AS (
    SELECT 
        t.RegionID,
        t.TerritoryDescription,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Rev
    FROM COCO_HOL_DB.NORTHWINDS.ORDER_DETAILS od
    JOIN COCO_HOL_DB.NORTHWINDS.ORDERS o ON od.OrderID = o.OrderID
    JOIN COCO_HOL_DB.NORTHWINDS.EMPLOYEETERRITORIES et ON o.EmployeeID = et.EmployeeID
    JOIN COCO_HOL_DB.NORTHWINDS.TERRITORIES t ON et.TerritoryID = t.TerritoryID
    GROUP BY 1, 2
)
SELECT 
    TerritoryDescription,
    ROUND(Rev, 2) AS TerritoryTotal,
    ROUND(AVG(Rev) OVER (PARTITION BY RegionID), 2) AS RegionAverage,
    ROUND(Rev - AVG(Rev) OVER (PARTITION BY RegionID), 2) AS VarianceFromAvg
FROM TerritoryRevenue;

-- 10. EMPLOYEE EFFICIENCY: TIME-TO-SHIP RANKING
-- Ranks employees within their country based on how fast their orders get shipped.
SELECT 
    FirstName || ' ' || LastName AS EmployeeName,
    Country,
    ROUND(AVG(DATEDIFF('day', OrderDate, ShippedDate)), 2) AS AvgProcessingTime,
    RANK() OVER (PARTITION BY Country ORDER BY AVG(DATEDIFF('day', OrderDate, ShippedDate)) ASC) AS EfficiencyRank
FROM COCO_HOL_DB.NORTHWINDS.EMPLOYEES e
JOIN COCO_HOL_DB.NORTHWINDS.ORDERS o ON e.EmployeeID = o.EmployeeID
WHERE ShippedDate IS NOT NULL
GROUP BY 1, 2;