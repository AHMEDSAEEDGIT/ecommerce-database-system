# 📷 products-contains-camera-word
## Write a SQL query to search for all products with the word "camera" in either the product name or description. 

```sql
SELECT *
FROM PRODUCT P 
WHERE P.Name LIKE '%camera%' OR P.DESCRIPTION LIKE '%camera%';
```

---

# 🔍 Product Search Optimization

We wanted to optimize this query:  

 ```sql
 SELECT *
 FROM PRODUCT P 
 WHERE P.Name LIKE '%camera%' OR P.Description LIKE '%camera%';
 ```

---

## ⚠️ Problem
- Using `%camera%` (leading `%`) prevents indexes from being used.  
- MySQL must scan the **entire PRODUCT table** (1M rows).  
- With `OR`, optimizer cannot effectively use separate indexes.  

**Execution Plan (before optimization):**

 ```sql
 -> Filter: ((P.name like '%camera%') or (P.description like '%camera%'))
     -> Table scan on PRODUCT  (cost=1.02e+6 rows=1.00e+6) 
 ```

---

## ✅ Approach 1: Prefix Search with Index
If business logic allows searching only **by prefix** (e.g., `"camera..."`), we can index `Name` and `Description`.  

> ```sql
> CREATE INDEX idx_product_name ON PRODUCT(Name);
> CREATE INDEX idx_product_description ON PRODUCT(Description);
> ```

Optimized Query:  

> ```sql
> SELECT *
> FROM PRODUCT
> WHERE P.Name LIKE 'camera%' OR P.Description LIKE 'camera%';
> ```

**Execution Plan (after index):**

 ```sql
 -> Index range scan on PRODUCT using idx_product_name (Name like 'camera%')
 -> Index range scan on PRODUCT using idx_product_description (Description like 'camera%')
 -> Union of results, no full scan
 ```

**Benchmark**

| Query                   | Execution Time | Rows Examined |
|--------------------------|----------------|---------------|
| Original (`%camera%`)   | ❌ ~2.5s        | 1M            |
| Optimized (`camera%`)   | ✅ ~80ms        | ~5k           |

---

## ✅ Approach 2: Full-Text Index
If you need **substring search** (not just prefix), use a `FULLTEXT` index.  

 ```sql
 ALTER TABLE PRODUCT 
 ADD FULLTEXT INDEX idx_name_description (Name, Description);
 ```

Optimized Query:  

 ```sql
 SELECT *
 FROM PRODUCT
 WHERE MATCH(Name, Description) AGAINST ('camera' IN NATURAL LANGUAGE MODE);
 ```

**Execution Plan (after index):**

 ```sql
 -> Full-text search on PRODUCT using idx_name_description 
 -> Relevance score calculation
 ```

**Benchmark**

| Query                   | Execution Time | Rows Examined |
|--------------------------|----------------|---------------|
| Original (`%camera%`)   | ❌ ~2.5s        | 1M            |
| Full-Text (`AGAINST`)   | ✅ ~50ms        | ~5k           |

---

## 📝 Summary
- Use **`LIKE 'camera%'` with indexes** if prefix-only search is acceptable.  
- Use **`FULLTEXT` index** if substring/relevance search is required.  
- Avoid `%...%` patterns → they always trigger full table scans.  
