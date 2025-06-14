
-- Q:Write an SQL query to generate a daily report of the total revenue for a specific date.
-- sol
SET @report_date = '2023-01-02';
SELECT  DATE(O.Order_Date) AS Report_Date ,SUM(OD.Quantity * OD.Unit_Price) as Total_Revenue
FROM  ORDERS O JOIN order_details OS
ON O.ORDER_ID = OD.ORDER_ID
WHERE DATE (O.Order_Date ) = @report_date -- '2023-01-02'
GROUP BY DATE (O.Order_Date);

-- Q:Write an SQL query to generate a monthly report of the top-selling products in a given month.
-- sol
SET @month = '2023-01';
SELECT P.NAME Top_Selling_Product , SUM(OD.Quantity) Product_Total_Quantity
FROM ORDERS O 
JOIN ORDER_DETAILS OD 
ON O.ORDER_ID = OD.ORDER_ID
JOIN PRODUCT P 
ON OD.PRODUCT_ID = P.PRODUCT_ID
WHERE DATE_FORMAT(O.Order_Date, '%Y-%m') = @month
GROUP BY P.Product_Id ,  P.NAME
ORDER BY   Product_Total_Quantity DESC
LIMIT 1;

-- Q:Write a SQL query to retrieve a list of customers who have placed orders totaling more than $500 in the past month.
-- 	Include customer names and their total order amounts. [Complex query].
-- sol
SET @Date = '2023-01-02'; -- CURDATE()
WITH CTE AS(
SELECT  O.Customer_Id, SUM(Quantity * Unit_Price) Order_Price
FROM ORDERS O
JOIN order_details OD
ON O.Order_Id = OD.Order_Id 
WHERE O.Order_Date >= DATE_SUB(@Date, INTERVAL 1 MONTH)
GROUP BY O.Customer_Id
HAVING SUM(Quantity * Unit_Price) > 500
)

SELECT CONCAT(C.First_Name, ' ', C.Last_Name) Customer_Name , CTE.Order_Price
FROM Customer C 
JOIN CTE
ON C.Customer_Id = CTE.Customer_Id