EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

EXEC sp_configure 'blocked process threshold (s)', 15;
RECONFIGURE;
GO

IF EXISTS
(
    SELECT 1
    FROM sys.server_event_sessions
    WHERE name = N'XE_Troubleshooting_CPU_Blocking_Deadlock'
)
BEGIN
    DROP EVENT SESSION [XE_Troubleshooting_CPU_Blocking_Deadlock]
    ON SERVER;
END
GO

CREATE EVENT SESSION [XE_Troubleshooting_CPU_Blocking_Deadlock]
ON SERVER

ADD EVENT sqlserver.rpc_completed
(
    ACTION
    (
        sqlserver.database_name,
        sqlserver.server_principal_name,
        sqlserver.username,
        sqlserver.client_hostname,
        sqlserver.client_app_name,
        sqlserver.session_id,
        sqlserver.sql_text,
        sqlserver.query_hash,
        sqlserver.query_plan_hash,
        sqlserver.plan_handle
    )
    WHERE
    (
        duration >= 5000000     
        OR cpu_time >= 5000000   
        OR logical_reads >= 100000
        OR writes >= 10000
    )
),

ADD EVENT sqlserver.sql_batch_completed
(
    ACTION
    (
        sqlserver.database_name,
        sqlserver.server_principal_name,
        sqlserver.username,
        sqlserver.client_hostname,
        sqlserver.client_app_name,
        sqlserver.session_id,
        sqlserver.sql_text,
        sqlserver.query_hash,
        sqlserver.query_plan_hash,
        sqlserver.plan_handle
    )
    WHERE
    (
        duration >= 5000000
        OR cpu_time >= 1000000
        OR logical_reads >= 100000
        OR writes >= 10000
    )
),

ADD EVENT sqlserver.blocked_process_report
(
    ACTION
    (
        sqlserver.database_name,
        sqlserver.server_principal_name,
        sqlserver.username,
        sqlserver.client_hostname,
        sqlserver.client_app_name,
        sqlserver.session_id,
        sqlserver.sql_text
    )
),

ADD EVENT sqlserver.xml_deadlock_report

ADD TARGET package0.event_file
(
    SET filename = N'E:\Testes\Extended Events\XE_Troubleshooting_CPU_Blocking_Deadlock.xel',
        max_file_size = 100,
        max_rollover_files = 10
)
WITH
(
    MAX_MEMORY = 4096 KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 30 SECONDS,
    MAX_EVENT_SIZE = 0 KB,
    MEMORY_PARTITION_MODE = NONE,
    TRACK_CAUSALITY = ON,
    STARTUP_STATE = ON
);
GO


/****************************
	Iniciar a sessão 
****************************/
ALTER EVENT SESSION [XE_Troubleshooting_CPU_Blocking_Deadlock]
ON SERVER
STATE = START;
GO

-- Confirmar:
SELECT *
FROM sys.dm_xe_sessions;





/***********************************************
	Para ler os eventos depois do alerta:
***********************************************/
-- Query ofensora de CPU
WITH x AS
(
    SELECT CAST(event_data AS XML) AS event_xml
    FROM sys.fn_xe_file_target_read_file
    (
        N'E:\Testes\Extended Events\XE_Troubleshooting_CPU_Blocking_Deadlock*.xel',
        NULL, NULL, NULL
    )
)
SELECT
    event_xml.value('(/event/@name)[1]', 'varchar(100)') AS event_name,
    DATEADD(HOUR, -3, event_xml.value('(/event/@timestamp)[1]', 'datetime2')) AS local_time_brt,
    event_xml.value('(/event/action[@name="database_name"]/value)[1]', 'sysname') AS database_name,
    event_xml.value('(/event/action[@name="server_principal_name"]/value)[1]', 'sysname') AS login_name,
    event_xml.value('(/event/action[@name="client_hostname"]/value)[1]', 'nvarchar(256)') AS host_name,
    event_xml.value('(/event/action[@name="client_app_name"]/value)[1]', 'nvarchar(256)') AS application_name,
    event_xml.value('(/event/action[@name="session_id"]/value)[1]', 'int') AS session_id,
    event_xml.value('(/event/data[@name="duration"]/value)[1]', 'bigint') / 1000 AS duration_ms,
    event_xml.value('(/event/data[@name="cpu_time"]/value)[1]', 'bigint') / 1000 AS cpu_ms,
    event_xml.value('(/event/data[@name="logical_reads"]/value)[1]', 'bigint') AS logical_reads,
    event_xml.value('(/event/data[@name="writes"]/value)[1]', 'bigint') AS writes,
    event_xml.value('(/event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS sql_text
FROM x
WHERE event_xml.value('(/event/@name)[1]', 'varchar(100)')
      IN ('sql_batch_completed', 'rpc_completed')
ORDER BY cpu_ms DESC, duration_ms DESC;


/************************************************************************************************************************************/

-- Eventos de blocking
WITH x AS
(
    SELECT CAST(event_data AS XML) AS event_xml
    FROM sys.fn_xe_file_target_read_file
    (
        N'E:\Testes\Extended Events\XE_Troubleshooting_CPU_Blocking_Deadlock*.xel',
        NULL, NULL, NULL
    )
)
SELECT
    DATEADD(HOUR, -3, event_xml.value('(/event/@timestamp)[1]', 'datetime2')) AS local_time_brt,

    event_xml.value('(/event/data[@name="duration"]/value)[1]', 'bigint') / 1000 AS blocked_duration_ms,

    event_xml.value(
        '(/event/data[@name="blocked_process"]/value/blocked-process-report/blocked-process/process/@spid)[1]',
        'int'
    ) AS blocked_spid,

    event_xml.value(
        '(/event/data[@name="blocked_process"]/value/blocked-process-report/blocking-process/process/@spid)[1]',
        'int'
    ) AS blocking_spid,

    event_xml.value(
        '(/event/data[@name="blocked_process"]/value/blocked-process-report/blocked-process/process/inputbuf)[1]',
        'nvarchar(max)'
    ) AS blocked_sql_text,

    event_xml.value(
        '(/event/data[@name="blocked_process"]/value/blocked-process-report/blocking-process/process/inputbuf)[1]',
        'nvarchar(max)'
    ) AS blocking_sql_text,

    event_xml AS raw_event_xml
FROM x
WHERE event_xml.value('(/event/@name)[1]', 'varchar(100)') = 'blocked_process_report'
ORDER BY blocked_duration_ms DESC;




/************************************************************
	blocked_spid  = quem está travado / vítima
	blocking_spid = quem está segurando o lock / ofensor
************************************************************/
