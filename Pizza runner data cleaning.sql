select * from customer_orders;

-- Data cleaning of customer_orders table

create temporary table customer_orders_temp_tbl as 
select  trim(order_id) as order_id, 
		customer_id, 
        pizza_id, 
		case 
			when exclusions = '' then null
            when exclusions = 'null' then null
            else exclusions
		end as exclusions,
        case
			when extras = '' then null
            when extras = 'null' then null
            else extras
		end as extras,
        order_time
	from customer_orders;
    
select * from customer_orders_temp_tbl;

-- Creating seperate rows for each value in ' exclusion' and 'extras'

create table customer_orders_cleaned as
 select co.order_id,
		co.customer_id,
        co.pizza_id,
        trim(jc1.exclusions) as exclusions,
        trim(jc2.extras) as extras,
        co.order_time
from customer_orders_temp_tbl co
inner join json_table(trim(replace(json_array(co.exclusions), ',','","')), '$[*]' columns(exclusions varchar(50) path '$')) jc1
inner join json_table(trim(replace(json_array(co.extras), ',','","')), '$[*]' columns(extras varchar(50) path '$')) jc2; 

select * from customer_orders_cleaned;
        
-------------------------------------------------------------------------------------
-- cleaning runner_orders

select * from runner_orders;

create table runner_orders_cleaned as
	select order_id,
		   runner_id,
           case
				when distance = 'null' then null
				else cast(regexp_replace(distance,'[a-z]','') as float)
		   end as distance,
           case 
				when duration = 'null' then null
                else cast(regexp_replace(duration,'[a-z]','') as float)
		   end as duration,
           case
				when cancellation = 'null' then null
                when cancellation = '' then null
                else cancellation
			end as cancellation
	from runner_orders;
    
        select * from runner_orders_cleaned;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Data cleaning in pizza_receipe

select * from pizza_recipes;

-- Concept of using json array 

select * , 
		json_array(toppings),
        replace(json_array(toppings),',','","'),
        trim(replace(json_array(toppings),',','","'))
from pizza_recipes;

-- Actual code for string to rows transformation of 'toppings'

create table pizza_recipes_cleaned as
	select pr.pizza_id, jpr.toppings
    from pizza_recipes pr
    join json_table(trim(replace(json_array(toppings),',','","')),'$[*]' columns (toppings varchar(50) path '$')) jpr;

select * from pizza_recipes_cleaned;
