-- 1. What is the total amount each customer spent at the restaurant?

select s.customer_id , sum(m.price) as total_sales
	from menu m join sales s on m.product_id = s.product_id
group by s.customer_id;

-- 2. How many days has each customer visited the restaurant?

select customer_id ,count(distinct(order_date)) as No_of_days_visited 
	from sales
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?

select s.customer_id , m.product_name 
 from sales s join menu m on s.product_id = m.product_id
	where s.order_date = (select min(s.order_date) from sales s)
group by s.customer_id,m.product_name
order by s.customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select m.product_name as Most_purchased_item , count(s.product_id) as Times_purchased
	from sales s join menu m on s.product_id = m.product_id
group by m.product_name
order by count(s.product_id) desc
limit 1;

-- 5. Which item was the most popular for each customer?

with popular_dish as (
	select s.customer_id,m.product_name,count(s.product_id) as order_count,
    dense_rank() over(partition by s.customer_id order by count(s.customer_id) desc) as rnk
    from menu m join sales s on m.product_id = s.product_id
    group by s.customer_id, m.product_name )
select customer_id, product_name,order_count from popular_dish
where rnk = 1;

-- 6. Which item was purchased first by the customer after they became a member?

with joined_as_member as (
	select mm.customer_id , s.product_id ,
           row_number() over(partition by s.customer_id order by s.order_date) as rn
           from members mm join sales s on mm.customer_id = s.customer_id and s.order_date >= mm.join_date)
select customer_id, m.product_name 
from joined_as_member jm join menu m on jm.product_id = m.product_id
where rn = 1
order by customer_id asc;

-- 7. Which item was purchased just before the customer became a member?

with joined_as_member as (
	select mm.customer_id , s.product_id ,
           row_number() over(partition by mm.customer_id order by s.order_date desc) as rn
           from members mm join sales s on mm.customer_id = s.customer_id and s.order_date < mm.join_date)
select jm.customer_id, m.product_name 
from joined_as_member jm join menu m on jm.product_id = m.product_id
where rn = 1 
order by jm.customer_id asc;
 
-- 8. What is the total items and amount spent for each member before they became a member?

select s.customer_id , count(s.product_id) as total_item , sum(m.price) as amount
from sales s right join menu m on s.product_id = m.product_id
right join members mm on s.customer_id = mm.customer_id
where s.order_date < mm.join_date
group by s.customer_id 
order by s.customer_id asc;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with points_table as (
	select * , case when product_id = 1 then price*20 
					else price*10 
						end as points
	 from menu)
select  s.customer_id, sum(pt.points) as Total_points 
from sales s join points_table pt on s.product_id = pt.product_id
group by s.customer_id; 

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi -  how many points do customer A and B have at the end of January?

with date_cte as (
	select * , date_add(join_date,interval 6 day) as valid_date,
			   dayofmonth('2021-01-31') as last_date_jan 
	from members
)
select s.customer_id ,
	   sum( case when m.product_id = 1 then m.price * 20
				 when s.order_date between d.join_date and d.valid_date then m.price*20
                 else m.price*10
                 end) as points
from date_cte d join sales s
on d.customer_id = s.customer_id
join menu m 
on m.product_id = s.product_id
where s.order_date <= '2021-01-31' and s.order_date >= d.join_date
group by s.customer_id
order by s.customer_id;

-- Bonus Questions 
/*
Join All The Things:

The following questions are related creating basic data tables that Danny and 
his team can use to quickly derive insights without needing to join the underlying tables using SQL.
*/

select s.customer_id, s.order_date , m.product_name, m.price,
		if (s.order_date > mm.join_date, 'Y','N') as member
from sales s right join menu m
on s.product_id = m.product_id
join members mm 
on mm.customer_id = s.customer_id
order by s.customer_id;

/*
Rank All The Things:

Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so
he expects null ranking values for the records when customers are not yet part of the loyalty program.
*/

with DD_cte as (
	select s.customer_id, s.order_date , m.product_name, m.price,
		if (s.order_date > mm.join_date, 'Y','N') as member
from sales s right join menu m
on s.product_id = m.product_id
join members mm 
on mm.customer_id = s.customer_id
order by s.customer_id)
select * , 
		if (member = 'N', null , 
			dense_rank() over(partition by s.customer_id,member order by s.order_date)) as ranking
from DD_cte;


