# 🗓️ monthly top-selling products
## Write an SQL query to generate a monthly report of the top-selling products in a given month..

```sql
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

```
