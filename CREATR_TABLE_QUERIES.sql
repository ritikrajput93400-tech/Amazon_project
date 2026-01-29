-- amazon project - advanced SQL


-- category Table 
 create Table category 
(
category_id int primary key, 
category_name varchar(20)
);

-- customers table 
create table customers
(
customer_id int primary key,
first_name varchar(20),
last_name varchar(20),
state varchar(20),
address varchar(5) default ('xxxx')
);

-- sellers table 
create table sellers 
(seller_id int primary key,
seller_name varchar(25),
origin varchar(5)
);


-- UDATING DATA TYPE 
alter table sellers 
alter column origin type  varchar(15);


-- product table 
create  table products
(
product_id int primary key,
product_name varchar(50),
price float,
cogs float,
category_id int , -- FK
constraint product_FK_category foreign key (category_id) references category(category_id)
);

-- orders table 
create table orders
(
order_id int primary key ,
order_date date,
customer_id int, --fk
seller_id int, --fk
order_status varchar(15),
constraint  orders_fk_customers foreign key (customer_id) references customers(customer_id),
constraint  orders_fk_sellers foreign key (seller_id) references sellers(seller_id)
);


--  order_item table 
create table order_items 
(
order_item_id int primary key,
order_id int ,  -- fk 
product_id int, ---fk 
quantity int ,
price_per_unit float,
constraint  orders_items_fk_orders foreign key (order_id) references orders(order_id),
constraint  orders_item_fk_products foreign key (product_id) references products(product_id)
);


-- payment table 
create table payment 
(
payment_id int primary key,
order_id  int, -- fk 
payment_date date,
payment_status varchar (20),
constraint payment_fk_orders foreign key (order_id) references orders(order_id)
);


--shipping table 
create table shipping 
(
shipping_id int primary key ,
order_id int ,-- fk 
shipping_date date,
return_date date ,
shipping_providers varchar(15),
delivery_status varchar(15),
constraint  shipping_item_fk_orders foreign key (order_id) references orders(order_id)
);


--inventory table 
create table  inventory
(
inventory_id int primary key ,
product_id int,  --fk 
stock int ,
warehouse_id int ,
last_stock_date date ,
constraint inventory_fk_products foreign key (product_id) references products(product_id)
);

--end of schemas 

select * from category;
select * from customers;
select * from  sellers ;
select * from products;
select * from  orders;
select * from order_items;
select * from  payment;
select * from shipping ;
select * from inventory;

-- Business problem advances analysis 

/*
1. Top selling products
query the top 10 products by total sales value .
cahllenge : INclude product name , total quantity sold, and total sales value 
*/
-- order_item - orders - products 

-- creating new column for total sales 
alter table order_items 
add column total_sales float ; 

-- updating price qty * price per unit(fill the columns)
update order_items 
set total_sales = quantity * price_per_unit ;


select p.product_name,count(*) as total_quantity , sum(oi.total_sales) as total_revenue  from order_items  as oi 
join 
orders as o 
on o.order_id = oi.order_id 
join 
products as p 
on p.product_id = oi.product_id
group by 1 
order by 3 desc
limit 10 ;

/* 
2 . Revenue by category 
calculate total revenue generted by each product category .
challenge include the percentage contribution of each category to total revenue .
*/

select 
	c.category_id,
	c.category_name , 
	sum(oi.total_sales)  as total_sale,
	sum(oi.total_sales)/(SELECT sum(total_sales) from order_items)*100 as contribution
from  products as p 	
join 
category as c 
on p.category_id = c.category_id 
join order_items as oi 
on p.product_id  = oi.product_id  
group by 1 ,2
order by 1;

/* 
3.Average order value (AOV)
compute the average order value  for each customer .
challenge : include only customers with more than 5 orders.
*/

select
	c.customer_id , 
	concat(c.first_name,' ', c.last_name) as full_name ,
	sum(total_sales)/count(o.order_id) as AOV,
	count(o.order_id)
from orders as o
join
customers as c 
on c.customer_id  = o.customer_id
join 
order_items as oi 
on oi.order_id = o.order_id 
group by 1,2
having count(o.order_id) > 5;

/* 
4. Monthly Sales Trend 
query monthly total sales over the last 2 year.
challenges : display the sales trend , grouping by month , return current_month sale, last month sale;

*/

select
	year,
	month ,
	total_sale as current_month_sale,
	lag(total_sale,1) over(order by year, month) as last_month_sale
from 
(
select 
	extract (month from order_date) as month,
	extract (year from order_date) as year,
	round(sum(oi.total_sales::numeric),2) as total_sale
from orders as o 
join 
order_items as oi 
on oi.order_id = o.order_id 
where  order_date >= current_date - interval '2 year'
group by 1,2
order by year,month
) as t1 ;


/* 
5. Customers with no purchases
find customers who  have registerd but never place an order.
challenge list customer details and the time since their registration .
*/

select * from customers 
where customer_id not in (
select distinct customer_id from orders);

--or 
select * 
from customers as c 
left join 
orders as o 
on o.customer_id  = c. customer_id 
where o.customer_id is null;

/* 
6.least - selling category by state 
identify the least  selling product category for each state 
cahllenge: include the total sales fot that category within eachs tate 
*/
with ranking_table 
as (

select c.state,
	cg.category_name,
	sum(oi.total_sales) as total_sale,
	rank() over(partition by cg.category_name  order by  sum (oi.total_sales) asc ) as rank
from orders as o
join 
customers as c 
on o.customer_id = c.customer_id 
join 
order_items as oi 
on o.order_id  = oi.order_id 
join
products as p 
on oi.product_id  = p.product_id 
join category as cg
on p.category_id = cg.category_id
group by 1,2
)

select  * from ranking_table 
where rank = 1 ;

/* 
7. customer lifetime value (cltv)
calculate the total value(total_sales ) of orders placed by each cusotmer over their lifetime 
challenge : Rank cusotmers based on their CLTV
*/

select concat(c.first_name,' ', c.last_name) as full_name ,
	sum(oi.total_sales) as total_orders,
	dense_rank() over(order by sum(oi.total_sales) desc ) as cx_rank 
from 
orders as  o 
join customers as c 
on c.customer_id  = o.customer_id
join order_items as oi 
on oi.order_id = o.order_id
group by 1 ;


/* 
8. Inventory stock alerts 
query products with stock levels below a certain threshold (e.g, less than 20 units ).
challenge : include last restock date warehouse  information 
*/

select i.inventory_id,
	p.product_name,
	i.stock as current_stock_left,
	i.last_stock_date,
	i.warehouse_id 
from inventory as  i  
join 
products as p 
on p.product_id = i.product_id 
where stock < 20 


/* 
9. Shipping delays 
identify orders where the shipping date is late than 5 days after the order_date .
challenge: Include customer, order details , and delivery provider.
*/
select c.* ,
	o.*,
	s.shipping_providers,
	s.shipping_date - o.order_date as days_tooK_to_deliver
from orders as o
join customers as c 
on c.customer_id = o.customer_id
join shipping  as s 
on o.order_id = s.order_id
where s.shipping_date - o.order_date  >5 ;

/*
Q10 payment success rate 
calculate the percentage of successful paymemnts across all orders.
challenge: include breakdowns by payment status (e.g., failed , peniding).
*/
select 
	p.payment_status,
	count(*) as total_cnt,
	count(*)::numeric/(select count(*) from payment)::numeric*100
from orders as o join 
payment as p 
on o.order_id = p.order_id 
group by 1 

/* 
11.Top performing sellers 
FIND THE top 5 sellers based on total sales value.
challenges: include both sucessful and inprogress orders , and display their percentage of sucessful orders 
*/
with top_sellers
as (
select 
	s.seller_id,
	s.seller_name,
	sum(oi.total_sales)as total_sale 
from 
orders as o 
join 
sellers as s 
on o.seller_id = s.seller_id 
join  
order_items as oi 
on o.order_id = oi.order_id
group by 1, 2
order by 3 desc

limit 5 
),
seller_reports as
(
select
	o.seller_id,
	ts.seller_name,
	o.order_status ,
	count(*) as total_orders
from orders  as o 
join top_sellers as ts 
on ts.seller_id = o.seller_id 
group by 1,2,3
)
select 
	seller_id ,
	seller_name,
	sum(case when order_status = 'Completed' then total_orders else 0  end) as completed_orders, 
	sum(case when order_status = 'Inprogress' then total_orders else 0  end) as inprogress_orders,
	sum(total_orders) as total_orders,
	sum(case when order_status = 'Completed' then total_orders else 0  end)::numeric/
						sum(total_orders)::numeric * 100 as sucessful_order_ratio_percentage
from seller_reports
group by 1,2; 


/* product profit margin 
calculate the profit margin for each (differenece between price and cost of goods sold ).
challenge : Rank Products by thier profit margin, showing highest to lowest 
*/

--orders_items + product 
-- profit  =sum( total_sale  -  cogs* qantity )


select 
p.product_id,
p.product_name,
sum(total_sales - (p.cogs*oi.quantity))as profit,
sum(total_sales - (p.cogs*oi.quantity))::numeric/sum(total_sales)::numeric*100 as profit_margin,
dense_rank()over(order by sum(total_sales - (p.cogs*oi.quantity))::numeric/sum(total_sales)::numeric*100 ) as product_rank
from
order_items as oi 
join 
products as p 
on oi.product_id = p.product_id 
group by 1,2;

/*
13 . Most returened products 
Query the top 10 products by the number of retruns 
challenge :display the return rate as a percentage of total units sold for each product
*/
with new_table as (
select *   from 
orders as o 
join shipping as s 
on o.order_id = s.order_id 
join order_items as oi 
on o.order_id  = oi.order_id 
),
return_table as (
select p.product_id ,
p.product_name ,
count(*) as total_sold_unit,
sum(case when nt.delivery_status='Returned' then 1 else 0 end) as total_returned,
sum(case when nt.delivery_status='Returned' then 1 else 0 end)::numeric/count(*)::numeric *100 as return_percentage
from products as p 
join new_table as nt 
on nt.product_id  = p.product_id
group by 1,2
order by 5 desc
)
select* from return_table ;

/* 
15. Inactive sellers 
identify sellers who have not made any sales in the last 6 months 
challenge: show the last sale date and total sales form those sellers.
*/

with cte1 -- as these sellers has not done any sale in last 6 month 
as
(
select * from sellers
where seller_id not in (select seller_id from orders where order_date >= current_date - Interval '6 month')
)

select o.seller_id,
max(o.order_date) as last_sale_date ,
max(oi.total_sales) as last_sale_amount
from orders  as o 
join 
cte1 
on cte1 .seller_id = o.seller_id
join order_items as oi 
on o.order_id = oi.order_id
group by 1 ;


/* 16. identify customers into returning or new 
if the customer has done more than 5 return categrize  them as returning otherwise new 
challenge : List customers id,name, total orders ,total returns 
*/


select 
full_name as customers ,
total_orders,
total_return,
case 
	 when total_return >5 then 'Returning_cusotmers' else 'New' end as Cx_category
from (

select 
	concat(c.first_name,' ',c.last_name) as full_name,
	count(o.order_id) as total_orders,
	sum(case when o.order_status = 'returned' then 1 else 0 end ) as total_return
from orders as o 
join customers as c 
on c.customer_id = o.customer_id 
join 
order_items as oi
on oi.order_id = o.order_id 
group by 1 
)

/* 
17 . Top 5 customers by orders in each state 
identify the top 5 customers with the highest number of orders for each state 
challenge :include the number of orders and total sales for each customer
*/
with cte as(
select c.state,
	concat(c.first_name,' ',c.last_name) as full_name,
	count(o.order_id) as total_orders,
	sum(total_sales) as total_sales,
	dense_rank()over(partition by c.state order by count(o.order_id) desc) as rank 
from 
orders as o 
join customers  as c 
on o.customer_id = c.customer_id 
join order_items as oi 
on o.order_id = oi.order_id 
group by 1 ,2 
)
select * from cte 
where rank <=5 ; 


/* 
18.Revenue by shipping provider 
calcualate the total revenue handles by each shipping provider 
challenge : include the total number of orders handled and the average delivery time for each provider 
*/ 
select 
	s.shipping_providers ,
	count(o.order_id) as total_ordes,
	sum (total_sales) as  total_revenue ,
	coalesce(avg(s.return_date-s.shipping_date),0) as average_days
from 
orders as o 
join shipping as s 
on o.order_id  = s.order_id
join order_items as oi 
on o.order_id = oi.order_id 
group by 1 ;


/* 
19 . Top 10 product with highest decreasing revenue ratio campare to last year(2022) and current_year(2023)
challenge: Return product_id , product_name ,Category_name,2022 revenue and 2023 revenue decrease ratio at end round  the result 
Note: Decrease ratio  = cr-ls/ls*100 = (cs = current_year ls = last_year)
*/


with last_year_sale
as(
select 
	p.product_id,
	p.product_name,
	sum(oi.total_sales) as revenue
from 
orders as o 
join shipping as s 
on o.order_id  = s.order_id
join order_items as oi 
on o.order_id = oi.order_id 
join products as p 
on  p.product_id = oi.product_id 
where Extract(year from o.order_date) = 2022
group by 1,2
),
current_year_sale  as 
(
select 
	p.product_id,
	p.product_name,
	sum(oi.total_sales) as revenue
from 
orders as o 
join shipping as s 
on o.order_id  = s.order_id
join order_items as oi 
on o.order_id = oi.order_id 
join products as p 
on  p.product_id = oi.product_id 
where Extract(year from o.order_date) = 2023
group by 1,2
)
select 
	ls.product_id ,
	ls.revenue as last_year_revenue,
	cs.revenue as current_year_revenue,
	ls.revenue-cs.revenue as rev_diff,
	round((cs.revenue-ls.revenue)::numeric/ls.revenue::numeric * 100,2) as revenue_dec_ratio
from  last_year_sale  as ls 
join 
current_year_sale as cs
on ls.product_id  = cs.product_id
where ls.revenue > cs.revenue
order by 5 desc 
limit 10;

/*
final task 
-- store procedure 
create a function as soon as the product is sold the  same quantity should reduced from inventory table
after adding any  sales records it should update in the inventory table based on the prodcut and qty purchased 
--*/

order_id,
order_date,
customer_id,
seller_id ,
order_item_id,
product_id,
quantity,

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

call  add_sales
(
50000, 2, 5,50001,1,40
);


(
    p_order_id INT,
    p_customer_id INT,
    p_seller_id INT,
    p_order_item_id INT,
    p_product_id INT,
    p_quantity INT
)





select * from category;
select * from customers;
select * from  sellers ;
select * from products;
select * from  orders;
select * from order_items;
select * from  payment;
select * from shipping ;
select * from inventory;











