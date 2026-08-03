if OBJECT_ID ('tempdb..#permissoes_all') IS NOT NULL DROP TABLE #permissoes_all
if OBJECT_ID ('tempdb..#roles') IS NOT NULL DROP TABLE #roles
if OBJECT_ID ('tempdb..#permissoes_defaults') IS NOT NULL DROP TABLE #permissoes_defaults
if OBJECT_ID ('tempdb..#permissoes_roles') IS NOT NULL DROP TABLE #permissoes_roles
if OBJECT_ID ('tempdb..#permissoes_objetos') IS NOT NULL DROP TABLE #permissoes_objetos
if OBJECT_ID ('tempdb..#permissoes_explicitas_com_role') IS NOT NULL DROP TABLE #permissoes_explicitas_com_role
if OBJECT_ID ('tempdb..#permissoes_explicitas_sem_role') IS NOT NULL DROP TABLE #permissoes_explicitas_sem_role


create table #permissoes_all (Banco varchar(300),Login varchar (300), Tipo_Usuario varchar(300),Usuario varchar(300), Role varchar(300), Tipo_Permissao varchar (300), Estado_Permissao varchar (300),
Tipo_Objeto varchar(1000),Esquema_Objeto varchar(50), Nome_Objeto varchar(1000))
create table #roles (Banco varchar(300),Nome_Role  varchar(300), Role varchar (300))
create table #permissoes_defaults (Banco varchar(300),Usuario varchar(300), Role_Database varchar(300))
create table #permissoes_roles (Banco varchar(300),Usuario varchar(300), Nome_Role varchar(300), Tipo_Permissao varchar(300),Estado_Permissao varchar(300),Esquema_Objeto varchar(50), Nome_Objeto varchar(1000))
create table #permissoes_objetos (Banco varchar(300),Usuario varchar(300),Tipo_Permissao varchar(300),Estado_Permissao varchar(300),Esquema_Objeto varchar(50), Nome_Objeto varchar(1000))
create table #permissoes_explicitas_com_role (Banco varchar(300),Usuario varchar(300),Nome_Role varchar(300),Tipo_Permissao varchar(300),Estado_Permissao varchar(300)) 
create table #permissoes_explicitas_sem_role (Banco varchar(300),Usuario varchar(300),Tipo_Permissao varchar(300)) 


Exec sp_MSforeachdb '
use [?]

insert into #permissoes_all 
SELECT  ''?'' as DataBase_Name,
    [UserName] = CASE princ.[type] 
                    WHEN ''S'' THEN princ.[name]
                    WHEN ''U'' THEN ulogin.[name] COLLATE Latin1_General_CI_AI
                 END,
    [UserType] = CASE princ.[type]
                    WHEN ''S'' THEN ''SQL User''
                    WHEN ''U'' THEN ''Windows User''
                 END,  
    [DatabaseUserName] = princ.[name],       
    [Role] = null,      
    [PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = obj.type_desc,    
    [SchemaName] = OBJECT_SCHEMA_NAME(object_id(OBJECT_NAME(perm.major_id))),   
    [ObjectName] = OBJECT_NAME(perm.major_id)
FROM    
    
    sys.database_principals princ  
LEFT JOIN
 
    sys.login_token ulogin on princ.[sid] = ulogin.[sid]
LEFT JOIN        
    
    sys.database_permissions perm ON perm.[grantee_principal_id] = princ.[principal_id]
LEFT JOIN
   
    sys.columns col ON col.[object_id] = perm.major_id 
                    AND col.[column_id] = perm.[minor_id]
LEFT JOIN
    sys.objects obj ON perm.[major_id] = obj.[object_id]
WHERE 
    princ.[type] in (''S'',''U'')
  '
  
 Exec sp_MSforeachdb  '
use [?]

insert into #permissoes_all
SELECT  
    ''?'' as DataBase_Name,
    [UserName] = CASE memberprinc.[type] 
                    WHEN ''S'' THEN memberprinc.[name]
                    WHEN ''U'' THEN ulogin.[name] COLLATE Latin1_General_CI_AI
                 END,
    [UserType] = CASE memberprinc.[type]
                    WHEN ''S'' THEN ''SQL User''
                    WHEN ''U'' THEN ''Windows User''
                 END, 
    [DatabaseUserName] = memberprinc.[name],   
    [Role] = roleprinc.[name],      
    [PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = obj.type_desc,  
    [SchemaName] = OBJECT_SCHEMA_NAME(object_id(OBJECT_NAME(perm.major_id))),
    [ObjectName] = OBJECT_NAME(perm.major_id)
FROM    
   
    sys.database_role_members members
JOIN sys.database_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
JOIN sys.database_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]
LEFT JOIN
    
    sys.login_token ulogin on memberprinc.[sid] = ulogin.[sid]
LEFT JOIN        
    
    sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
LEFT JOIN
    
    sys.columns col on col.[object_id] = perm.major_id 
                    AND col.[column_id] = perm.[minor_id]
LEFT JOIN
    sys.objects obj ON perm.[major_id] = obj.[object_id]

'
 Exec sp_MSforeachdb  '
use [?]

insert into #permissoes_all 
 SELECT  
    ''?'' as DataBase_Name,
    [UserName] = ''{All Users}'',
    [UserType] = ''{All Users}'', 
    [DatabaseUserName] = ''{All Users}'',       
    [Role] = roleprinc.[name],      
    [PermissionType] = perm.[permission_name],       
    [PermissionState] = perm.[state_desc],       
    [ObjectType] = obj.type_desc,
    [SchemaName] = OBJECT_SCHEMA_NAME(object_id(OBJECT_NAME(perm.major_id))),
    [ObjectName] = OBJECT_NAME(perm.major_id)
FROM    
    
    sys.database_principals roleprinc
LEFT JOIN        
   
    sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
LEFT JOIN
    
    sys.columns col on col.[object_id] = perm.major_id 
                    AND col.[column_id] = perm.[minor_id]                   
JOIN     
    sys.objects obj ON obj.[object_id] = perm.[major_id]
WHERE
      roleprinc.[type] = ''R'' AND   roleprinc.[name] = ''public'' AND   obj.is_ms_shipped = 0
  

 DELETE FROM #permissoes_all WHERE Banco in (''master'',''msdb'',''model'',''tempdb'')
   '


 /*************************Tratamentos nas temporárias*********************************************/
    
    DELETE FROM #permissoes_all
    where LOGIN in ('dbo','INFORMATION_SCHEMA','sys','guest','public','{All Users}')
    
    DELETE FROM #permissoes_all
    where Usuario in ('dbo','INFORMATION_SCHEMA','sys','guest','public','{All Users}')     
    
    DELETE FROM #permissoes_all
    where Usuario like '##%'
    
    DELETE FROM #permissoes_all
    where Usuario like 'NT SERVICE%'
    
    --Ignora o Connect
    DELETE FROM #permissoes_all
    WHERE Tipo_Permissao = 'CONNECT'
    
           
     UPDATE  #permissoes_all
     SET Role = 'PERMISSAO_OBJETO'
     where Role is null
    
    
    INSERT INTO #roles  (Banco,Nome_Role, Role)
    
    select distinct  Banco,role,Tipo_Permissao from #permissoes_all
    where role not in ('db_datawriter','db_datareader','db_ddladmin','db_owner','db_accessadmin',
    'db_backupoperator','db_denydatawriter','db_denydatareader','db_securityadmin')
    and Role <> 'PERMISSAO_OBJETO' 
    
     
    --Mata roles e usuários inúteis (sem permissão nenhuma)
    DELETE FROM #permissoes_all
    where role in (select distinct Nome_Role from #roles)   
    and Tipo_Permissao is null and Estado_Permissao is null 
     
        
    update #permissoes_all
    set Tipo_Objeto = 'PERMISSAO_EXPLICITA',Nome_Objeto = 'PERMISSAO_EXPLICITA'
    where Tipo_Objeto is null and Nome_Objeto is null and Tipo_Permissao is not null
    
    update #permissoes_all
    set Esquema_Objeto = 'PERMISSAO_EXPLICITA',Nome_Objeto = 'PERMISSAO_EXPLICITA'
    where Esquema_Objeto is null and Nome_Objeto is null 
       
    
    update #permissoes_all
    set Login = Usuario
    where Tipo_Usuario = 'Windows User' 
    
    
        
    --Pega as permissões de roles de database defaults  
    insert into #permissoes_defaults
    SELECT  Banco,Usuario, Role FROM #permissoes_all
    where Role not in (select distinct Nome_Role from #roles)
    and Role <> 'permissao_objeto'
    order by 1,2    
    
    
    --Pega as permissões de role de usuário. Permissão direto a um objeto. 
    insert into #permissoes_roles
    SELECT DISTINCT Banco,Usuario,Role, Tipo_Permissao,Estado_Permissao, Esquema_Objeto, Nome_Objeto FROM #permissoes_all
    where Role  in (select distinct Nome_Role from #roles)
    and Role <> 'permissao_objeto' and Nome_Objeto <> 'PERMISSAO_EXPLICITA'
    order by 1,2          
    
   --Permissões Explícitas com role
    insert into #permissoes_explicitas_com_role    
    SELECT DISTINCT  Banco,Usuario,Role, Tipo_Permissao,Estado_Permissao FROM #permissoes_all
    where Role  in (select distinct Nome_Role from #roles)
    and Role <> 'permissao_objeto' and Nome_Objeto = 'PERMISSAO_EXPLICITA'
    order by 1,2        
       
    --Pega as permissões de objeto sem criação role 
    insert into #permissoes_objetos    
    SELECT DISTINCT Banco,Usuario, Tipo_Permissao,Estado_Permissao, Esquema_Objeto, Nome_Objeto FROM #permissoes_all
    where  Role = 'permissao_objeto' and Nome_Objeto <> 'PERMISSAO_EXPLICITA'
    order by 1,2             
        
    --Permissões Explícitas sem role
    insert into #permissoes_explicitas_sem_role    
    SELECT DISTINCT  Banco,Usuario, Tipo_Permissao FROM #permissoes_all
    where  Role = 'permissao_objeto' and Nome_Objeto = 'PERMISSAO_EXPLICITA'
    order by 1,2   

/*
select * from #permissoes_defaults    
    
select * from #permissoes_roles

select * from #permissoes_explicitas_com_role

select * from #permissoes_objetos   

select * from #permissoes_explicitas_sem_role 
*/  
