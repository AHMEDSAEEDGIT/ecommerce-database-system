# 🗓️ Daily Revenue Report
## Write an SQL query to generate a daily report of the total revenue for a specific date.

```sql
SET @DATE =  '2023-01-02'
SELECT DATE(Order_Date) AS Report_Date, 
       SUM(Order_Details.Quantity * Order_Details.Unit_Price) AS Total_Revenue
FROM Orders
JOIN Order_Details ON Orders.Order_Id = Order_Details.Order_Id
WHERE DATE(Order_Date) = @DATE
GROUP BY DATE(Order_Date);

```
