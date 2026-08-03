USE [master];
GO

CREATE OR ALTER PROCEDURE dbo.SP_LOCKS
AS
BEGIN
    SET NOCOUNT ON;

    /*
        Sessões que estão bloqueadas neste momento.
    */
    ;WITH SessoesBloqueadas AS
    (
        SELECT
            r.session_id             AS blocked_spid,
            r.blocking_session_id    AS blocking_spid
        FROM sys.dm_exec_requests AS r
        WHERE r.blocking_session_id > 0
    ),
    SessoesEnvolvidas AS
    (
        SELECT blocked_spid AS session_id
        FROM SessoesBloqueadas

        UNION

        SELECT blocking_spid
        FROM SessoesBloqueadas
    )
    SELECT
        CASE
            WHEN EXISTS
            (
                SELECT 1
                FROM SessoesBloqueadas AS b
                WHERE b.blocking_spid = s.session_id
            )
            AND r.blocking_session_id > 0
                THEN N'OFENSOR E VÍTIMA'

            WHEN EXISTS
            (
                SELECT 1
                FROM SessoesBloqueadas AS b
                WHERE b.blocking_spid = s.session_id
            )
                THEN N'OFENSOR / SEGURANDO LOCK'

            ELSE N'VÍTIMA / TRAVADO'
        END AS tipo_sessao,

        s.session_id AS spid,

        CASE
            WHEN r.blocking_session_id > 0
                THEN r.blocking_session_id
            ELSE NULL
        END AS blocking_spid,

        CASE
            WHEN r.blocking_session_id > 0
                THEN CONCAT
                (
                    N'SPID ',
                    s.session_id,
                    N' está bloqueado pelo SPID ',
                    r.blocking_session_id
                )
            ELSE CONCAT
                (
                    N'SPID ',
                    s.session_id,
                    N' está bloqueando outras sessões'
                )
        END AS interpretacao,

        s.host_name       AS host_aplicacao,
        s.login_name      AS login_usuario,
        s.program_name    AS programa,

        DB_NAME(r.database_id) AS banco,

        COALESCE(r.status, s.status) AS status,

        r.command,
        r.wait_type,
        r.wait_time       AS wait_time_ms,
        r.wait_resource,

        r.cpu_time        AS cpu_time_ms,
        r.logical_reads,
        r.reads,
        r.writes,

        s.open_transaction_count,

        r.start_time,

        CASE
            WHEN r.start_time IS NOT NULL
                THEN DATEDIFF(SECOND, r.start_time, GETDATE())
        END AS duracao_segundos,

        CASE
            WHEN r.start_time IS NOT NULL
                THEN CONCAT
                (
                    DATEDIFF(SECOND, r.start_time, GETDATE()) / 86400,
                    N'd ',
                    RIGHT
                    (
                        '00' + CONVERT
                        (
                            varchar(2),
                            (
                                DATEDIFF
                                (
                                    SECOND,
                                    r.start_time,
                                    GETDATE()
                                ) % 86400
                            ) / 3600
                        ),
                        2
                    ),
                    N':',
                    RIGHT
                    (
                        '00' + CONVERT
                        (
                            varchar(2),
                            (
                                DATEDIFF
                                (
                                    SECOND,
                                    r.start_time,
                                    GETDATE()
                                ) % 3600
                            ) / 60
                        ),
                        2
                    ),
                    N':',
                    RIGHT
                    (
                        '00' + CONVERT
                        (
                            varchar(2),
                            DATEDIFF
                            (
                                SECOND,
                                r.start_time,
                                GETDATE()
                            ) % 60
                        ),
                        2
                    )
                )
        END AS duracao,

        CASE
            WHEN r.sql_handle IS NOT NULL
                 AND r.statement_start_offset >= 0
            THEN SUBSTRING
            (
                txt.text,
                (r.statement_start_offset / 2) + 1,
                (
                    (
                        CASE
                            WHEN r.statement_end_offset = -1
                                THEN DATALENGTH(txt.text)
                            ELSE r.statement_end_offset
                        END
                        - r.statement_start_offset
                    ) / 2
                ) + 1
            )
            ELSE txt.text
        END AS comando_sql_executando,

        txt.text AS comando_sql_completo

    FROM SessoesEnvolvidas AS e

    INNER JOIN sys.dm_exec_sessions AS s
        ON s.session_id = e.session_id

    LEFT JOIN sys.dm_exec_requests AS r
        ON r.session_id = s.session_id

    LEFT JOIN sys.dm_exec_connections AS c
        ON c.session_id = s.session_id

    OUTER APPLY sys.dm_exec_sql_text
    (
        COALESCE(r.sql_handle, c.most_recent_sql_handle)
    ) AS txt

    ORDER BY
        CASE
            WHEN EXISTS
            (
                SELECT 1
                FROM SessoesBloqueadas AS b
                WHERE b.blocking_spid = s.session_id
            )
                THEN 0
            ELSE 1
        END,
        r.blocking_session_id,
        s.session_id;
END;
GO
