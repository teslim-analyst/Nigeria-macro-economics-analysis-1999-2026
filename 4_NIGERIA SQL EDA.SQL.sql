#-- NIGERIA MACROECONOMIC DATA (1999-2026)-- COMPLETE SQL EXPLORATORY DATA ANALYSIS-- 
#-- HOW TO USE THIS FILE:-- Load your CSV into a SQL database first, 


#====-- SECTION 1: FIRST LOOK AT THE DATA--  
SELECT *
FROM nigeria_economy
;
-- 1b. How many years of data do we,

SELECT
    COUNT(*)           AS total_rows,
    MIN(YEAR)          AS earliest_year,
    MAX(YEAR)          AS latest_year,
    MAX(YEAR) - MIN(YEAR) + 1 AS 
years_covered
FROM nigeria_economy;
-- 1c. Which columns have missing data and 
SELECT
    SUM(CASE WHEN GDP           IS NULL 
THEN 1 ELSE 0 END) AS missing_gdp,
    SUM(CASE WHEN REVENUE       IS NULL 
THEN 1 ELSE 0 END) AS missing_revenue,
    SUM(CASE WHEN INFLATION_RATE IS NULL 
THEN 1 ELSE 0 END) AS missing_inflation,
    SUM(CASE WHEN ANNUAL_DEBT   IS NULL 
THEN 1 ELSE 0 END) AS missing_debt,
    SUM(CASE WHEN OIL_PRICE     IS NULL 
THEN 1 ELSE 0 END) AS missing_oil_price,
    SUM(CASE WHEN EXCHANGE_RATE IS NULL 
THEN 1 ELSE 0 END) AS 
missing_exchange_rate,
    SUM(CASE WHEN ANNUAL_RESERVES IS NULL 
THEN 1 ELSE 0 END) AS missing_reserves,
    SUM(CASE WHEN INTEREST_RATE IS NULL 
THEN 1 ELSE 0 END) AS 
missing_interest_rate,
    SUM(CASE WHEN EXPENDITURE   IS NULL 
THEN 1 ELSE 0 END) AS missing_expenditure,
    SUM(CASE WHEN UNEMPLOYMENT  IS NULL 
THEN 1 ELSE 0 END) AS missing_unemployment,
    SUM(CASE WHEN DEBT_PAID     IS NULL 
THEN 1 ELSE 0 END) AS missing_debt_paid
FROM nigeria_economy;-- 
#null values Revenue,annual_debt,oil_price,unemployment,debt_paid, ARE NULL BECUASE NIGERIA HAS NOT PUBLISHED DATA FOR THOSE YEARS
# SECTION 2: UNIT MISMATCH CHECK-- 
alter table nigeria_economy
modify COLUMN OIL_PRICE DECIMAL(10,2),
modify COLUMN DEBT_PAID DECIMAL(10,2);
-- SECTION 3: BASIC STATISTICS-- 

-- 3a. GDP stats across all years
SELECT 
    ROUND(MIN(GDP), 2)   AS gdp_min,
    ROUND(MAX(GDP), 2)   AS gdp_max,
    ROUND(AVG(GDP), 2)   AS gdp_avg,
    ROUND(MAX(GDP) - MIN(GDP), 2) AS 
gdp_range
FROM nigeria_economy;
-- 3b. Full descriptive stats for all key economic indicators
SELECT 
    'GDP'           AS metric, 
ROUND(MIN(GDP),2) AS min_val, 
ROUND(MAX(GDP),2) AS max_val, 
ROUND(AVG(GDP),2) AS avg_val FROM 
nigeria_economy 
UNION ALL
SELECT 'INFLATION',   
ROUND(MIN(INFLATION_RATE),2), 
ROUND(MAX(INFLATION_RATE),2), 
ROUND(AVG(INFLATION_RATE),2) FROM 
nigeria_economy
UNION ALL
SELECT 'EXCHANGE RATE', 
ROUND(MIN(EXCHANGE_RATE),2), 
ROUND(MAX(EXCHANGE_RATE),2), 
ROUND(AVG(EXCHANGE_RATE),2) FROM 
nigeria_economy
UNION ALL
SELECT 'INTEREST RATE', 
ROUND(MIN(INTEREST_RATE),2), 
ROUND(MAX(INTEREST_RATE),2), 
ROUND(AVG(INTEREST_RATE),2) FROM 
nigeria_economy
UNION ALL
SELECT 'UNEMPLOYMENT', 
ROUND(MIN(UNEMPLOYMENT),2), 
ROUND(MAX(UNEMPLOYMENT),2), 
ROUND(AVG(UNEMPLOYMENT),2) FROM 
nigeria_economy WHERE UNEMPLOYMENT IS NOT 
NULL
UNION ALL
SELECT 'OIL PRICE',   
ROUND(MIN(OIL_PRICE),2), 
ROUND(MAX(OIL_PRICE),2), 
ROUND(AVG(OIL_PRICE),2) FROM 
nigeria_economy WHERE OIL_PRICE IS NOT NULL
UNION ALL
SELECT 'EXPENDITURE', 
ROUND(MIN(EXPENDITURE),2), 
ROUND(MAX(EXPENDITURE),2), 
ROUND(AVG(EXPENDITURE),2) FROM 
nigeria_economy
UNION ALL
SELECT 'ANNUAL DEBT', 
ROUND(MIN(ANNUAL_DEBT),2), 
ROUND(MAX(ANNUAL_DEBT),2), 
ROUND(AVG(ANNUAL_DEBT),2) FROM 
nigeria_economy WHERE ANNUAL_DEBT IS NOT 
NULL
; 

-- SECTION 4: GDP ANALYSIS-- Key question: How has Nigeria's economy actually grown?-- 
-- 4a. GDP year by year with year-on-year growth rate-- LAG() looks at the previous row — like saying "what was GDP last year?"
SELECT
    YEAR,
    GDP,
    LAG(GDP) OVER (ORDER BY YEAR) AS 
prev_year_gdp,
    ROUND(
        ((GDP - LAG(GDP) OVER (ORDER BY 
YEAR)) / LAG(GDP) OVER (ORDER BY YEAR)) * 
100
    , 2) AS gdp_growth_pct
FROM nigeria_economy
ORDER BY YEAR;
-- 4b. Which 5 years had the biggest GDP jumps?-- The 2010 jump from ₦24.79T to ₦54.61T 
#is suspicious — that was-- the GDP rebasing exercise, not real growth. Worth flagging.
SELECT
    YEAR,
    GDP,
    LAG(GDP) OVER (ORDER BY YEAR) AS 
prev_year_gdp,
    ROUND(GDP - LAG(GDP) OVER (ORDER BY 
YEAR), 2) AS absolute_gdp_increase
FROM nigeria_economy
ORDER BY absolute_gdp_increase DESC
LIMIT 5;-- 4c. GDP per administration era-- How much did GDP grow under each president?
SELECT
    PRESIDENT,
    MIN(YEAR)                  AS 
years_from,
    MAX(YEAR)                  AS years_to,
    ROUND(MIN(GDP), 2)         AS 
gdp_at_start,
    ROUND(MAX(GDP), 2)         AS 
gdp_at_end,
    ROUND(MAX(GDP) - MIN(GDP), 2) AS 
total_gdp_growth,
    ROUND(AVG(GDP), 2)         AS 
avg_gdp_during_tenure
FROM nigeria_economy
GROUP BY PRESIDENT
ORDER BY MIN(YEAR);-- 

-- SECTION 5: INFLATION ANALYSIS-- Key question: When did prices spiral and what caused it?-- 
-- 5a. Inflation every year with a label showing how bad it was
SELECT
    YEAR,
    PRESIDENT,
    INFLATION_RATE,
    CASE
        WHEN INFLATION_RATE >= 25  THEN 
'CRISIS LEVEL (25%+)'
        WHEN INFLATION_RATE >= 15  THEN 
'HIGH (15-25%)'
        WHEN INFLATION_RATE >= 10  THEN 
'ELEVATED (10-15%)'
        WHEN INFLATION_RATE >= 5   THEN 
'MODERATE (5-10%)'
        ELSE                            
'LOW (Under 5%)'
    END AS inflation_severity
FROM nigeria_economy
ORDER BY YEAR;
-- 5b. Worst inflation years ever
SELECT
    YEAR,
    PRESIDENT,
    INFLATION_RATE
FROM nigeria_economy
ORDER BY INFLATION_RATE DESC
LIMIT 5;-- 5c. Average inflation per president-- FINDING: This will show Tinubu era has 
#highest avg inflation-- because 2023 (24.66%) and 2024 (33.24%) are both on his watch
SELECT
    PRESIDENT,
    COUNT(YEAR)                    AS 
years_in_office,
    ROUND(AVG(INFLATION_RATE), 2)  AS 
avg_inflation,
    ROUND(MIN(INFLATION_RATE), 2)  AS 
best_inflation_year,
    ROUND(MAX(INFLATION_RATE), 2)  AS 
worst_inflation_year
FROM nigeria_economy
GROUP BY PRESIDENT
ORDER BY avg_inflation DESC;-- 5d. How many years was inflation in double digits (above 10%)?-- Nigeria's CBN target is 6-9%. Double 
#digit means target missed.
SELECT
    COUNT(*) AS years_above_10pct,
    ROUND(COUNT(*) * 100.0 / (SELECT 
COUNT(*) FROM nigeria_economy), 1) AS 
pct_of_all_years
FROM nigeria_economy
WHERE INFLATION_RATE > 10;-- 

-- SECTION 6: EXCHANGE RATE ANALYSIS-- Key question: When did the Naira collapse and under who?-- 
-- 6a. Exchange rate trend with year-on year naira depreciation
SELECT
    YEAR,
    PRESIDENT,
    EXCHANGE_RATE,
    LAG(EXCHANGE_RATE) OVER (ORDER BY YEAR) 
AS prev_year_rate,
    ROUND(EXCHANGE_RATE - 
LAG(EXCHANGE_RATE) OVER (ORDER BY YEAR), 2) 
AS naira_depreciation,
    ROUND(
        ((EXCHANGE_RATE - 
LAG(EXCHANGE_RATE) OVER (ORDER BY YEAR))
        / LAG(EXCHANGE_RATE) OVER (ORDER BY 
YEAR)) * 100
    , 2) AS depreciation_pct
FROM nigeria_economy
ORDER BY YEAR;
-- 6b. Worst single-year Naira crashes-- FINDING: 2016 (305 from 197) and 2023 (650 from 430) will top this list
SELECT
    YEAR,
    PRESIDENT,
    LAG(EXCHANGE_RATE) OVER (ORDER BY YEAR) 
AS rate_previous_year,
    EXCHANGE_RATE AS rate_this_year,
    ROUND(EXCHANGE_RATE - 
LAG(EXCHANGE_RATE) OVER (ORDER BY YEAR), 2) 
AS naira_fell_by
FROM nigeria_economy
ORDER BY naira_fell_by DESC
LIMIT 5;
-- 6c. Total Naira depreciation per section.-- Shows how much the Naira lost under each administration.
SELECT
    PRESIDENT,
    MIN(EXCHANGE_RATE) AS 
rate_when_took_office,
    MAX(EXCHANGE_RATE) AS 
rate_when_left_office,
    ROUND(MAX(EXCHANGE_RATE) - 
MIN(EXCHANGE_RATE), 2) AS total_naira_loss,
    ROUND(
        ((MAX(EXCHANGE_RATE)
ORDER BY MIN(YEAR)
MIN(EXCHANGE_RATE)) / MIN(EXCHANGE_RATE)) * 
100
    , 1) AS total_depreciation_pct
FROM nigeria_economy
GROUP BY PRESIDENT-- 
-- SECTION 7: DEBT ANALYSIS-- Key question: Is Nigeria drowning in debt?-- 

-- 7a. Debt growth over time with debt-toGDP ratio-- Debt-to-GDP ratio is the key metric economists use.
-- Above 50% starts getting concerning for developing countries.
SELECT
    YEAR,
    PRESIDENT,
    ANNUAL_DEBT,
    GDP,
    ROUND((ANNUAL_DEBT / GDP) * 100, 1) AS 
debt_to_gdp_ratio_pct,
    CASE
        WHEN (ANNUAL_DEBT / GDP) * 100 > 
70  THEN 'DANGER ZONE (70%+)'
        WHEN (ANNUAL_DEBT / GDP) * 100 > 
50  THEN 'HIGH RISK (50-70%)'
        WHEN (ANNUAL_DEBT / GDP) * 100 > 
30  THEN 'MODERATE (30-50%)'
ELSE                                       
'MANAGEABLE (Under 30%)'
    END AS debt_risk_level
FROM nigeria_economy
WHERE ANNUAL_DEBT IS NOT NULL
ORDER BY YEAR;
-- 7b. How much debt was added per president?-- FINDING: Buhari added roughly ₦34T in debt (11T to 46T).
-- Tinubu's era shows ₦97T by 2023 — that ##is almost double what-- existed at the end of Buhari's tenure. 
#That is the story.
SELECT
    PRESIDENT,
    MIN(YEAR)                               
AS from_year,
    MAX(YEAR)                               
AS to_year,
    ROUND(MIN(ANNUAL_DEBT), 2)              
AS debt_at_start,
    ROUND(MAX(ANNUAL_DEBT), 2)              
AS debt_at_end,
    ROUND(MAX(ANNUAL_DEBT) - 
MIN(ANNUAL_DEBT), 2) AS 
debt_added_during_tenure
FROM nigeria_economy
WHERE ANNUAL_DEBT IS NOT NULL
GROUP BY PRESIDENT
ORDER BY MIN(YEAR);
-- 7c. Debt service burden — what % of revenue goes just to paying debt?-- PROBLEM: When debt service eats too much 
#of revenue, there is no-- money left for roads, hospitals, schools.-- FINDING: This will likely show 2023/2024 as catastrophic 
-- Nigeria was spending more servicing debt than on anything else.
SELECT
    YEAR,
    PRESIDENT,
    DEBT_PAID,
    REVENUE,
    ROUND((DEBT_PAID / REVENUE) * 100, 1) 
AS debt_service_to_revenue_pct,
    CASE
        WHEN (DEBT_PAID / REVENUE) * 100 > 
80 THEN 'DEBT TRAP - Over 80% of revenue on 
debt'
        WHEN (DEBT_PAID / REVENUE) * 100 > 
50 THEN 'SEVERE - Over half of revenue on 
debt'
        WHEN (DEBT_PAID / REVENUE) * 100 > 
30 THEN 'HIGH - Debt eating into budget'
        ELSE 'MANAGEABLE'
    END AS debt_burden_level
FROM nigeria_economy
WHERE DEBT_PAID IS NOT NULL
  AND REVENUE IS NOT NULL
  AND REVENUE > 0
ORDER BY YEAR;-- 

-- SECTION 8: OIL PRICE VS ECONOMY-- Key question: Is Nigeria's economy just oil in disguise?-- 
-- 8a. Oil price vs exchange rate side by side-- THEORY: When oil price falls, Naira falls.Test this.
 -- FINDING: 2014-2016 oil crash ($108 to $40) perfectly matches-- the Naira crashing from 170 to 305. The correlation is real.
SELECT
    YEAR,
    PRESIDENT,
    OIL_PRICE,
    EXCHANGE_RATE,
    ANNUAL_RESERVES,
    -- When oil revenue drops, CBN burns reserves defending Naira
    -- Watch reserves fall when oil falls
    CASE
        WHEN OIL_PRICE < 50 THEN 'LOW OIL 
PERIOD'
        WHEN OIL_PRICE < 80 THEN 'MODERATE 
OIL'
        ELSE 'HIGH OIL PERIOD'
    END AS oil_price_era
FROM nigeria_economy
WHERE OIL_PRICE IS NOT NULL
ORDER BY YEAR;
-- 8b. Average reserves during high vs low oil price periods-- This directly tests whether Nigeria saves when oil is high
-- FINDING: Reserves are higher when oil is above $80. This confirms-- Nigeria has not built enough non-oil buffers.
SELECT
    CASE
        WHEN OIL_PRICE < 50 THEN 'Low Oil 
(Under $50)'
        WHEN OIL_PRICE < 80 THEN 'Moderate 
Oil ($50-$80)'
        ELSE 'High Oil (Above $80)'
    END AS oil_price_category,
    COUNT(*)                        AS 
number_of_years,
    ROUND(AVG(ANNUAL_RESERVES), 2)  AS 
avg_reserves_usd_billion,
    ROUND(AVG(EXCHANGE_RATE), 2)    AS 
avg_exchange_rate,
    ROUND(AVG(INFLATION_RATE), 2)   AS 
avg_inflation
FROM nigeria_economy
WHERE OIL_PRICE IS NOT NULL
GROUP BY
    CASE
        WHEN OIL_PRICE < 50 THEN 'Low Oil 
(Under $50)'
        WHEN OIL_PRICE < 80 THEN 'Moderate 
Oil ($50-$80)'
        ELSE 'High Oil (Above $80)'
    END
ORDER BY avg_reserves_usd_billion DESC;
-- 8c. Years where oil crashed and what than $20 from previous year
SELECT
    YEAR,
    OIL_PRICE,
    LAG(OIL_PRICE) OVER (ORDER BY YEAR)  AS 
prev_year_oil,
    ROUND(OIL_PRICE - LAG(OIL_PRICE) OVER 
(ORDER BY YEAR), 2) AS oil_price_change,
    EXCHANGE_RATE,
    INFLATION_RATE,
    GDP
FROM nigeria_economy
WHERE OIL_PRICE IS NOT NULL
ORDER BY oil_price_change ASC
LIMIT 5;-- 
-- SECTION 9: REVENUE VS EXPENDITURE-- Key question: Is Nigeria living beyond its means?-- 
-- 9a. Revenue vs Expenditure every year — is there a deficit?-- A deficit means Nigeria is spending more than it earns
-- FINDING: Every single year from 2016 onward is a deficit year
SELECT
    YEAR,
    PRESIDENT,
    REVENUE,
    EXPENDITURE,
    ROUND(REVENUE - EXPENDITURE, 2) AS 
budget_balance,
    CASE
        WHEN REVENUE > EXPENDITURE THEN 
'SURPLUS'
        WHEN REVENUE < EXPENDITURE THEN 
'DEFICIT'
        ELSE 'BALANCED'
    END AS budget_position
FROM nigeria_economy
WHERE REVENUE IS NOT NULL
ORDER BY YEAR;
-- 9b. How many surplus vs deficit years total?
SELECT
    CASE
        WHEN REVENUE > EXPENDITURE THEN 
'SURPLUS YEAR'
        ELSE 'DEFICIT YEAR'
    END AS budget_result,
    COUNT(*) AS number_of_years
FROM nigeria_economy
WHERE REVENUE IS NOT NULL
GROUP BY
    CASE
        WHEN REVENUE > EXPENDITURE THEN 
'SURPLUS YEAR'
        ELSE 'DEFICIT YEAR'
    END;
    -- 9c. Revenue as a % of GDP — how well is Nigeria collecting taxes?-- Nigeria's tax-to-GDP ratio is famously one of the lowest in Africa
-- FINDING: It hovers around 5-10%, far below the African average of 15%
SELECT
    YEAR,
    PRESIDENT,
    REVENUE,
    GDP,
    ROUND((REVENUE / GDP) * 100, 2) AS 
revenue_to_gdp_pct
FROM nigeria_economy
WHERE REVENUE IS NOT NULL
ORDER BY YEAR;-- 9d. Expenditure growth vs GDP growth — is spending growing faster than the economy?
SELECT
    YEAR,
    GDP,
    EXPENDITURE,
    ROUND((EXPENDITURE / GDP) * 100, 2) AS 
expenditure_to_gdp_pct,
    ROUND(
        ((GDP - LAG(GDP) OVER (ORDER BY 
YEAR)) / LAG(GDP) OVER (ORDER BY YEAR)) * 
100
    , 2) AS gdp_growth_pct,
    ROUND(
        ((EXPENDITURE - LAG(EXPENDITURE) 
OVER (ORDER BY YEAR)) / LAG(EXPENDITURE) 
OVER (ORDER BY YEAR)) * 100
    , 2) AS expenditure_growth_pct
FROM nigeria_economy
ORDER BY YEAR;-- 

-- SECTION 10: ADMINISTRATION SCORECARD-- Key question: Who governed Nigeria's economy best?-- 
-- 10a. Full scorecard — every metric averaged per president-- This is the HEADLINE query of the entire analysis.
-- It lets you compare all 5 administrations side by side.
SELECT
    PRESIDENT,
    MIN(YEAR)                           AS 
years_from,
    MAX(YEAR)                           AS 
years_to,
    COUNT(YEAR)                         AS 
years_in_office,
    ROUND(AVG(GDP), 2)                  AS 
avg_gdp,
    ROUND(AVG(INFLATION_RATE), 2)       AS 
avg_inflation,
    ROUND(AVG(EXCHANGE_RATE), 2)        AS 
avg_exchange_rate,
    ROUND(AVG(ANNUAL_RESERVES), 2)      AS 
avg_reserves,
    ROUND(AVG(INTEREST_RATE), 2)        AS 
avg_interest_rate,
    ROUND(AVG(EXPENDITURE), 2)          AS 
avg_expenditure,
    ROUND(AVG(UNEMPLOYMENT), 2)         AS 
avg_unemployment
FROM nigeria_economy
GROUP BY PRESIDENT
ORDER BY MIN(YEAR);-- 10b. Rank presidents by average inflation (lower is better)
SELECT
    PRESIDENT,
    ROUND(AVG(INFLATION_RATE), 2) AS 
avg_inflation,
    RANK() OVER (ORDER BY 
AVG(INFLATION_RATE) ASC) AS inflation_rank
FROM nigeria_economy
GROUP BY PRESIDENT
ORDER BY avg_inflation ASC;
-- 10c. Rank presidents by GDP growth 
achieved
SELECT
    PRESIDENT,
    ROUND(MAX(GDP) - MIN(GDP), 
2)                                  AS 
total_gdp_added,
    ROUND(((MAX(GDP) - MIN(GDP)) / 
MIN(GDP)) * 100, 1)            AS 
pct_gdp_growth,
    RANK() OVER (ORDER BY ((MAX(GDP) - 
MIN(GDP)) / MIN(GDP)) DESC) AS growth_rank
FROM nigeria_economy
GROUP BY PRESIDENT
ORDER BY pct_gdp_growth DESC;-- 

-- SECTION 11: CRISIS DETECTION-- Key question: When did things start going wrong and why?-- 
-- 11a. Find all economic shock years — years where multiple-- indicators went bad at the same time-
 #This is the most analytical query in the file.-- EXPECTED FINDINGS:
--   2009 — Global financial crisis. Oil 
#crashed, reserves fell.--   2016 — Oil crash + currency collapse. 
#GDP contracted.--   2020 — COVID. Everything went negative.
--   2023/2024 — Subsidy removal shock. Naira free fall. Inflation at 33%.
SELECT
    YEAR,
    PRESIDENT,
    INFLATION_RATE,
    EXCHANGE_RATE,
    LAG(EXCHANGE_RATE) OVER (ORDER BY YEAR) 
AS prev_exchange_rate,
    OIL_PRICE,
    LAG(OIL_PRICE) OVER (ORDER BY YEAR) AS 
prev_oil_price,
    ANNUAL_RESERVES,
    -- Score each year: how many bad signals appeared?
    (
        CASE WHEN INFLATION_RATE > 15 THEN 
1 ELSE 0 END +
        CASE WHEN EXCHANGE_RATE > 
LAG(EXCHANGE_RATE) OVER (ORDER BY YEAR) * 
1.10 THEN 1 ELSE 0 END +
        CASE WHEN OIL_PRICE < 
LAG(OIL_PRICE) OVER (ORDER BY YEAR) * 0.85 
THEN 1 ELSE 0 END +
        CASE WHEN ANNUAL_RESERVES < 
LAG(ANNUAL_RESERVES) OVER (ORDER BY YEAR) 
THEN 1 ELSE 0 END
    ) AS crisis_signal_count
FROM nigeria_economy
WHERE OIL_PRICE IS NOT NULL
ORDER BY crisis_signal_count DESC, YEAR;-- 11b. The Subsidy Removal shock — Tinubu's first year 2023--
#Petrol subsidy was removed May 29 2023. This query isolates-- exactly what changed and how fast.
SELECT
    YEAR,
    INFLATION_RATE,
    EXCHANGE_RATE,
    ROUND(EXCHANGE_RATE - 
LAG(EXCHANGE_RATE) OVER (ORDER BY YEAR), 0) 
AS rate_jump,
    ANNUAL_DEBT,
    ROUND(ANNUAL_DEBT - LAG(ANNUAL_DEBT) 
OVER (ORDER BY YEAR), 2) AS debt_jump,
    EXPENDITURE,
    REVENUE
FROM nigeria_economy
WHERE YEAR BETWEEN 2022 AND 2026
ORDER BY YEAR;-- 11c. Interest rate as a crisis response tool-- When inflation spikes, CBN raises interest rates to cool it.
-- Does that actually work in Nigeria? This query tests it.-- If CBN raises rates but inflation still rises,the policy is not working.
SELECT
    YEAR,
    INFLATION_RATE,
    INTEREST_RATE,
    LAG(INTEREST_RATE) OVER (ORDER BY YEAR) 
AS prev_year_rate,
    INTEREST_RATE - LAG(INTEREST_RATE) OVER 
(ORDER BY YEAR) AS rate_change,
    CASE
        WHEN INTEREST_RATE > 
LAG(INTEREST_RATE) OVER (ORDER BY YEAR)
             AND INFLATION_RATE > 
LAG(INFLATION_RATE) OVER (ORDER BY YEAR)
             THEN 'RATE HIKE - But 
inflation still rose (policy not working)'
        WHEN INTEREST_RATE > 
LAG(INTEREST_RATE) OVER (ORDER BY YEAR)
             AND INFLATION_RATE < 
LAG(INFLATION_RATE) OVER (ORDER BY YEAR)
             THEN 'RATE HIKE - Inflation 
fell (policy worked)'
        WHEN INTEREST_RATE < 
LAG(INTEREST_RATE) OVER (ORDER BY YEAR)
             THEN 'RATE CUT - Stimulus 
mode'
        ELSE 'RATE HELD'
    END AS monetary_policy_outcome
FROM nigeria_economy
ORDER BY YEAR;-- 

-- SECTION 12: FOREIGN RESERVES ANALYSIS-- Key question: Does Nigeria have enough buffer for shocks?-- 
-- 12a. Reserve coverage — a healthy economy needs 3+ months import cover
-- Nigeria's monthly imports average roughly $3-4 billion-- So minimum healthy reserves = $9-12 billion
SELECT
    YEAR,
    PRESIDENT,
    ANNUAL_RESERVES,
    ROUND(ANNUAL_RESERVES / 3.5, 1) AS 
estimated_months_import_cover,
    CASE
        WHEN ANNUAL_RESERVES >= 30 THEN 
'STRONG (8+ months cover)'
        WHEN ANNUAL_RESERVES >= 15 THEN 
'ADEQUATE (4-8 months cover)'
        WHEN ANNUAL_RESERVES >= 9  THEN 
'BORDERLINE (3 months cover)'
        ELSE 'DANGER - Below minimum 
threshold'
    END AS reserve_adequacy
FROM nigeria_economy
ORDER BY YEAR;
-- 12b. Biggest reserve drawdowns — when did Nigeria burn through savings?
-- These moments reveal hidden crises even when official data looks calm
SELECT
    YEAR,
    PRESIDENT,
    ANNUAL_RESERVES,
    LAG(ANNUAL_RESERVES) OVER (ORDER BY 
YEAR) AS prev_year_reserves,
    ROUND(ANNUAL_RESERVES - 
LAG(ANNUAL_RESERVES) OVER (ORDER BY YEAR), 
2) AS reserve_change,
    CASE
        WHEN ANNUAL_RESERVES < 
LAG(ANNUAL_RESERVES) OVER (ORDER BY YEAR)
             THEN 'RESERVES FELL'
        ELSE 'RESERVES GREW'
    END AS direction
FROM nigeria_economy
ORDER BY reserve_change ASC
LIMIT 8;-- 

-- SECTION 13: FINAL SUMMARY — THE BIG PICTURE-- 

-- 13a. Decade comparison: 2000s vs 2010s vs 2020s-- Simple but powerful way to see Nigeria's trajectory
SELECT
    CASE
        WHEN YEAR BETWEEN 1999 AND 2009 
THEN '1999-2009 (Democracy foundation era)'
        WHEN YEAR BETWEEN 2010 AND 2019 
THEN '2010-2019 (Oil boom and bust era)'
        WHEN YEAR BETWEEN 2020 AND 2026 
THEN '2020-2026 (Crisis and reform era)'
    END AS era,
    COUNT(*)                        AS 
years_in_era,
    ROUND(AVG(GDP), 2)              AS 
avg_gdp,
    ROUND(AVG(INFLATION_RATE), 2)   AS 
avg_inflation,
    ROUND(AVG(EXCHANGE_RATE), 2)    AS 
avg_exchange_rate,
    ROUND(AVG(ANNUAL_RESERVES), 2)  AS 
avg_reserves,
    ROUND(AVG(OIL_PRICE), 2)        AS 
avg_oil_price
FROM nigeria_economy
GROUP BY
    CASE
        WHEN YEAR BETWEEN 1999 AND 2009 
THEN '1999-2009 (Democracy foundation era)'
        WHEN YEAR BETWEEN 2010 AND 2019 
THEN '2010-2019 (Oil boom and bust era)'
        WHEN YEAR BETWEEN 2020 AND 2026 
THEN '2020-2026 (Crisis and reform era)'
    END
ORDER BY MIN(YEAR);-- 13b. The most important single query in this entire analysis:
-- How much has the average Nigerian's purchasing power changed?
-- Nominal GDP growth means nothing if inflation and naira depreciation
-- wipe out the gains. This adjusts GDP for exchange rate to get USD terms.
SELECT
    YEAR,
    PRESIDENT,
GDP                                        
               AS 
nominal_gdp_trillions_ngn,
    EXCHANGE_RATE,
    ROUND(GDP / EXCHANGE_RATE, 
3)                            AS 
gdp_in_usd_trillions,
    ROUND((GDP / EXCHANGE_RATE) * 1000 / 
200, 2)            AS 
est_gdp_per_capita_usd,
    -- Note: Using ~200 million as approximate population base
    CASE
        WHEN ROUND((GDP / EXCHANGE_RATE) * 
1000 / 200, 0) > 2500 THEN 'UPPER MIDDLE 
INCOME LEVEL'
        WHEN ROUND((GDP / EXCHANGE_RATE) * 
1000 / 200, 0) > 1500 THEN 'LOWER MIDDLE 
INCOME LEVEL'
        ELSE 'LOW INCOME LEVEL'
    END AS income_level
FROM nigeria_economy
ORDER BY YEAR;-- 

-- END OF EDA-- What you should do next after running these queries:
-- 1. Export key results to Excel for charting
-- 2. Build a Power BI or Tableau dashboard from the scorecard
-- 3. Write your findings narrative using the crisis detection results
-- 4. The headline story this data tells:
--    Nigeria grew in nominal terms every year but the Naira lost
--    so much value that real living standards fell. Revenue never
--    kept pace with debt. Oil dependency made every global shock
--    become a Nigerian crisis. The 2023 reform was necessary but
--    the pain was immediate while the benefits are long-term.-- 

