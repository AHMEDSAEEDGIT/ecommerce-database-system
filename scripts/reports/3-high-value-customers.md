# 🗓️ high-value-customers
## Write a SQL query to retrieve a list of customers who have placed orders totaling more than $500 in the past month ,include customer names and their total order amounts. 

```sql
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

```

---

```sql
SELECT CONCAT(C.First_Name, ' ', C.Last_Name) Customer_Name , CTE.Order_Price
FROM Customer C 
JOIN CTE
ON C.Customer_Id = CTE.Customer_Id
```
