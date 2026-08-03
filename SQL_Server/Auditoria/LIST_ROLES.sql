if object_id ('tempdb..#permissions') is not null
begin
DROP TABLE #permissions
end 


CREATE table #permissions
(DBNAME varchar(300) ,
 USR varchar(300) ,
 Permission varchar(300) )

 EXEC sp_MSforeachdb '
 USE [?]

 insert into #permissions
 SELECT  
 ''?'' as DBNAME,
 members.name as USR,
 roles.name as Permission

FROM sys.database_role_members rolemem
INNER JOIN sys.database_principals roles
    ON rolemem.role_principal_id = roles.principal_id
INNER JOIN sys.database_principals members
    ON rolemem.member_principal_id = members.principal_id
	where 
members.name COLLATE Latin1_General_CI_AI in (select name COLLATE Latin1_General_CI_AI from sys.syslogins)
	'
	

delete from #permissions
where dbname in  ('master','tempdb','model','msdb','distribution')

select 'USE ['+dbname + '] CREATE USER ['+usr+ '] for login ['+usr+ ']
        alter role '+permission+' add member ['+usr+'] ' as all_permissions from #permissions
--where usr = ''

