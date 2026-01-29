🛒 Amazon Project – Advanced SQL Analysis
📌 Project Overview

This project simulates an Amazon-like e-commerce system using Advanced SQL (PostgreSQL).
It covers database design, relationships, business analytics, window functions, CTEs, and stored procedures to solve real-world business problems.

The goal is to analyze sales, customers, sellers, inventory, payments, shipping, and revenue trends using optimized SQL queries.

🛠️ Tech Stack

Database: PostgreSQL

Language: SQL (Advanced level)

Concepts Used:

Joins (INNER, LEFT)

CTEs (WITH clause)

Window Functions (RANK, DENSE_RANK, LAG)

Aggregations

Subqueries

Stored Procedures (PL/pgSQL)

Constraints & Foreign Keys

🗂️ Database Schema
1️⃣ Category Table

Stores product categories.

category(category_id, category_name)

2️⃣ Customers Table

Stores customer details.

customers(customer_id, first_name, last_name, state, address)

3️⃣ Sellers Table

Stores seller information.

sellers(seller_id, seller_name, origin)

4️⃣ Products Table

Stores product details and category mapping.

products(product_id, product_name, price, cogs, category_id)

5️⃣ Orders Table

Stores order-level details.

orders(order_id, order_date, customer_id, seller_id, order_status)

6️⃣ Order Items Table

Stores item-level sales data.

order_items(order_item_id, order_id, product_id, quantity, price_per_unit, total_sales)

7️⃣ Payment Table

Stores payment details.

payment(payment_id, order_id, payment_date, payment_status)

8️⃣ Shipping Table

Tracks shipping and returns.

shipping(shipping_id, order_id, shipping_date, return_date, shipping_providers, delivery_status)

9️⃣ Inventory Table

Tracks stock availability.

inventory(inventory_id, product_id, stock, warehouse_id, last_stock_date)

📊 Business Problems & SQL Analysis
✅ 1. Top Selling Products

Finds Top 10 products by revenue

Uses GROUP BY, SUM, ORDER BY

✅ 2. Revenue by Category

Category-wise revenue

Percentage contribution to total sales

✅ 3. Average Order Value (AOV)

Customer AOV

Only customers with more than 5 orders

✅ 4. Monthly Sales Trend

Last 2 years sales

Uses LAG() window function

✅ 5. Customers With No Purchases

Registered customers with zero orders

✅ 6. Least-Selling Category by State

Category performance by state

Uses RANK()

✅ 7. Customer Lifetime Value (CLTV)

Total sales per customer

Ranked using DENSE_RANK()

✅ 8. Inventory Stock Alerts

Products with stock < 20 units

Includes last restock date

✅ 9. Shipping Delays

Orders shipped after 5 days

Includes customer & provider details

✅ 10. Payment Success Rate

Payment success percentage

Status-wise breakdown

✅ 11. Top Performing Sellers

Top 5 sellers by revenue

Successful vs in-progress order ratio

✅ 12. Product Profit Margin

Profit = Sales − (COGS × Quantity)

Ranked by margin

✅ 13. Most Returned Products

Return percentage per product

✅ 14. Inactive Sellers

Sellers with no sales in last 6 months

✅ 15. Customer Segmentation

Returning vs New customers

Based on return count

✅ 16. Top Customers by State

Top 5 customers per state

Orders + revenue

✅ 17. Revenue by Shipping Provider

Revenue & avg delivery time

✅ 18. Revenue Decrease Analysis (YoY)

Compare 2022 vs 2023

Products with highest revenue drop

  19.final task 
store procedure 
create a function as soon as the product is sold the  same quantity should reduced from inventory table
after adding any  sales records it should update in the inventory table based on the prodcut and qty purchased 


order_id,
order_date,
customer_id,
seller_id ,
order_item_id,
product_id,
quantity,
```
CREATE OR REPLACE PROCEDURE add_sales
(
    p_order_id INT,
    p_customer_id INT,
    p_seller_id INT,
    p_order_item_id INT,
    p_product_id INT,
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INT;
    v_price FLOAT;
    v_product VARCHAR(50);
BEGIN
    -- Fetch product price and name
    SELECT price, product_name
    INTO v_price, v_product
    FROM products
    WHERE product_id = p_product_id;

    -- Check stock availability
    SELECT COUNT(*)
    INTO v_count
    FROM inventory
    WHERE product_id = p_product_id
      AND stock >= p_quantity;

    IF v_count > 0 THEN

        -- Insert into orders table
        INSERT INTO orders (order_id, order_date, customer_id, seller_id)
        VALUES (p_order_id, CURRENT_DATE, p_customer_id, p_seller_id);

        -- Insert into order_items table
        INSERT INTO order_items
        (order_item_id, order_id, product_id, quantity, price_per_unit, total_sales)
        VALUES
        (p_order_item_id, p_order_id, p_product_id,
         p_quantity, v_price, v_price * p_quantity);

        -- Update inventory
        UPDATE inventory
        SET stock = stock - p_quantity
        WHERE product_id = p_product_id;

        RAISE NOTICE
        'Thank you! Product % sold successfully. Inventory updated.',
        v_product;

    ELSE
        RAISE NOTICE
        'Sorry! Product % is not available in required quantity.',
        v_product;
    END IF;

END;
$$;
```

⚙️ Stored Procedure: Inventory Auto-Update
🔹 Use Case

Whenever a product is sold:

Order is created

Order item is added

Inventory stock is automatically reduced

🔹 Procedure Name
add_sales

🔹 Parameters
(p_order_id, p_customer_id, p_seller_id,
 p_order_item_id, p_product_id, p_quantity)

🔹 Features

Stock availability check

Auto inventory deduction

Transaction-safe logic

User-friendly messages

▶️ Sample Procedure Call
CALL add_sales(50000, 2, 5, 50001, 1, 40);

📈 Key Learnings

Real-world e-commerce data modeling

Writing optimized analytical SQL

Using window functions like an analyst

Automating workflows with stored procedures

Strong foundation for Data Analyst / SQL Developer roles

🚀 Future Enhancements

Triggers instead of procedures

Indexing for performance optimization

Power BI / Tableau dashboard integration

Partitioning large tables

👨‍💻 Author

Ritik Rajput
📍 Bhopal, India
🎯 Aspiring Data Analyst / SQL Developer
