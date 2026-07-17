USE [DBADMIN]
GO
--DROP TABLE [dbo].[TB_AuditoriaDDL]
CREATE TABLE [dbo].[TB_AuditoriaDDL](
	[Data] [datetime] NULL,
	[EventType] [varchar](30) NULL,
	[Login] [varchar](100) NULL,
	[Usr] [varchar](100) NULL,
	[DBName] [varchar](100) NULL,
	[SQLStatement] [varchar](max) NULL,
	Ip varchar(100),
	Host varchar(100),
	Program varchar(100),
	[Evento] [xml] NULL,
	[NivelAuditoria] [char](1) NULL
) 

grant insert on  [dbo].[TB_AuditoriaDDL] to public
grant connect to guest


--DROP TRIGGER [TR_DDL_DB] ON DATABASE
--nivel database
USE BANCO

CREATE TRIGGER [TR_DDL_DB]  
ON DATABASE   
FOR DDL_DATABASE_LEVEL_EVENTS   
AS   

BEGIN
    SET NOCOUNT ON;
DECLARE @evento xml     
SET @evento = eventdata()  

   DECLARE @ip varchar(100) = CONVERT(varchar(100), 
         CONNECTIONPROPERTY('client_net_address'));     

INSERT INTO DBADMIN.dbo.TB_AuditoriaDDL         
(Data, EventType, Login, Usr, DBName, SQLStatement,Ip, Host, Program, Evento, NivelAuditoria)    
VALUES (
 getdate ()    ,
 @evento.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(100)')    
,@evento.value('(/EVENT_INSTANCE/LoginName)[1]', 'nvarchar(100)')    ,
 @evento.value('(/EVENT_INSTANCE/UserName)[1]', 'nvarchar(100)')    ,
 @evento.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'nvarchar(100)')    ,
 @evento.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'nvarchar(2000)')    ,
 @ip ,
 HOST_NAME(),
 PROGRAM_NAME(),
 @evento   ,
 'D'   )        


END


--USE [master]
--GO
--DROP TRIGGER [TR_DDL_AUDIT] ON ALL SERVER



--nivel server
USE [master]
GO
CREATE TRIGGER [TR_DDL_AUDIT]
ON ALL SERVER 
FOR 
--DDL_SERVER_LEVEL_EVENTS
 ddl_endpoint_events, 
 ddl_login_events, 
 ddl_gdr_server_events, 
 ddl_authorization_server_events,
 create_database,
 alter_database,
 drop_database
AS 

BEGIN
    SET NOCOUNT ON;
  DECLARE @evento xml 
  SET @evento = eventdata() 
  
   DECLARE @ip varchar(100) = CONVERT(varchar(100), 
         CONNECTIONPROPERTY('client_net_address'));  
		     
  INSERT INTO DBADMIN.dbo.TB_AuditoriaDDL 		 
   (Data, EventType, Login, Usr, DBName, SQLStatement,Ip, Host, Program, Evento, NivelAuditoria) 
  VALUES (
     getdate ()
	 ,@evento.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(100)') 
	,@evento.value('(/EVENT_INSTANCE/LoginName)[1]', 'nvarchar(100)') 
	,@evento.value('(/EVENT_INSTANCE/UserName)[1]', 'nvarchar(100)') 
	,@evento.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'nvarchar(100)') 
	,@evento.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'nvarchar(2000)') 
	,@ip 
     ,HOST_NAME()
     ,PROGRAM_NAME()
	,@evento
	,'S'
	)


END

