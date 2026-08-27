-- Renaming and clearing the data

select * from customers;

desc customers;

alter table customers
rename column ï»¿customer_id to customer_id;

select * from order_details;

alter table order_details
rename column ï»¿order_id to order_id;

select * from orders;

alter table orders
rename column ï»¿order_id to order_id;

select * from products;

alter table products
rename column ï»¿product_id to product_id;

----------------------------------------------------------------------
select * from customers; -- customer_id, name, location
select * from order_details; -- order_id, product_id, quantity, price_per_unit
select * from orders; --  order_id, order_date, customer_id, total_amount
select * from products; -- product_id, name, category, price

desc products;
------------------------------------------------------------------------
/*  
Identify the top 3 cities with the highest number of customers to determine key markets for targeted marketing and logistic optimization.
*/

select location, count(customer_id) as number_of_customers
from customers
group by 1
order by number_of_customers desc
limit 3;




--------------------------------------------------------------





/*
Q2.
Determine how many customers fall into each order frequency category based on the number of orders they have placed.

Using the Orders table, calculate the number of customers who placed 1 order, 2 orders, 3 orders, etc.

Return a table showing:
The number of orders placed
The count of customers who placed that many orders
Sort the results by NumberOfOrders in ascending order.

Number of order			Customer count
1							30
2							12
*/

select * from orders;

select NumberOfOrders, count(*) as Customercount
from (
	select customer_id, count(*) as NumberOfOrders
    from orders
    group by 1
) as order_summary
group by 1
order by numberoforders asc;


select customer_id, count(*) as NumberOfOrders
from orders
group by 1;

---------------------------------------------------------------------------
/*
Q3.
Identify products where the average purchase quantity per order is 2 but with a high total revenue, suggesting premium product trends.

Hint:
Use “OrderDetails”.
Return the result table which includes average quantity and the total revenue in descending order.
*/


select * from order_details;

select product_id, avg(quantity) as AvgQuantity, sum(price_per_unit*quantity) as TotalRevenue
from order_details
group by 1;

select product_id, avg(quantity) as AvgQuantity, sum(price_per_unit*quantity) as TotalRevenue
from order_details
group by 1
having avg(quantity) = 2
order by TotalRevenue desc;

-----------------------------------------------------------------------

/*
Q4.

For each product category, calculate the unique number of customers purchasing from it. This will help understand which categories have wider appeal across the customer base.

Hint:
Use the “Products”, “OrderDetails” and “Orders” table.
Return the result table which will help you count the unique number of customers in descending order.
*/

select * from products; #product_id, category, price
select * from order_details; #order_id, product_id, quantity, price_per_unit
select * from orders; #order_id, order_date, customer_id

select p.category, count(distinct o.customer_id) as unique_customers
from products p 
join order_details od ON p.product_id= od.product_id
join orders o ON od.order_id=o.order_id
group by 1
order by unique_customers desc;

--------------------------------------------------------------

/*
Q5.
Analyze the month-on-month percentage change in total sales to identify growth trends.

Hint:
Use the “Orders” table.
Return the result table which will help you get the month (YYYY-MM), Total Sales and Percent Change of the total amount (Present month value- Previous month value/ Previous month value)*100.
The resulting change in percentage should be rounded to 2 decimal places.
*/

select * from orders;
desc orders;

select date_format(order_date, '%Y-%m') as month, sum(Total_amount) as Total_sales
from orders
group by 1
order by month;


#o1-current month, o2-previous month
select date_format(o1.order_date,'%Y-%m') as month, sum(o1.total_amount) as Total_sales, 
		round(((sum(o1.total_amount)-sum(o2.total_amount))/sum(o2.total_amount))*100,2) as percentchange
from orders o1
left join orders o2 
		ON date_format(o2.order_date,'%Y-%m')= Date_format(date_sub(o1.order_date, INTERVAL 1 MONTH),'%Y-%m')
group by 1
order by month ;

#Using windows function
with monthly_sales as(
	select date_format(order_date, '%Y-%m') as month, 
			sum(Total_amount) as Totalsales
	from orders
    group by 1
    order by month
)

select month, totalsales, 
		round((((totalsales-lag(Totalsales) over(order by month))/lag(Totalsales) over(order by month)))*100,2) as percentchange
from monthly_sales;

-----------------------------------------------------

/*
Q6.
Examine how the average order value changes month-on-month. Insights can guide pricing and promotional strategies to enhance order value.

Hint:
Use the “Orders” Table.
Return the result table which will help you get the month (YYYY-MM), Average order value and Change in the average order value (Present month value- Previous month value).
Both the resulting AvgOrderValue and ChangeInValue column should be rounded to two decimal places, with the final results ordered in descending order by ChangeInValue.
*/

select * from orders;

with monthly_sales as (
	select date_format(order_date,'%Y-%m') as month, round(avg(Total_amount),2) as Avgordervalue
    from orders
    group by 1
    order by month
)

select month, avgordervalue, 
		round(avgordervalue-lag(avgordervalue) over(order by month),2) as changeinvalue
from monthly_sales
order by changeinvalue desc;

-- December has the highest change in avgordervalue

------------------------------------------------------------------
/*
Q7.
Based on sales data, identify products with the fastest turnover rates, suggesting high demand and the need for frequent restocking.

Hint:
Use the “OrderDetails” table.
Return the result table limited to top 5 product according to the SalesFrequency column in descending order.
*/

select * from order_details;

select product_id, count(product_id) as salesfrequency
from order_details
group by 1
order by salesfrequency desc
limit 5;

-- 7 product_id has the highest turnover rates and needs to be restocked frequently.

--------------------------------------------------------------------------

/*
Q8.
List products purchased by less than 40% of the customer base, indicating potential mismatches between inventory and customer interest.

Hint:
Use the “Products”, “Orders”, “OrderDetails” and “Customers” table.
Return the result table which will help you get the product names along with the count of unique customers who belong to the lower 40% of the customer pool.
*/

select * from customers; -- customer_id, name, location
select * from order_details; -- order_id, product_id, quantity, price_per_unit
select * from orders; --  order_id, order_date, customer_id, total_amount
select * from products; -- product_id, name, category, price

select p.product_id, p.name, count(distinct o.customer_id) as uniquecustomercount
from order_details od 
join orders o ON o.order_id=od.order_id
join customers c ON c.customer_id=o.customer_id
join products p ON p.product_id=od.product_id
group by 1,2
having count(distinct o.customer_id) <  (select count(*) * 0.40 from customers )
order by uniquecustomercount ;

-- Why might certain products have purchase rates below 40% of the total customer base? 
-- Poor visibility on platform 

--------------------------------------------------------------------------------

/*
Q9.
Evaluate the month-on-month growth rate in the customer base to understand the effectiveness of marketing campaigns and market expansion efforts.

Hint:
Use the “Orders” table.
Return the result table which will help you get the count of the number of customers who made the first purchase on monthly basis.
The resulting table should be ascendingly ordered according to the month.
*/

select * from orders;

select date_format(first_purchase_date,'%Y-%m') as month, count(customer_id) as new_customers
from (
	select customer_id, min(order_date) as first_purchase_date
    from orders
    group by 1
    ) as first_orders
group by 1
order by month;

-- What can be inferred about the growth trend in the customer base from the result table?
-- It is an upward trend which implies  the marketing campaign are not much effective

--------------------------------------------------------------------------------
/*
Q10.
Identify the months with the highest sales volume, aiding in planning for stock levels, marketing efforts, and staffing in anticipation of peak demand periods.

Hint:
Use the “Orders” table.
Return the result table which will help you get the month (YYYY-MM) and the Total sales made by the company limiting to top 3 months.
The resulting table should be in descending order suggesting the highest sales month.
*/

select date_format(order_date,'%Y-%m') as month, sum(total_amount) as TotalSales
from orders
group by 1
order by totalsales desc
limit 3;

-- Which months will require major restocking of product and increased staffs?
-- September and December
