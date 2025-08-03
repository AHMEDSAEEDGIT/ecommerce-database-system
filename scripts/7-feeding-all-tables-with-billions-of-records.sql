use ecommerce_db;
-- Disable foreign key checks temporarily
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE Order_Details;
TRUNCATE TABLE Orders;
TRUNCATE TABLE Product;
TRUNCATE TABLE Customer;
TRUNCATE TABLE Category;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- --------------------------------------------------------------------------------------------------------------------------
-- fill category table 

DELIMITER //

CREATE PROCEDURE insert_categories_feed(IN num_records INT)
BEGIN
    DECLARE x INT DEFAULT 0;
    DECLARE batch_size INT DEFAULT 1000;
    DECLARE batch_count INT DEFAULT CEIL(num_records / batch_size);
    DECLARE current_batch INT DEFAULT 0;

    SET @start_time = NOW(6);

    WHILE current_batch < batch_count DO
        START TRANSACTION;

        SET x = current_batch * batch_size;
        WHILE x < (current_batch + 1) * batch_size AND x < num_records DO
            INSERT INTO Category (Category_Name)
            VALUES (CONCAT('Category ', x + 1));
            SET x = x + 1;
        END WHILE;

        COMMIT;

        IF current_batch MOD 10 = 0 THEN
            SELECT CONCAT('Inserted ', x, ' of ', num_records, ' categories') AS progress;
        END IF;

        SET current_batch = current_batch + 1;
    END WHILE;

    SET @total_time = TIMESTAMPDIFF(MICROSECOND, @start_time, NOW(6)) / 1000000;
    SELECT CONCAT('Total time: ', @total_time, ' seconds') AS result;
END //

DELIMITER ;


-- ----------------------
CALL insert_categories_feed(100000);
-- --------------------------------------------------------------------------------------------------------------------------
-- fill product table 
DELIMITER //

CREATE PROCEDURE insert_products_feed(IN num_records INT)
BEGIN
    DECLARE x INT DEFAULT 0;
    DECLARE batch_size INT DEFAULT 1000;
    DECLARE batch_count INT DEFAULT CEIL(num_records / batch_size);
    DECLARE current_batch INT DEFAULT 0;

    DECLARE cat_count INT;
    SELECT COUNT(*) INTO cat_count FROM Category;

    SET @start_time = NOW(6);

    WHILE current_batch < batch_count DO
        START TRANSACTION;

        SET x = current_batch * batch_size;
        WHILE x < (current_batch + 1) * batch_size AND x < num_records DO
            INSERT INTO Product (Category_Id, Name, Description, Price, Stock_Quantity)
            VALUES (
                FLOOR(1 + RAND() * cat_count),
                CONCAT('Product ', x + 1),
                CONCAT('Description for product ', x + 1),
                ROUND(1 + RAND() * 999, 2),
                FLOOR(RAND() * 1000)
            );
            SET x = x + 1;
        END WHILE;

        COMMIT;

        IF current_batch MOD 10 = 0 THEN
            SELECT CONCAT('Inserted ', x, ' of ', num_records, ' products') AS progress;
        END IF;

        SET current_batch = current_batch + 1;
    END WHILE;

    SET @total_time = TIMESTAMPDIFF(MICROSECOND, @start_time, NOW(6)) / 1000000;
    SELECT CONCAT('Total time: ', @total_time, ' seconds') AS result;
END //

DELIMITER ;
-- ----------------------
CALL insert_products_feed(100000);

-- --------------------------------------------------------------------------------------------------------------------------
-- fill customer table 

DELIMITER //

CREATE PROCEDURE insert_customers_feed(IN num_records INT)
BEGIN
    DECLARE x INT DEFAULT 0;
    DECLARE batch_size INT DEFAULT 1000;
    DECLARE batch_count INT DEFAULT CEIL(num_records / batch_size);
    DECLARE current_batch INT DEFAULT 0;

    SET @start_time = NOW(6);

    WHILE current_batch < batch_count DO
        START TRANSACTION;

        SET x = current_batch * batch_size;
        WHILE x < (current_batch + 1) * batch_size AND x < num_records DO
            INSERT INTO Customer (First_Name, Last_Name, Email, Password)
            VALUES (
                CONCAT('First', x + 1),
                CONCAT('Last', x + 1),
                CONCAT('user', x + 1, '@example.com'),
                'hashedpassword123'
            );
            SET x = x + 1;
        END WHILE;

        COMMIT;

        IF current_batch MOD 10 = 0 THEN
            SELECT CONCAT('Inserted ', x, ' of ', num_records, ' customers') AS progress;
        END IF;

        SET current_batch = current_batch + 1;
    END WHILE;

    SET @total_time = TIMESTAMPDIFF(MICROSECOND, @start_time, NOW(6)) / 1000000;
    SELECT CONCAT('Total time: ', @total_time, ' seconds') AS result;
END //

DELIMITER ;
-- ----------------------
CALL insert_customers_feed(1000000);
-- --------------------------------------------------------------------------------------------------------------------------
 -- fill order table 
 DELIMITER //

CREATE PROCEDURE insert_orders_feed(IN num_records INT)
BEGIN
    DECLARE x INT DEFAULT 0;
    DECLARE batch_size INT DEFAULT 1000;
    DECLARE batch_count INT DEFAULT CEIL(num_records / batch_size);
    DECLARE current_batch INT DEFAULT 0;

    DECLARE cust_count INT;
    SELECT COUNT(*) INTO cust_count FROM Customer;

    SET @start_time = NOW(6);

    WHILE current_batch < batch_count DO
        START TRANSACTION;

        SET x = current_batch * batch_size;
        WHILE x < (current_batch + 1) * batch_size AND x < num_records DO
            INSERT INTO Orders (Customer_Id, Total_Amount)
            VALUES (
                FLOOR(1 + RAND() * cust_count),
                ROUND(10 + RAND() * 990, 2)
            );
            SET x = x + 1;
        END WHILE;

        COMMIT;

        IF current_batch MOD 10 = 0 THEN
            SELECT CONCAT('Inserted ', x, ' of ', num_records, ' orders') AS progress;
        END IF;

        SET current_batch = current_batch + 1;
    END WHILE;

    SET @total_time = TIMESTAMPDIFF(MICROSECOND, @start_time, NOW(6)) / 1000000;
    SELECT CONCAT('Total time: ', @total_time, ' seconds') AS result;
END //

DELIMITER ;

-- ----------------------
CALL insert_orders_feed(2000000);
-- --------------------------------------------------------------------------------------------------------------------------
 -- fill order detila table 
DELIMITER //

CREATE PROCEDURE order_details_feed(IN num_records INT)
BEGIN
    DECLARE x INT DEFAULT 0;
    DECLARE batch_size INT DEFAULT 1000;
    DECLARE batch_count INT DEFAULT CEIL(num_records / batch_size);
    DECLARE current_batch INT DEFAULT 0;
    
    DECLARE prod_count INT;
    DECLARE order_count INT;
    
    -- Get current counts
    SELECT COUNT(*) INTO prod_count FROM Product;
    SELECT COUNT(*) INTO order_count FROM Orders;

    -- Start timer
    SET @start_time = NOW(6);

    WHILE current_batch < batch_count DO
        START TRANSACTION;

        SET x = current_batch * batch_size;
        WHILE x < (current_batch + 1) * batch_size AND x < num_records DO
            INSERT INTO Order_Details (Order_Id, Product_Id, Quantity, Unit_Price)
            VALUES (
                FLOOR(1 + RAND() * order_count),
                FLOOR(1 + RAND() * prod_count),
                FLOOR(1 + RAND() * 5),
                ROUND(1 + RAND() * 500, 2)
            );
            SET x = x + 1;
        END WHILE;

        COMMIT;

        IF current_batch MOD 10 = 0 THEN
            SELECT CONCAT('Inserted ', x, ' of ', num_records, ' records') AS progress;
        END IF;

        SET current_batch = current_batch + 1;
    END WHILE;

    -- Show total time
    SET @total_time = TIMESTAMPDIFF(MICROSECOND, @start_time, NOW(6)) / 1000000;
    SELECT CONCAT('Total time: ', @total_time, ' seconds') AS result;
END //

DELIMITER ;

-- ----------------------
CALL order_details_feed(5000000);


-- ----------------------------------------------------------

