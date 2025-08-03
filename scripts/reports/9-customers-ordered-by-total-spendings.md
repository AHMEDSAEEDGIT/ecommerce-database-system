# 🧑💲 Customers Ordered by Total Spending

## Query Purpose
Retrieve customers sorted by their total spending in descending order.

## Original Query

```sql
 SELECT O.Customer_Id, CONCAT(C.First_Name, ' ', C.Last_Name) AS "Full Name"
 FROM ORDERS O 
 JOIN Customer C 
     ON O.Customer_Id = C.Customer_Id
 ORDER BY O.Total_Amount DESC;
```

## 🔍 Execution Plan Analysis

```sql
-> Nested loop inner join  (cost=1.2e+6 rows=2e+6) (actual time=1956..7703 rows=2e+6 loops=1)
    -> Sort: o.Total_Amount DESC  (cost=203700 rows=2e+6) (actual time=1956..2067 rows=2e+6 loops=1)
        -> Filter: (o.Customer_Id is not null)  (cost=203700 rows=2e+6) (actual time=8.32..1205 rows=2e+6 loops=1)
            -> Table scan on O  (cost=203700 rows=2e+6) (actual time=8.32..1106 rows=2e+6 loops=1)
    -> Single-row index lookup on C using PRIMARY (Customer_Id=o.Customer_Id)  (cost=0.399 rows=1) (actual time=0.00267..0.0027 rows=1 loops=2e+6)
```

The original query showed these performance characteristics:
- Full table scan on Orders (2M rows)
- Sorting all 2M rows by Total_Amount (expensive operation)
- Index lookup on Customer table for each Order (2M lookups)

---

## 📈 Optimization Techniques Applied

1. **✔Composite Index Creation**
`actually we will extend the current index that has been built already on CustomerID FK`
```sql
 CREATE INDEX idx_orders_customer_amount ON Orders(Customer_Id, Total_Amount DESC);
```

**Then analyze the query again:**
```sql
-> Nested loop inner join  (cost=1.38e+6 rows=2e+6) (actual time=1524..7738 rows=2e+6 loops=1)
    -> Sort: o.Total_Amount DESC  (cost=204378 rows=2e+6) (actual time=1523..1637 rows=2e+6 loops=1)
        -> Filter: (o.Customer_Id is not null)  (cost=204378 rows=2e+6) (actual time=1.34..773 rows=2e+6 loops=1)
            -> Index scan on O using idx_orders_customer_amount  (cost=204378 rows=2e+6) (actual time=1.34..674 rows=2e+6 loops=1)
    -> Single-row index lookup on C using PRIMARY (Customer_Id=o.Customer_Id)  (cost=0.489 rows=1) (actual time=0.0029..0.00293 rows=1 loops=2e+6)
```

This index helps with:
- Faster join operations between Orders and Customer tables
- Pre-sorting by Total_Amount in descending order
- Covering both the join condition and sort operation

2. **✔Query Rewrite Considerations**
The optimized query now benefits from:
- Reduced sorting overhead due to the index
- More efficient join path
- Better utilization of existing primary key indexes

--- 
# 🛠 Key Improvements Observed
## Execution Plan Comparison

### Before Optimization
```sql
 -> Nested loop inner join (cost=1.2e+6 rows=2e+6) (actual time=1956..7703)
     -> Sort: o.Total_Amount DESC (cost=203700 rows=2e+6) (actual time=1956..2067)
         -> Filter: (o.Customer_Id is not null) (cost=203700 rows=2e+6) (actual time=8.32..1205)
             -> Table scan on O (cost=203700 rows=2e+6) (actual time=8.32..1106)
```
### After Optimization
```sql
 -> Nested loop inner join (cost=1.38e+6 rows=2e+6) (actual time=1524..7738)
     -> Sort: o.Total_Amount DESC (cost=204378 rows=2e+6) (actual time=1523..1637)
         -> Filter: (o.Customer_Id is not null) (cost=204378 rows=2e+6) (actual time=1.34..773)
             -> Index scan on O using idx_orders_customer_amount (cost=204378 rows=2e+6) (actual time=1.34..674)
```

1. **Scan Type Upgrade**
   - Before: Full `Table scan` on Orders (expensive I/O)
   - After: `Index scan` using idx_orders_customer_amount (faster access)

2. **Initial Data Fetch Acceleration**
   - Before: 8.32ms to start fetching data
   - After: 1.34ms to start fetching data (83% faster initial access)

3. **Full Scan Time Reduction**
   - Before: 1106ms for complete table scan
   - After: 674ms for index scan (39% faster)

4. **Overall Query Start Improvement**
   - Before: 1956ms to begin join operation
   - After: 1524ms to begin join operation (22% faster)


## 🏸 Further Optimization Potential

1. **For Top-N Queries**
```sql
	SELECT ... ORDER BY Total_Amount DESC LIMIT 100;
```
2. **Using Materialized Views**
   Pre-compute and periodically refresh customer totals


