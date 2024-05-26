# 1.Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT market FROM dim_customer 
WHERE customer = 'Atliq Exclusive' AND region = 'APAC'
GROUP BY market
ORDER BY market ;

# 2.What is the percentage of unique product increase in 2021 vs. 2020? 
# The final output contains these fields : unique_products_2020, unique_products_2021, percentage_chg

SELECT X.A as unique_product_2020, Y.B as unique_product_2021, ROUND((B-A)*100/A , 2) as pct_change
FROM
((SELECT COUNT(distinct(product_code)) as A FROM fact_sales_monthly
WHERE fiscal_year = 2020) X, 
(SELECT COUNT(distinct(product_code)) as B FROM fact_sales_monthly
WHERE fiscal_year = 2021) Y);


# 3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
#The final output contains 2 fields : segment & product_count

SELECT count(distinct(product_code)) as product_count, segment from dim_product
group by segment
order by product_count desc;

# 4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
#The final output contains these fields: segment product_count_2020, product_count_2021, difference

with cte1 as 
(SELECT p.segment as A , count(distinct(fs.product_code)) as B
FROM dim_product p
join fact_sales_monthly fs
on fs.product_code=p.product_code
group by fs.fiscal_year, p.segment
having fs.fiscal_year = "2020"),

cte2 as
(SELECT p.segment as C , count(distinct(fs.product_code)) as D
FROM dim_product p
join fact_sales_monthly fs
on fs.product_code=p.product_code
group by fs.fiscal_year, p.segment
having fs.fiscal_year = "2021")

select cte1.A as Segment, cte1.B as product_count_2020, cte2.D as product_count_2021, (cte2.D-cte1.B) as Difference
from cte1, cte2
where cte1.A = cte2.C ;

# 5. Get the products that have the highest and lowest manufacturing costs.
# The final output should contain these fields : product_code, product, manufacturing_cost

select p.product_code, p.product, m.manufacturing_cost
from dim_product p 
join fact_manufacturing_cost m 
on p.product_code = m.product_code
where manufacturing_cost
in 
	(select max(manufacturing_cost) from fact_manufacturing_cost
	union
	select min(manufacturing_cost) from fact_manufacturing_cost)
order by manufacturing_cost desc;

# 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct 
# for the fiscal year 2021 and in the Indian market.
# The final output contains these fields : customer_code, customer, average_discount_percentage

SELECT 
c.customer_code, c.customer, round(avg(pd.pre_invoice_discount_pct),4) as average_discount_pct
FROM dim_customer c
join fact_pre_invoice_deductions pd 
on c.customer_code=pd.customer_code
where fiscal_year="2021" and market="India"
group by c.customer_code
order by pre_invoice_discount_pct desc
limit 5;

# 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month.
# This analysis helps to get an idea of low and high-performing months and take strategic decisions.
# The final report contains these columns: Month, Year, Gross sales Amount

select concat(monthname(fs.date),' ', year(fs.date)) as 'Month', fs.fiscal_year,
round(sum(g.gross_price*fs.sold_quantity),2) as gross_sales_amount
from fact_sales_monthly fs
join dim_customer c
	on fs.customer_code = c.customer_code
join fact_gross_price g 
	on fs.product_code = g.product_code
where c.customer = "Atliq Exclusive"
group by month, fs.fiscal_year
order by fs.fiscal_year;

# 8. In which quarter of 2020, got the maximum total_sold_quantity?
# The final output contains these fields sorted by the total_sold_quantity: Quarter, total_sold_quantity

select
	case
    WHEN date BETWEEN '2019-09-01' and '2019-11-01' then 1  
    WHEN date BETWEEN '2019-12-01' and '2020-02-01' then 2
    WHEN date BETWEEN '2020-03-01' and '2020-05-01' then 3
    WHEN date BETWEEN '2020-06-01' and '2020-08-01' then 4
    end as Quarters,
    sum(sold_quantity) as Total_sold_quantity
from fact_sales_monthly
where fiscal_year = 2020
group by Quarters
order by fiscal_year;

# 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
# The final output contains these fields: channel, gross_sales_mln, percentage

with cte1 as
(select c.channel , (g.gross_price*f.sold_quantity) as gross_sales_mln
from fact_sales_monthly f
join dim_customer c
	on f.customer_code = c.customer_code
join fact_gross_price g
	on f.product_code = g.product_code
where f.fiscal_year = 2021
group by c.channel)

select *,
gross_sales_mln*100/sum(gross_sales_mln) over() as percentage
from cte1
order by percentage desc;

# 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
#The final output contains these fields: division, product_code

 with cte1 as 
(select p.division, p.product_code, sum(s.sold_quantity) as total_sold_qty
from fact_sales_monthly s 
join dim_product p
	on p.product_code=s.product_code
where s.fiscal_year=2021 
group by p.division, p.product_code),

cte2 as ( select 
		*,
		dense_rank() over(partition by division order by total_sold_qty desc) as drnk
 from cte1)
 
 select division, product_code
 from cte2 where drnk<=3