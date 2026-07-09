RESTORE FILELISTONLY 
FROM DISK = 'E:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\ITG_MODULOS_DATA.bak';



/**********************************************************/
drop table if exists #t
 
create table #t
(name varchar(300),
fileid int,
filename varchar(300),
filegroup varchar(300),
size  varchar(300),
maxsize  varchar(300),
growth varchar(300),
usage  varchar(300))
 
insert into #t
exec sp_helpfile
 
select 
'MOVE '''+ name + ''' TO ''' +filename + ''',' +CHAR(13)
 
from #t

/**********************************************************/

--filelistonly
DROP TABLE IF EXISTS #filelist
CREATE TABLE #filelist (
    LogicalName NVARCHAR(128),
    PhysicalName NVARCHAR(260),
    Type CHAR(1),
    FileGroupName NVARCHAR(128),
    Size BIGINT,
    MaxSize BIGINT,
    FileId INT,
    CreateLSN NUMERIC(25,0),
    DropLSN NUMERIC(25,0),
    UniqueId UNIQUEIDENTIFIER,
    ReadOnlyLSN NUMERIC(25,0),
    ReadWriteLSN NUMERIC(25,0),
    BackupSizeInBytes BIGINT,
    SourceBlockSize INT,
    FileGroupId INT,
    LogGroupGUID UNIQUEIDENTIFIER,
    DifferentialBaseLSN NUMERIC(25,0),
    DifferentialBaseGUID UNIQUEIDENTIFIER,
    IsReadOnly BIT,
    IsPresent BIT,
    TDEThumbprint VARBINARY(32),
    SnapshotUrl NVARCHAR(MAX)
);

INSERT INTO #filelist
EXEC ('RESTORE FILELISTONLY
FROM DISK =''\\vpwbkpbd01\SQL_SERVER\HOMOLOGACAO\CPRODWEB5_01.bak'',
	DISK =''\\vpwbkpbd01\SQL_SERVER\HOMOLOGACAO\CPRODWEB5_02.bak'',
	DISK =''\\vpwbkpbd01\SQL_SERVER\HOMOLOGACAO\CPRODWEB5_03.bak'',
	DISK =''\\vpwbkpbd01\SQL_SERVER\HOMOLOGACAO\CPRODWEB5_04.bak'',
	DISK =''\\vpwbkpbd01\SQL_SERVER\HOMOLOGACAO\CPRODWEB5_05.bak'',
	DISK =''\\vpwbkpbd01\SQL_SERVER\HOMOLOGACAO\CPRODWEB5_06.bak'',
	DISK =''\\vpwbkpbd01\SQL_SERVER\HOMOLOGACAO\CPRODWEB5_07.bak'',
	DISK =''\\vpwbkpbd01\SQL_SERVER\HOMOLOGACAO\CPRODWEB5_08.bak'',
	DISK =''\\vpwbkpbd01\SQL_SERVER\HOMOLOGACAO\CPRODWEB5_09.bak'',
	DISK =''\\vpwbkpbd01\SQL_SERVER\HOMOLOGACAO\CPRODWEB5_10.bak''')


select 
'MOVE '''+ LogicalName + ''' TO ''' +PhysicalName + ''',' +CHAR(13)

from #filelist



-- Gerar permissão 
exec master.dbo.SP_GeraPermissoesPorBanco 'ITG_MODULOS'
