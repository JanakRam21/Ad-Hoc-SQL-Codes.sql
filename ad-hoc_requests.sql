

-- 1
SELECT 
    market
FROM
    dim_customer
WHERE
    region = 'APAC'
        AND customer = 'atliq Exclusive'
ORDER BY market;

-- 2 
with cte as 
(SELECT 
    SUM(CASE
        WHEN fiscal_year = '2020' THEN 1
        ELSE 0
    END) AS unique_product_2020,
    SUM(CASE
        WHEN fiscal_year = '2021' THEN 1
        ELSE 0
    END) AS unique_product_2021
FROM
    fact_gross_price)
select unique_product_2020, unique_product_2021, 
Round((unique_product_2021-unique_product_2020)/unique_product_2020 * 100,2) as percent_change
from cte;

-- 3
SELECT 
    segment, COUNT(product_code) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY 2 DESC;

-- 4
with cte as 
(SELECT 
    dp.segment,
    count(case when fgp.fiscal_year = '2020' then dp.product_code end) as 2020_product_count,
    count(case when fgp.fiscal_year = '2021' then dp.product_code end) as 2021_product_count
FROM
    fact_gross_price AS fgp
        JOIN
    dim_product AS dp ON dp.product_code = fgp.product_code
GROUP BY dp.segment)
select segment, 2020_product_count, 2021_product_count, (2021_product_count - 2020_product_count) AS difference
from cte
order by 4 desc;

-- 5

SELECT 
    p.product_code, product, manufacturing_cost
FROM
    dim_product AS p
        LEFT JOIN
    fact_manufacturing_cost AS fmc ON p.product_code = fmc.product_code
WHERE
    manufacturing_cost = (SELECT 
            MAX(manufacturing_cost)
        FROM
            fact_manufacturing_cost) 
UNION SELECT 
    p.product_code, product, manufacturing_cost
FROM
    dim_product AS p
        LEFT JOIN
    fact_manufacturing_cost AS fmc ON p.product_code = fmc.product_code
WHERE
    manufacturing_cost = (SELECT 
            MIN(manufacturing_cost)
        FROM
            fact_manufacturing_cost);
            
-- 6

SELECT 
    c.customer_code,
    customer,
    AVG(pre_invoice_discount_pct) AS average_discount_percentage
FROM
    dim_customer AS c
        LEFT JOIN
    fact_pre_invoice_deductions AS d ON c.customer_code = d.customer_code
WHERE
    fiscal_year = 2021
        AND LOWER(market) LIKE 'india'
GROUP BY c.customer_code , customer
ORDER BY 3 DESC
LIMIT 5;

-- 7

SELECT 
    YEAR(date) AS 'Year',
    MONTH(date) AS 'Month',
    ROUND(SUM(Sales) / 1000000, 2) AS Gross_Sales_Amount
FROM
    (SELECT 
        date, customer_code, (sold_quantity * gross_price) AS sales
    FROM
        fact_sales_monthly fsm
    JOIN fact_gross_price AS fgp ON fsm.product_code = fgp.product_code
        AND fsm.fiscal_year = fgp.fiscal_year) AS temp
        JOIN
    dim_customer AS dc ON temp.customer_code = dc.customer_code
WHERE
    customer = 'Atliq Exclusive'
GROUP BY YEAR(date) , MONTH(date)
ORDER BY 1 , 2;

-- 8

SELECT 
    CASE
        WHEN MONTH(date) IN (9 , 10, 11) THEN 'Q1'
        WHEN MONTH(date) IN (12 , 1, 2) THEN 'Q2'
        WHEN MONTH(date) IN (3 , 4, 5) THEN 'Q3'
        ELSE 'Q4'
    END AS quarter,
    ROUND(SUM(sold_quantity) / 1000000, 2) AS 'total_sold_quantity(M)'
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2020
GROUP BY quarter
ORDER BY 2 DESC;

-- 9


SELECT
   channel,
   gross_sales_mln,
   concat(round(gross_sales_mln / (sum(gross_sales_mln) over (partition by fiscal_year))*100, 2), '%') as percentage 
FROM
   (
      SELECT
         channel,
         fsm.fiscal_year,
         round(sum(sold_quantity * gross_price) / 1000000, 2) AS gross_sales_mln 
      FROM
         fact_sales_monthly AS fsm 
         join
            fact_gross_price AS fgp 
            ON fsm.product_code = fgp.product_code 
            AND fsm.fiscal_year = fgp.fiscal_year 
         join
            dim_customer AS dc 
            ON fsm.customer_code = dc.customer_code 
      WHERE
         fsm.fiscal_year = 2021 
      GROUP BY
         channel,
         fsm.fiscal_year
   )
   as temp 
ORDER BY
   2 DESC;
   
-- 10

with cte as
(SELECT division, fsm.product_code, product, sum(sold_quantity) as total_sold_qty,
dense_rank() over (partition by division order by sum(sold_quantity) desc) as rank_order
FROM dim_product as prod
JOIN fact_sales_monthly AS fsm
ON prod.product_code = fsm.product_code
where fiscal_year = 2021
group by division, product_code, product
order by 4 desc, 5 asc)
select division, product_code, product, total_sold_qty, rank_order
from cte
where rank_order <=3;

