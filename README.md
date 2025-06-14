# 🛒 Simple E-Commerce Database System

This project demonstrates a basic relational database design for an e-commerce platform using MySQL. It includes an ERD, schema diagram, SQL scripts to create and populate tables, sample reporting queries, and a denormalized version for performance testing.

---

## 📌 Project Structure

- `diagrams/`: Contains the ERD and schema diagram images.
- `scripts/`: SQL files to:
  - Create the tables
  - Insert sample data
  - Generate reports
  - Define a denormalized version and insert into it

---

## 📚 Features

- **Entities**: `Customer`, `Product`, `Category`, `Orders`, `Order_Details`
- **Relationships**:
  - One-to-many between `Category` and `Product`
  - One-to-many between `Customer` and `Orders`
  - Many-to-many between `Orders` and `Product` via `Order_Details`
- **Reports**:
  - Daily revenue
  - Monthly top-selling products
  - Customers with high total purchases
- **Denormalized Table**: Combined view for customer and order analysis

---

## 💾 Tools

- MySQL 8.0+ (or compatible database engine)
- SQL client or IDE (e.g., MySQL Workbench)

---

