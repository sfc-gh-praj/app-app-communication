
-- namespace under which our services and their functions will live

create schema if not exists services;

-- namespace for service administration
create or alter versioned schema setup;


grant usage on schema setup to application role app_public;

grant usage on schema services to application role app_public;


-- creates a compute pool, service, and service function
create or replace procedure setup.create_service(privileges array)
returns varchar
language sql
execute as owner
as $$
    begin
        let pool_name := (select current_database()) || '_app_pool';

        create compute pool if not exists identifier(:pool_name)
            MIN_NODES = 1
            MAX_NODES = 1
            INSTANCE_FAMILY = CPU_X64_XS;

        create service if not exists services.spcs_na_service
            in compute pool identifier(:pool_name)
            from spec='service_spec.yml';

        grant usage on service services.spcs_na_service
            to application role app_public;
        
        -- GRANT USAGE,MONITOR,OPERATE ON SERVICE services.spcs_na_service TO APPLICATION ROLE app_public;
        GRANT SERVICE ROLE services.spcs_na_service!ALL_ENDPOINTS_USAGE to APPLICATION ROLE app_public;
        GRANT SERVICE ROLE services.spcs_na_service!streamlit_endpoint_role to APPLICATION ROLE custom_app_public;

        -- GRANT USAGE ON SERVICE services.spcs_na_service TO APPLICATION ROLE app_public;


        return 'Done';
    end;
$$;
grant usage on procedure setup.create_service(array)
    to application role app_public;

-- create or replace procedure setup.create_api_service()
-- returns varchar
-- language sql
-- execute as owner
-- as $$
--     begin
--         let pool_name := (select current_database()) || 'usersapi_app_pool';

--         create compute pool if not exists identifier(:pool_name)
--             MIN_NODES = 1
--             MAX_NODES = 1
--             INSTANCE_FAMILY = CPU_X64_XS;

--         create service if not exists services.users_api_service
--             in compute pool identifier(:pool_name)
--             from spec='api_service.yml';

--         grant usage on service services.users_api_service
--             to application role app_public;
        
--         -- GRANT USAGE,MONITOR,OPERATE ON SERVICE services.spcs_na_service TO APPLICATION ROLE app_public;
--         GRANT SERVICE ROLE services.users_api_service!ALL_ENDPOINTS_USAGE to APPLICATION ROLE app_public;
--         GRANT USAGE ON SERVICE services.spcs_na_service TO APPLICATION ROLE app_public;
        
--         CREATE OR REPLACE FUNCTION services.udf_getuser(user_id varchar)
--         RETURNS VARIANT
--         SERVICE=services.users_api_service
--         ENDPOINT=api
--         AS '/specific_user';

--         grant usage on function services.udf_getuser(varchar)
--             to application role app_public;

--         return 'Done';
--     end;
-- $$;
-- grant usage on procedure setup.create_api_service()
--     to application role app_public;

create or replace procedure setup.suspend_service()
returns varchar
language sql
execute as owner
as $$
    begin
        alter service services.spcs_na_service suspend;
        -- alter service services.users_api_service suspend;
        return 'Done';
    end;
$$;
grant usage on procedure setup.suspend_service()
    to application role app_public;

create or replace procedure setup.resume_service()
returns varchar
language sql
execute as owner
as $$
    begin
        alter service services.spcs_na_service resume;
        -- alter service services.users_api_service resume;
        return 'Done';
    end;
$$;
grant usage on procedure setup.resume_service()
    to application role app_public;

create or replace procedure setup.drop_service_and_pool()
returns varchar
language sql
execute as owner
as $$
    begin
        let pool_name := (select current_database()) || '_app_pool';
        -- let api_pool_name := (select current_database()) || 'usersapi_app_pool';
        drop service if exists services.spcs_na_service;
        drop compute pool if exists identifier(:pool_name);
        -- drop service if exists services.users_api_service;
        -- drop compute pool if exists identifier(:api_pool_name);

        return 'Done';
    end;
$$;
grant usage on procedure setup.drop_service_and_pool()
    to application role app_public;

create or replace procedure setup.service_status()
returns varchar
language sql
execute as owner
as $$
    declare
        service_status varchar;
    begin
        call system$get_service_status('services.spcs_na_service') into :service_status;
        return parse_json(:service_status)[0]['status']::varchar;
    end;
$$;
grant usage on procedure setup.service_status()
    to application role app_public;

-- create or replace procedure setup.users_api_service_status()
-- returns varchar
-- language sql
-- execute as owner
-- as $$
--     declare
--         service_status varchar;
--     begin
--         call system$get_service_status('services.users_api_service') into :service_status;
--         return parse_json(:service_status)[0]['status']::varchar;
--     end;
-- $$;
-- grant usage on procedure setup.users_api_service_status()
--     to application role app_public; 

CREATE OR REPLACE PROCEDURE setup.service_endpoints()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS $$
   DECLARE
        res VARCHAR;
   BEGIN
         SHOW ENDPOINTS IN SERVICE services.spcs_na_service;
         SELECT "ingress_url" INTO res FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
         RETURN res;
   END;
$$;

grant usage on procedure setup.service_endpoints()
    to application role app_public;


CREATE OR REPLACE PROCEDURE setup.service_dns_name()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS $$
   DECLARE
        res VARCHAR;
   BEGIN
         desc service services.spcs_na_service;
         select "dns_name" as source_service_dns into res from table(result_scan(last_query_id()));
         RETURN res;
   END;
$$;

grant usage on procedure setup.service_dns_name()
    to application role app_public;