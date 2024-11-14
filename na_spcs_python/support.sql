-- Break Glass Support Functions
CREATE SCHEMA IF NOT EXISTS app_internal;
CREATE SCHEMA IF NOT EXISTS support;
GRANT USAGE ON SCHEMA support TO APPLICATION ROLE app_admin;

CREATE OR REPLACE PROCEDURE support.get_service_status(service VARCHAR)
    RETURNS VARCHAR
    LANGUAGE SQL
AS $$
DECLARE
    res VARCHAR;
BEGIN
    SELECT SYSTEM$GET_SERVICE_status(:service) INTO res;
    RETURN res;
END;
$$;
GRANT USAGE ON PROCEDURE support.get_service_status(VARCHAR) TO APPLICATION ROLE app_admin;

CREATE OR REPLACE PROCEDURE support.get_service_logs(service VARCHAR, instance INT, container VARCHAR, num_lines INT)
    RETURNS VARCHAR
    LANGUAGE SQL
AS $$
DECLARE
    res VARCHAR;
BEGIN
    SELECT SYSTEM$GET_SERVICE_LOGS(:service, :instance, :container, :num_lines) INTO res;
    RETURN res;
END;
$$;
GRANT USAGE ON PROCEDURE support.get_service_logs(VARCHAR, INT, VARCHAR, INT) TO APPLICATION ROLE app_admin;