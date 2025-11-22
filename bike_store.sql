-- viewing all the data i will be working with first to see what needs tuning

select * from bike_store..customers$

select * from bike_store..brands$

select * from bike_store..categories$

select * from bike_store..order_items$

select * from bike_store..orders$

select * from bike_store..products$

select * from bike_store..staffs$

select * from bike_store..stocks$

select * from bike_store..stores$

--CUSTOMER TABLE

--check for duplicates first
--trim what needs trimming
-- null values are present in the phone coulmn in the customers data table and will be handled


-- a replica table will be created so as to maintain originality of the main table

--SELECT * INTO customers2 FROM bike_store..customers$;

select * from bike_store..customers2

-- check for duplicates
with dups as
(
select 
	*,
	ROW_NUMBER() over( partition by first_name,last_name,phone, email, street, city, state, zip_code
	order by customer_id) 
	as row_num
from bike_store..customers2
)
select *
from dups
where row_num > 1

--trimming and updating
UPDATE bike_store..customers2
SET
    first_name = TRIM(first_name),
    last_name  = TRIM(last_name),
    email      = TRIM(email),
    street     = TRIM(street),
    city       = TRIM(city),
    state      = TRIM(state);
   
--only phone column has null values
-- now null values will be replaced with 'unknown'
update bike_store..customers2
set phone = 'unknown'
where phone ='NULL' or phone = '';


--ORDERS TABLE
-- create duplicate orders table
SELECT *
INTO order2
FROM bike_store..orders$;

select * from bike_store..order2

-- convert order date and required date to date column

alter table bike_store..order2
alter column order_date date

alter table bike_store..order2
alter column required_date date 

-- shipped date is converted to date column first then converted back to varchar, so the null values could be renamed

alter table bike_store..order2
alter column shipped_date date 

alter table bike_store..order2
alter column shipped_date varchar(20)

-- handle null values, replace null with not shipped in shipped date column
update bike_store..order2
set shipped_date = 'not shipped'
where shipped_date is null

-- find the total sales amount
select 
    sum((list_price - discount) * quantity) as total_sales
from bike_store..order_items$ 

-- find total amount of orders
select 
    COUNT(*) as total_orders
from bike_store..order2

--find the total profit percentage
with profit as
(
select 
    sum((list_price - discount) * quantity) as revenue,
    sum((list_price - discount) * quantity) * 0.30 as profit,
    30.0 as profit_percentage
from bike_store..order_items$
)
select profit_percentage
from profit

-- find the yearly revenue

select
    year(o.order_date) as year,
    sum((oi.list_price - oi.discount) * oi.quantity) as yearly_revenue
from bike_store..orders$ o
join bike_store..order_items$ oi
    on o.order_id = oi.order_id
group by year(o.order_date)
order by year asc;

--Find the top 5 paying cutomers per total revenue                                                       

with total_revenue as (
    select
        c.first_name,
        c.last_name,
        sum(oi.list_price - oi.discount) as Total_money_spent
    from bike_store..customers2 c
    join bike_store..order2 o
        on c.customer_id = o.customer_id
    join bike_store..order_items$ oi
        on o.order_id = oi.order_id
    join bike_store..products$ p
        on oi.product_id = p.product_id
    group by c.first_name, c.last_name
)
select top 5 *
from total_revenue
order by Total_money_spent desc;

--find the top 5 paying products
select top 5
    p.product_name,
    sum((oi.list_price - oi.discount) * oi.quantity) as total_price_accumulated
from bike_store..order_items$ oi
join bike_store..products$ p
    on oi.product_id = p.product_id
group by  p.product_name
order by total_price_accumulated desc

--find the top 5 least paying products

select top 5
    p.product_name,
    sum((oi.list_price - oi.discount) * oi.quantity) as total_price_accumulated
from bike_store..order_items$ oi
join bike_store..products$ p
    on oi.product_id = p.product_id
group by  p.product_name
order by total_price_accumulated asc

--find out what category of bikes is purchased the most and the least
select 
    c.category_name as bike_category,
    sum(oi.quantity) as times_purchased
from bike_store..products$ p
join bike_store..categories$ c
    on p.category_id = c.category_id
join bike_store..order_items$ oi
    on p.product_id = oi.product_id
group by c.category_name
order by times_purchased desc

--find out the monthly revenue per category

select
    format(o.order_date, 'yyyy-MM') as order_month,
    c.category_name as bike_category,
    sum((oi.list_price - oi.discount) * oi.quantity) as monthly_revenue,
    sum((oi.list_price - oi.discount) * oi.quantity) * 100/ 
        (select 
        sum((list_price - discount) * quantity) from bike_store..order_items$) as revenue_percent
from bike_store..orders$ o
join bike_store..order_items$ oi
    on o.order_id = oi.order_id
join bike_store..products$ p
    on oi.product_id = p.product_id
join bike_store..categories$ c
    on p.category_id = c.category_id
group by 
    format(o.order_date, 'yyyy-MM'),
    c.category_name
order by
    order_month,
    monthly_revenue desc;

-- for tableu dashboard
select
    *
from order2 o
join order_items$ oi
    on o.order_id = oi.order_id
left join customers2 c
    on o.customer_id = c.customer_id
left join products$ p
    on oi.product_id = p.product_id
left join categories$ ca
    on p.category_id = ca.category_id
left join brands$ b
    on p.brand_id = b.brand_id


