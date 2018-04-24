#!/bin/bash
sqlplus sys/Oradoc_db1@localhost/orclcdb.localdomain as sysdba << EOF
whenever sqlerror exit sql.sqlcode;
set echo off
set heading off

@apxremov.sql;
create pluggable database orclpdb514 admin user pdb_adm identified by Oradoc_db1
file_name_convert=('/u02/app/oracle/oradata/ORCL/pdbseed/','/u02/app/oracle/oradata/ORCL/ORCLPDB514/');
alter pluggable database orclpdb514 open read write;
alter pluggable database all save state;
Alter session set container = ORCLPDB514;
@apexins.sql SYSAUX SYSAUX TEMP /i/;
@apex_rest_config_core.sql oracle oracle;
alter user apex_public_user identified by oracle account unlock;
declare
    l_acl_path varchar2(4000);
    l_apex_schema varchar2(100);
begin
    for c1 in (select schema
                 from sys.dba_registry
                where comp_id = 'APEX') loop
        l_apex_schema := c1.schema;
    end loop;
    sys.dbms_network_acl_admin.append_host_ace(
        host => '*',
        ace => xs\$ace_type(privilege_list => xs\$name_list('connect'),
        principal_name => l_apex_schema,
        principal_type => xs_acl.ptype_db));
    commit;
end;
/
begin
    apex_util.set_security_group_id( 10 );
    apex_util.create_user(
        p_user_name => 'ADMIN',
        p_email_address => 'you@youremail.com',
        p_web_password => 'Oradoc_db1',
        p_developer_privs => 'ADMIN',
        p_change_password_on_first_use => 'N');
    apex_util.set_security_group_id( null );
    commit;
end;
/

exit;
EOF
