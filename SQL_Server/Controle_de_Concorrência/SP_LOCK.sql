USE [master];
GO

CREATE OR ALTER PROCEDURE dbo.SP_LOCKS
AS
BEGIN
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS #mon_whoisactive;

    CREATE TABLE #mon_whoisactive
    (
        [dd_hh_mm_ss_mss]      varchar(8000) NULL,
        [blocked_spid]         smallint NULL,
        [blocking_spid]        smallint NULL,
        [sql_text]             xml NULL,
        [sql_command]          xml NULL,
        [login_name]           varchar(300) NULL,
        [host_name]            varchar(300) NULL,
        [program_name]         varchar(300) NULL,
        [database_name]        varchar(300) NULL,
        [status]               varchar(30) NULL,
        [wait_info]            varchar(4000) NULL,
        [CPU]                  varchar(30) NULL,
        [reads]                varchar(30) NULL,
        [writes]               varchar(30) NULL
    );

    EXEC master.dbo.sp_WhoIsActive
        @get_outer_command = 1,
        @get_full_inner_text = 1,
        @output_column_list =
        '[dd%][session_id][blocking_session_id][sql_text][sql_command][login_name][host_name][program_name][database_name][status][wait_info][CPU][reads][writes]',
        @destination_table = '#mon_whoisactive';

    SELECT
        CASE 
            WHEN blocking_spid IS NULL THEN 'OFENSOR / SEGURANDO LOCK'
            ELSE 'VÍTIMA / TRAVADO'
        END AS tipo_sessao,

        blocked_spid,
        blocking_spid,

        CASE 
            WHEN blocking_spid IS NOT NULL 
                THEN CONCAT('SPID ', blocked_spid, ' está travado pelo SPID ', blocking_spid)
            ELSE CONCAT('SPID ', blocked_spid, ' está segurando lock')
        END AS interpretacao,

        host_name       AS host_aplicacao,
        login_name      AS login_usuario,
        program_name    AS programa,
        database_name   AS banco,
        status,
        wait_info,
        CPU,
        reads,
        writes,
        dd_hh_mm_ss_mss AS duracao,

        sql_text        AS comando_sql_executando,
        sql_command     AS comando_sql_completo

    FROM #mon_whoisactive
    WHERE 
        blocking_spid IS NOT NULL
        OR blocked_spid IN
        (
            SELECT DISTINCT blocking_spid
            FROM #mon_whoisactive
            WHERE blocking_spid IS NOT NULL
        )
    ORDER BY
        CASE WHEN blocking_spid IS NULL THEN 0 ELSE 1 END,
        blocking_spid,
        blocked_spid;
END;
GO
