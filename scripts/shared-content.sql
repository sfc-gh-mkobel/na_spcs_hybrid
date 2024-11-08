USE ROLE naspcs_role;
USE WAREHOUSE wh_nap;

CREATE OR REPLACE SCHEMA na_spcs_pkg.shared_data;
CREATE OR REPLACE TABLE na_spcs_pkg.shared_data.feature_flags(flags VARIANT, acct VARCHAR);
CREATE OR REPLACE SECURE VIEW na_spcs_pkg.shared_data.feature_flags_vw AS SELECT * FROM na_spcs_pkg.shared_data.feature_flags WHERE acct = current_account();
--this is the shared dataset
CREATE OR REPLACE TABLE na_spcs_pkg.shared_data.ticker_data AS 
WITH c1 AS (SELECT 
    TICKER, 
    TO_DATE(DATE::varchar,'YYYYMMDD') as DATE, 
    AVG(LAST_PRICE) as AVG_PRICE
FROM TICK_HISTORY.PUBLIC.TH_SF_MKTPLACE
WHERE SECURITY_TYPE = 1 
AND TICKER in ('AMZN','META', 'FDS', 'IBM')
GROUP BY TICKER, DATE)
SELECT TICKER, DATE, AVG_PRICE, AVG(AVG_PRICE) OVER (PARTITION BY TICKER ORDER BY DATE ASC) as M_AVG 
FROM c1
ORDER BY TICKER,DATE ASC;

GRANT USAGE ON SCHEMA na_spcs_pkg.shared_data TO SHARE IN APPLICATION PACKAGE na_spcs_pkg;
GRANT SELECT ON TABLE na_spcs_pkg.shared_data.ticker_data TO SHARE IN APPLICATION PACKAGE na_spcs_pkg;
GRANT SELECT ON VIEW na_spcs_pkg.shared_data.feature_flags_vw TO SHARE IN APPLICATION PACKAGE na_spcs_pkg;
INSERT INTO na_spcs_pkg.shared_data.feature_flags SELECT parse_json('{"debug": ["GET_SERVICE_STATUS", "GET_SERVICE_LOGS", "LIST_LOGS", "TAIL_LOG"]}') AS flags, current_account() AS acct;
GRANT USAGE ON SCHEMA na_spcs_pkg.shared_data TO SHARE IN APPLICATION PACKAGE na_spcs_pkg;