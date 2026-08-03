--nova sessão no banco de dados postres
--no Parameter Group do RDS em shared_preload_libraries deve existir o values pg_stat_statements,pg_cron
--A versão mínima do RDS deve ser 12.5
create extension pg_cron;


create user usr_manutencao with password 'U3r!M_nUT3nCa0!';

grant usr_forte to usr_manutencao;


--0 9 * * * 09 da manhã
--minuto em minuto tb_get_activity + pid + get_locks - without get reads with foreign table
SELECT cron.schedule('tb_get_activity', '* * * * *', 'insert into tb_get_activity 
(dt_log,state,usr,db,ip,query,query_start,time_seconds,pid)
	SELECT  distinct
	cast (cast(cast(now() - INTERVAL ''3 HOURS'' as date) as char(10))|| '' '' || cast(cast(now() - INTERVAL ''3 HOURS'' as time) as char(5)) as timestamp) as dt_log,
			 state ,
			 usename  ,
			 datname ,
			 client_addr ,
			 query ,
			 query_start,
to_seconds(age(
cast(cast(cast(now() as date) as char(10))||'' ''||cast(cast(now() as time) as char(5)) as timestamp),
cast(cast(cast(query_start as date) as char(10))||'' ''||cast(cast(query_start as time) as char(5)) as timestamp)
       )::text)::int as time_seconds,
			 pid		 

	FROM pg_stat_activity
	where pid <> pg_backend_pid()
	and usename not in (''rdsadmin'','''',''rdsproxyadmin'')
	and datname not in (''dbadmin'')
		and query not in (''SET application_name = ''''PostgreSQL JDBC Driver'''''',''COMMIT'',
	''SHOW TRANSACTION ISOLATION LEVEL'',''SET SESSION CHARACTERISTICS AS TRANSACTION READ WRITE'',
	''SET extra_float_digits = 3'', ''ROLLBACK'','''',''SELECT 1'')
	and query not like ''%search_path%''
	and query not like ''%pg_catalog%''
	and age(
cast(cast(cast(now() as date) as char(10))||'' ''||cast(cast(now() as time) as char(5)) as timestamp),
cast(cast(cast(query_start as date) as char(10))||'' ''||cast(cast(query_start as time) as char(5)) as timestamp)
       )::text not ilike ''%day%''
	ORDER BY query_start;

insert into tb_get_activity_pid (dt_log,total_pid,total_pid_by_db,ip,usr,db)
select 
cast (cast(cast(now() - INTERVAL ''3 HOURS'' as date) as char(10))|| '' '' || cast(cast(now() - INTERVAL ''3 HOURS'' as time) as char(5)) as timestamp) as dt_log,
(select count(*) from pg_stat_activity) as total, 
count(*) as qtd, 
client_addr, 
usename, 
datname 
from pg_stat_activity
where client_addr is not null
and pid <> pg_backend_pid()  
and usename not in (''rdsadmin'','''',''rdsproxyadmin'')
and datname not in (''dbadmin'')
group by client_addr, usename, datname
order by qtd desc;


insert 	into 	tb_get_locks 
(dt_log, blocked_pid, blocked_user,blocking_pid,blocking_user,		
blocked_statement,	current_statement_in_blocking_process)

 select
cast (cast(cast(now() - INTERVAL ''3 HOURS'' as date) as char(10))|| '' '' || cast(cast(now() - INTERVAL ''3 HOURS'' as time) as char(5)) as timestamp) as dt_log,
	blocked_locks.pid as blocked_pid,
	blocked_activity.usename as blocked_user,
	blocking_locks.pid as blocking_pid,
	blocking_activity.usename as blocking_user,
	blocked_activity.query as blocked_statement,
	blocking_activity.query as current_statement_in_blocking_process
from
	pg_catalog.pg_locks blocked_locks
join pg_catalog.pg_stat_activity blocked_activity on
	blocked_activity.pid = blocked_locks.pid
join pg_catalog.pg_locks blocking_locks
        on
	blocking_locks.locktype = blocked_locks.locktype
	and blocking_locks.database is not distinct
from 	blocked_locks.database	and blocking_locks.relation is not distinct
from 	blocked_locks.relation and blocking_locks.page is not distinct
from 	blocked_locks.page 	and blocking_locks.tuple is not distinct
from 	blocked_locks.tuple 	and blocking_locks.virtualxid is not distinct
from 	blocked_locks.virtualxid 	and blocking_locks.transactionid is not distinct
from 	blocked_locks.transactionid 	and blocking_locks.classid is not distinct
from 	blocked_locks.classid 	and blocking_locks.objid is not distinct
from 	blocked_locks.objid 	and blocking_locks.objsubid is not distinct
from 	blocked_locks.objsubid 	and blocking_locks.pid != blocked_locks.pid 
join pg_catalog.pg_stat_activity blocking_activity on 	blocking_activity.pid = blocking_locks.pid
where
	not blocked_locks.granted;
	');
	


--às 21 hs todo dia tb_db_size
SELECT cron.schedule('tb_db_size', '0 21 * * *', 'insert into tb_db_size (dt_log, db,db_size_mb)
SELECT
cast (cast(cast(now() - INTERVAL ''3 HOURS'' as date) as char(10))|| '' '' || cast(cast(now() - INTERVAL ''3 HOURS'' as time) as char(5)) as timestamp) as dt_log,
d.datname , pg_database_size(d.datname)/1024/1024
FROM pg_database d
WHERE d.datname not in (''template1'',''template0'',''postgres'',''rdsadmin'')
ORDER by 3 DESC;

insert into tb_top_cpu (dt_log,db,total_time,calls,mean, percentage_cpu,short_query)
SELECT
cast (cast(cast(now()  - INTERVAL ''3 HOURS'' as date) as char(10))|| '' '' || cast(cast(now() - INTERVAL ''3 HOURS''  as time) as char(5)) as timestamp) as dt_log,
  datname ,
  round(total_exec_time::numeric, 2) AS total_time,
  calls,
  round(mean_exec_time::numeric, 2) AS mean,
  round((100 * total_exec_time /
  sum(total_exec_time::numeric) OVER ())::numeric, 2) AS percentage_cpu,
  substring(query, 1, 2500) AS short_query
FROM    pg_stat_statements t1
join pg_database t2 on t1.dbid = t2.oid
ORDER BY total_exec_time DESC
LIMIT 20;

--reset pg_stat_statements
SELECT pg_stat_statements_reset();


delete from tb_get_activity WHERE dt_log::date < (now() - ''33 days''::interval)::date ;
delete from tb_get_activity_pid WHERE dt_log::date < (now() - ''33 days''::interval)::date ;
delete from tb_db_size WHERE dt_log::date < (now() - ''33 days''::interval)::date ;
delete from tb_top_cpu WHERE dt_log::date < (now() - ''33 days''::interval)::date ;
delete from tb_tables_size WHERE dt_log::date < (now() - ''33 days''::interval)::date ;
delete from tb_get_locks WHERE dt_log::date < (now() - ''33 days''::interval)::date ;
delete from tb_get_lag WHERE dt_log::date < (now() - ''33 days''::interval)::date ;
delete from tb_get_activity_read WHERE dt_log::date < (now() - ''33 days''::interval)::date ;
delete from tb_get_activity_pid_read WHERE dt_log::date < (now() - ''33 days''::interval)::date ; ');


--CRON TB_TABLES_SIZE
/*
GENERATE DYNAMIC FROM DATABASES 
TO GET INFORMATION FROM TABLES USING EXTENSION DBLINK

--CHANGE  INFORMATION :  HOST_AQUI 

SELECT 
'
INSERT INTO tb_tables_size
SELECT  
'||datname||'.*
FROM dblink(''''dbname='||datname||' port=5432 
            host=HOST_AQUI user=usr_manutencao password=U3r!M_nUT3nCa0!'''',''''
SELECT 
cast (cast(cast(now() -  INTERVAL ''''''''3 HOURS'''''''' as date) as char(10))
|| '''''''' '''''''' || cast(cast(now() -  INTERVAL ''''''''3 HOURS'''''''' as time) as char(5)) as timestamp) as dt_log, 
       current_database() as db,
       relnamespace::regnamespace as sche,
       relname as tb,
       pg_total_relation_size(C.oid)::bigint size,
       pg_size_pretty (pg_total_relation_size(C.oid)) as size_pretty,
       reltuples::bigint as rows
FROM pg_class C
WHERE relkind = ''''''''r''''''''
  AND relnamespace NOT IN (''''''''information_schema''''''''::regnamespace,
                           ''''''''pg_catalog''''''''::regnamespace)
ORDER BY size DESC;
'''') AS '||datname||' (dt_log timestamp, db text, sche text,tb text,size bigint, size_pretty text, rows bigint);
'
from pg_database
where datname not in ('template1','template0','postgres','rdsadmin','cloudsqladmin','dbadmin');


*/


--CRON TB_TABLES_SIZE
SELECT cron.schedule('tb_tables_size', '0 23 * * *', 
'
/* COLAR AQUI O OUTPUT DA QUERY ACIMA*/

'
);


--EXPURGO da tabela de sistema  cron.job_run_details
SELECT cron.schedule('expurgo_job_run_details', '0 22 * * *', 'delete from cron.job_run_details
WHERE end_time::date < (now() - ''07 days''::interval)::date ;');



--coloca o banco correto
update cron.job
set database = 'dbadmin'
where jobname 
in ('tb_get_activity','tb_get_activity_read','tb_db_size',
'tb_tables_size','tb_get_lag');


/************************
CASO TENHA REPLICA tb_get_activity_read - TROCAR HOST_REPLICA
************************/
	
	
SELECT cron.schedule('tb_get_activity_read', '* * * * *',
'
insert into tb_get_activity_read (dt_log,state,usr,db,ip,query,query_start,time_seconds,pid)
SELECT  
cast (cast(cast(now() - INTERVAL ''3 HOURS'' as date) as char(10))|| '' '' 
|| cast(cast(now() - INTERVAL ''3 HOURS'' as time) as char(5)) as timestamp) as dt_log,
tb_get_activity_read.*
FROM dblink(''dbname=dbadmin port=5432 host=HOST_REPLICA user=usr_manutencao password=U3r!M_nUT3nCa0!'',
''
	SELECT  distinct
			 state ,
			 usename  ,
			 datname ,
			 client_addr ,
			 query ,
			 query_start,
to_seconds(age(now(), query_start)::text)::int as time_seconds,
			 pid

	FROM pg_stat_activity
	where pid <> pg_backend_pid()
	and usename not in (''''rdsadmin'''','''''''',''''rdsproxyadmin'''')
	and datname not in (''''dbadmin'''')
	and query not in (''''SET application_name = ''''''''PostgreSQL JDBC Driver'''''''''''',''''COMMIT'''',
	''''SHOW TRANSACTION ISOLATION LEVEL'''',''''SET SESSION CHARACTERISTICS AS TRANSACTION READ WRITE'''',
	''''SET extra_float_digits = 3'''', ''''ROLLBACK'''','''''''',''''SELECT 1'''')
	and query not like ''''%search_path%''''
	and query not like ''''%pg_catalog%''''
	and age(
cast(cast(cast(now() as date) as char(10))||'''' ''''||cast(cast(now() as time) as char(5)) as timestamp),
cast(cast(cast(query_start as date) as char(10))||'''' ''''||cast(cast(query_start as time) as char(5)) as timestamp)
       )::text not ilike ''''%day%''''
	ORDER BY query_start;
'') 
AS tb_get_activity_read (state varchar(200),usr varchar(200),db varchar(200),ip varchar(100),query text ,query_start timestamp,time_seconds int,pid int);	


insert into tb_get_activity_pid_read (dt_log,total_pid,total_pid_by_db,ip,usr,db)
SELECT  
cast (cast(cast(now() - INTERVAL ''3 HOURS'' as date) as char(10))|| '' '' 
|| cast(cast(now() - INTERVAL ''3 HOURS'' as time) as char(5)) as timestamp) as dt_log,
tb_get_activity_pid_read.*
FROM dblink(''dbname=dbadmin port=5432 host=HOST_REPLICA user=usr_manutencao password=U3r!M_nUT3nCa0!'',
''
select 
(select count(*) from pg_stat_activity) as total, 
count(*) as qtd, 
client_addr, 
usename, 
datname 
from pg_stat_activity
where client_addr is not null
and pid <> pg_backend_pid()  
and usename not in (''''rdsadmin'''','''''''',''''rdsproxyadmin'''')
and datname not in (''''dbadmin'''')
group by client_addr, usename, datname
order by qtd desc;	
''
) AS tb_get_activity_pid_read (total_pid int,total_pid_by_db int,ip varchar(100),usr varchar(200),db varchar(200));
');	


/************************
CASO TENHA REPLICA tb_get_lag - TROCAR HOST_REPLICA
************************/
	
SELECT cron.schedule('tb_get_lag', '* * * * *', '	
	
insert into tb_get_lag	
SELECT  
cast (cast(cast(now() - INTERVAL ''3 HOURS'' as date) as char(10))|| '' '' 
|| cast(cast(now() - INTERVAL ''3 HOURS'' as time) as char(5)) as timestamp) as dt_log,
lag_replication
FROM dblink(''dbname=dbadmin port=5432 host=HOST_REPLICA user=usr_manutencao password=U3r!M_nUT3nCa0!'',''
SELECT
    (
   extract(epoch FROM now()) -
   extract(epoch FROM pg_last_xact_replay_timestamp())
  )::int as lag_replication
'') AS lag_replication (lag_replication int);
') ;




--dia atual
select start_time ,status , return_message , command  from cron.job_run_details
WHERE end_time::date = now()::date
and  jobid =  (select jobid from cron.job where jobname = 'refresh_vwm_renewal_confirmed')
order by runid  desc


--configurations pg_Cron
SELECT name, setting, short_desc FROM pg_settings WHERE name LIKE 'cron.%' ORDER BY name;
--muda o max running jobs
select cron.max_running_jobs (12);

name                         setting    short_desc
cron.database_name           postgres   Database in which pg_cron metadata is kept.
cron.host                    localhost  Hostname to connect to postgres.
cron.log_run                 on         Log all jobs runs into the job_run_details table
cron.log_statement           on         Log all cron statements prior to execution.
cron.max_running_jobs        5          Maximum number of jobs that can run concurrently.
cron.use_background_workers  on         Use background workers instead of client sessions.

