IF OBJECT_ID ('TEMPDB..#Usuarios_dbo') IS NOT NULL
DROP TABLE #Usuarios_dbo

CREATE TABLE #Usuarios_dbo

(BANCO VARCHAR(100), USUARIO VARCHAR (100), LOGIN VARCHAR(100))

EXEC sp_MSforeachdb '
INSERT INTO #Usuarios_dbo
SELECT ''?'' as banco, u.name as usuario, ISNULL(l.name, ''usuário não atribuído a login'') AS "Login"
FROM [?].sys.sysusers u
    LEFT JOIN master.dbo.syslogins l ON u.sid = l.sid
	where islogin = 1 and 
	u.name not in (''guest'',''INFORMATION_SCHEMA'',''sys'')
	
delete from #Usuarios_dbo where banco in (''master'',''msdb'',''tempdb'',''model'')
	'

--select * from #Usuarios_dbo 

/*
declare @banco varchar (300) = 'focus'

select 'use '+BANCO+ ' create user ['+USUARIO+ '] for login ['+USUARIO+ ']'  from #Usuarios_dbo
WHERE BANCO = @banco
and USUARIO <> 'dbo'
and LOGIN <> 'usuário não atribuído a login'
union all
select 'use '+BANCO+ ' alter user ['+USUARIO+ '] with login =['+USUARIO+ ']'  from #Usuarios_dbo
WHERE BANCO = @banco
and USUARIO <> 'dbo'
and LOGIN <> 'usuário não atribuído a login'
union all
select 'create role HOM_EXECUTE'
union all
select 'exec sp_addrolemember ''db_datareader'',''HOM_EXECUTE'''
union all
select 'exec sp_addrolemember ''db_datawriter'',''HOM_EXECUTE'''
union all
select 'exec sp_addrolemember ''db_ddladmin'',''HOM_EXECUTE'''
union all
select 'grant execute to HOM_EXECUTE'
union all
select 'use '+BANCO+ ' exec sp_addrolemember ''HOM_EXECUTE'','''+USUARIO+ ''''  from #Usuarios_dbo
WHERE BANCO = @banco
and USUARIO <> 'dbo'
and LOGIN <> 'usuário não atribuído a login'
*/
