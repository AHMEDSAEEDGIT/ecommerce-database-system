# 🔢 Daily Revenue Report
## Write an SQL query to retrive total number of products for each category.

```sql
SELECT CATEGORY_ID, COUNT(*) count_products
FROM PRODUCT
GROUP BY CATEGORY_ID;
```


---

## 🧪 Query Optimization: Grouping Products by Category

### 🔍 Goal

Retrieve the total number of products in each category:


### ✅ Observed Optimization Behavior

The query groups rows by `Category_Id` and performs a `COUNT(*)`. With the right index, MySQL can use a **covering index scan**, which significantly improves performance by avoiding full table scans and using only the index pages.

---

### 📊 Comparison: **With vs. Without Index**

#### ➤ With Index on `Category_Id`

```sql
    EXPLAIN SELECT CATEGORY_ID, COUNT(*) count_products
    FROM PRODUCT
    GROUP BY CATEGORY_ID;
```

```sql
 -> Group aggregate: count(0)  (cost=20187 rows=99625) (actual time=1.18..53 rows=62895 loops=1)
     -> Covering index scan on PRODUCT using Category_Id  (cost=10224 rows=99625) (actual time=1.17..44.7 rows=100000 loops=1)
```

✅ Efficient because MySQL scans the index only (covering index) — no need to access full table rows.

---
## ➤ Without Index on `Category_Id`
> [!NOTE]
> MySQL creates index by default when creating foreign key , and because we have relationship between Products and Categories 
> we have already index on the category id column,so to be able to benchmark without index we need to drop the FK constraint and then the index

### 🔧 Testing Steps

To benchmark performance **without the index**, follow these steps:

1. Drop the foreign key constraint (required before dropping the index):

```sql
    ALTER TABLE Product DROP FOREIGN KEY product_ibfk_1;
```
2. Drop the index on `Category_Id`:

```sql
    ALTER TABLE PRODUCT DROP INDEX Category_Id;
```

3. Run the query again and compare the `EXPLAIN` output.

```sql   
    EXPLAIN SELECT CATEGORY_ID, COUNT(*) count_products
    FROM PRODUCT
    GROUP BY CATEGORY_ID;
```

4.  The result will be:

```sql
-> Table scan on <temporary>  (actual time=99.1..104 rows=62895 loops=1)
    -> Aggregate using temporary table  (actual time=99.1..99.1 rows=62895 loops=1)
        -> Table scan on PRODUCT  (cost=10225 rows=99625) (actual time=6.48..63.5 rows=100000 loops=1)
```

**Observation**
> Slower — MySQL must read the entire table and use a temporary table for grouping.



### Restore the foreign key constraint after testing:

```sql
    ALTER TABLE Product
    ADD CONSTRAINT product_category_id_to_category_category_id
    FOREIGN KEY (Category_Id) REFERENCES Category(Category_Id);

```

---

### 🧠 Conclusion

- A simple `GROUP BY` with `COUNT(*)` can benefit **greatly** from proper indexing.
- In this case, adding an index on `Category_Id` allowed MySQL to use a **covering index scan**, minimizing disk I/O.
- Without the index, the query falls back to a **full table scan** and uses a **temporary table**, which is more expensive in terms of performance.

🟢 **Takeaway**: For large datasets, always consider indexing the columns used in `GROUP BY` clauses to maximize aggregation efficiency.

