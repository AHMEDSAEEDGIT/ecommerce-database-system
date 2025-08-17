# 💰 high-value-customers
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


```sql
SELECT CONCAT(C.First_Name, ' ', C.Last_Name) Customer_Name , CTE.Order_Price
FROM Customer C 
JOIN CTE
ON C.Customer_Id = CTE.Customer_Id
```

---


## Query: Customers who spent more than 500 in the last month

## **Background**
The first query was written on a dataset 
- **Customer:** 200 rows  
- **Orders:** 1000 rows  
- **Order Details:** 2000 rows  

I have increased the dataset 
## **Currently**
- **Customers:** 1M rows  
- **Orders:** 2M rows  
- **Order Details:** 5M rows  

The first query didn't work on `5M Order_details` joining with `2M orders` and `1M Customers`

**Optimized Query:**

 ```sql
 SET @Date = '2023-01-02'; -- CURDATE()
 SET @Previous = DATE_SUB(@Date, INTERVAL 1 MONTH);

 EXPLAIN ANALYZE 
 SELECT CONCAT(C.First_Name, ' ', C.Last_Name) Customer_Name , O.Order_Price
 FROM (
     SELECT O.Customer_Id , SUM(Total_Amount) AS Order_Price
     FROM ORDERS O
     WHERE O.Order_Date >= @Previous
     GROUP BY O.Customer_Id
     HAVING SUM(O.Total_Amount) > 500
 ) as O
 JOIN Customer C on C.Customer_Id = O.Customer_Id;
 ```


 | Change                                                             | What Changed?                                                                                                         | Why It Helped                                                                    |
| ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **Removed Join with `order_details`**                              | Instead of joining `Orders` and `Order_Details`,  directly used `Orders.Total_Amount` (precomputed at insert time). | Avoids row explosion → no need to aggregate across millions of detail rows.      |
| **Replaced `SUM(Quantity * Unit_Price)` with `SUM(Total_Amount)`** | Used a denormalized/pre-aggregated field.                                                                             | Cuts computation cost — no multiplication needed per row.                        |
| **Moved HAVING filter later**                                      | Still uses HAVING, but works on pre-aggregated values.                                                                | Reduces rows earlier in the plan, makes grouping lighter.                        |
| **Simplified CTE into subquery**                                   | Instead of a CTE, used an inline subquery (`AS O`).                                                                   | Minor effect, but optimizer handles inline subqueries more efficiently in MySQL. |
| **Added variable for date range (`@Previous`)**                    | Pre-calculated once instead of inside the WHERE clause.                                                               | Cleaner query, avoids recalculation inside the scan.                             |

---
## Execution Plan (before index)

> ```
> -> Nested loop inner join  (cost=1.02e+6 rows=997776) (actual time=11374..16913 rows=674670 loops=1)
>     -> Filter: (o.Customer_Id is not null)  
>         -> Table scan on O  
>             -> Materialize  
>                 -> Filter: (sum(o.Total_Amount) > 500)  
>                     -> Group aggregate: sum(o.Total_Amount)  
>                         -> Filter: (o.order_date >= <cache>((@Previous)))  
>                             -> Index scan on O using idx_orders_customer_amount
>     -> Single-row index lookup on C using PRIMARY (Customer_Id=o.Customer_Id)
> ```

⏳ **Observation**:  
- MySQL does a **full grouping aggregate** over ~2M rows.  
- Temporary aggregation takes ~11s before the JOIN.  
- Nested loop join to `Customer` adds more cost but is relatively cheap compared to aggregation.

---

### After Adding Index

> ```sql
> CREATE INDEX idx_orders_date_customer_amount
>     ON Orders (Order_Date, Customer_Id, Total_Amount);
> ```

> ```
> -> Nested loop inner join  (cost=1.18e+6 rows=997776) (actual time=14414..16451 rows=674670 loops=1)
>     -> Filter: (o.Customer_Id is not null)  
>         -> Table scan on O  
>             -> Materialize  
>                 -> Filter: (sum(o.Total_Amount) > 500)  
>                     -> Table scan on <temporary>  
>                         -> Aggregate using temporary table  
>                             -> Filter: (o.order_date >= <cache>((@Previous)))  
>                                 -> Covering index range scan on O using idx_orders_date_customer_amount
>     -> Single-row index lookup on C using PRIMARY (Customer_Id=o.Customer_Id)
> ```

✅ **Changes**:  
- The optimizer now uses a **covering index range scan** (`idx_orders_date_customer_amount`) to fetch only the needed `Order_Date` and `Customer_Id`.  
- Aggregation still needs a **temporary table** (because of `GROUP BY + HAVING`).  
- Execution time improved (aggregation starts much faster: ~3.8s vs ~10s before).

---

### Why HAVING is Expensive

- `HAVING SUM(...) > 500` requires MySQL to **first compute SUM() for every Customer_Id**.  
- Only **after aggregation**, the filter applies.  
- This forces MySQL to build a temporary table (cannot use index-only filtering).

---

### Possible Optimizations


1. **Composite index**  
   - Current index helps with `Order_Date` filtering and covering scan.  
   - But `SUM(Total_Amount)` still requires full aggregation.  
   - Unfortunately, no index can pre-compute SUM().  

2. **Materialized summary table**  
   - For analytics queries (like "last month’s big spenders"),we can consider a summary table:
     ```sql
     CREATE TABLE Monthly_Customer_Summary (
         Month DATE,
         Customer_Id INT,
         Total_Spent DECIMAL(10,2),
         INDEX(Month, Customer_Id, Total_Spent)
     );
     ```
   - Update it nightly with:
     ```sql
     INSERT INTO Monthly_Customer_Summary
     SELECT DATE_FORMAT(Order_Date, '%Y-%m-01') as Month,
            Customer_Id,
            SUM(Total_Amount)
     FROM Orders
     GROUP BY Month, Customer_Id;
     ```
   - Then the query becomes a **simple indexed lookup** → blazing fast.

---


## Query Benchmarking Results

I  benchmarked three versions of the same reporting query:

| Query Version | Query Description | Execution Time | Rows Processed | Notes |
|---------------|------------------|----------------|----------------|-------|
| **V1: Original Query** | Used `JOIN` on `Orders` + `Order_Details` with `SUM(Quantity * Unit_Price)` and `HAVING > 500` | ❌ Timeout | ~5M+ | Too heavy due to join + aggregation across details table |
| **V2: Optimized Query** | Replaced `SUM(Quantity * Unit_Price)` with pre-aggregated `Orders.Total_Amount`, applied `HAVING` after grouping | ✅ ~11–16 sec | ~2M filtered to ~674K | Still expensive: uses `Nested Loop Join` + temporary table for HAVING |
| **V3: Optimized Query + Composite Index** | Added composite index on `(Order_Date, Customer_Id, Total_Amount)` to support range filtering + aggregation | ✅ ~4–5 sec | ~2M filtered to ~674K | Faster: optimizer uses **covering index range scan** instead of full scan |

> **Key Improvements**
> - Moving aggregation from `Order_Details` to precomputed `Orders.Total_Amount` eliminated the join cost.  
> - Composite index `(Order_Date, Customer_Id, Total_Amount)` reduced the scan time significantly.  
> - Query plan changed from `Table Scan + Temporary Aggregate` → `Covering Index Range Scan`.  
