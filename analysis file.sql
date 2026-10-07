select * from cafe_final;

#rename the table table name
rename table cafe_final to ajeys_cafe;

select * from ajeys_cafe;

#Har outlet (city-wise) ka total revenue nikaalo
select city,round(sum(quantity * price),2) as total_revenue
from ajeys_cafe
group by city;

#Sabse zyada bikne wala item kaun sa hai (overall aur outlet-wise)
# this is outlet-wise
select outlet_name,item_name,sum(quantity) as top_item
from ajeys_cafe
group by outlet_name,item_name
order by top_item desc
limit 5;

#this is overall quantity
select sum(quantity) as total_sold_product
from ajeys_cafe;
select * from cafe_orders;

#Month-wise / year-wise sales trend dikhao
# this is year wise
select year(order_datetime) as sales_year,
sum(quantity) as total_qty,
round(sum(quantity * price),2) as total_revenue
from ajeys_cafe
where order_datetime is not null
group by  year(order_datetime) 
order by sales_year asc;

#this is monthwise
select monthname(order_datetime) as month_sale,
sum(quantity) as total_qty,
sum(quantity * price) as total_revenue
from ajeys_cafe
where order_datetime is not null
group by monthname(order_datetime),month(order_datetime)
order by month(order_datetime) asc;

#Payment mode ka distribution (UPI vs Cash vs Card) nikaalo
select  payment_mode,count(order_id) as total_orders,
sum(quantity) as total_sold_quantity,
round(sum(quantity * price),2) as total_revenue
from ajeys_cafe
where payment_mode != 'Unknown'
group by payment_mode
order by total_orders desc;

#Average order value (AOV) per outlet calculate karo
select 
count(distinct order_id) as total_orders,
round(sum(quantity * price),2) as total_revenue,
round(sum(quantity * price) / count(distinct order_id),2) as average_order_value
from ajeys_cafe
group by outlet_name
order by average_order_value desc;

#Rating aur sales ke beech koi correlation hai kya, check karo
select rating,
count(order_id) as total_orders,
round(avg(quantity * price),2) as average_order_value,
round(sum(quantity * price),2) as total_revenue
from ajeys_cafe
where rating is not null
group by rating
order by rating desc;

#Kaunsa outlet sabse zyada profitable/growing hai (year-over-year)?
select outlet_name,year(order_datetime) as year_sales,
round(sum(quantity * price),2) as total_revenue,
sum(quantity) as total_sold_qty
from ajeys_cafe
where order_datetime is not null
group by outlet_name,year(order_datetime)
order by outlet_name asc, total_revenue desc;

#if i want to show only top year revenue 
with yearly_sales as(
select outlet_name,
year(order_datetime) as year_sales,
sum(quantity) as total_qty_sold,
round(sum(quantity * price),2) as total_revenue,
rank() over(partition by outlet_name order by sum(quantity * price) desc) as rnk
from ajeys_cafe
where order_datetime is not null
group by outlet_name,year(order_datetime)
)
select outlet_name,year_sales,total_qty_sold,total_revenue
from yearly_sales  # --------> this is on the process
where rnk = 1;

#Kaunse items low-rated hain but high-selling — improvement chahiye?
select rating,item_name,
sum(quantity) as total_sold_quantity,
round(sum(quantity * price),2) as total_revenue
from ajeys_cafe
where rating is not null and rating <= 2
group by rating,item_name
order by total_sold_quantity desc;

#Customer repeat-purchase pattern nikaalo (agar naam clean ho jaye)
select customer_name as total_customer, count(distinct order_id) as count_purchase,year(order_datetime) as yearly
from ajeys_cafe
where customer_name is not null
group by customer_name,year(order_datetime)
having count(distinct order_id) > 1
order by count_purchase desc,yearly asc;

select customer_name,count(*) as total_ravis
from ajeys_cafe
where customer_name = 'Ravi Patel'
group by customer_name;


#Kaunsa outlet sabse zyada profitable/growing hai (year-over-year)?
with CTE as (
select outlet_name,year(order_datetime) as yearly,
sum(quantity) as total_sold_qty,
round(sum(quantity * price),2) as total_revenue,
rank() over(partition by outlet_name order by sum(quantity * price) desc) as rnk
from ajeys_cafe
where order_datetime is not null
group by outlet_name,year(order_datetime)
),
growth_calculation as(
select outlet_name,
yearly,total_sold_qty,
total_revenue,
LAG(total_revenue) over(partition by  outlet_name order by yearly) as previous_year_sale
from CTE
)
SELECT outlet_name,yearly,total_sold_qty,total_revenue,previous_year_sale,
round((total_revenue - previous_year_sale) / NULLIF(previous_year_sale,0) * 100 , 2) AS growth_percent
from growth_calculation
order by outlet_name,yearly;

#Weekday vs weekend sales pattern kaisa hai?
select dayname(order_datetime),
sum(quantity) as total_qty_sold,
round(sum(quantity * price),2) as total_revenue
from ajeys_cafe
where order_datetime is not null
group by weekday(order_datetime),dayname(order_datetime)
order by total_revenue asc
limit 2;
select 
case
when weekday(order_datetime) in (5,6) then 'weekend'
else 'weekday'
end as day_type,
count(distinct order_datetime) as total_days,
sum(quantity) as total_qty_sold,
round(sum(quantity * price),2) as total_revenue,
round(sum(quantity * price) / count(distinct order_datetime) ,2) as average_revenue_per_day
from ajeys_cafe
where order_datetime is not null
group by day_type;

#Window functions use karo — har outlet ka rank by revenue (RANK() OVER (PARTITION BY ... ORDER BY ...))
select outlet_name,round(sum(quantity * price)) as total_revenue,year(order_datetime) as yearly,
rank() over(partition by year(order_datetime) order by round(sum(quantity * price),2)desc) as rnk
from ajeys_cafe
where order_datetime is not null
group by outlet_name,year(order_datetime)
order by yearly asc , rnk asc;
with CTE as (
select outlet_name,year(order_datetime) as yearly,
sum(quantity) as total_sold_qty,
round(sum(quantity * price),2) as total_revenue,
rank() over(partition by outlet_name order by sum(quantity * price) desc) as rnk
from ajeys_cafe
where order_datetime is not null
group by outlet_name,year(order_datetime)
),
growth_calculation as(
select outlet_name,
yearly,total_sold_qty,
total_revenue,
LAG(total_revenue) over(partition by  outlet_name order by yearly) as previous_year_sale
from CTE
)
SELECT outlet_name,yearly,total_sold_qty,total_revenue,previous_year_sale,
round((total_revenue - previous_year_sale) / NULLIF(previous_year_sale,0) * 100 , 2) AS growth_percent
from growth_calculation
order by outlet_name,yearly;

#Month-over-month growth % nikaalo (LAG() window function)
select * from ajeys_cafe;
with CTE as(
select outlet_name,
month(order_datetime) as month_num,
year(order_datetime) as year_sale,
sum(quantity) as total_sold_qty,
round(sum(quantity * price),2) as total_revenue,
date_format(order_datetime , '%b %Y') as month_year_display
from ajeys_cafe
where order_datetime is not null
group by  outlet_name,month(order_datetime),year(order_datetime),date_format(order_datetime , '%b %Y') 
),
growth_calculation as (
select outlet_name,month_num,year_sale,total_sold_qty,total_revenue,month_year_display,
LAG(total_revenue) over(partition by outlet_name order by year_sale asc, month_num asc) as previous_month_sale
from CTE
)
select outlet_name, month_num,year_sale,total_sold_qty,total_revenue,month_year_display,previous_month_sale,
round((previous_month_sale - total_revenue) / nullif(previous_month_sale,0) *100 ,2) as growth_percent
from growth_calculation
order by year_sale,outlet_name asc ,  month_num asc;

#Stored procedure banao jo kisi bhi outlet ka monthly report generate kare
drop procedure if exists GetOutletMonthlyReport;
DELIMITER //
 create procedure GetOutletMonthlyReport( in p_outlet_name varchar(100))
 begin
 with CTE as(
 select outlet_name,
 year(order_datetime) as year_sale,
 month(order_datetime) as month_num,
 date_format(order_datetime, '%b %Y') as month_year,
 sum(quantity) as total_sold_product,
 round(sum(quantity * price),2) as total_revenue,
 count(distinct order_id) as total_orders
 from ajeys_cafe
 where order_datetime is not null 
 and quantity is not null
 and outlet_name = p_outlet_name
 group by outlet_name,year(order_datetime),month(order_datetime),date_format(order_datetime, '%b %Y')
 )
 select outlet_name,year_sale,month_num,month_year,total_sold_product,total_revenue,total_orders,
 round(total_revenue / nullif(total_orders ,0),2) as average_order_value
 from CTE
 order by year_sale asc,month_num asc;
 END //
 DELIMITER ;
 
 CALL GetOutletMonthlyReport('Ajey\'s Cafe - Surat');
 
 #Subquery/CTE se "outlets jinka revenue average se kam hai" nikaalo
 with revenue as (
 select outlet_name,
 sum(quantity) as total_sold_qty,
 round(sum(quantity * price)) as total_revenue
 from ajeys_cafe
 group by outlet_name
 )
 select outlet_name,
 total_sold_qty,total_revenue,
 round((select avg(total_revenue) from revenue),2) as overall_average_revenue
 from revenue
 where total_revenue < (select avg(total_revenue) from revenue)
 order by total_revenue asc;

#Self-join ya EXISTS use karke repeat customers dhundo
select distinct c1.customer_name
from ajeys_cafe c1
where c1.customer_name is not null 
and exists (
select 1
from ajeys_cafe c2
where c2.customer_name = c1.customer_name
and c2.order_id <> c1.order_id 
and c1.customer_name <> 'Guest Customer'
);
