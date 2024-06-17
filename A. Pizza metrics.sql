# A. Pizza Metrics
-- How many pizzas were ordered?

SELECT 
    COUNT(pizza_id) AS Total_Pizza_Orderd
FROM
    customer_orders_cleaned;

-- How many unique customer orders were made?

SELECT 
    COUNT(DISTINCT order_id) AS unique_customer_orders
FROM
    customer_orders_cleaned;

-- How many successful orders were delivered by each runner?

SELECT 
    runner_id,COUNT(order_id) AS successful_orders
FROM
    runner_orders_cleaned
WHERE
    cancellation IS NULL
GROUP BY runner_id;

-- How many of each type of pizza was delivered?

SELECT 
    pizza_id, COUNT(order_id) no_of_pizzas
FROM
    customer_orders_cleaned
GROUP BY pizza_id;

-- How many Vegetarian and Meatlovers were ordered by each customer?

SELECT 
    customer_id,
    SUM(CASE
        WHEN pizza_id = 1 THEN 1
        ELSE 0
        END) AS Meatlovers_pizza,
    SUM(CASE
        WHEN pizza_id = 2 THEN 1
        ELSE 0
        END) AS Vegetarian_pizza
FROM
    customer_orders_cleaned
GROUP BY customer_id;
 
-- What was the maximum number of pizzas delivered in a single order?

SELECT 
    customer_id, order_id, COUNT(order_id) AS Pizza_count
FROM
    customer_orders_cleaned
GROUP BY customer_id , order_id
ORDER BY Pizza_count DESC
LIMIT 1;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

select customer_id,
	   sum(case
			   when (exclusions is not null
						or extras is not null) 
			   then 1
               else 0
		   end) as Change_in_pizza,
		sum(case
				when (exclusions is null 
					  and extras is null)
				then 1
                else 0
			end) as No_change_in_pizza
from customer_orders_cleaned co inner join runner_orders_cleaned ro on co.order_id = ro.order_id
where cancellation is null
group by customer_id
order by customer_id;

-- How many pizzas were delivered that had both exclusions and extras?

select * from customer_orders_cleaned;
select * from runner_orders_cleaned;

SELECT 
    pizza_id, COUNT(pizza_id) AS Delivered_pizzas
FROM
    customer_orders_cleaned co
        JOIN
    runner_orders_cleaned ro ON co.order_id = ro.order_id
WHERE
    exclusions IS NOT NULL
        AND extras IS NOT NULL
        AND cancellation IS NULL
GROUP BY pizza_id;

-- What was the total volume of pizzas ordered for each hour of the day?

SELECT 
    HOUR(order_time) AS Hour_of_day,
    COUNT(order_id) AS volume_of_pizza
FROM
    customer_orders_cleaned
GROUP BY Hour_of_day;

-- What was the volume of orders for each day of the week?

SELECT 
    DAYNAME(order_time) AS Day_of_week,
    COUNT(order_id) AS volume_of_pizza
FROM
    customer_orders_cleaned
GROUP BY Day_of_week;