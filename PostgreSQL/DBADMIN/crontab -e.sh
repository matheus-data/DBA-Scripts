#
# INICIO - ROTINAS ADMINISTRATIVAS DE BANCO - DBA MATHEUS ROSSI
#

#every minute foto historica do ambiente para apoios em incidentes ou melhorias
* * * * * /root/postgresql/scripts/dbadmin_activity_minute.sh

# Vacuum diario das tabelas de todos os bancos de producao , comentado a definir com as areas melhor horario
#00 23 * * * /root/postgresql/scripts/vacuum_analyze.sh &

# Size dbs + pg_stat_statements diario
00 21 * * * /root/postgresql/scripts/dbadmin_diario.sh

# Size tables + rows diariamente + bloast inchaco
00 22 * * * /root/postgresql/scripts/dbadmin_diario_tables.sh

# tb_top_cpu - postgresql 11
00 21 * * * /root/postgresql/scripts/dbadmin_diario_tb_top_cpu_pg11.sh


# tb_top_cpu - postgresql 13
00 21 * * * /root/postgresql/scripts/dbadmin_diario_tb_top_cpu_pg13.sh
