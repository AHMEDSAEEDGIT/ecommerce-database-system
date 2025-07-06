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

### 💡 How does it  work ?
> **First** when applying this query `SELECT * FROM CategoryHierarchy` the engine selects from the recursive CTE `CategoryHierarchy`

> which will start with the anchor query `SELECT .... FROM Category WHERE ParentCategoryId IS NULL` which will display all parents from `level 0` So now we have all parents from the root level.

> **Next** we will we move to the recursive part which will  `SELECT * FROM Category` and it will join with `CategoryHierarchy` on the fetched records already we got `the level 0 records` so it will match the records from the `category` that have ParentCategoryId equal to 
CategoryId fromn `CategoryHierarchy` and we will union the reuslt to the same CTE we have got already.

> **Next** We will union the result again with new recursive part to get level 2 categories that have parent categoryId equal to CategoryId that i have got already in the CTE 

> **Finally** Repeat till no record match the condition `JOIN CategoryHierarchy ch ON c.ParentCategoryId = ch.CategoryId`