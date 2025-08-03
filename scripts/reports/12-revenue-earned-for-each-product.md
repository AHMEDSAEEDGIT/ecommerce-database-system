# 💰 Revenue earned by each product
## Write sql query to project Revenue earned by each product

```sql
SELECT P.PRODUCT_ID ,P.Name , SUM(O.TOTAL_AMOUNT) Product_Revenue
FROM ORDERS O 
JOIN ORDER_DETAILS OD
	ON O.ORDER_ID = OD.ORDER_ID
JOIN PRODUCT P
	ON OD.PRODUCT_ID = P.PRODUCT_ID
GROUP BY PRODUCT_ID 
ORDER BY Product_Revenue DESC ;
```

---



# 📊 Product Revenue Query Optimization Analysis

## Original Query Performance
```sql
 EXPLAIN ANALYZE SELECT P.PRODUCT_ID, P.Name, SUM(O.TOTAL_AMOUNT) Product_Revenue
 FROM ORDERS O 
 JOIN ORDER_DETAILS OD ON O.ORDER_ID = OD.ORDER_ID
 JOIN PRODUCT P ON OD.PRODUCT_ID = P.PRODUCT_ID
 GROUP BY PRODUCT_ID 
 ORDER BY Product_Revenue DESC 
 LIMIT 1000;
```
**Issue**: Query timed out before completion due to:
- Complex multi-table join
- Aggregation across 5M+ order details
- Sorting large result set

## Initial Optimization Attempts

1. **Timeout Adjustment**:
```sql
SET SESSION wait_timeout = 28800;
SET SESSION interactive_timeout = 28800;

SET GLOBAL  mysqlx_connect_timeout = 600;
SET GLOBAL  mysqlx_read_timeout = 600;
SET GLOBAL connect_timeout = 60;
SET GLOBAL net_read_timeout = 300;
SET GLOBAL net_write_timeout = 300;
SET GLOBAL interactive_timeout = 3600;
SET GLOBAL wait_timeout = 3600;
SET GLOBAL innodb_lock_wait_timeout = 120;
```
2. **Query Restructuring and adding index**:

```sql
 CREATE INDEX idx_order_details_revenue ON ORDER_DETAILS(PRODUCT_ID, Quantity, Unit_Price);
```

```sql
> EXPLAIN ANALYZE SELECT P.PRODUCT_ID, P.Name, SUM(OD.Quantity * OD.Unit_Price) AS Product_Revenue
> FROM (SELECT PRODUCT_ID, SUM(Quantity) AS Quantity, AVG(Unit_Price) AS Unit_Price
>       FROM ORDER_DETAILS GROUP BY PRODUCT_ID) OD
> JOIN PRODUCT P ON OD.PRODUCT_ID = P.PRODUCT_ID
> GROUP BY P.PRODUCT_ID, P.Name
> ORDER BY Product_Revenue DESC
```


**Execution Plan**:
```sql
-> Sort: Product_Revenue DESC  (actual time=2881..2888 rows=100000 loops=1)
    -> Table scan on <temporary>  (actual time=2808..2818 rows=100000 loops=1)
        -> Aggregate using temporary table  (actual time=2808..2808 rows=100000 loops=1)
            -> Nested loop inner join  (cost=990e+6 rows=9.89e+9) (actual time=2524..2684 rows=100000 loops=1)
                -> Covering index scan on P using idx_product_low_stock_covering  (cost=10502 rows=99574) (actual time=0.448..47.5 rows=100000 loops=1)
                -> Index lookup on OD using <auto_key0> (PRODUCT_ID=p.Product_Id)  (cost=1e+6..1e+6 rows=49.2) (actual time=0.0261..0.0262 rows=1 loops=100000)
                    -> Materialize  (cost=1e+6..1e+6 rows=99345) (actual time=2523..2523 rows=100000 loops=1)
                        -> Group aggregate: sum(order_details.Quantity), avg(order_details.Unit_Price)  (cost=990460 rows=99345) (actual time=1..2406 rows=100000 loops=1)
                            -> Covering index scan on ORDER_DETAILS using idx_order_details_product  (cost=500303 rows=4.9e+6) (actual time=0.99..1760 rows=5e+6 loops=1)
```


- Sort: Product_Revenue DESC (2881-2888ms)
- Table scan on temporary (2808-2818ms)
- Nested loop join (2524-2684ms)
- Materialization of subquery (2523ms)
- Group aggregation (1-2406ms)

## Current Performance Bottlenecks

1. **Materialization Cost**:
   - 2523ms spent creating temporary table
   - Processing all 5M order details

2. **Join Efficiency**:
   - Nested loop join not optimal for this data volume
   - 100,000 iterations of index lookups

3. **Sorting Overhead**:
   - Still sorting 100,000 products after aggregation

## Further Optimizations

 **Batch Processing**:
```sql
 CREATE TEMPORARY TABLE temp_product_revenue AS
 SELECT PRODUCT_ID, SUM(Quantity*Unit_Price) AS Revenue
 FROM ORDER_DETAILS
 GROUP BY PRODUCT_ID
 ORDER BY Revenue DESC
 LIMIT 1000;

 SELECT P.* FROM temp_product_revenue t
 JOIN PRODUCT P ON t.PRODUCT_ID = P.PRODUCT_ID;
```






















































# 🚀 Optimization Analysis: Revenue earned by each product

## Original Query
```sql
 SELECT O.ORDER_ID, CONCAT(C.First_Name, ' ', C.Last_Name) AS "Full Name", C.EMAIL
 FROM Customer C
 JOIN ORDERS O ON O.Customer_Id = C.Customer_Id
 ORDER BY O.ORDER_DATE DESC 
 LIMIT 1000;
```
## Performance Benchmarks

### 1. Before Any Optimization
**Execution Plan:**
> -- -> Limit: 1000 row(s) (cost=1.07e+6 rows=1000) (actual time=1577..1663)
> --     -> Nested loop join (cost=1.07e+6 rows=2e+6) (actual time=1577..1663)
> --         -> Sort: o.order_date DESC (cost=204384 rows=2e+6) (actual time=1576..1576)
> --             ->🐌 Table scan on O (cost=204384 rows=2e+6) (actual time=6.12..982)

**Key Observations:**
- Full table scan of 2M orders
- Sorts all 2M records before limiting
- Total execution: ~1663ms


### 2. Correct Composite Index
**Optimal Index:**
> CREATE INDEX idx_orders_customer_date ON Orders(Customer_Id, Order_Date DESC);

**Execution Plan:**
> -- -> Limit: 1000 row(s) (cost=2.05e+6 rows=1000) (actual time=1400..1519)
> --     -> Nested loop join (cost=2.05e+6 rows=2e+6) (actual time=1400..1519)
> --         -> Sort: o.order_date DESC (cost=202310 rows=2e+6) (actual time=1400..1400)
> --             ->🐇 Index scan on O using idx_orders_customer_date (cost=202310 rows=2e+6) (actual time=1.02..684)

**Improvements:**
- 9% faster than single-column attempt (1563ms → 1519ms)
- 14% faster than original (1663ms → 1519ms)
- Table scan → Index scan (6.12ms → 1.02ms initial access)
- Full scan time reduced by 18% (982ms → 831ms → 684ms)

## Why The Sort Still Appears

The `Sort: o.order_date DESC` operation remains because:
1. MySQL doesn't fully utilize index ordering for this join pattern
2. The optimizer chooses to materialize results before joining
3. The composite index helps but doesn't eliminate sorting entirely

## 🚀 Further Optimization

1. **Query Restructuring**:
```sql
 SELECT O.ORDER_ID, CONCAT (C.First_Name,' ' , C.Last_Name ), C.EMAIL
 FROM (
     SELECT Order_Id, Customer_Id, Order_Date 
     FROM ORDERS
     ORDER BY Order_Date DESC
     LIMIT 1000
 ) O
 JOIN Customer C ON O.Customer_Id = C.Customer_Id;
```
**The analysis of the reuslt :**

```sql
 -> Nested loop inner join  (cost=979 rows=1000) (actual time=678..803 rows=1000 loops=1)
    -> Filter: (o.Customer_Id is not null)  (cost=202208..115 rows=1000) (actual time=678..678 rows=1000 loops=1)
        -> Table scan on O  (cost=202410..202425 rows=1000) (actual time=678..678 rows=1000 loops=1)
            -> Materialize  (cost=202410..202410 rows=1000) (actual time=678..678 rows=1000 loops=1)
                -> Limit: 1000 row(s)  (cost=202310 rows=1000) (actual time=678..678 rows=1000 loops=1)
                    -> Sort: orders.order_date DESC, limit input to 1000 row(s) per chunk  (cost=202310 rows=2e+6) (actual time=678..678 rows=1000 loops=1)
                        -> Index scan on ORDERS using idx_orders_customer_date  (cost=202310 rows=2e+6) (actual time=1.14..461 rows=2e+6 loops=1)
```

2. **Covering Index**:

```sql
 CREATE INDEX idx_orders_covering ON Orders(Order_Date DESC, Customer_Id, Order_Id); -- this too optional because we have this index already `idx_orders_customer_date`
```

3. **For Production Systems**:
- we can partition by date ranges
- Also we can implement materialized views for frequent queries
- Explore query hints if needed

---

# 🏆 Query Optimization Comparison: Recent 1000 Orders

## Performance Metrics Comparison

| Optimization Stage          | Total Time | Initial Access | Sort Time | Join Cost | Scan Type          | Rows Processed |
|-----------------------------|------------|----------------|-----------|-----------|--------------------|----------------|
| **No Optimization**         | 1663ms     | 6.12ms         | 1576ms    | 1.07e+6   | Full table scan    | 2M rows        |
| **With Composite Index**    | 1519ms     | 1.02ms         | 1400ms    | 2.05e+6   | Index scan         | 2M rows        |
| **Restructured Query**      | 803ms      | 1.14ms         | 678ms     | 979       | Index scan (limit) | 1000 rows      |

## Key Improvements

1. **Execution Time Reduction**
   - Original: 1663ms → Composite Index: 1519ms (9% faster)
   - Composite Index: 1519ms → Restructured: 803ms (47% faster)
   - **Total Improvement:** 1663ms → 803ms (52% faster)

2. **Data Processing**
   - Original & Composite Index: Processed 2M rows
   - Restructured: Processes only 1000 rows before join

3. **Join Cost**
   - Original: 1.07e+6 → Composite: 2.05e+6 → Restructured: 979 (99.9% reduction)

4. **Initial Access Time**
   - Original: 6.12ms → Composite: 1.02ms → Restructured: 1.14ms
   - 81% faster than original

## Why Restructured Query Wins

1. **Early Row Reduction**
   - Applies LIMIT before joining (1000 vs 2M rows)
   
2. **Efficient Materialization**
   - Creates temporary table with just needed columns

3. **Optimized Join**
   - Smaller dataset reduces join overhead significantly

4. **Better Index Utilization**
   - idx_orders_customer_date enables fast sorting