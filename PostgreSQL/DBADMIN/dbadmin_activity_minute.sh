#!/bin/bash
#
# Objetivo: Esse script acessa o arquivo .servers, pega cada um dos servidores registrados nele e
#                       registra uma foto histórica da tabela de sistema pg_stat_activity no banco de dados dbadmin.public.tb_get_activity
#
# Criador:      Matheus Rossi
#

export PGPORT=5432
export SERVERS="/root/postgresql/host/.servers"

while read line; do

    export PGHOST=`echo $line | awk '{split($0, a, ";"); print a[1]}'`
    export PGUSER=`echo $line | awk '{split($0, a, ";"); print a[2]}'`
    export PGPASSWORD=`echo $line | awk '{split($0, a, ";"); print a[3]}'`
    export PGDATABASE=dbadmin

echo "Begin endpoint $PGHOST - tb_get_activity"

#Pega a pg_stat_activity
psql -d dbadmin -c  "

--dbadmin
insert into tb_get_activity (dt_log,state,usr,db,ip,query,query_start,time_running,pid)
SELECT  distinct
cast (cast(cast(now() - INTERVAL '3 HOURS' as date) as char(10))|| ' ' || cast(cast(now() - INTERVAL '3 HOURS' as time) as char(5)) as timestamp) as dt_log,
         state ,
         usename  ,
         datname ,
         client_addr ,
         query ,
         query_start,
         age(now(), query_start),
         pid

FROM pg_stat_activity
where pid <> pg_backend_pid()
and usename not in ('rdsadmin','','patrocinio.diniz.meta')
and datname not in ('dbadmin')
--retira as querys desnecessarias
and query not in ('SET application_name = ''PostgreSQL JDBC Driver''','COMMIT',
'SHOW TRANSACTION ISOLATION LEVEL','SET SESSION CHARACTERISTICS AS TRANSACTION READ WRITE',
'SET extra_float_digits = 3', 'ROLLBACK','','SELECT 1')
and query not like '%search_path%'
and query not like '%pg_catalog%'
ORDER BY query_start;



insert into tb_get_activity_pid (dt_log,total_pid,total_pid_by_db,ip,usr,db)
select 
cast (cast(cast(now() - INTERVAL '3 HOURS' as date) as char(10))|| ' ' || cast(cast(now() - INTERVAL '3 HOURS' as time) as char(5)) as timestamp) as dt_log,
(select count(*) from pg_stat_activity) as total, 
count(*) as qtd, 
client_addr, 
usename, 
datname 
from pg_stat_activity
where client_addr is not null
and pid <> pg_backend_pid()  
and usename not in ('rdsadmin','')
and datname not in ('dbadmin')
group by client_addr, usename, datname
order by qtd desc;



 insert 	into 	tb_get_locks
(dt_log, blocked_pid, blocked_user,blocking_pid,blocking_user,
blocked_statement,	current_statement_in_blocking_process)

 select
 cast (cast(cast(now() - INTERVAL '3 HOURS' as date) as char(10))|| ' ' || cast(cast(now() - INTERVAL '3 HOURS' as time) as char(5)) as timestamp) as dt_log,
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


"

echo "Finish endpoint $PGHOST - tb_get_activity"
echo "-------------------------------------------------------------------------------------------------------------"

done < $SERVERS
