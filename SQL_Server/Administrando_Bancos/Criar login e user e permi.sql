/***********************************************
Criar Login / Usuario / permissão - SQL Server
************************************************/
-- Entrar no contexto do banco de dados desejado
USE [banco];
GO

-- 1. Criar o usuário no banco mapeando para o login existente
CREATE USER "nome_user" FOR LOGIN "nome_login";
-- OU
ALTER USER "nome_user" WITH LOGIN = "nome_login";
GO

-- 2. Adicionar o usuário à role db_owner (acesso total ao banco)
ALTER ROLE nome_role ADD MEMBER "nome_user";
GO


CREATE LOGIN "usr_teste"       -- Cria um login no nível da instância do SQL Serve
WITH PASSWORD = 'mudar@123'  -- Define a senha inicial do login
     MUST_CHANGE, 			 -- Exige que o usuário altere a senha no primeiro login.
     CHECK_EXPIRATION = ON;  -- Ativa a política de expiração de senha do Windows para este login


/*************************************************************************************************
db_owner       :	Acesso total ao banco. Pode criar, alterar e excluir qualquer objeto.
db_datareader  :	Permite fazer SELECT em todas as tabelas e views do banco
db_datawriter  :	Permite fazer INSERT, UPDATE e DELETE em todas as tabelas e views.
db_ddladmin	   :    Pode criar, alterar e excluir objetos do esquema (tabelas, views, procs etc).
**************************************************************************************************/

-- Definir senha temporária e exigir troca no próximo login
ALTER LOGIN "usr_teste"
WITH PASSWORD = 'mudar@123'
	 MUST_CHANGE,
	 CHECK_POLICY = ON,
	 CHECK_EXPIRATION = ON;
WITH PASSWORD = 

/********************************************
Verificar se o banco existe na instancia 
********************************************/
SELECT name 
FROM sys.databases 
WHERE name = 'NOME_DO_BANCO'

/********************************************
Verificar se o Login existe (instância)
********************************************/
SELECT name 
FROM sys.server_principals 
WHERE name = 'NOME_DO_LOGIN'

/********************************************
Verificar se o Usuário existe (no banco)
********************************************/
SELECT name 
FROM sys.database_principals 
WHERE name = 'NOME_DO_USUARIO'
