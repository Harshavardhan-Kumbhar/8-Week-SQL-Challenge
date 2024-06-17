
use pizza_runner;

#C. Ingredient Optimisation

-- What are the standard ingredients for each pizza?

SELECT pr.pizza_id, pn.pizza_name,
       GROUP_CONCAT(pt.topping_name, ', ') AS ingredients
FROM pizza_recipes_cleaned pr
JOIN pizza_names pn ON pr.pizza_id = pn.pizza_id
JOIN pizza_toppings pt on pr.toppings = pt.topping_id
GROUP BY pr.pizza_id,pn.pizza_name;

-- What was the most commonly added extra?

SELECT pt.topping_name, 
	   COUNT(co.extras) AS times_added
FROM customer_orders_cleaned co 
LEFT JOIN pizza_toppings pt ON co.extras = pt.topping_id
WHERE topping_name IS NOT NULL
GROUP BY topping_name
LIMIT 1;

-- What was the most common exclusion?

SELECT pt.topping_name, 
	   COUNT(exclusions) AS exclusions_count
FROM customer_orders_cleaned co
JOIN pizza_toppings pt ON co.exclusions = pt.topping_id
GROUP BY pt.topping_name;
				
/*
-- Generate an order item for each record in the customers_orders table in the format of one of the following:
    Meat Lovers
	Meat Lovers - Exclude Beef
	Meat Lovers - Extra Bacon
	Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
*/

with order_details as (
		SELECT 
			co.order_id,
            co.customer_id,
            pn.pizza_id,
            pn.pizza_name, 
            co.exclusions, 
            co.extras
		FROM customer_orders_cleaned co
        JOIN pizza_names pn 
        ON co.pizza_id = pn.pizza_id
        ),
toppings as (
		SELECT topping_id, 
			   topping_name
		FROM pizza_toppings
        ),
formatted_exclusions as (
		SELECT od.order_id,
			   GROUP_CONCAT(DISTINCT t.topping_name ORDER BY t.topping_name SEPARATOR ', ') AS exclusions
		FROM order_details od
        LEFT JOIN toppings t ON FIND_IN_SET(t.topping_id, od.exclusions)
		GROUP BY od.order_id
        ),
formatted_extras as (
		SELECT od.order_id,
			   GROUP_CONCAT(DISTINCT t.topping_name ORDER BY t.topping_name SEPARATOR ', ') AS extras
		FROM order_details od
        LEFT JOIN toppings t ON FIND_IN_SET(t.topping_id, od.extras)
		GROUP BY od.order_id
        )
SELECT od.order_id,od.customer_id,od.pizza_id,
	   CONCAT_WS(' ', od.pizza_name,
									CASE
										WHEN fe.exclusions is not null and fe.exclusions != '' 
                                        THEN CONCAT('- Exclude ', fe.exclusions)
										ELSE ''
									END,
									CASE
										WHEN fx.extras is not null and fx.extras != '' 
										THEN CONCAT('- Extra ', fx.extras)
										ELSE ''
									END) AS order_description
FROM order_details od
left JOIN formatted_exclusions fe ON od.order_id = fe.order_id
left JOIN formatted_extras fx ON od.order_id = fx.order_id;


/*                    
-- Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and
 add a 2x in front of any relevant ingredients
 For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
 */
 
 
 WITH Extras_cte AS ( SELECT extras AS extras_t
					  FROM customer_orders_cleaned),
	  Exclusions_cte AS ( SELECT exclusions AS exclusions_t
						  FROM customer_orders_cleaned),
	  Pizza_recipes_cte AS ( SELECT co.record_id,
									pr.pizza_id, 
									pr.toppings AS topping_id, 
                                    pt.topping_name AS topping_name
							  FROM customer_orders_cleaned co
							  JOIN pizza_recipes_cleaned pr USING (pizza_id)
							  JOIN pizza_toppings pt ON pr.toppings = pt.topping_id)
 select co.record_id,
		co.order_id,
        co.customer_id,
        co.pizza_id,
        concat_ws(pn.pizza_name, ' : ', GROUP_CONCAT( SELECT CASE
																 WHEN prc.topping_id IN Extras_cte
																	THEN CONCAT_WS( '2x ', prc.topping_name)
																 WHEN prc.topping_id IN Exclusions_cte
																	THEN ""
																 Else topping_name
															 END 
													  FROM Pizza_recipes_cte prc
                                                      LEFT JOIN Extras_cte xc ON prc.topping_id = xc.extras_t
                                                      LEFT JOIN Exclusions_cte ec ON prc.topping_id = ec.exclusions_t
													  ))
		FROM customer_orders_cleaned co
        JOIN pizza_names pn USING (pizza_id)
        GROUP BY co.record_id,
				 co.order_id,
                 co.customer_id,
                 co.pizza_id,
                 pn.pizza_name;
----------------------------------------------------------------------------------------------------------------------------------------


WITH order_details AS (
    SELECT 
        co.record_id,
        co.order_id,
        co.customer_id,
        co.pizza_id,
        co.order_time,
        pn.pizza_name,
        co.extras,
        co.exclusions
    FROM customer_orders_cleaned co
    JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
),
Pizza_recipes_cte AS (
    SELECT 
        pr.pizza_id, 
        pr.toppings AS topping_id, 
        pt.topping_name
    FROM pizza_recipes_cleaned pr 
    JOIN pizza_toppings pt ON pr.toppings = pt.topping_id
),
Toppings_with_modifiers AS (
    SELECT 
        od.record_id,
        od.order_id,
        od.customer_id,
        od.pizza_id,
        od.order_time,
        od.pizza_name,
        prc.topping_id,
        prc.topping_name,
        CASE
            WHEN FIND_IN_SET(prc.topping_id, od.extras) THEN CONCAT('2x ', prc.topping_name)
            WHEN FIND_IN_SET(prc.topping_id, od.exclusions) THEN NULL
            ELSE prc.topping_name
        END AS modified_topping_name
    FROM order_details od
    JOIN Pizza_recipes_cte prc ON od.pizza_id = prc.pizza_id
),
Order_toppings AS (
    SELECT 
        record_id,
        order_id,
        customer_id,
        pizza_id,
        order_time,
        pizza_name,
        GROUP_CONCAT(DISTINCT modified_topping_name ORDER BY modified_topping_name SEPARATOR ', ') AS ingredients_list
    FROM Toppings_with_modifiers
    WHERE modified_topping_name IS NOT NULL
    GROUP BY 
        record_id, 
        order_id,
        customer_id,
        pizza_id,
        order_time,
        pizza_name
)
SELECT 
    record_id,
    order_id,
    customer_id,
    pizza_id,
    order_time,
    CONCAT(pizza_name, ': ', ingredients_list) AS order_description
FROM Order_toppings
ORDER BY record_id;
                 
                                            
-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

WITH frequent_ingredients AS (
								SELECT co.order_id,
									   pt.topping_name as topping_name,
                                       CASE 
											WHEN pt.topping_id IN ( SELECT extras 
                                                                    FROM customer_orders_cleaned) THEN 2
											WHEN pt.topping_id IN ( SELECT exclusions
																	FROM customer_orders_cleaned ) THEN 0
											ELSE 1
										END AS times_used
								FROM customer_orders_cleaned co
                                LEFT JOIN pizza_recipes_cleaned pr USING(pizza_id)
                                JOIN pizza_toppings pt on pt.topping_id = pr.toppings)
SELECT topping_name,
	   SUM(times_used) as times_used
FROM frequent_ingredients
GROUP BY topping_name
ORDER BY times_used DESC;
																


