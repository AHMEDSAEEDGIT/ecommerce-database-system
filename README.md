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
  - [📅 Daily Revenue Report](scripts/reports/1-daily-revenue.md)
  - [📈 Monthly Top-Selling Products](scripts/reports/2-monthly-top-products.md)
  - [💰 Customers with High Total Purchases](scripts/reports/3-high-value-customers.md)
- **Denormalization version on customer and order entities**:
  - [🔧 Customers with High Total Purchases](scripts/reports/3-high-value-customers.md)
---

## 💾 Tools

- MySQL 8.0+ (or compatible database engine)
- SQL client or IDE (e.g., MySQL Workbench)

---

