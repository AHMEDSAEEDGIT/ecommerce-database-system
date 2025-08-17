# 📈 monthly top-selling products
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



---

# 🛠 SQL Query Optimization – Finding the Top Selling Product in a Given Month

## **Background**
The first query was written on a dataset 
- **Products:** 500 rows  
- **Orders:** 1000 rows  
- **Order Details:** 2000 rows  

I have increased the dataset 
## **Currently**
- **Products:** 1M rows  
- **Orders:** 2M rows  
- **Order Details:** 5M rows  

---

## 🔎 Initial Problem

I needed to return the most sold product in a given month, but this query time out after 10 minutes 

 ```sql
 SET @month = '2023-01';
 SELECT P.NAME AS Top_Selling_Product, SUM(OD.Quantity) AS Product_Total_Quantity
 FROM ORDERS O
 JOIN ORDER_DETAILS OD ON O.ORDER_ID = OD.ORDER_ID
 JOIN PRODUCT P ON OD.PRODUCT_ID = P.PRODUCT_ID
 WHERE DATE_FORMAT(O.Order_Date, '%Y-%m') = @month
 GROUP BY P.Product_Id, P.NAME
 ORDER BY Product_Total_Quantity DESC
 LIMIT 1;
 ```

> [!NOTE]
> I have index on the orders table `idx_orders_date_amount` (`order_date`, `Total_Amount`)
### Issue  
- Using `DATE_FORMAT` prevents index usage on `Order_Date`.  
- Query became **very slow🐌** (~10+ minutes) with large data.  

---

## Step 1: Use Range Filtering Instead of `DATE_FORMAT`

Instead of formatting the date, i filtered using a **date range**:

 ```sql
 SET @month_start = '2025-08-01';
 SET @month_end   = DATE_ADD(@month_start, INTERVAL 1 MONTH);
 EXPLAIN ANALYZE
 SELECT ORDER_ID
 FROM ORDERS
 WHERE Order_Date >= @month_start
   AND Order_Date < @month_end;
 ```

**Execution Plan**  

 ```sql
 -> Filter: ((orders.order_date >= <cache>((@month_start))) and (orders.order_date < <cache>((@month_end))))  (cost=201133 rows=997776) (actual time=1.09..1502 rows=2e+6 loops=1)
    -> Covering index range scan on ORDERS using idx_orders_date_amount over ('2025-08-01 00:00:00' <= order_date < '2025-09-01 00:00:00')  (cost=201133 rows=997776) (actual time=1.08..742 rows=2e+6 loops=1)
 ```

✅ Improvement: The query now uses the **covering index** `idx_orders_date_amount (Order_Date, Total_Amount)`, scanning only the relevant range.

---

## Step 2: Optimize the Main Aggregation Query

i rewrote the main query to first fetch relevant orders and then aggregate product sales:

> [!WARNING]
> - The first query was joining `~1M` rows from the `products` with `~2M` from the `Orders` with `~5m` from `Order_Details` which massively expensive

**Modifications**
- I have changed the joining using subqueries that will make sure to filter the Orders first with `@month_start` so i don't need to join `~2M` records 
- Then i can join the result from the orders which was `~200k` rows with the order details 
- then aggregate and group the result and limit it by 1 because we need the best selling product .
- then we can simply join that record with products table to get the name of that product 

 ```sql
 SET @month_start = '2025-08-01';
 SET @month_end   = DATE_ADD(@month_start, INTERVAL 1 MONTH);

 EXPLAIN ANALYZE
 SELECT OD.PRODUCT_ID, SUM(Quantity) AS Total_QTY
 FROM ORDER_DETAILS OD
 JOIN (
     SELECT ORDER_ID
     FROM ORDERS
     WHERE Order_Date >= @month_start
       AND Order_Date < @month_end
 ) O USING(ORDER_ID)
 GROUP BY OD.PRODUCT_ID
 ORDER BY Total_QTY DESC
 LIMIT 1;
 ```

**Execution Plan**  

 ```sql
 -> Limit: 1 row(s)  (actual time=12394..12394 rows=1 loops=1)
     -> Sort: Total_QTY DESC, limit input to 1 row(s) per chunk  (actual time=12394..12394 rows=1 loops=1)
         -> Table scan on <temporary>  (actual time=12372..12380 rows=100000 loops=1)
             -> Aggregate using temporary table  (actual time=12372..12372 rows=100000 loops=1)
                 -> Nested loop inner join  (cost=1.49e+6 rows=2.91e+6) (actual time=1.09..9484 rows=5e+6 loops=1)
                     -> Filter: ((orders.order_date >= <cache>((@month_start))) and (orders.order_date < <cache>((@month_end))))  (cost=200213 rows=997776) (actual time=1.07..1767 rows=2e+6 loops=1)
                         -> Covering index range scan on ORDERS using idx_orders_date_amount over ('2025-08-01 00:00:00' <= order_date < '2025-09-01 00:00:00')  (cost=200213 rows=997776) (actual time=1.07..859 rows=2e+6 loops=1)
                     -> Covering index lookup on OD using idx_od_orderid_product_qty (Order_Id=orders.Order_Id)  (cost=1 rows=2.92) (actual time=0.00278..0.00364 rows=2.5 loops=2e+6)
  ```

---

## Step 3: Supporting Indexes

I added indexes to help both filtering and joining:

> ```sql
> CREATE INDEX idx_orders_date_amount ON Orders (Order_Date, Total_Amount);
> CREATE INDEX idx_od_orderid_product_qty ON Order_Details (Order_Id, Product_Id, Quantity);
> ```

- `idx_orders_date_amount` → Enables efficient **range scans** on `Order_Date` (already exists ).  
- `idx_od_orderid_product_qty` → Speeds up **joins and aggregations** on `(Order_Id, Product_Id)`.  

---

## Benchmarking Results
| Approach                               | Indexes Used                              | Execution Time | Notes                              |
| -------------------------------------- | ----------------------------------------- | -------------- | ---------------------------------- |
| Naive Query (DATE\_FORMAT)             | None                                      | 10+ mins + timeout        | Non-sargable filter, worst case    |
| Date Range Filter                      | `idx_orders_date_amount`                  | \~1.5 sec      | Orders filtering fast              |
| Aggregation with Join                  | + `idx_od_orderid_product_qty`            | \~12 sec       | Still costly aggregation           |
| Composite Indexes (best tested so far) | Orders + Order\_Details composite indexes | \~12 sec total | Much better, but still not instant |
