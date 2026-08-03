#!/bin/bash
#
# Objetivo:  Pega o banco + esquema + tabela + size + rows de todas as tabelas diariamente e popula no dbadmin
# Criador:      Matheus Rossi
#

export PGPORT=5432
export SERVERS="/root/postgresql/host/.servers"

while read line; do

    export PGHOST=`echo $line | awk '{split($0, a, ";"); print a[1]}'`
    export PGUSER=`echo $line | awk '{split($0, a, ";"); print a[2]}'`
    export PGPASSWORD=`echo $line | awk '{split($0, a, ";"); print a[3]}'`
    export PGDATABASE=postgres

#cria a pasta do server, caso não exista
mkdir -p /root/postgresql/host/$PGHOST

LIST_DATABASES="/root/postgresql/host/$PGHOST/databases-to-process.txt"

#alimenta o arquivo databases-to-process.txt
psql -q -A -t -c "select datname from pg_database where datname not in ('dbadmin','rdsadmin','template0','template1','postgres');" > $LIST_DATABASES

echo "Begin endpoint $PGHOST"

    while read database; do

        export PGDATABASE="$database"

INSERT_DBADMIN="/root/postgresql/host/$PGHOST/insert_into_dbadmin_$PGDATABASE.sql"

        echo "Begin - Table Size from  $PGDATABASE ..."

        #Limpa o .sql
        truncate -s 0 $INSERT_DBADMIN

        ##Get tables size and Rows
        psql -q -A -t -c "SELECT
                                                'insert into tb_tables_size values ('''||
                                                cast (cast(cast(now() - INTERVAL '3 HOURS' as date) as char(10))|| ' ' ||
                                                cast(cast(now() - INTERVAL '3 HOURS' as time) as char(5)) as timestamp)::text||
                                                ''',''' ||current_database()|| ''',''' || relnamespace::regnamespace || ''',''' ||
                                        relname || ''',''' ||  pg_total_relation_size(C.oid)::text || ''',' ||
                                                '''' ||  pg_size_pretty (pg_total_relation_size(C.oid))::text || ''',' ||
                                                reltuples::bigint::text ||',' || free_space_mb::bigint::text ||');'
                                                FROM pg_class C,
                                                LATERAL (
                                                          SELECT
                                               (sum(avail)/1024/1024)  as free_space_mb
                                                  FROM pg_freespace(oid)
                                                ) AS space

                                                        WHERE relkind = 'r'
                                              AND relnamespace NOT IN ('information_schema'::regnamespace, 'pg_catalog'::regnamespace)
                                                        ORDER BY pg_total_relation_size(C.oid) desc;" >> $INSERT_DBADMIN

        ##Insert into dbadmin.public.tb_tables_size
        psql -d dbadmin -c "\i $INSERT_DBADMIN"


           done < $LIST_DATABASES

done < $SERVERS
