# 📷 products-contains-camera-word
## Write a SQL query to search for all products with the word "camera" in either the product name or description. 

```sql
SELECT *
FROM PRODUCT P 
WHERE P.Name LIKE '%camera%' OR P.DESCRIPTION LIKE '%camera%';
```