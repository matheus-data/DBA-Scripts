/*Nível server*/
CREATE TRIGGER [TR_DDL_AUDIT]
ON ALL SERVER 
FOR 
 ddl_endpoint_events, 
 ddl_login_events, 
 ddl_gdr_server_events, 
 ddl_authorization_server_events,
 create_database,
 alter_database,
 drop_database,
 DROP_SERVER_ROLE_MEMBER,
 ADD_SERVER_ROLE_MEMBER
AS 
  DECLARE @data xml 
  SET @data = eventdata()   
  INSERT INTO DBA.dbo.TBAuditoriaDDL 		 
   (TipoEvento, Login, Usuario, Banco, Comando, Evento)
  VALUES (
	 @data.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(100)') 
	,@data.value('(/EVENT_INSTANCE/LoginName)[1]', 'nvarchar(100)') 
	,@data.value('(/EVENT_INSTANCE/UserName)[1]', 'nvarchar(100)') 
	,@data.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'nvarchar(100)') 
	,@data.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'nvarchar(2000)') 
	,@data
	
	)


ENABLE TRIGGER [TR_DDL_AUDIT] ON ALL SERVER



/*Nível database*/
CREATE TRIGGER [TR_DDL_DB]
ON DATABASE 
FOR DDL_DATABASE_LEVEL_EVENTS 
AS   
  DECLARE @data xml 
  SET @data = eventdata()   
  INSERT INTO DBA_Anatel.dbo.TBAuditoriaDDL
   (TipoEvento, Login, Usuario, Banco, Comando, Evento, NivelAuditoria )
  VALUES (
       @data.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(100)') 
      ,@data.value('(/EVENT_INSTANCE/LoginName)[1]', 'nvarchar(100)') 
      ,@data.value('(/EVENT_INSTANCE/UserName)[1]', 'nvarchar(100)') 
      ,@data.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'nvarchar(100)') 
      ,@data.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'nvarchar(2000)') 
      ,@data
      ,'D'
      )

--ENABLE TRIGGER [TR_DDL_DB] ON DATABASE



CREATE TABLE [dbo].[TBAuditoriaDDL](
[IDAuditoriaDDL] [int] IDENTITY(1,1) NOT NULL,
	[TipoEvento] [varchar](30) NULL,
	[Login] [varchar](100) NULL,
	[Usuario] [varchar](100) NULL,
	[Banco] [varchar](100) NULL,
	[Comando] [varchar](max) NULL,
	[DataEvento] [datetime] NULL,
	[Evento] [xml] NULL,	
	[NivelAuditoria] [char](1)  NULL,
 CONSTRAINT [PK_AuditoriaDDL] PRIMARY KEY CLUSTERED 
(
	[IDAuditoriaDDL] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[TBAuditoriaDDL]  WITH CHECK ADD  CONSTRAINT [CC_AuditoriaDDL_NivelAudit] CHECK  (([NivelAuditoria]='S' OR [NivelAuditoria]='D'))
ALTER TABLE [dbo].[TBAuditoriaDDL] CHECK CONSTRAINT [CC_AuditoriaDDL_NivelAudit]
ALTER TABLE [dbo].[TBAuditoriaDDL] ADD  DEFAULT (getdate()) FOR [DataEvento]
ALTER TABLE [dbo].[TBAuditoriaDDL] ADD  DEFAULT ('S') FOR [NivelAuditoria]



--alerta os eventos de ROLE SERVER MEMBER o time de DBAS
declare @login varchar(300), @comando varchar(500), @data varchar(16), @assunto varchar(300),
@corpo varchar(500)

--coleta o evento mais novo do dia atual
SELECT top 1 
 @assunto = 'Alerta de Permissão de Role Server Member - Servidor:' +@@servername,
@login  = login,
@comando = comando,
@data = convert(varchar(16), dataevento,20) 
FROM DBA.dbo.TBAuditoriaDDL 
where TipoEvento = 'ADD_SERVER_ROLE_MEMBER' 
and convert(date, dataevento) = convert(date, getdate())
order by DataEvento desc

set @corpo = 'O Login [' +@login + '] concedeu a permissão de Role Server Member abaixo no Servidor:' + @@SERVERNAME +' 
              
		  Comando: '+@comando+'

	    	  Data/Horário: '+@data+'
			  '

exec msdb.dbo.sp_send_dbmail 
@profile_name = 'gmail', --profilename do ambiente
@recipients = 'seu_email@gmail.com', -- grupo de dbas
@subject = @assunto, 
@body = @corpo,
@body_format = 'text'
