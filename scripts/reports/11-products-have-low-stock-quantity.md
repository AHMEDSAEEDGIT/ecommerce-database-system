# 📊 Low Stock Products Query Optimization Comparison
**LIST PRODUCTS THAT HAVE LOW STOCK QUANTITIY THAT LESS THAN 10 QUANTITIES**

```sql
EXPLAIN ANALyZE SELECT *
FROM PRODUCT
WHERE STOCK_QUANTITY < 10;
```
---

## 🚀 Optimization Techniques Applied

0. **before optimization the execution plan is :**

```sql
-> Filter: (product.Stock_Quantity < 10)  (cost=10502 rows=33188) (actual time=8.12..64 rows=963 loops=1)
    -> Table scan on PRODUCT  (cost=10502 rows=99574) (actual time=8.11..60.1 rows=100000 loops=1)
```

1. **Single column index on the stock quantity**

```sql
 CREATE INDEX idx_product_stock_quantity ON PRODUCT(STOCK_QUANTITY);
```

**Then analyze the query again the result will be :**
```sql
 -> Index range scan on PRODUCT using idx_product_stock_quantity over (Stock_Quantity < 10), with index condition: (product.Stock_Quantity < 10)  (cost=434 rows=963) (actual time=0.39..3.37 rows=963 loops=1)
```

2.  **limit columns returned**

```sql
explain analyze SELECT Product_Id, Name, Stock_Quantity 
FROM PRODUCT
WHERE STOCK_QUANTITY < 10;
```

**Then analyze the query again the result will be :**

```sql 
 -> Index range scan on PRODUCT using idx_product_stock_quantity over (Stock_Quantity < 10), with index condition: (product.Stock_Quantity < 10)  (cost=434 rows=963) (actual time=0.389..3.12 rows=963 loops=1)
```

3.  **after creating covering index**
```sql
CREATE INDEX idx_product_low_stock_covering ON PRODUCT(STOCK_QUANTITY, Name, Price);
```

**Then analyze the query again the result will be :**
```sql
explain analyze SELECT Product_Id, Name, Stock_Quantity 
FROM PRODUCT
WHERE STOCK_QUANTITY < 10;
```
```sql
-> Filter: (product.Stock_Quantity < 10)  (cost=218 rows=963) (actual time=0.0763..0.483 rows=963 loops=1)
    -> Covering index range scan on PRODUCT using idx_product_low_stock_covering over (Stock_Quantity < 10)  (cost=218 rows=963) (actual time=0.0744..0.423 rows=963 loops=1)

```

---

## 📊  Performance Metrics

| Optimization Stage               | Cost  | Execution Time | Scan Type               | Rows Examined | Rows Returned |
|----------------------------------|-------|----------------|-------------------------|---------------|---------------|
| **No Optimization**              | 10502 | 64ms           | Full Table Scan         | 100,000       | 963           |
| **Basic Index Added**            | 434   | 3.37ms         | Index Range Scan        | 963           | 963           |
| **Limited Columns Returned**     | 434   | 3.12ms         | Index Range Scan        | 963           | 963           |
| **Covering Index Implemented**   | 218   | 0.483ms        | Covering Index Scan     | 963           | 963           |

## Key Improvements

1. **Performance Boost**
   - ⚡ **24x faster** (64ms → 2.67ms) after adding basic index
   - ⚡ **132x faster** (64ms → 0.483ms) with covering index

2. **Cost Reduction**
   - Original cost: 10,502 → Covering index: 218 (98% reduction)

3. **Efficiency Gains**
   - Rows examined reduced from 100,000 to exactly 963 (only matching rows)

## Optimization Takeaways

1. **Index Impact**
   - Basic index changed full scan → targeted index range scan
   - Reduced examined rows by 99% (100,000 → 963)

2. **Covering Index Benefits**
   - Eliminated need to access table data (uses index only)
   - Cut execution time by 85% compared to basic index (3.37ms → 0.483ms)

3. **Column Selection**
   - Limited columns didn't help much here because:
     - MySQL was already using the index effectively
     - Product_Id is included in secondary indexes automatically (InnoDB)


