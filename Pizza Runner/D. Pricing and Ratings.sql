use pizza_runner;

# 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes:
-- - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT SUM(CASE
		WHEN co.pizza_id = 1 THEN 12
		ELSE 10
	   END) AS Earned_money
FROM customer_orders_cleaned co LEFT JOIN
     runner_orders_cleaned ro USING (order_id)
WHERE ro.cancellation IS NULL;

# 2. What if there was an additional $1 charge for any pizza extras?
		-- Add cheese is $1 extra
        
  SELECT SUM(CASE
		 WHEN co.pizza_id = 1 THEN 12
		 ELSE 10
	      END) +
		 SUM(CASE
			 WHEN co.extras = 4 THEN 2
			 WHEN co.extras IS NULL THEN 0
			 ELSE 1
		     END) AS updated_money
FROM customer_orders_cleaned co LEFT JOIN
     runner_orders_cleaned ro USING (order_id)
WHERE ro.cancellation IS NULL;

# 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
	-- how would you design an additional table for this new dataset - 
		-- generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
        
CREATE TABLE ratings (
    order_id INT,
    rating INT
);

INSERT INTO ratings (order_id, rating)
VALUES (1,3),
       (2,5),
       (3,3),
       (4,1),
       (5,5),
       (7,3),
       (8,4),
       (9,2),
       (10,4);

SELECT * FROM ratings;
        
        
# 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id -- order_id
-- runner_id -- rating 
-- order_time -- pickup_time 
-- Time between order and pickup  -- Delivery duration 
-- Average speed -- Total number of pizzas

SELECT co.customer_id,
       co.order_id,
       ro.runner_id,
       rt.rating,
       co.order_time,
       ro.pickup_time,
       TIMESTAMPDIFF(MINUTE,co.order_time, ro.pickup_time) AS Time_betn_Order_and_Pickup,
       ro.duration,
       ROUND(AVG(ro.distance/ro.duration * 60),1) AS Average_speed,
       COUNT(co.order_id) AS Pizza_count
FROM customer_orders_cleaned co
LEFT JOIN runner_orders_cleaned ro USING (order_id)
JOIN ratings rt USING (order_id)
GROUP BY co.customer_id,
		 co.order_id,
         ro.runner_id,
         co.order_time,
         ro.pickup_time,
         ro.duration;

# 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled -
-- how much money does Pizza Runner have left over after these deliveries?

SELECT SUM(CASE
		WHEN co.pizza_id = 1 THEN 12
		ELSE 10
	    END) AS Revenue,
	ROUND(SUM(ro.distance) * 0.3, 2) AS runner_paid,
	ROUND(SUM(CASE
		      WHEN co.pizza_id = 1 THEN 12
		      ELSE 10
	          END) - (SUM(ro.distance) * 0.3),2) AS Money_left
FROM customer_orders_cleaned co JOIN
     runner_orders_cleaned ro USING (order_id)
WHERE ro.cancellation IS NULL;
