-- Backup do banco atual de homologação
BACKUP DATABASE nome_banco 
TO DISK = ''
WITH INIT, STATS = 1, COPY_ONLY, COMPRESSION


-- Identificar os arquivos
RESTORE FILELISTONLY 
FROM DISK = ''



-- Restaurar o banco
USE MASTER
go

ALTER DATABASE nome_banco SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

RESTORE DATABASE nome_banco 
FROM DISK = ''
WITH
	MOVE = 'Nome_Logico' TO '',
	MOVE = 'Nome_Logico' TO '',
	REPLACE,
	KEEP_CDC, -- Bancos que tem CDC
	STATS = 1;
	
ALTER DATABASE nome_banco SET recovery simple -- HML
ALTER DATABASE nome_banco SET MULTI_USER;


/********************************************
Verificar se o banco existe na instancia 
********************************************/
SELECT name 
FROM sys.databases 
WHERE name = 'NOME_DO_BANCO'


-- conferir onde estão os MDF/NDF/LDF
USE NomeDoBanco;
GO
EXEC sp_helpfile;
