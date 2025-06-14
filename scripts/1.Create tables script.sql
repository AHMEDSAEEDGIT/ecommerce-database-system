CREATE DATABASE ecommerce_db;
USE ecommerce_db;

CREATE TABLE Category
(
Category_Id INTEGER AUTO_INCREMENT  ,
Category_Name VARCHAR(30) NOT NULL CHECK (Category_Name  <> '') ,
PRIMARY KEY (Category_Id)
);

CREATE TABLE Product 
(
Product_Id INTEGER AUTO_INCREMENT,
Category_Id INTEGER ,
Name VARCHAR (50) NOT NULL ,
Description VARCHAR(100) ,
Price NUMERIC (6,2) DEFAULT 0  NOT NULL CHECK (Price >=0) , 
Stock_Quantity INTEGER NOT NULL DEFAULT 0 CHECK (Stock_Quantity BETWEEN 0 AND 1000), 
PRIMARY KEY (Product_Id) ,
CONSTRAINT product_category_id_to_category_category_id	FOREIGN KEY (Category_Id) REFERENCES  Category(Category_Id)
);

CREATE TABLE Customer
(
Customer_Id INTEGER AUTO_INCREMENT,
First_Name VARCHAR(20) NOT NULL ,
Last_Name VARCHAR(20) NOT NULL ,
Email VARCHAR(100) NOT NULL UNIQUE  CHECK (Email LIKE '%_@__%.__%'),
Password  VARCHAR(225) NOT NULL,
PRIMARY KEY (Customer_Id)
);

CREATE TABLE Orders
(
Order_Id INTEGER AUTO_INCREMENT,
Customer_Id INTEGER ,
order_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
Total_Amount NUMERIC (8,2) DEFAULT 0  NOT NULL CHECK (Total_Amount >=0) , 
PRIMARY KEY (Order_Id),
CONSTRAINT fk_orders_order_id_to_customer_customer_id	FOREIGN KEY (Customer_Id) REFERENCES  Customer(Customer_Id) 
);



CREATE TABLE Order_Details
(
Order_Detail_Id Integer AUTO_INCREMENT,
Order_Id Integer , 
Product_Id INTEGER ,
Quantity INTEGER NOT NULL DEFAULT 0 CHECK (Quantity BETWEEN 0 AND 2000), 
Unit_Price NUMERIC (6,2) DEFAULT 0  NOT NULL CHECK (Unit_Price >=0) , 
PRIMARY KEY (Order_Detail_Id),
CONSTRAINT fk_order_details_order_id_to_orders_order_id  FOREIGN KEY (Order_Id)  REFERENCES Orders(Order_Id),
CONSTRAINT fk_order_details_product_id_to_product_product_id FOREIGN KEY (Product_Id) REFERENCES Product(Product_Id)

);