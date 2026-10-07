CREATE DATABASE ajeyscafes;
use ajeyscafes;

CREATE TABLE cafe_orders (
    order_id VARCHAR(50),
    outlet_name VARCHAR(100),
    city VARCHAR(50),
    order_datetime VARCHAR(50),
    item_name VARCHAR(100),
    quantity VARCHAR(50),
    price VARCHAR(50),
    payment_mode VARCHAR(50),
    customer_name VARCHAR(100),
    rating VARCHAR(50),
    franchise_owner VARCHAR(100)
);

set global local_infile = 1;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ajeys_cafe_franchise_unclean_dataset.csv'
INTO TABLE cafe_orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

#count how many rows in table
SELECT COUNT(*) AS total_rows
FROM cafe_orders;

select * from cafe_orders;

#create copy of table
create table cafe as 
select * 
from cafe_orders;

select * from cafe;

select * from cafe 
limit 10;

#check the null values 
select 
sum(order_id is null or order_id='') as order_id_null,
sum(outlet_name is null or outlet_name='') as outlet_name_null,
sum(city is null or city='') as city_null,
sum(order_datetime is null or order_datetime='') as order_datetime_null,
sum(item_name is null or item_name='') as item_name_null,
sum(quantity is null or quantity='') as quantity_null,
sum(price is null or price='') as price_null,
sum(payment_mode is null or payment_mode='') as payment_mode_null,
sum(customer_name is null or customer_name='') as customer_name_null,
sum(rating is null or rating='') as rating_null,
sum(franchise_owner is null or franchise_owner='') as franchise_owner_null
from cafe;

#check duplicate values / which id comes how many times
select order_id,count(*) as unique_order_id
from cafe
group by order_id
having unique_order_id > 1;

#how many duplicate values available in exiting table
select count(*) as duplicate_rows 
from (
select order_id,count(*) as unique_order_id
from cafe
group by order_id
having unique_order_id > 1
) as duplicates;

#from every cloumns  we check how many duplicates rows and how many time they are repeting 
#in this query every duplicates values is 2 times repeted
select
order_id,
outlet_name,
city,
order_datetime,
item_name,
quantity,
price,
payment_mode,
customer_name,
rating,
franchise_owner,
count(*) as cnt
from cafe
group by 
order_id,
outlet_name,
city,
order_datetime,
item_name,
quantity,
price,
payment_mode,
customer_name,
rating,
franchise_owner
having cnt > 1;

#just we check above query gave correct output or not but this above query give correct output every duplicate row repeated 2 times
select *
from cafe
where order_id = 100031;

#now we clean the outlet_name name first we check how many unique values and then clean this columns
select distinct outlet_name
from cafe
order by outlet_name;

#first we add new colum of outlet_name 
alter table cafe add column outlet_name_clean varchar(100);
select * from cafe;

UPDATE cafe
SET outlet_name_clean = CASE 
    WHEN LOWER(TRIM(outlet_name)) LIKE '%surat%' THEN 'Ajey''s Cafe - Surat'
    WHEN LOWER(TRIM(outlet_name)) LIKE '%ahmedabad%' OR LOWER(TRIM(outlet_name)) LIKE '%ahmadabad%' THEN 'Ajey''s Cafe - Ahmedabad'
    WHEN LOWER(TRIM(outlet_name)) LIKE '%baroda%' OR LOWER(TRIM(outlet_name)) LIKE '%vadodara%' THEN 'Ajey''s Cafe - Vadodara'
    WHEN LOWER(TRIM(outlet_name)) LIKE '%bengaluru%' OR LOWER(TRIM(outlet_name)) LIKE '%bangalore%' OR LOWER(TRIM(outlet_name)) LIKE '%banglore%' THEN 'Ajey''s Cafe - Bangalore'
    WHEN LOWER(TRIM(outlet_name)) LIKE '%rajkot%' THEN 'Ajey''s Cafe - Rajkot'
    WHEN LOWER(TRIM(outlet_name)) LIKE '%mumbai%' THEN 'Ajey''s Cafe - Mumbai'
    WHEN LOWER(TRIM(outlet_name)) LIKE '%delhi%' OR LOWER(TRIM(outlet_name)) LIKE '%new delhi%' THEN 'Ajey''s Cafe - Delhi'
    WHEN LOWER(TRIM(outlet_name)) LIKE '%pune%' THEN 'Ajey''s Cafe - Pune'
    ELSE NULL
END;
select outlet_name,outlet_name_clean,count(*) as counts
from cafe
group by outlet_name,outlet_name_clean;
set sql_safe_updates=0;

#clean city column first we add city column
alter table cafe add column city_clean varchar(100);
update cafe 
set city_clean=
case 
when lower(trim(city)) = 'surat' then 'Surat'
when lower(trim(city)) = 'ahmedabad' then 'Ahmedabad'
when lower(trim(city))  in ('mumbai') then 'Mumbai'
when lower(trim(city)) = 'pune' then 'Pune'
when lower(trim(city)) = 'rajkot' then 'Rajkot'
when lower(trim(city)) in ('baroda','vadodara') then 'Vadodara'
when lower(trim(city)) in ('bengaluru','bangalore','banglore') then 'Bangalore'
when lower(trim(city)) in ('delhi','new delhi') then 'Delhi'
else null
end;

select city, city_clean, count(*) as total_rows 
from cafe
group by city, city_clean
order by city;

select * from cafe;

# clean payment_mode columns 
alter table cafe add column payment_mode_clean varchar(100);

update cafe 
set payment_mode_clean =
case 
when lower(trim(payment_mode)) = 'cash' then 'Case'
when lower(trim(payment_mode)) = 'upi' then 'UPI'
when lower(trim(payment_mode)) = 'credit card' then 'Credit Card'
when lower(trim(payment_mode)) = 'debit card' then 'Debit Card'
when lower(trim(payment_mode)) = 'netbanking' then 'NetBanking'
when lower(trim(payment_mode)) = 'card' then 'Card'
else null
end;

select payment_mode,payment_mode_clean,count(*) as total_rows
from cafe
group by payment_mode,payment_mode_clean
order by payment_mode;

##then clean the customer name column 
alter table cafe add column customer_name_clean varchar(100);

UPDATE cafe
SET customer_name_clean = CASE 
    -- 1. Missing / Blank values handling
    WHEN customer_name IS NULL OR TRIM(customer_name) = '' THEN 'Guest Customer'
    
    -- 2. Dynamic Title Casing (First Name + Last Name)
    ELSE CONCAT(
        -- First Name (Pehle word ka 1st letter Capital, baaki small)
        UPPER(LEFT(SUBSTRING_INDEX(REGEXP_REPLACE(TRIM(customer_name), '[[:space:]]+', ' '), ' ', 1), 1)),
        LOWER(SUBSTRING(SUBSTRING_INDEX(REGEXP_REPLACE(TRIM(customer_name), '[[:space:]]+', ' '), ' ', 1), 2)),
        ' ',
        -- Last Name (Dusre word ka 1st letter Capital, baaki small)
        UPPER(LEFT(SUBSTRING_INDEX(REGEXP_REPLACE(TRIM(customer_name), '[[:space:]]+', ' '), ' ', -1), 1)),
        LOWER(SUBSTRING(SUBSTRING_INDEX(REGEXP_REPLACE(TRIM(customer_name), '[[:space:]]+', ' '), ' ', -1), 2))
    )
END;

select customer_name,customer_name_clean, count(*) as total_rows
from cafe
group by customer_name,customer_name_clean
order by customer_name;

#now we are cleaning the franchise_owner column
alter table cafe add column franchise_owner_clean varchar(100);
select * from cafe;

update cafe
set franchise_owner_clean = 
case 
when lower(replace(trim(franchise_owner),'','  ')) = 'ajey shah' then 'Ajey Shah'
else 'Ajey Shah'
end;

select franchise_owner,franchise_owner_clean,count(*) as total_rows
from cafe
group by franchise_owner,franchise_owner_clean
order by franchise_owner;

#now we are cleaning rating columns 
select rating,count(*) as records
from cafe
group by rating
order by rating;

alter table cafe add column rating_clean decimal(2,1);

update cafe 
set rating_clean = 
case
when rating is null or trim(rating) = '' or trim(rating) = '0.0' or trim(rating) = '0' then null
when abs(cast(trim(rating) as decimal (3,1))) between 1.0 and 5.0 then abs(cast(trim(rating) as decimal (3,1))) 
else null
end;

select rating,rating_clean,count(*) as total_rows
from cafe
group by rating,rating_clean
order by rating;

#now we are clean orderdate columns
select order_datetime
from cafe
where order_datetime is not null;

alter table cafe add column order_datetime_clean datetime;
UPDATE cafe 
SET order_datetime_clean = DATE(order_datetime_clean);
alter table cafe modify column order_datetime_clean date;

UPDATE cafe
SET order_datetime_clean = CASE
    -- 1. Blank/NULL values handling
    WHEN order_datetime IS NULL OR TRIM(order_datetime) = '' THEN NULL

    -- 2. Format: YYYY-MM-DD (with or without seconds)
    WHEN TRIM(order_datetime) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN 
        STR_TO_DATE(TRIM(order_datetime), CASE 
            WHEN TRIM(order_datetime) LIKE '%:%:%' THEN '%Y-%m-%d %H:%i:%s'
            WHEN TRIM(order_datetime) LIKE '%:%' THEN '%Y-%m-%d %H:%i'
            ELSE '%Y-%m-%d'
        END)

    -- 3. Format: DD/MM/YYYY (with or without seconds)
    WHEN TRIM(order_datetime) REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}' THEN 
        STR_TO_DATE(TRIM(order_datetime), CASE 
            WHEN TRIM(order_datetime) LIKE '%:%:%' THEN '%d/%m/%Y %H:%i:%s'
            WHEN TRIM(order_datetime) LIKE '%:%' THEN '%d/%m/%Y %H:%i'
            ELSE '%d/%m/%Y'
        END)

    -- 4. Format: DD-Mon-YYYY (e.g., 15-Jan-2024)
    WHEN TRIM(order_datetime) REGEXP '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}' THEN 
        STR_TO_DATE(TRIM(order_datetime), '%d-%b-%Y')

    ELSE NULL
END;

select order_datetime,order_datetime_clean,count(*) as total_rows
from cafe
group by order_datetime,order_datetime_clean
order by order_datetime;

select * from cafe;

#only extract clean columns and create copy of old table 
 create table cafe_final as
 select 
 order_id,
outlet_name_clean as outlet_name,
city_clean as city,
payment_mode_clean as payment_mode,
customer_name_clean as customer_name,
franchise_owner_clean as franchise_owner,
quantity_clean as quantity,
price_clean as price,
rating_clean as rating,
order_datetime_clean as order_datetime
from cafe;

select * from cafe_final;

select count(*) as total_rows
from cafe_final;

#check if it is null values or not
select 
sum(order_id is null) as missing_order_id,
sum(outlet_name is null) as missing_outlet_name,
sum(city is null) as missing_city,
sum(payment_mode is null) as missing_payment_mode,
sum(customer_name is null) as missing_customer_name,
sum(franchise_owner is null) as missing_franchise_owner,
sum(quantity is null) as missing_quantity,
sum(price is null) as missing_price,
sum(rating is null) as missing_rating,
sum(order_datetime is null) as missing_order_datetime
from cafe_final;

update cafe_final 
set city = outlet_name
where city is null and outlet_name is not null;

select * from cafe_final;

-- outlet_name se city extract karke city column me set karein
UPDATE cafe_final
SET city = REPLACE(outlet_name, 'Ajey''s Cafe - ', '');

#handle the null values in paymentmode method colummn
update cafe_final 
set payment_mode = "Unknown"
where payment_mode is null;

#update wrong spelling in paymentmode method
update cafe_final 
set payment_mode = 'Cash'
where lower(trim(payment_mode)) = 'case';

#replace the null values in price column with average values
update cafe_final c
cross join (
select round(avg(price)) as overroll_avg
from cafe_final
where price is not null
) avg_table
set c.price = avg_table.overroll_avg
where price is null;

#duplicate check query
select order_id,count(*) as duplicate_check
from cafe_final
group by order_id
having duplicate_check > 1;

select * from cafe_final;

#drop duplicates values
create table cafe_temp as
with CTE as (
select *,
row_number() over(partition by order_id order by order_datetime desc, price desc) as row_num from cafe_final
)
select * from CTE where row_num = 1;

truncate table cafe_final;

insert into cafe_final 
select * from cafe_temp;

alter table cafe_temp drop column row_num;

select * from cafe_temp;
drop table cafe_temp;

select * from cafe_final;

select order_id,count(*) as total_orders
from cafe_temp
group by order_id
having total_orders > 1;

select count(*) as total_rows
from cafe_final;

alter table ajeys_cafe add column item_name varchar(100);

update ajeys_cafe a 
join cafe_orders c
on
a.order_id = c.order_id
set a.item_name = c.item_name;

set sql_safe_updates=0;

CREATE INDEX idx_cafe_orders_id ON cafe_orders(order_id);
CREATE INDEX idx_ajeys_cafe_id ON ajeys_cafe(order_id);

#clean qty columns
select * from ajeys_cafe;
alter table ajeys_cafe drop column quantity;
alter table ajeys_cafe add column quantity_clean int;
SET sql_safe_updates = 0;

UPDATE ajeys_cafe a
JOIN cafe c ON a.order_id = c.order_id
SET a.quantity_clean = CASE
    WHEN c.quantity IS NULL 
      OR TRIM(c.quantity) = '' 
      OR TRIM(c.quantity) = '0' 
      OR TRIM(c.quantity) = '0.0' 
      THEN NULL
    WHEN CAST(TRIM(c.quantity) AS DECIMAL(10,2)) > 0 
      THEN CAST(CAST(TRIM(c.quantity) AS DECIMAL(10,2)) AS SIGNED)
    ELSE NULL
END;
set sql_safe_updates=0;

alter table ajeys_cafe rename column quantity_clean to quantity;
select * from ajeys_cafe;

DESCRIBE ajeys_cafe;
DESCRIBE cafe;
