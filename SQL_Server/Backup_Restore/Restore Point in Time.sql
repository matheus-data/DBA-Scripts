
--Backups Full
SELECT 
'RESTORE DATABASE ['+database_name+'] FROM DISK ='''+physical_device_name+ ''' with norecovery,replace,stats' as cmd,
backup_finish_date,B.backup_set_id

FROM msdb.dbo.backupset b
    JOIN msdb.dbo.backupmediafamily m 
    ON b.media_set_id = m.media_set_id
where 
--convert(date,backup_finish_date) < '2014-03-25' AND
 database_name = 'SITARWEB'  AND type = 'D' 
--Elimina os Backups Copy_only
and is_copy_only = 0
ORDER BY backup_finish_date DESC

--Pega os Logs

/* STOPAT ='2014-03-25 00:00'*/
SELECT  
'RESTORE log ['+database_name+ '] from disk ='''+ replace(physical_device_name,'V:\BACKUP\BACKUP_MSSQL\LOG\','\\anatelbackup\BACKUP_SQLSERVER\CRUZADO\LOG\')+ /*+physical_device_name+*/''' with file='+convert(varchar(30),position)+',norecovery,stats' as cmd,
b.backup_set_id ,
b.position,
backup_finish_date

FROM msdb.dbo.backupset b
    JOIN msdb.dbo.backupmediafamily m 
    ON b.media_set_id = m.media_set_id
WHERE b.backup_set_id>(5011) and b.backup_set_id<(5020) /*O próximo backup, caso seja o último não precisa*/

AND database_name = 'SITARWEB'  
AND type = 'L' 


ORDER BY b.backup_set_id 


/*
Esse tipo de backup de LOG gera os LSNs no mesmo arquivo TRN


 'BACKUP LOG SITARWEB TO DISK = ''v:\BACKUP\BACKUP_MSSQL\LOG\SITARWEB-2014-03-28.TRN'' 
 WITH NAME = ''Backup do Log ' + CONVERT (VARCHAR(30), GETDATE(),103) + ''',DESCRIPTION=''Backup LOG ' + CONVERT (VARCHAR(30), GETDATE(),120) + ''', COMPRESSION'   

BACKUP LOG SITARWEB TO DISK = 'V:\BACKUP\BACKUP_MSSQL\LOG\SITARWEB-2014-03-28.TRN' WITH NAME = 'Backup do Log 28/03/2014',DESCRIPTION='Backup LOG 2014-03-28 08:42:15', COMPRESSION
*/


/*

IF OBJECT_ID ('TEMPDB..#FILELISTONLY') IS NOT NULL DROP TABLE #FILELISTONLY

CREATE TABLE #FILELISTONLY (LogicalName nvarchar(1000),PhysicalName nvarchar(1000) ,Type char(1) 
,FileGroupName nvarchar(128) ,Size numeric(20,0) ,MaxSize numeric(20,0),Fileid tinyint,
CreateLSN numeric(25,0),DropLSN numeric(25, 0),UniqueID uniqueidentifier,
ReadOnlyLSN numeric(25,0),ReadWriteLSN numeric(25,0),BackupSizeInBytes bigint,
SourceBlocSize int,FileGroupId int,LogGroupGUID uniqueidentifier,
DifferentialBaseLSN numeric(25,0),DifferentialBaseGUID uniqueidentifier,IsReadOnly bit,
IsPresent bit,TDEThumbprint varchar(100) )

DECLARE @CAMINHO VARCHAR(1000) = '\\CRUZADO\X$\BACKUP\BACKUP_MSSQL\FULL\SITARWEB_DB_2014-03-22_01-16-13.BAK'


INSERT INTO #FILELISTONLY 
EXEC ('RESTORE FILELISTONLY FROM DISK = '''+@caminho+'''')


SELECT 'move '''+LogicalName + ''' to ''D:\DBA\DATA\'+substring (PhysicalName,charindex('MSSQLFiles\',PhysicalName)+11,LEN(PhysicalName)) + ''','
 FROM #FILELISTONLY




*/
