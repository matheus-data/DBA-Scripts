#!/bin/bash
#
# Objetivo: Esse script acessa o arquivo .servers, pega cada um dos servidores registrados nele e
#  e popula as tabelas do banco de dados dbadmin (tb_db_size e tb_top_cpu)
#  Efetua o expurgo ao final onde a coluna dt_log for menor que 30 dias
#  Execução diária uma vez ao dia
# Criador:      Matheus Rossi
# PostgreSQL 13

export PGPORT=5432
export SERVERS="/root/postgresql/host/.servers"

while read line; do

    export PGHOST=`echo $line | awk '{split($0, a, ";"); print a[1]}'`
    export PGUSER=`echo $line | awk '{split($0, a, ";"); print a[2]}'`
    export PGPASSWORD=`echo $line | awk '{split($0, a, ";"); print a[3]}'`
    export PGDATABASE=dbadmin

echo "Begin endpoint $PGHOST - dbadmin"

#Pega a pg_stat_activity
time psql -d dbadmin -c  "


--dbadmin
insert into tb_top_cpu (dt_log,db,total_time,calls,mean, percentage_cpu,short_query)
SELECT
cast (cast(cast(now()  - INTERVAL '3 HOURS' as date) as char(10))|| ' ' || cast(cast(now() - INTERVAL '3 HOURS'  as time) as char(5)) as timestamp) as dt_log,
  datname ,
  round(total_exec_time::numeric, 2) AS total_exec_time,
  calls,
  round(mean_exec_time::numeric, 2) AS mean,
  round((100 * total_exec_time /
  sum(total_exec_time::numeric) OVER ())::numeric, 2) AS percentage_cpu,
  substring(query, 1, 2500) AS short_query
FROM    pg_stat_statements t1
join pg_database t2 on t1.dbid = t2.oid
ORDER BY total_exec_time DESC
LIMIT 20;




"

echo "Finish endpoint $PGHOST - dbadmin"
echo "-------------------------------------------------------------------------------------------------------------"


done < $SERVERS
