SELECT
    DB_NAME(dbid) AS Banco,
    spid,
    status,
    hostname AS Maquina,
    cmd,
    loginame AS Usuario
FROM master.dbo.sysprocesses
WHERE open_tran = 1;
