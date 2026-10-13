-- =====================================================================
--  INSURANCE POLICY ANALYSIS - SQL PROJECT
--  Database : insurance_policy (MySQL)
--  Tables   : customer_information, policy_details, claims,
--             payment_history, additional_fields
--  Contents : 21 KPI queries, 3 join queries, window function,
--             view, stored procedure and trigger
-- =====================================================================

USE insurance_policy;

-- ---------------------------------------------------------------------
-- TABLE STRUCTURE
-- ---------------------------------------------------------------------
DESCRIBE additional_fields;
DESCRIBE claims;
DESCRIBE customer_information;
DESCRIBE payment_history;
DESCRIBE policy_details;


-- =====================================================================
--  PART 1: KPI QUERIES
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q1) What is the total number of customers in the policy database?
-- ---------------------------------------------------------------------
SELECT COUNT(DISTINCT customer_id) AS Total_Customers
FROM customer_information;

-- ---------------------------------------------------------------------
-- Q2) What is the total number of policies issued?
-- ---------------------------------------------------------------------
SELECT COUNT(DISTINCT policy_id) AS Total_Policy
FROM policy_details;

-- ---------------------------------------------------------------------
-- Q3) What is the total claim amount generated from all policies?
-- ---------------------------------------------------------------------
SELECT CONCAT(ROUND(SUM(Claim_Amount) / 1000000, 2), ' M') AS Total_Claim_Amount
FROM claims;

-- ---------------------------------------------------------------------
-- Q4) What is the average coverage amount per policy?
-- ---------------------------------------------------------------------
SELECT CONCAT(ROUND(AVG(Coverage_Amount) / 1000, 2), 'K') AS Avg_Coverage_Amount
FROM policy_details;

-- ---------------------------------------------------------------------
-- Q5) What is the average premium amount collected per policy?
-- ---------------------------------------------------------------------
SELECT CONCAT(ROUND(AVG(Premium_Amount) / 1000, 2), 'K') AS Avg_Premium_Amount
FROM policy_details;

-- ---------------------------------------------------------------------
-- Q6) What percentage of policies are currently active?
-- ---------------------------------------------------------------------
SELECT CONCAT(
         ROUND((SUM(CASE WHEN Status = 'Active' THEN 1 ELSE 0 END) * 100.0)
               / COUNT(*), 2), '%') AS Active_Policy_Percentage
FROM policy_details;

-- ---------------------------------------------------------------------
-- Q7) How many policies are in Active, Lapsed and Terminated status?
-- ---------------------------------------------------------------------
SELECT Status,
       COUNT(Policy_ID) AS Policy_Count
FROM policy_details
GROUP BY Status
ORDER BY Policy_Count DESC;

-- ---------------------------------------------------------------------
-- Q8) Which policy status has the highest number of policies?
-- ---------------------------------------------------------------------
SELECT Status,
       COUNT(Policy_ID) AS Policy_Count
FROM policy_details
GROUP BY Status
ORDER BY Policy_Count DESC
LIMIT 1;

-- ---------------------------------------------------------------------
-- Q9) What is the ratio between active and inactive policies?
-- ---------------------------------------------------------------------
SELECT CONCAT(ROUND(SUM(CASE WHEN Status = 'Active'
                             THEN 1 ELSE 0 END) * 100 / COUNT(*), 2), ' %') AS Active,
       CONCAT(ROUND(SUM(CASE WHEN Status IN ('Lapsed', 'Terminated')
                             THEN 1 ELSE 0 END) * 100 / COUNT(*), 2), ' %') AS Inactive
FROM policy_details;

-- ---------------------------------------------------------------------
-- Q10) Which age group has the highest number of policies?
-- ---------------------------------------------------------------------
SELECT CASE
         WHEN Age BETWEEN 18 AND 27 THEN '18-27'
         WHEN Age BETWEEN 28 AND 37 THEN '28-37'
         WHEN Age BETWEEN 38 AND 47 THEN '38-47'
         WHEN Age BETWEEN 48 AND 57 THEN '48-57'
         WHEN Age BETWEEN 58 AND 67 THEN '58-67'
         WHEN Age BETWEEN 68 AND 77 THEN '68-77'
         ELSE '78+'
       END AS Age_Group,
       COUNT(*) AS Policy_Count
FROM customer_information
GROUP BY Age_Group
ORDER BY Policy_Count DESC
LIMIT 1;

-- ---------------------------------------------------------------------
-- Q11) Identify the top three age groups by policy count.
-- ---------------------------------------------------------------------
SELECT CASE
         WHEN Age BETWEEN 18 AND 27 THEN '18-27'
         WHEN Age BETWEEN 28 AND 37 THEN '28-37'
         WHEN Age BETWEEN 38 AND 47 THEN '38-47'
         WHEN Age BETWEEN 48 AND 57 THEN '48-57'
         WHEN Age BETWEEN 58 AND 67 THEN '58-67'
         WHEN Age BETWEEN 68 AND 77 THEN '68-77'
         ELSE '78+'
       END AS Age_Group,
       COUNT(*) AS Policy_Count
FROM customer_information
GROUP BY Age_Group
ORDER BY Policy_Count DESC
LIMIT 3;

-- ---------------------------------------------------------------------
-- Q12) Which gender has the highest policy participation?
-- ---------------------------------------------------------------------
SELECT Gender,
       COUNT(*) AS Policy_Count
FROM customer_information c
JOIN policy_details p ON c.Customer_ID = p.Customer_ID
GROUP BY Gender
ORDER BY Policy_Count DESC
LIMIT 1;

-- ---------------------------------------------------------------------
-- Q13) What is the difference between male and female policy counts?
-- ---------------------------------------------------------------------
SELECT ABS(SUM(CASE WHEN Gender = 'Male'   THEN 1 ELSE 0 END)
         - SUM(CASE WHEN Gender = 'Female' THEN 1 ELSE 0 END)) AS Difference_Count
FROM customer_information c
JOIN policy_details p ON c.Customer_ID = p.Customer_ID;

-- ---------------------------------------------------------------------
-- Q14) Which policy type has the maximum number of policies?
-- ---------------------------------------------------------------------
SELECT Policy_Type,
       COUNT(*) AS Total_Policies
FROM policy_details
GROUP BY Policy_Type
ORDER BY Total_Policies DESC
LIMIT 1;

-- ---------------------------------------------------------------------
-- Q15) Which policy type has the minimum number of policies?
-- ---------------------------------------------------------------------
SELECT Policy_Type,
       COUNT(*) AS Total_Policies
FROM policy_details
GROUP BY Policy_Type
ORDER BY Total_Policies ASC
LIMIT 1;

-- ---------------------------------------------------------------------
-- Q16) Compare Auto and Health policy counts.
-- ---------------------------------------------------------------------
SELECT Policy_Type,
       COUNT(*) AS Total_Policies
FROM policy_details
WHERE Policy_Type IN ('Auto', 'Health')
GROUP BY Policy_Type;

-- ---------------------------------------------------------------------
-- Q17) What is the total number of policies across all policy types?
-- ---------------------------------------------------------------------
SELECT Policy_Type,
       COUNT(*) AS Total_Policies
FROM policy_details
GROUP BY Policy_Type;

-- ---------------------------------------------------------------------
-- Q18) What is the average premium growth rate over all years?
-- ---------------------------------------------------------------------
-- Step 1: Average premium for each policy start year
SELECT YEAR(Policy_Start_Date) AS Policy_Year,
       AVG(Premium_Amount)     AS Avg_Premium
FROM policy_details
GROUP BY YEAR(Policy_Start_Date)
ORDER BY Policy_Year;

-- Step 2: Year-on-year growth rate, then its average
WITH PremiumGrowth AS (
    SELECT YEAR(Policy_Start_Date) AS Policy_Year,
           AVG(Premium_Amount)     AS Avg_Premium,
           LAG(AVG(Premium_Amount))
               OVER (ORDER BY YEAR(Policy_Start_Date)) AS Previous_Premium
    FROM policy_details
    GROUP BY YEAR(Policy_Start_Date)
)
SELECT ROUND(AVG(((Avg_Premium - Previous_Premium)
                  / Previous_Premium) * 100), 2) AS Avg_Growth_Rate
FROM PremiumGrowth
WHERE Previous_Premium IS NOT NULL;

-- ---------------------------------------------------------------------
-- Q19) Is the premium growth trend increasing or decreasing over time?
--      (positive growth rate = increase, negative = decrease)
-- ---------------------------------------------------------------------
WITH PremiumGrowth AS (
    SELECT YEAR(Policy_Start_Date) AS Policy_Year,
           AVG(Premium_Amount)     AS Avg_Premium,
           LAG(AVG(Premium_Amount))
               OVER (ORDER BY YEAR(Policy_Start_Date)) AS Previous_Premium
    FROM policy_details
    GROUP BY YEAR(Policy_Start_Date)
)
SELECT Policy_Year,
       ROUND(Avg_Premium, 2) AS Avg_Premium,
       ROUND(((Avg_Premium - Previous_Premium)
              / Previous_Premium) * 100, 2) AS Growth_Rate
FROM PremiumGrowth
WHERE Previous_Premium IS NOT NULL;

-- ---------------------------------------------------------------------
-- Q20) Difference between the highest and lowest premium growth rates.
-- ---------------------------------------------------------------------
WITH PremiumGrowth AS (
    SELECT YEAR(Policy_Start_Date) AS Policy_Year,
           (AVG(Premium_Amount)
            - LAG(AVG(Premium_Amount)) OVER (ORDER BY YEAR(Policy_Start_Date)))
           / LAG(AVG(Premium_Amount)) OVER (ORDER BY YEAR(Policy_Start_Date))
           * 100 AS Growth_Rate
    FROM policy_details
    GROUP BY YEAR(Policy_Start_Date)
)
SELECT ROUND(MAX(Growth_Rate) - MIN(Growth_Rate), 2) AS Growth_Rate_Difference
FROM PremiumGrowth;

-- ---------------------------------------------------------------------
-- Q21) Yearly trend of policies ending (2016 to 2034).
-- ---------------------------------------------------------------------
SELECT YEAR(Policy_End_Date) AS Policy_End_Year,
       COUNT(*)              AS Policies_Ended
FROM policy_details
WHERE YEAR(Policy_End_Date) BETWEEN 2016 AND 2034
GROUP BY YEAR(Policy_End_Date)
ORDER BY Policy_End_Year;


-- =====================================================================
--  PART 2: ADDITIONAL SQL WORK
-- =====================================================================

-- ---------------------------------------------------------------------
-- Join Query 1: Top 10 customers by premium paid
-- ---------------------------------------------------------------------
SELECT c.Customer_ID,
       c.Name,
       ROUND(SUM(p.Premium_Amount), 2) AS Total_Premium
FROM customer_information c
JOIN policy_details p ON c.Customer_ID = p.Customer_ID
GROUP BY c.Customer_ID, c.Name
ORDER BY Total_Premium DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- Join Query 2: Policy type vs total claim amount
-- ---------------------------------------------------------------------
SELECT p.Policy_Type,
       ROUND(SUM(c.Claim_Amount), 2) AS Total_Claim
FROM policy_details p
JOIN claims c ON p.Policy_ID = c.Policy_ID
GROUP BY p.Policy_Type
ORDER BY Total_Claim DESC;

-- ---------------------------------------------------------------------
-- Join Query 3: Gender-wise claim amount
-- ---------------------------------------------------------------------
SELECT ci.Gender,
       ROUND(SUM(c.Claim_Amount), 2) AS Total_Claim
FROM customer_information ci
JOIN policy_details p ON ci.Customer_ID = p.Customer_ID
JOIN claims c         ON p.Policy_ID    = c.Policy_ID
GROUP BY ci.Gender;

-- ---------------------------------------------------------------------
-- Window Function: Rank customers by total premium
-- ---------------------------------------------------------------------
SELECT Customer_ID,
       ROUND(SUM(Premium_Amount), 2) AS Total_Premium,
       RANK() OVER (ORDER BY SUM(Premium_Amount) DESC) AS Customer_Rank
FROM policy_details
GROUP BY Customer_ID;

-- ---------------------------------------------------------------------
-- View: Policy summary
-- Gives a summary of policy types, total policies and average premium
-- without rewriting the aggregation query each time.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vw_policy_summary;

CREATE VIEW vw_policy_summary AS
SELECT Policy_Type,
       COUNT(*) AS Policy_Count,
       ROUND(AVG(Premium_Amount), 2) AS Avg_Premium
FROM policy_details
GROUP BY Policy_Type;

SELECT * FROM vw_policy_summary;

-- ---------------------------------------------------------------------
-- Stored Procedure: Get policies by type
-- Saves reusable SQL logic in the database and accepts a parameter
-- so different results can be returned based on user input.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS GetPolicyByType;

DELIMITER $$

CREATE PROCEDURE GetPolicyByType (IN p_type VARCHAR(50))
BEGIN
    SELECT *
    FROM policy_details
    WHERE Policy_Type = p_type;
END$$

DELIMITER ;

CALL GetPolicyByType('Health');
CALL GetPolicyByType('Auto');

-- ---------------------------------------------------------------------
-- Trigger: Claim validation
-- Runs automatically before every insert on claims and blocks
-- negative claim amounts.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_claim_validation;

DELIMITER $$

CREATE TRIGGER trg_claim_validation
BEFORE INSERT ON claims
FOR EACH ROW
BEGIN
    IF NEW.Claim_Amount < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Claim Amount Cannot Be Negative';
    END IF;
END$$

DELIMITER ;

-- =====================================================================
--  END OF SCRIPT
-- =====================================================================
