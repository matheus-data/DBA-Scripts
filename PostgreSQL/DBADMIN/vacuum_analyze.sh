#!/bin/bash
#
# Objetivo: Vacuum Analyze em todos os RDSs
# Criador:      Matheus Nunes Rossi
#

export PGPORT=5432
export SERVERS="/root/postgresql/host/.servers"
export PG_TABLES=`cat /root/postgresql/scripts/pg_tables.sql`

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
        
                 
                       #Entra no contexto do banco \c database
                       export PGDATABASE="$database"

	
	                echo "Begin - Vacuum Analyze from $PGDATABASE ..."

                             
			#cria a pasta do banco de dados, caso não exista
                    mkdir -p /root/postgresql/host/$PGHOST/$PGDATABASE					
          
		            LIST_TABLES=/root/postgresql/host/$PGHOST/$PGDATABASE/tables-to-process.txt 
          
		            psql -q -A -t -c "$PG_TABLES"  > $LIST_TABLES
		  
                    #Loop das tabelas do banco atual
					# Paralelizando com OITO cores de CPU o ANALYZE
                    while read table; do
                            
						#versoes anteriores a 13, retire o PARALLEL	
						VACUUM_ANALYZE="VACUUM (ANALYZE) $table ;"

						psql -q -A -t -c "$VACUUM_ANALYZE" 2>&1 &

						#echo "$VACUUM_ANALYZE"
						
  
                     done < $LIST_TABLES


        done < $LIST_DATABASES

echo "---------------------------------------------------------------------------------------------------------"


done < $SERVERS

