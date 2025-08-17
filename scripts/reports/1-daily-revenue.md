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

---






# 📈 MySQL Query Optimization Benchmark — Orders & Order_Details

## 🔍 **Background**
We started with a small dataset:

- **Orders** table: ~1000  rows  
- **Order_Details** table: ~2000  rows  

The goal was to calculate **total revenue** for a specific date, and the query seemed to work so good.

## ✔ **Currently**

- **Orders** table: ~2 million rows  
- **Order_Details** table: ~5 million rows  

The goal was to calculate **total revenue** for a specific date.

---

## 1️⃣ **First Solution — Original Query with JOIN**
We began with a query joining `Orders` and `Order_Details`:

```sql
SET @DATE =  '2023-01-02'
SELECT DATE(Order_Date) AS Report_Date, 
       SUM(Order_Details.Quantity * Order_Details.Unit_Price) AS Total_Revenue
FROM Orders
JOIN Order_Details ON Orders.Order_Id = Order_Details.Order_Id
WHERE DATE(Order_Date) = @DATE
GROUP BY DATE(Order_Date);
```

**Problem:**
- Query timed out (~30 seconds) .
- Massive join between 2M orders and 5M details with no filtering indexes.
- MySQL did a **full table scan** on both tables, then aggregated.

> [!NOTE]
> I have increased the session time out limit to 600 seconds (10 minutes)

```sql
SHOW VARIABLES LIKE '%timeout%';

SET SESSION net_read_timeout = 600;
SET SESSION net_write_timeout = 600;
SET SESSION wait_timeout = 600;
SET SESSION interactive_timeout = 600;
```
> ![WARNING]
> Spoiler Alert : after **10 minutes !** ...query time out 🙄


Even i have tried change the way of the query written :
- Used  `WHERE Order_Date >= '2025-08-02' AND Order_Date < '2025-08-03'` instead of using `DATE('2025-08-03')` to truncate the date
- Used subquery instead of join
- Used limit 1000;

```sql
 WITH ORDERS_On_Date AS (
   SELECT Order_id, Order_Date
   FROM Orders
   WHERE Order_Date >= '2025-08-02' AND Order_Date < '2025-08-03'
 )
 SELECT DATE(Order_Date) AS Report_Date,
        SUM(od.Quantity * od.Unit_Price) AS Total_Revenue
 FROM Order_Details od
 JOIN ORDERS_On_Date o ON od.order_id = o.order_id
 GROUP BY DATE(Order_Date)
 limit 1000;
 ```
> still it was not enough 🐌


---

## 2️⃣ **Second Solution — Avoid the JOIN by Using Precomputed Column**
I noticed `Orders` already had a `Total_Amount` column (sum of all details), so we could avoid joining `Order_Details`.

```sql
 SELECT DATE(o.order_date), SUM(o.Total_Amount) AS Total_Revenue
 FROM Orders o
 WHERE o.Order_Date >= '2025-08-02' AND o.Order_Date < '2025-08-03'
 GROUP BY DATE(o.Order_Date);
```

**Result:**
- Reduced complexity: only reading from `Orders`.
- Still slow because there was **no useful index** on `Order_Date`.


**Execution Plan:**

```sql
-> Table scan on <temporary>  (actual time=1853..1853 rows=1 loops=1)
    -> Aggregate using temporary table  (actual time=1853..1853 rows=1 loops=1)
        -> Filter: ((o.order_date >= TIMESTAMP'2025-08-02 00:00:00') and (o.order_date < TIMESTAMP'2025-08-03 00:00:00'))  (cost=204246 rows=221684) (actual time=9.48..949 rows=2e+6 loops=1)
            -> Table scan on o  (cost=204246 rows=2e+6) (actual time=9.47..669 rows=2e+6 loops=1)

```

**Performance:**
- ~1.85 seconds for aggregation after scanning 2M rows.
- CPU and I/O heavy.
- MySQL couldn't use existing indexes because they started with `Customer_Id` instead of `Order_Date`.

**Enhancement:**  
> We can use an index to avoid sequential scan espially we have only one date no range so index will be amazing but we need to be careful not to abuse index creation at affects insertion and update after all

---

## 3️⃣ **Third Solution — Add Single-Column Index on Order_Date**
> CREATE INDEX idx_orders_date ON Orders(Order_Date);

**Execution Plan:**

```sql
-> Table scan on <temporary>  (actual time=2525..2525 rows=1 loops=1)
    -> Aggregate using temporary table  (actual time=2525..2525 rows=1 loops=1)
        -> Filter: ((o.order_date >= TIMESTAMP'2025-08-02 00:00:00') and (o.order_date < TIMESTAMP'2025-08-03 00:00:00'))  (cost=204393 rows=997776) (actual time=6.17..1610 rows=2e+6 loops=1)
            -> Table scan on o  (cost=204393 rows=2e+6) (actual time=6.17..1329 rows=2e+6 loops=1)
```

> Table scan on o (still scanning all rows)


**Why it failed:**
- Query used `DATE(o.Order_Date)` in `GROUP BY`, which prevents index optimization for grouping.
- Index didn’t include `Total_Amount`, so MySQL estimated it would be slower to use the index (due to millions of random row lookups) and chose a table scan.
- Result was actually slower (~2.5s scan time).

> [!NOTE]
> A single-column index may be ignored if the query also requires non-indexed columns, because MySQL must fetch them from the table (random I/O).

---

## 4️⃣ **4TH Solution — Add Composite Covering Index**
We replaced the single-column index with a covering index:

> DROP INDEX idx_orders_date ON Orders;
>
> CREATE INDEX idx_orders_date_amount ON Orders(Order_Date, Total_Amount);

**Execution Plan:**
```sql
-> Table scan on <temporary>  (actual time=2032..2032 rows=1 loops=1)
    -> Aggregate using temporary table  (actual time=2032..2032 rows=1 loops=1)
        -> Filter: ((o.order_date >= TIMESTAMP'2025-08-02 00:00:00') and (o.order_date < TIMESTAMP'2025-08-03 00:00:00'))  (cost=201137 rows=997776) (actual time=1.85..1105 rows=2e+6 loops=1)
            -> Covering index range scan on o using idx_orders_date_amount over ('2025-08-02 00:00:00' <= order_date < '2025-08-03 00:00:00')  (cost=201137 rows=997776) (actual time=1.25..819 rows=2e+6 loops=1)
```

**Performance:**
- ~0.82 seconds for the index scan.
- MySQL read only from the index (no table lookups).
- Far fewer I/O operations.

**Pros:**
- Fast range filtering on `Order_Date`.
- Covers `Total_Amount`, so MySQL doesn’t touch the base table.

**Cons:**
- Extra storage space for the index.
- Additional maintenance cost on `INSERT`/`UPDATE` to `Orders`.

**Lesson:**  
For reporting queries that filter by one column and aggregate another, a **covering index** is often the optimal solution.


---

## **Benchmark Summary Table**

| Case | Index Used | Plan Summary | Rows Scanned | Scan Time | Notes |
|------|-----------|--------------|--------------|-----------|-------|
| No index | None | Table scan, temp table aggregate | 2M | ~1.85s | Existing indexes unusable |
| Single index | `Order_Date` | Table scan (index ignored) | 2M | ~2.5s | MySQL avoided index due to extra lookups |
| Composite covering index | `(Order_Date, Total_Amount)` | Covering index range scan | 2M | ~0.82s | Best performance |

