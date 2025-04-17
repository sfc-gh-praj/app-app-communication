
-- namespace under which our services and their functions will live

create or alter versioned schema setup;


create schema if not exists services;

grant usage on schema setup to application role app_public;

grant usage on schema services to application role app_public;

-- creates a compute pool, service, and service function

CREATE OR REPLACE PROCEDURE setup.create_service(service_url varchar,port varchar)
RETURNS VARCHAR
LANGUAGE PYTHON
PACKAGES = ('snowflake-snowpark-python')
RUNTIME_VERSION = 3.9
HANDLER = 'main'
AS $$
from snowflake.snowpark import Session
def main(session: Session, service_url: str, port: str) -> str:
    from inspect import cleandoc
    pool_name = session.sql(f'''  select current_database()||'_dest_app_pool' as pool_name ''').collect()[0]['POOL_NAME']


    session.sql(f'''create compute pool if not exists {pool_name}
        MIN_NODES = 1
        MAX_NODES = 1
        INSTANCE_FAMILY = CPU_X64_XS;
    ''').collect()

    spec = cleandoc(f"""
        spec:
            containers:  
            - name: streamlitcontainer
              image: <<org-account>>.registry.snowflakecomputing.com/app_app_comm_db/public/docker_images/ui:latest
              env:
                SERVICE_URL: {service_url}:{port}
              resources:                           
                requests:
                    cpu: 1
                limits:
                    cpu: 1
            endpoints:
            - name: streamlit
              port: 8001
              public: true
    """)

    _ = session.sql(f"""
        CREATE SERVICE IF NOT EXISTS services.dest_app_service
        IN COMPUTE POOL {pool_name}
        FROM SPECIFICATION '{spec}'
        MIN_INSTANCES=1
        MAX_INSTANCES=1;
    """).collect()

    session.sql(f"GRANT USAGE ON SERVICE services.dest_app_service TO APPLICATION ROLE app_public").collect()
    session.sql(f"GRANT SERVICE ROLE services.dest_app_service!ALL_ENDPOINTS_USAGE to APPLICATION ROLE app_public").collect()
    return 'Service successfully created';
$$;
grant usage on procedure setup.create_service(varchar,varchar) to application role app_public;

create or replace procedure setup.suspend_service()
returns varchar
language sql
execute as owner
as $$
    begin
        alter service services.dest_app_service suspend;
        return 'Done';
    end;
$$;
grant usage on procedure setup.suspend_service()
    to application role app_public;

create or replace procedure setup.resume_service_compute()
returns varchar
language sql
execute as owner
as $$
    begin
        let pool_name := (select current_database()) || '_dest_app_pool';
        alter service services.dest_app_service resume;
        alter compute pool identifier(:pool_name) resume;
        return 'Done';
    end;
$$;
grant usage on procedure setup.resume_service_compute()
    to application role app_public;

create or replace procedure setup.suspend_service_compute()
returns varchar
language sql
execute as owner
as $$
    begin
        let pool_name := (select current_database()) || '_dest_app_pool';
        alter service services.dest_app_service suspend;
        alter compute pool identifier(:pool_name) suspend;
        return 'Done';
    end;
$$;
grant usage on procedure setup.suspend_service_compute()
    to application role app_public;

create or replace procedure setup.drop_service_and_pool()
returns varchar
language sql
execute as owner
as $$
    begin
        let pool_name := (select current_database()) || '_dest_app_pool';
        drop service if exists services.dest_app_service;
        drop compute pool if exists identifier(:pool_name);
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
        call system$get_service_status('services.dest_app_service') into :service_status;
        return parse_json(:service_status)[0]['status']::varchar;
    end;
$$;
grant usage on procedure setup.service_status()
    to application role app_public;

CREATE OR REPLACE PROCEDURE setup.service_endpoints()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS $$
   DECLARE
        res VARCHAR;
   BEGIN
         SHOW ENDPOINTS IN SERVICE services.dest_app_service;
         SELECT "ingress_url" INTO res FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
         RETURN res;
   END;
$$;

grant usage on procedure setup.service_endpoints()
    to application role app_public;