-- ========================================
-- 1. Create Tables
-- ========================================

-- Customers Table
CREATE TABLE IF NOT EXISTS customers (
    Customer_ID TEXT PRIMARY KEY,
    Name TEXT,
    Age INTEGER,
    Operator_Experience TEXT,
    Multi_Policy TEXT,
    Years_Insured INTEGER,
    Income_Band TEXT
);

-- Policies Table
CREATE TABLE IF NOT EXISTS policies (
    Policy_ID INTEGER PRIMARY KEY,
    Navigation_Area TEXT,
    Hull_Material TEXT,
    Coverage_Limit INTEGER,
    Annual_Premium INTEGER,
    Year_Boat_Built INTEGER,
    Customer_ID TEXT,
    FOREIGN KEY(Customer_ID) REFERENCES customers(Customer_ID)
);

-- Claims Table
CREATE TABLE IF NOT EXISTS claims (
    Claim_ID TEXT PRIMARY KEY,
    Claim_Date DATE,
    Claim_Payment INTEGER,
    Cause_of_Loss TEXT,
    Policy_ID INTEGER,
    FOREIGN KEY(Policy_ID) REFERENCES policies(Policy_ID)
);


--check if foreign keys work
SELECT conname, conrelid::regclass AS table_name, confrelid::regclass AS references_table
FROM pg_constraint
WHERE contype = 'f';

SELECT * FROM pg_constraint;


-- ========================================
-- 2. Import CSV Data
-- ========================================

--CSV files were directly imported into PostgreSQL
--There are 3 CVS files imported, and these CSV files were generated using Python 


-- ========================================
-- 3. Example Queries / Transformations
-- ========================================

--Calculate the total profit. total of annual premiums - total of claim payments. JOIN method.Output -9,434,518
SELECT SUM(p.annual_premium) - COALESCE(SUM(cl.claim_payment),0) AS total_profit
FROM policies p
LEFT JOIN claims cl ON cl.policy_id = p.policy_id ;

--Calculate the total profit. Subquery method. output -9,434,518
CREATE VIEW profit_total AS 
SELECT
    (SELECT SUM(annual_premium) FROM policies) -
    (SELECT SUM(claim_payment) FROM claims) AS total_profit;

--Do multiple claims exist for a policy? The JOIN method will have duplicates of policy premium added when multiple claims per policy
SELECT policy_id, COUNT(*) AS claim_count
FROM claims
GROUP BY policy_id
HAVING COUNT(*) > 1;

--A CTE method for the same total profit calculation. Output also -9,434,518.
WITH premium_total AS (
    SELECT SUM(annual_premium) AS total_premium
    FROM policies
),
claim_total AS (
    SELECT SUM(claim_payment) AS total_claims
    FROM claims
)
SELECT total_premium - total_claims AS total_profit
FROM premium_total, claim_total;

--The total profit by navigation area. I use case here and rollup for a total row. 
SELECT
CASE 
        WHEN p.navigation_area IS NULL THEN 'Total'
        ELSE p.navigation_area
    END AS navigation_area,
    SUM(p.annual_premium) - SUM(cl.claim_payment) AS profit
FROM policies p
LEFT JOIN claims cl ON p.policy_id = cl.policy_id
GROUP BY ROLLUP(p.navigation_area)
ORDER BY 
    CASE WHEN p.navigation_area IS NULL THEN 1 ELSE 0 END,
    profit DESC;

--To make a total profit by navigation area and hull material in the same table. The All Hulls is repetitive

CREATE VIEW navigation_hull_profit AS
SELECT
    COALESCE(p.navigation_area, 'All Areas') AS navigation_area,
    COALESCE(p.hull_material, 
             CASE WHEN p.navigation_area IS NOT NULL THEN 'All Hulls' ELSE 'Grand Total' END
    ) AS hull_material,
    SUM(p.annual_premium) - COALESCE(SUM(cl.claim_payment), 0) AS profit
FROM policies p
LEFT JOIN claims cl ON p.policy_id = cl.policy_id
GROUP BY ROLLUP(p.navigation_area, p.hull_material)
ORDER BY
    CASE WHEN p.navigation_area IS NULL THEN 2 ELSE 0 END,  -- grand total last
    CASE WHEN p.hull_material IS NULL AND p.navigation_area IS NOT NULL THEN 1 ELSE 0 END,  -- subtotal per nav area
    navigation_area,
    hull_material;

--This shows total profit for navigation_area and hull_material without total rows. It shows what cases were actually profitable
CREATE VIEW navigation_hull_profit_other AS
SELECT
    p.navigation_area,
    p.hull_material,
    SUM(p.annual_premium) - COALESCE(SUM(cl.claim_payment), 0) AS profit
FROM policies p
LEFT JOIN claims cl ON p.policy_id = cl.policy_id
GROUP BY p.navigation_area, p.hull_material
ORDER BY profit DESC; --add navigation_area in front of profit if you want areas grouped. 


--Profit by hull material
CREATE VIEW hull_profit AS
SELECT 
p.hull_material, 
SUM(p.annual_premium) - COALESCE(SUM(cl.claim_payment),0) AS profit
FROM policies p
LEFT JOIN claims cl ON p.policy_id = cl.policy_id
GROUP BY p.hull_material
ORDER BY profit DESC; 

 
--Number of policies per navigation area
CREATE VIEW navigation_area_number_policies AS
SELECT 
p.navigation_area,
COUNT(*) AS Number_of_Policies
FROM policies p
GROUP BY navigation_area
ORDER BY Number_of_Policies DESC;


--Number of policies per hull material
CREATE VIEW number_hull AS
SELECT p.hull_material,
COUNT(*) AS Number_of_Policies
FROM policies p
GROUP BY p.hull_material
ORDER BY Number_of_Policies DESC; 



--Profit by Operators with and without experience. A 3 Table Join 
CREATE VIEW operator_exp_vs_none AS
SELECT 
c.operator_experience,
SUM(p.annual_premium) - COALESCE(SUM(cl.claim_payment),0) AS profit
FROM customers c
JOIN policies p ON c.customer_id = p.customer_id 
LEFT JOIN claims cl ON p.policy_id = cl.policy_id
GROUP BY c.operator_experience
ORDER BY profit DESC; 

---Number of policies by income band and their profit
CREATE VIEW income_band_number_profit AS
SELECT 
c.income_band,
COUNT(p.policy_id) AS number_of_policies,
SUM(p.annual_premium) - COALESCE(SUM(cl.claim_payment),0) AS profit
FROM customers c
JOIN policies p ON p.customer_id = c.customer_id
LEFT JOIN claims cl ON cl.policy_id = p.policy_id
GROUP BY c.income_band
ORDER BY profit DESC;



--Loss ratio per area
CREATE VIEW loss_ratio_navigation AS
SELECT 
p.navigation_area,
(SUM(cl.claim_payment) / SUM(p.annual_premium))*100 AS loss_ratio_percent --NULLIF can be used to stop errors if premium was 0
FROM policies p
JOIN claims cl ON p.policy_id = cl.policy_id
GROUP BY p.navigation_area
ORDER BY loss_ratio_percent DESC;


--Loss ratio per hull material
CREATE VIEW loss_ratio_hull AS
SELECT 
p.hull_material,
(SUM(cl.claim_payment) / SUM(p.annual_premium))*100 AS loss_ratio_percent
FROM policies p
JOIN claims cl ON p.policy_id = cl.policy_id
GROUP BY p.hull_material
ORDER BY loss_ratio_percent DESC; 


--avg premium by hull material
CREATE VIEW avg_premium_hull AS
SELECT
p.hull_material,
ROUND(AVG(p.annual_premium),0) AS avg_premium
FROM policies p
GROUP BY hull_material
ORDER BY avg_premium DESC;

--how many customers have multiple policies. aggregation and having problem. 44 with multiple, 2 customers have 3
--common sense check. 500 policies, 454 customers plus 44 multiple plus 2 three policy holders is 500. check 
SELECT 
p.customer_id,
COUNT(*) AS num_policies
FROM policies p
GROUP BY p.customer_id
HAVING COUNT(*) > 1
ORDER BY num_policies DESC; 


--How many claims were a total loss? 
SELECT 
cl.claim_id,
cl.policy_id,
cl.claim_payment,
p.coverage_limit
FROM claims cl
JOIN policies p ON p.policy_id = cl.policy_id
WHERE cl.claim_payment = p.coverage_limit; 

--A single number for how many total losses occurred 
CREATE VIEW number_total_losses AS
SELECT 
COUNT(*) AS num_of_total_losses
FROM claims cl
JOIN policies p ON p.policy_id = cl.policy_id
WHERE cl.claim_payment = p.coverage_limit ; 

--A window function
SELECT 
    cl.claim_id,
    cl.policy_id,
    cl.claim_payment,
    p.coverage_limit,
    COUNT(*) OVER (PARTITION BY cl.policy_id) AS claims_per_policy
FROM claims cl
JOIN policies p ON p.policy_id = cl.policy_id
WHERE cl.claim_payment = p.coverage_limit;

--number of claims per area and the total payout per region, total premium per region
CREATE VIEW area_claims_payout_premium AS
SELECT
p.navigation_area,
COUNT(cl.claim_id) AS num_claims,
SUM(cl.claim_payment) AS total_payout,
SUM(p.annual_premium) AS total_premium
FROM policies p
JOIN claims cl ON p.policy_id = cl.policy_id
GROUP BY p.navigation_area
ORDER BY total_payout DESC ;

--High Risk policies, those with higher limits, analyzed with a CTE
CREATE VIEW high_risk_policies AS
WITH top_policies AS (
    SELECT 
        policy_id,
        hull_material,
        coverage_limit
    FROM policies
    ORDER BY coverage_limit DESC
    LIMIT 50
)
SELECT 
    tp.policy_id,
    tp.hull_material,
    cl.cause_of_loss,
    cl.claim_payment,
    tp.coverage_limit
FROM top_policies tp
LEFT JOIN claims cl ON tp.policy_id = cl.policy_id
ORDER BY tp.coverage_limit DESC, cl.claim_payment DESC;


--# of claims grouped by month, and total payments. Month 6,7,8 have high claims. Lets investigate
CREATE VIEW claims_months AS 
SELECT 
    DATE_TRUNC('month', claim_date) AS claim_month,
    COUNT(claim_id) AS number_of_claims,
    SUM(claim_payment) AS total_claim_payment
FROM claims
GROUP BY DATE_TRUNC('month', claim_date)
ORDER BY claim_month;

--Lets investigate what happened in month 6,7 and 8. Seems like a hurricane hit primarily in the 7-8 months significantly
SELECT 
    cl.cause_of_loss,
    COUNT(cl.claim_id) AS number_of_claims,
    SUM(cl.claim_payment) AS total_claim_payout
FROM claims cl
WHERE EXTRACT(MONTH FROM cl.claim_date) IN (6,7,8)
GROUP BY cl.cause_of_loss
ORDER BY total_claim_payout DESC;

--This is the claim payout totals per cause of loss, and the number of claims for each cause of loss
CREATE VIEW cause_of_loss_number_payout AS
SELECT 
    cl.cause_of_loss,
    COUNT(cl.claim_id) AS number_of_claims,
    SUM(cl.claim_payment) AS total_claim_payout
FROM claims cl
GROUP BY cl.cause_of_loss
ORDER BY total_claim_payout DESC;

--This shows the area, cause of loss, month relationship. To get a specific month--WHERE EXTRACT(MONTH FROM cl.claim_date) IN (6, 7, 8)
SELECT 
    p.navigation_area,
    cl.cause_of_loss,
    COUNT(cl.claim_id) AS number_of_claims,
    SUM(cl.claim_payment) AS total_claim_payout,
    TO_CHAR(cl.claim_date, 'YYYY-MM') AS claim_month
FROM claims cl
JOIN policies p ON cl.policy_id = p.policy_id
GROUP BY p.navigation_area, cl.cause_of_loss, TO_CHAR(cl.claim_date, 'YYYY-MM')
ORDER BY claim_month, total_claim_payout DESC;

-- it breaks down with multiple rows per claim month
--To look into a specific month range. WHERE EXTRACT(MONTH FROM cl.claim_date) IN (6, 7, 8)
CREATE VIEW month_loss_number_payout AS
SELECT 
    EXTRACT(MONTH FROM cl.claim_date) AS claim_month,
    cl.cause_of_loss,
    COUNT(cl.claim_id) AS number_of_claims,
    SUM(cl.claim_payment) AS total_claim_payout
FROM claims cl
GROUP BY claim_month, cl.cause_of_loss
ORDER BY claim_month, total_claim_payout DESC;


--it gives an old boat vs new comparison via their loss ratio
CREATE VIEW new_old_comparison AS
SELECT 
    CASE 
        WHEN p.year_boat_built < 2000 THEN 'Old Boat'
        ELSE 'Newer Boat'
    END AS boat_age_group,
    SUM(cl.claim_payment) AS total_claims,
    SUM(p.annual_premium) AS total_premiums,
    (SUM(cl.claim_payment) / NULLIF(SUM(p.annual_premium), 0)) * 100 AS loss_ratio_percent
FROM policies p
JOIN claims cl ON p.policy_id = cl.policy_id
GROUP BY 
    CASE 
        WHEN p.year_boat_built < 2000 THEN 'Old Boat'
        ELSE 'Newer Boat'
    END
ORDER BY loss_ratio_percent DESC;




--the avg years insured for all customers
SELECT 
ROUND(AVG(c.years_insured),2) AS average_years_insured
FROM customers c

--the avg years insured for customers with claims . In this data the difference is insignificant 
SELECT 
ROUND(AVG(c.years_insured),2) AS avg_years_insured_with_claim
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM policies p
    JOIN claims cl ON cl.policy_id = p.policy_id
    WHERE p.customer_id = c.customer_id
      AND cl.claim_id IS NOT NULL
);

--This gives years insured and the claim id. without the where clause all 500 policy rows would appear. 
--This could be used for a graph distribution of claims and years insured
CREATE VIEW customers_with_claims_years_insured AS
SELECT 
    c.customer_id,
    c.years_insured,
    cl.claim_id
FROM customers c
LEFT JOIN policies p ON c.customer_id = p.customer_id
LEFT JOIN claims cl ON p.policy_id = cl.policy_id
WHERE cl.claim_id IS NOT NULL
ORDER BY c.years_insured DESC;

--average age of customers overall
SELECT 
ROUND(AVG(c.age),2) AS average_age
FROM customers c

--average age of customers with claims
SELECT 
ROUND(AVG(c.age),2) AS average_age
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM policies p
    JOIN claims cl ON cl.policy_id = p.policy_id
    WHERE p.customer_id = c.customer_id
      AND cl.claim_id IS NOT NULL
);

--login stuff for power bi
SELECT current_database()
SELECT usename FROM pg_user

