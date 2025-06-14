CREATE TABLE Customer_Order_Denormalized
(
Order_Detail_Id INTEGER PRIMARY KEY AUTO_INCREMENT,
Customer_Id INTEGER ,
First_Name VARCHAR(20) NOT NULL ,
Last_Name VARCHAR(20) NOT NULL ,
Order_Id Integer ,
order_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
Product_Id INTEGER ,
Product_Name VARCHAR (50) NOT NULL ,
Quantity INTEGER NOT NULL DEFAULT 0 CHECK (Quantity BETWEEN 0 AND 2000), 
Unit_Price NUMERIC (6,2) DEFAULT 0  NOT NULL CHECK (Unit_Price >=0) , 
Product_Total NUMERIC(10,2) NOT NULL  
);


INSERT INTO Customer_Order_Denormalized (Customer_Id , First_Name , Last_Name , Order_Id ,order_date ,Product_Id ,Product_Name , Quantity ,Unit_Price ,Product_Total)
SELECT  C.Customer_Id,
    C.First_Name,
    C.Last_Name,
    O.Order_Id,
    O.Order_Date,
    P.Product_Id,
    P.Name,
    OD.Quantity,
    OD.Unit_Price,
    (OD.Quantity * OD.Unit_Price) AS Product_Total

FROM Customer C
JOIN Orders O ON C.Customer_Id = O.Customer_Id
JOIN Order_Details OD ON O.Order_Id = OD.Order_Id
JOIN Product P ON OD.Product_Id = P.Product_Id;
 
 
 select * from Customer_Order_Denormalized