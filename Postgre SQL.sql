-- ===================================== Create the desiered tables =================================== --
CREATE TABLE pizzas (
    pizza_id VARCHAR(50) PRIMARY KEY,   -- Unique identifier for each pizza
    pizza_type_id VARCHAR(50) NOT NULL, -- Links to pizza_types table
    size VARCHAR(10) NOT NULL,          -- Size of the pizza (S, M, L)
    price DECIMAL(10, 2) NOT NULL       -- Price of the pizza in USD
);


CREATE TABLE pizza_types (
    pizza_type_id VARCHAR(50) PRIMARY KEY, -- Unique identifier for each pizza type
    name VARCHAR(255) NOT NULL,            -- Full name of the pizza type
    category VARCHAR(50) NOT NULL          -- Category of the pizza (e.g., Chicken)
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,        -- Unique identifier for each order
    date DATE NOT NULL,                 -- Order date
    time TIME NOT NULL                  -- Order time
);

CREATE TABLE order_details (
    order_details_id SERIAL PRIMARY KEY, -- Unique identifier for each order detail
    order_id INTEGER NOT NULL,          -- Links to orders table
    pizza_id VARCHAR(50) NOT NULL,      -- Links to pizzas table
    quantity INTEGER NOT NULL           -- Number of pizzas ordered
);

-- ========================================== Upload CSV Files ==================================== --
COPY pizzas
FROM 'D:/Israr/CSV datasets/Pizza/pizzas.csv'
DELIMITER ','
CSV HEADER;
SELECT * FROM pizzas;

COPY pizza_types
FROM 'D:/Israr/CSV datasets/Pizza/pizza_types.csv'
DELIMITER ','
CSV HEADER;
SELECT * FROM pizza_types;

COPY orders
FROM 'D:/Israr/CSV datasets/Pizza/orders.csv'
DELIMITER ','
CSV HEADER;
SELECT * FROM orders;

COPY order_details
FROM 'D:/Israr/CSV datasets/Pizza/order_details.csv'
DELIMITER ','
CSV HEADER;
SELECT * FROM order_details;

-- ==================================== Questions To Solve ======================================== --
-- ========================================== Basic =============================================== --
-- 1: Retrieve the total number of orders placed.
-- 2: Calculate the total revenue generated from pizza sales.
-- 3: Identify the highest-priced pizza.
-- 4: Identify the most common pizza size ordered.
-- 5: List the top 5 most ordered pizza types along with their quantities.

--------------------------------------------- 1 --------------------------------------------------------
-- Count the total number of rows in the orders table to determine the total number of orders placed
SELECT COUNT(*) AS total_orders
FROM orders;

--------------------------------------------- 2 ---------------------------------------------------------
-- Calculate the total revenue by summing up the product of quantity and price for all pizzas ordered
SELECT 
    SUM(od.quantity * p.price) AS total_revenue
FROM order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id;

--------------------------------------------- 3 -------------------------------------------------------
-- Retrieve the pizza with the highest price from the pizzas table
SELECT 
    pizza_id, size, price
FROM pizzas
ORDER BY price DESC
LIMIT 10;

------------------------------------------------ 4 -----------------------------------------------------
-- Find the most frequently ordered pizza size
SELECT 
    p.size, 
    COUNT(DISTINCT od.order_id) AS size_count,
	SUM (od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p
ON  od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY size_count DESC;

-------------------------------------------------- 5 -------------------------------------------------------

-- Get the top 5 pizza types by total quantity ordered
SELECT 
    pt.name AS pizza_type, 
    SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_quantity DESC
LIMIT 5;

---------------------------------------- Intermediat Questions  -----------------------------------------------
--Intermediate:
--Find the total quantity of each pizza category ordered (this will help us to understand the category which customers prefer the most).
--Determine the distribution of orders by hour of the day (at which time the orders are maximum (for inventory management and resource allocation).
--Find the category-wise distribution of pizzas (to understand customer behaviour).
--Group the orders by date and calculate the average number of pizzas ordered per day.
--Determine the top 3 most ordered pizza types based on revenue (let's see the revenue wise pizza orders to understand from sales perspective which pizza is the best selling)

-------------------------------------------------- 1 -----------------------------------------
-- Get the total quantity ordered for each pizza category
SELECT 
    pt.category,                      
    SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY total_quantity DESC;

-- ============================================== 2 ============================================== --
-- Get the distribution of orders by hour of the day
SELECT 
    EXTRACT(HOUR FROM o.time) AS hour_of_day,
    COUNT(o.order_id) AS total_orders
FROM orders o
GROUP BY hour_of_day
ORDER BY total_orders DESC;

-- =============================================== 3 ================================================= --
-- Get the category-wise distribution of pizzas
SELECT 
    pt.category,                      
    COUNT(DISTINCT p.pizza_id) AS total_pizzas  
FROM pizzas p
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category                 
ORDER BY total_pizzas DESC;           

-- ======================================= 4 ======================================= --
-- Get the number of pizzas ordered per day
SELECT 
    o.date,                                  
    ROUND(SUM(od.quantity),2) AS total_orders   
FROM orders o
JOIN order_details od
ON o.order_id = od.order_id                
GROUP BY o.date                             
ORDER BY o.date;                            

-- AND --
-- Get the AVG number of pizzas ordered per day
WITH CTE AS(
SELECT 
    o.date,                                  
    ROUND(SUM(od.quantity),2) AS total_orders   
FROM orders o
JOIN order_details od
ON o.order_id = od.order_id                
GROUP BY o.date
)
SELECT 
	ROUND (AVG(total_orders),2) AS avg_orders_per_day
FROM CTE;                            

-- ================================ 5 ===================================== --
-- Get the top 3 most ordered pizza types based on revenue
SELECT 
    pt.name AS pizza_type,                              
    SUM(od.quantity * p.price) AS total_revenue         
FROM order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id                           
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id                
GROUP BY pt.name                                      
ORDER BY total_revenue DESC                            
LIMIT 3;                                              

-- ====================================== ADVANCE ===================================== --
-- Calculate the percentage contribution of each pizza type to total revenue (to understand % of contribution of each pizza in the total revenue)
-- Analyze the cumulative revenue generated over time.
-- Determine the top 3 most ordered pizza types based on revenue for each pizza category (In each category which pizza is the most selling)

-- ============================================ 1 ======================================== --
-- Calculate the percentage contribution of each pizza type to total revenue using CTE
WITH total_revenue_all AS (
    SELECT SUM(od.quantity * p.price) AS total_revenue
    FROM order_details od
    JOIN pizzas p
    ON od.pizza_id = p.pizza_id
)
SELECT 
    pt.name AS pizza_type,
    SUM(od.quantity * p.price) AS total_revenue,
    ROUND((SUM(od.quantity * p.price) / total_revenue_all.total_revenue) * 100, 2) AS revenue_percentage
FROM order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id
CROSS JOIN total_revenue_all  -- Use CROSS JOIN to include total revenue from the CTE
GROUP BY pt.name, total_revenue_all.total_revenue
ORDER BY revenue_percentage DESC;

-- AND -- 
-- BY CATEGORY --
-- Calculate the percentage contribution of each pizza category to total revenue using CTE
WITH total_revenue_all AS (
    SELECT SUM(od.quantity * p.price) AS total_revenue
    FROM order_details od
    JOIN pizzas p
    ON od.pizza_id = p.pizza_id
)
SELECT 
    pt.category,                                              
    SUM(od.quantity * p.price) AS total_revenue,               -- Total revenue for each category
    ROUND((SUM(od.quantity * p.price) / total_revenue_all.total_revenue) * 100, 2) AS revenue_percentage
FROM order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id
CROSS JOIN total_revenue_all  -- Use CROSS JOIN to include total revenue from the CTE
GROUP BY pt.category, total_revenue_all.total_revenue
ORDER BY revenue_percentage DESC;


-- ===================================== 2 ========================================== --
-- Analyze the cumulative revenue generated over time
WITH revenue_per_day AS (
    SELECT 
        o.date, 
        SUM(od.quantity * p.price) AS daily_revenue
    FROM orders o
    JOIN order_details od
    ON o.order_id = od.order_id
    JOIN pizzas p
    ON od.pizza_id = p.pizza_id
    GROUP BY o.date
)
SELECT 
    date,
    daily_revenue,
    SUM(daily_revenue) OVER (ORDER BY date) AS cumulative_revenue  -- Calculate cumulative revenue
FROM revenue_per_day
ORDER BY date;

-- ======================================= 3 ========================================= --
-- Determine the top 3 most ordered pizza types based on revenue for each pizza category using CTE and window function
WITH total_revenue_all AS (
    SELECT SUM(od.quantity * p.price) AS total_revenue
    FROM order_details od
    JOIN pizzas p
    ON od.pizza_id = p.pizza_id
),
ranked_pizza_types AS (
    SELECT 
        pt.category,                                              
        pt.name AS pizza_type,                                     
        SUM(od.quantity * p.price) AS total_revenue,               
        ROW_NUMBER() OVER (PARTITION BY pt.category ORDER BY SUM(od.quantity * p.price) DESC) AS rank
    FROM order_details od
    JOIN pizzas p
    ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt
    ON p.pizza_type_id = pt.pizza_type_id
    CROSS JOIN total_revenue_all  -- Use CROSS JOIN to include total revenue from the CTE
    GROUP BY pt.category, pt.name
)
SELECT 
    category,
    pizza_type,
    total_revenue
FROM ranked_pizza_types
WHERE rank <= 3  -- Limit to top 3 pizza types per category
ORDER BY category, rank;










