
#File type:  CSV UTF-8 (Comma delimited)

CREATE  DATABASE BANK_ANAYLSIS;

USE BANK_ANAYLSIS;

SELECT *FROM FINANCE1;
SELECT *FROM FINANCE2;  

ALTER TABLE FINANCE1 CHANGE COLUMN ï»¿id ID INT;
ALTER TABLE FINANCE2 CHANGE COLUMN ï»¿id ID INT;

SET SQL_SAFE_UPDATES = 0; 

UPDATE finance1
SET issue_d = STR_TO_DATE(issue_d, '%d-%m-%Y');

ALTER TABLE finance1
MODIFY COLUMN issue_d DATE;
       
DESC finance1;
DESC finance2;

-- KP1 1 : Year Wise Loan Amount Stats 

SELECT
    YEAR(issue_d) AS year,
    CONCAT(ROUND(SUM(loan_amnt) / 1000000, 0), 'M') AS total_loan
FROM finance1
GROUP BY year
ORDER BY year;

-- KPI 2 : Grade and Sub Grade Wise Revolving Balance

SELECT f1.grade,f1.sub_grade,
         ROUND(SUM(f2.revol_bal)/1000000,2) AS revolving_balance_million
FROM finance1 f1
JOIN finance2 f2
ON f1.id = f2.id
GROUP BY f1.grade,f1.sub_grade
ORDER BY f1.grade,f1.sub_grade;

-- KPI 3 : Verified Status vs Non Verified Total Payment

SELECT f1.verification_status,
          CONCAT(ROUND(SUM(f2.total_pymnt)/1000000,0),"M") as total_payment 
FROM finance1 f1
JOIN finance2 f2 
on f1.id=f2.id 
WHERE f1.verification_status in 
('verified', 'not verified') GROUP BY 1;


-- KPI 4 : State Wise and Month Wise Loan Status

select addr_state as state,
monthname(issue_d) month ,loan_status,
concat(round(sum(loan_amnt)/1000000,0),"M")
total_loan from finance1
group by state,month, loan_status;

-- KPI 5 : Home Ownership vs Last Payment Date Stats

SELECT f1.home_ownership,
      COUNT(f2.last_pymnt_d) as payment_count,
      CONCAT(ROUND(SUM(f2.last_pymnt_amnt)/1000,0),'K') as total_last_payment
FROM finance1 f1
JOIN finance2 f2
ON f1.id=f2.id
GROUP BY f1.home_ownership
ORDER BY total_last_payment DESC;