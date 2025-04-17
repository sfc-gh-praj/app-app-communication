create application role if not exists app_public;

create application role if not exists custom_app_public;
execute immediate from './services.sql';
