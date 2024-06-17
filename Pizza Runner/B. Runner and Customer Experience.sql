#  Runner and Customer Experience
-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT 
    WEEK(registration_date) AS week_of_registration,
    COUNT(runner_id) AS number_of_runner
FROM runners
GROUP BY week_of_registration;

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT 
    ro.runner_id,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, co.order_time, ro.pickup_time)),2) AS Avg_arrive_time_to_HQ
FROM
    customer_orders_cleaned co
        JOIN
    runner_orders_cleaned ro ON co.order_id = ro.order_id
GROUP BY ro.runner_id;

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?

SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

/*
-- This is error was showing while runnning below query in MySQL

of SELECT list is not in GROUP BY clause and contains nonaggregated column 'cte.order_prep_time'
 which is not functionally dependent on columns in GROUP BY clause; this is incompatible with sql_mode=only_full_group_by	0.000 sec
 
 so I disabled only_full_group_by mode

*/

WITH cte AS (
		SELECT  count(co.pizza_id) AS pizza_count, 
			co.order_id, 
               		round(AVG(TIMESTAMPDIFF(MINUTE, co.order_time, ro.pickup_time)),2) AS order_prep_time
		FROM customer_orders_cleaned co 
		JOIN runner_orders_cleaned ro 
		ON co.order_id = ro.order_id
		WHERE ro.pickup_time IS NOT NULL
		GROUP BY co.order_id)
SELECT pizza_count,order_prep_time 
FROM cte
GROUP BY pizza_count;

 #PEARSON CORRELATION FOR FINDING REALTION BETWEEN 'PIZZA_COUNT' AND 'PREPARATION TIME'

create temporary table pearson 
select count(co.pizza_id) as pizza_count, 
co.order_id, avg(timestampdiff(minute,co.order_time,ro.pickup_time)) as order_prep_time
from customer_orders_cleaned co join runner_orders_cleaned ro on co.order_id = ro.order_id
where ro.pickup_time is not null
group by co.order_id;

-- #create average and standard rows to calculate pearson r value

SELECT 
    @ax:=AVG(order_prep_time),
    @ay:=AVG(pizza_count),
    @div:=(STDDEV_SAMP(order_prep_time) * STDDEV_SAMP(pizza_count))
FROM
    pearson;

-- # calculate pearson r value

SELECT 
    SUM((order_prep_time - @ax) * (pizza_count - @ay)) / ((COUNT(order_prep_time) - 1) * @div) AS pearson_r
FROM
    pearson;
    
--# pearson r value is '0.277'. This proves that there is a relation between pizza count and preparation time

-- What was the average distance travelled for each customer?

SELECT 
    co.customer_id, round(AVG(ro.distance),2) AS avg_distance
FROM
    customer_orders_cleaned co
        JOIN
    runner_orders_cleaned ro ON co.order_id = ro.order_id
GROUP BY co.customer_id;

-- What was the difference between the longest and shortest delivery times for all orders?

SELECT 
    MAX(duration) - MIN(duration) AS difference
FROM
    runner_orders_cleaned
WHERE
    duration IS NOT NULL;

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT 
    co.customer_id,
    ro.runner_id,
    ro.order_id,
    ROUND(AVG((ro.distance*1000) / (ro.duration *60)),2) AS avg_speed_M_per_S
FROM
    runner_orders_cleaned ro
        JOIN
    customer_orders_cleaned co
WHERE
    distance IS NOT NULL
GROUP BY customer_id,ro.runner_id , ro.order_id
order by customer_id asc,ro.runner_id asc, ro.order_id asc;

-- There is no trend for these values

-- What is the successful delivery percentage for each runner?

SELECT 
    runner_id,
    (SUM(CASE
        WHEN cancellation IS NULL THEN 1
        ELSE 0
    END) * 100 / COUNT(runner_id)) AS Percentage
FROM
    runner_orders_cleaned
GROUP BY runner_id;
