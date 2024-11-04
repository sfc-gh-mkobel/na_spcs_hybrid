USE ROLE naspcs_role;
USE WAREHOUSE wh_nap;

CREATE OR REPLACE SCHEMA na_spcs_pkg.shared_data;
CREATE OR REPLACE TABLE na_spcs_pkg.shared_data.feature_flags(flags VARIANT, acct VARCHAR);
CREATE OR REPLACE SECURE VIEW na_spcs_pkg.shared_data.feature_flags_vw AS SELECT * FROM na_spcs_pkg.shared_data.feature_flags WHERE acct = current_account();
--this is the shared dataset
CREATE OR REPLACE TABLE na_spcs_pkg.shared_data.ticker_data AS 
SELECT TICKER, TO_DATE(DATE::varchar,'YYYYMMDD') as DATE, AVG(LAST_PRICE) as LAST_PRICE FROM TICK_HISTORY.PUBLIC.TH_SF_MKTPLACE
WHERE MSG_TYPE = 0
GROUP BY 1,2
ORDER BY 1,2;


GRANT USAGE ON SCHEMA na_spcs_pkg.shared_data TO SHARE IN APPLICATION PACKAGE na_spcs_pkg;
GRANT SELECT ON TABLE na_spcs_pkg.shared_data.ticker_data TO SHARE IN APPLICATION PACKAGE na_spcs_pkg;
GRANT SELECT ON VIEW na_spcs_pkg.shared_data.feature_flags_vw TO SHARE IN APPLICATION PACKAGE na_spcs_pkg;
INSERT INTO na_spcs_pkg.shared_data.feature_flags SELECT parse_json('{"debug": ["GET_SERVICE_STATUS", "GET_SERVICE_LOGS", "LIST_LOGS", "TAIL_LOG"]}') AS flags, current_account() AS acct;
GRANT USAGE ON SCHEMA na_spcs_pkg.shared_data TO SHARE IN APPLICATION PACKAGE na_spcs_pkg;