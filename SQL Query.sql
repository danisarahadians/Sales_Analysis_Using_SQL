

select * from Customers;
select * from Orders;
select * from Delivery_person;
select * from Products;
select * from Pincode;



--1. How many customers do not have DOB information available?
select count(*) DOB_NA
from Customers
where dob is null;

--2. How many customers are there in each pincode and gender combination?

select primary_pincode, gender, count(*) No_of_customer
from customers
group by primary_pincode, gender
order by primary_pincode, gender;


--3. Print product name and mrp for products which have more than 50000 MRP?

select product_name,mrp
from Products
where mrp > 50000;


--4. How many delivery personal are there in each pincode?

select pincode, count(*) No_of_deliveryperson
from Delivery_person
group by pincode;

--5. For each Pin code, print the count of orders, sum of total amount paid, average amount paid, maximum amount paid, 
-- minimum amount paid for the transactions which were
-- paid by 'cash'. Take only 'buy' order types.

select count(order_id) Total_order, SUM(total_amount_paid) Total_amount, AVG(total_amount_paid) average_amount,
max(total_amount_paid) Max_amount, min(total_amount_paid) Min_amount
from Orders
where order_type = 'buy' and payment_type = 'cash';

--6. For each delivery_person_id, print the count of orders and total amount paid for
--product_id = 12350 or 12348 and total units > 8. Sort the output by total amount paid in
--descending order. Take only 'buy' order types.

select delivery_person_id, COUNT(order_id) Total_Order,SUM(total_amount_paid) Total_Amount
from orders
where product_id = '12350' or product_id = '12348' and order_type = 'buy' and payment_type = 'cash' and tot_units>8
group by delivery_person_id;


--7. Print the Full names (first name plus last name) for customers that have email on "gmail.com"?

select CONCAT(first_name,' ',last_name) Full_Name
from customers
where email like '%gmail.com';

--8. Which pincode has average amount paid more than 150,000? Take only 'buy' order types.

select delivery_pincode, AVG(total_amount_paid) AVG_amount
from orders
where order_type = 'buy'
group by delivery_pincode
having AVG(total_amount_paid)>'150000';

--9. Create following columns from order_dim data -
-- order_date
-- Order day
-- Order month
-- Order year

select order_date, day(order_date) [Order day], month(order_date) [Order Month], year(order_date) [Order Year]
from Orders;

--10. How many total orders were there in each month and how many of them were
-- returned? Add a column for return rate too.

with cte1 as(
select month(order_date) [Order Month], Count(Order_type) total_order
from Orders
where Order_type = 'buy'
group by month(order_date)),

cte2 as(
select month(order_date) [Order Month], Count(Order_type) total_return_order
from Orders
where Order_type = 'return'
group by month(order_date))

select cte1.[Order Month], cte1.total_order, cte2.total_return_order, (100* cte2.total_return_order)/cte1.total_order return_Rate
from cte1 
join
cte2 on cte1.[Order Month] = cte2.[Order Month]


-- 11. How many units have been sold by each brand? Also get total returned units for each brand.

with cte1 as(
select p.brand, Sum(displayed_selling_price_per_unit) Total_unit
from Products p
join Orders o
on p.product_id = o.product_id
where order_type = 'buy'
group by p.brand),

cte2 as(
select p.brand, Sum(displayed_selling_price_per_unit) Total_return_unit
from Products p
join Orders o
on p.product_id = o.product_id
where order_type = 'return'
group by p.brand)

select cte1.brand,Total_unit, Total_return_unit
from cte1
join cte2
on cte1.brand = cte2.brand;


--12. How many distinct customers and delivery boys are there in each state?

with cte1 as(
select pincode, count(d.name) delivery_person_count
from Delivery_person d
group by pincode),

cte2 as(
select primary_pincode, count(first_name) person_count
from Customers 
group by primary_pincode)

select pincode, delivery_person_count,person_count
from cte1
join cte2
on cte1.pincode = cte2.primary_pincode


/*13. For every customer, print how many total units were ordered, how many units were
ordered from their primary_pincode and how many were ordered not from the
primary_pincode. Also calulate the percentage of total units which were ordered from
primary_pincode(remember to multiply the numerator by 100.0). Sort by the
percentage column in descending order*/

with cte1 as(
select c.cust_id, SUM(tot_units) Total_OrderUnits_own_pincode
from customers c
join orders o
on c.cust_id = o.cust_id
and c.primary_pincode = o.delivery_pincode
group by c.cust_id),

cte2 as(
select c.cust_id, SUM(tot_units) Total_OrderUnits_other_pincode
from customers c
join orders o
on c.cust_id = o.cust_id
and c.primary_pincode <> o.delivery_pincode
group by c.cust_id),

cte3 as(
select cte1.cust_id, Total_OrderUnits_own_pincode,Total_OrderUnits_other_pincode
from cte1
join cte2
on cte1.cust_id = cte2.cust_id
),

cte4 as(
select c.cust_id, SUM(tot_units) Total_OrderUnits
from customers c
join orders o
on c.cust_id = o.cust_id
group by c.cust_id
)


select cte3.cust_id, Total_OrderUnits_own_pincode,Total_OrderUnits_other_pincode,Total_OrderUnits,
round((Total_OrderUnits_own_pincode/Total_OrderUnits)*100,2) Percentage_OrderUnits_own_pincode
from cte3
join cte4
on cte3.cust_id = cte4.cust_id
order by cte3.cust_id

/*14. For each product name, print the sum of number of units, total amount paid, total
displayed selling price, total mrp of these units, and finally the net discount from selling
price.*/

with cte1 as(
select p.product_name, Sum(tot_units) total_units, sum(total_amount_paid) total_amout, sum(tot_units*displayed_selling_price_per_unit) Display_Amount,
sum(tot_units*mrp) MRP
from orders o
join Products p
on o.product_id = p.product_id
group by p.product_name)


select *, (100-100*total_amout/Display_Amount) Net_Discount_from_Display, (100-100*total_amout/MRP) Net_Discount_from_mrp
from cte1;

/*15. For every order_id (exclude returns), get the product name and calculate the discount
percentage from selling price. Sort by highest discount and print only those rows where
discount percentage was above 10.10%.*/

with cte1 as(
select o.order_id, p.product_name, Sum(total_amount_paid) total_amount_paid, 
sum(tot_units*displayed_selling_price_per_unit) Display_Amount
from orders o
join products p
on o.product_id = p.product_id
where order_type = 'buy'
group by o.order_id, p.product_name)

select *,(100-100*total_amount_paid/Display_Amount) Net_Discount_from_Display
from cte1
where (100-100*total_amount_paid/Display_Amount)>10.10;


/*16. Using the per unit procurement cost in product_dim, find which product category has
made the most profit in both absolute amount and percentage
Absolute Profit = Total Amt Sold - Total Procurement Cost
Percentage Profit = 100.0 * Total Amt Sold / Total Procurement Cost - 100.0*/

with cte1 as(
select p.product_name, Sum(tot_units) total_units, sum(total_amount_paid) total_amount, sum(tot_units*procurement_cost_per_unit) Procurement_cost
from orders o
join Products p
on o.product_id = p.product_id
group by p.product_name)


select *, (total_amount - Procurement_cost) [Absolute Profit], (100*total_amount/Procurement_cost - 100) [Percentage Profit]
from cte1;


/*17. For every delivery person(use their name), print the total number of order ids (exclude
returns) by month in separate columns i.e. there should be one row for each
delivery_person_id and 12 columns for every month in the year.*/

with cte1 as(
select name, month(order_date) Month, count(order_id) Total_Order
from orders o
join Delivery_person d
on o.delivery_person_id = d.delivery_person_id
where order_type = 'buy'
group by name,month(order_date))


select name as Name, sum(case when month = '1' then Total_Order end) as 'January',
sum(case when month = '2' then Total_Order end) as 'February',
sum(case when month = '3' then Total_Order end) as 'March',
sum(case when month = '4' then Total_Order end) as 'April',
sum(case when month = '5' then Total_Order end) as 'May',
sum(case when month = '6' then Total_Order end) as 'June',
sum(case when month = '7' then Total_Order end) as 'July',
sum(case when month = '8' then Total_Order end) as 'August',
sum(case when month = '9' then Total_Order end) as 'September',
sum(case when month = '10' then Total_Order end) as 'October',
sum(case when month = '11' then Total_Order end) as 'November',
sum(case when month = '12' then Total_Order end) as 'December'
from cte1
group by name;


/*18. For each gender - male and female - find the absolute and percentage profit (like in
Q16) by product name*/

with cte1 as(
select c.gender,p.product_name, Sum(tot_units) total_units, sum(total_amount_paid) total_amount, sum(tot_units*procurement_cost_per_unit) Procurement_cost
from orders o
join Customers c
on o.cust_id = c.cust_id
join Products p
on o.product_id = p.product_id
group by c.gender,p.product_name)


select *, (total_amount - Procurement_cost) [absolute profit], (100*total_amount/Procurement_cost - 100) [percentage profit]
from cte1
order by total_units desc;