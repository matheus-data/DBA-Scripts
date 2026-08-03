/*********************************************
	Autor: Matheus Nunes Rossi
	Tema: Backup e Restore 
**********************************************/

/*******************************
	PG_DUMP do Banco inteiro:
********************************/
pg_dump -h host_name -v -Fc -U nome_user -p 5432 -d nome_banco  -R -f /caminho/do/backup/nome_banco.sql
--OU
PGPASSWORD 'senha_user' time pg_dump -h host_name -v -Fc -U nome_user -p 5432 -d nome_banco -f /caminho/do/backup/nome_banco.sql


/*******************************
	PG_DUMP do Schema:
********************************/
PGPASSWORD 'senha_user' time pg_dump -h host_name -p 5432 -U nome_user -d nome_banco -v -Fc -R /caminho/do/backup/nome_schema.sql --schema nome_schema


/***********************************
	PG_RESTORE do Banco inteiro:
************************************/
PGPASSWORD 'senha_user' time pg_restore -h host_name -U nome_user -d nome_banco --clean --create --verbose /caminho/do/backup/nome_banco.sql

/*******************************
	PG_RESTORE do Schema:
********************************/
PGPASSWORD 'senha_user' time pg_restore -h host_name -U nome_user -d nome_banco --verbose /caminho/do/backup/nome_schema.sql
