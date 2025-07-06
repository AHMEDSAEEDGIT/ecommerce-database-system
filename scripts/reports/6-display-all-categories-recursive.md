# display hierarchical data from a self-referencing table (Category)
## displaying all categories parent > child > .... > grand child

```sql
WITH RECURSIVE CategoryHierarchy AS (
    SELECT 
        CategoryId,
        Name,
        Description,
        ParentCategoryId,
        0 AS Level,
        CAST(Name AS CHAR(1000)) AS Path
    FROM Category
    WHERE ParentCategoryId IS NULL

    UNION ALL

    SELECT 
        c.CategoryId,
        c.Name,
        c.Description,
        c.ParentCategoryId,
        ch.Level + 1,
        CONCAT(ch.Path, ' > ', c.Name)
    FROM Category c
    JOIN CategoryHierarchy ch ON c.ParentCategoryId = ch.CategoryId
)
```

```sql
SELECT * FROM CategoryHierarchy
ORDER BY Path;
```