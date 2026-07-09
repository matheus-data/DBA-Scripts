USE master
GO

SELECT Db_Name(dbid) AS Banco,
       Spid,
       Status,
       hostname AS Maquina,
       cmd,
       loginame AS Usuario
FROM master.dbo.sysProcesses
WHERE open_tran = 1
