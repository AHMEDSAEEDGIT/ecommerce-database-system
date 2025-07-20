# Write a transaction query to lock the field quantity with product id = 211 from being updated
## 🔍 Understanding the Limitations

SQL databases **do not support locking individual columns (fields)**. Locking is always at the **row**, **page**, or **table** level depending on the database system and query.

> “Lock the `quantity` field for product with id = 211 from being updated”


## ✅ Workarounds to Simulate Field-Level Locking

### 1️⃣ Option 1: Lock the row and enforce field immutability in application logic

```sql
BEGIN TRANSACTION;

SELECT * FROM products
WHERE id = 211
FOR UPDATE;

COMMIT;
```

#### in case we want to lock using shared lock 
```sql 
SELECT * 
FROM product 
WHERE product_id = 211
LOCK IN SHARE MODE;
```

> [!NOTE]
> - The `SELECT ... FOR UPDATE` approach is generally preferred as it only locks the specific row(s) .
> - The lock is released when we COMMIT or ROLLBACK the transaction.
> - Other transactions attempting to update the locked row or even delete will be blocked until the locked transaction completes (`ROLLBACK` , `COMMIT`).


---

### 2️⃣ Option 2: Use a ISNTEAD UPDATE TRIGGER to block changes to quantity **Permanently**

```sql
CREATE TRIGGER prevent_quantity_update
BEFORE UPDATE ON product
FOR EACH ROW
BEGIN
    IF OLD.product_id = 211 AND NEW.quantity <> OLD.quantity THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Update to quantity is not allowed for product_id 211';
    END IF;
END

```
---
### 3️⃣ Option 3 : Add lock field to the table

```sql
- Add a lock field to your table
ALTER TABLE products ADD COLUMN quantity_lock TINYINT DEFAULT 0;


BEGIN TRANSACTION;
-- Check if quantity is unlocked
SELECT quantity_lock FROM products WHERE product_id = 211 FOR UPDATE;
-- If unlocked (0):
UPDATE products 
SET quantity = [new_value], quantity_lock = 1 
WHERE product_id = 211 AND quantity_lock = 0;
COMMIT;

```