/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT 
	product_name || ', ' || 
    COALESCE(product_size, '') || ' (' || 
    COALESCE(product_qty_type, 'unit') || ')' AS product_description
FROM product;

--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */
SELECT *
, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY market_date) AS 'ranking'
FROM customer_purchases;

SELECT *
, DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY market_date) AS 'ranking'
FROM customer_purchases;

/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

DROP TABLE IF EXISTS temp_vendor;
CREATE TEMPORARY TABLE temp_vendor AS
	SELECT *
	, dense_rank() OVER(PARTITION BY customer_id ORDER BY market_date DESC) AS 'rank'
	FROM customer_purchases;
	
SELECT *
FROM temp_vendor
WHERE rank = 1;


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

SELECT
product_id
, customer_id
, COUNT(product_id) OVER (PARTITION BY customer_id, product_id) AS purchase_count
FROM customer_purchases;


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */
SELECT
    product_name,
    CASE
        WHEN INSTR(product_name, '-') > 0 THEN TRIM(SUBSTR(product_name, INSTR(product_name, '-') + 1))
        ELSE NULL
    END AS description
FROM product
WHERE INSTR(product_name, '-') > 0;



/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */
SELECT
    product_name,
	product_size,
    CASE
        WHEN INSTR(product_name, '-') > 0 THEN TRIM(SUBSTR(product_name, INSTR(product_name, '-') + 1))
        ELSE NULL
    END AS description
FROM product
WHERE product_size REGEXP'[0-9]';

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

/* Making a temp table to rank and count for best day*/
DROP TABLE IF EXISTS best_day1;

CREATE TEMPORARY TABLE best_day1 AS
SELECT 
    market_date,
    purchase_count,
    DENSE_RANK() OVER (ORDER BY purchase_count DESC) AS rank
FROM (
    SELECT 
        market_date,
        COUNT(market_date) AS purchase_count
    FROM customer_purchases
    GROUP BY market_date
);
DROP TABLE IF EXISTS worst_day1;

/* Making a temp table to rank and count for worst day*/
CREATE TEMPORARY TABLE worst_day1 AS
SELECT 
    market_date,
    purchase_count,
    DENSE_RANK() OVER (ORDER BY purchase_count ASC) AS rank
FROM (
    SELECT 
        market_date,
        COUNT(market_date) AS purchase_count
    FROM customer_purchases
    GROUP BY market_date
);

/* Unionizing the table for best and worst day*/
SELECT market_date, purchase_count
FROM temp.best_day1
WHERE rank = 1
UNION
SELECT market_date, purchase_count
FROM temp.worst_day1
WHERE rank = 1

/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

--making temp tables to combine the 3 tables of interest

DROP TABLE IF EXISTS customer_count;
CREATE TEMPORARY TABLE customer_count AS
    SELECT COUNT(DISTINCT customer_id) AS num_customers,
	product_id
    FROM customer_purchases;

DROP TABLE IF EXISTS product_name_table;

CREATE TEMPORARY TABLE product_name_table AS
	SELECT product.product_name AS product_name,
	vendor_inventory.vendor_id AS vendor_id,
	vendor_inventory.product_id AS product_id,
	vendor_inventory.original_price AS original_price
	FROM vendor_inventory JOIN product
	ON vendor_inventory.product_id = product.product_id;

DROP TABLE IF EXISTS vendor_name_table;
CREATE TEMPORARY TABLE vendor_name_table AS
    SELECT DISTINCT
        vendor.vendor_name, 
        product_name_table.product_name,
        product_name_table.product_id,
		product_name_table.original_price
    FROM product_name_table 
    JOIN vendor
    ON product_name_table.vendor_id = vendor.vendor_id;

	
DROP TABLE IF EXISTS finalized_table;
CREATE TEMPORARY TABLE finalized_table AS
    SELECT 
		vendor_name_table.vendor_name, 
        vendor_name_table.product_name,
		customer_count.num_customers,
		vendor_name_table.original_price
	FROM vendor_name_table CROSS JOIN customer_count;
	
SELECT 
    finalized_table.vendor_name,
    finalized_table.product_name,
    5 * original_price * num_customers AS revenue
FROM finalized_table

-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

DROP TABLE IF EXISTS product_units;

CREATE TEMPORARY TABLE product_units AS
SELECT *,
CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';

SELECT *
from temp.product_units

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO temp.product_units
VALUES('79','Buttertarts','12','3','unit',CURRENT_TIMESTAMP);

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE FROM temp.product_units
WHERE product_id = '79';

SELECT *
FROM temp.product_units;

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

ALTER TABLE product_units
ADD current_quantity INT;

-- temp table to find last quantity per product
DROP TABLE IF EXISTS last_question;
CREATE TEMPORARY TABLE last_question AS
SELECT *,
    DENSE_RANK() OVER (PARTITION BY product_id ORDER BY market_date DESC) AS rank
FROM vendor_inventory;

-- changing the Null to 0
UPDATE temp.last_question
SET quantity = COALESCE(quantity, 0);

-- udating the product units table to reflect the last quantity
UPDATE product_units
SET current_quantity = (
    SELECT quantity
    FROM temp.last_question
    WHERE last_question.product_id = product_units.product_id
    AND last_question.rank = 1
)

WHERE EXISTS (
    SELECT 1
    FROM temp.last_question
    WHERE last_question.product_id = product_units.product_id
    AND last_question.rank = 1
);

SELECT *
FROM temp.product_units;

--



