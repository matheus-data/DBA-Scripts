IF OBJECT_ID ('tempdb..#ColetaLogInfo') IS NOT NULL DROP TABLE #ColetaLogInfo
IF OBJECT_ID ('tempdb..#LogInfo') IS NOT NULL DROP TABLE #LogInfo


CREATE TABLE #LogInfo (NomeBanco varchar(300),NomeLogicoLOG varchar(300), Qtd_VLFs INT, DataColeta SMALLDATETIME)

EXEC sp_MSforeachdb '
USE [?];


CREATE TABLE #ColetaLogInfo ([FileId] tinyint, [FileSize] bigint,[StartOffset] bigint, [FSeqNo] int,[Status] tinyint,[Parity] tinyint,[CreateLSN] varchar(2000))

INSERT INTO #ColetaLogInfo
EXEC (''DBCC LOGINFO WITH NO_INFOMSGS'')


INSERT INTO #LogInfo  (NomeBanco,Qtd_VLFs)

select db_name() AS NomeBanco, 
       COUNT (*) AS Qtd_VLFs
 from #ColetaLogInfo
 
 update #LogInfo
set NomeLogicoLOG = (select name from sys.master_files where type_desc = ''LOG'' AND database_id = db_id(''?'')), 
    DataColeta = CONVERT(SMALLDATETIME,GETDATE()) 
where NomeBanco = ''?'' 
 
 DROP TABLE #COLETALOGINFO
 
 DELETE FROM #LogInfo where NomeBanco in (''master'',''model'',''msdb'',''DBADMIN'',''tempdb'')  
 '
   
--Faz a coleta dos VLFs de todos os bancos, através do comando DBCC LOGINFO
INSERT INTO DBADMIN.dbo.TB_ColetaLOGINFO
select * from #LogInfo
where Qtd_VLFs > 50
order by NomeBanco

--Corrige

/*
USE DBADMIN
GO

IF OBJECT_ID ('tempdb..#ComandosLOGINFO') IS NOT NULL DROP TABLE #ComandosLOGINFO

CREATE TABLE #ComandosLOGINFO (ID INT IDENTITY, NomeBanco varchar(300), Comando_ShrinkFile nvarchar(1000), Comando_Alter_FILEGROWTH nvarchar(1000))

INSERT INTO #ComandosLOGINFO
SELECT 
      NomeBanco,
       'USE ['+NomeBanco+'] DBCC SHRINKFILE (['+NomeLogicoLOG+ '],1)' AS    Comando_ShrinkFile,
     CASE 
         WHEN Qtd_VLFs > 500 then 'ALTER DATABASE ['+NomeBanco+'] MODIFY FILE (NAME = ['+NomeLogicoLOG+'], SIZE = 2GB ,FILEGROWTH = 2GB);' 
         WHEN Qtd_VLFs <= 500 then 'ALTER DATABASE ['+NomeBanco+'] MODIFY FILE (NAME = ['+NomeLogicoLOG+'],  SIZE = 2GB ,FILEGROWTH = 1GB);' 
         END AS Comando_Alter_FILEGROWTH
   

FROM dbo.TB_ColetaLOGINFO
--Pega somente a coleta de LOG INFO do dia atual
where CONVERT(date,DataColeta) = CONVERT(date, getdate())        
  

DECLARE @CONT INT, @Shrink NVARCHAR(1000), @FileGrowth NVARCHAR(1000)


SET @CONT = 1

WHILE @CONT <= (SELECT MAX(ID) FROM #ComandosLOGINFO)
    
    BEGIN    
  
         
     SELECT  @Shrink=Comando_ShrinkFile FROM #ComandosLOGINFO
     WHERE ID = @CONT     
    
      SELECT  @FileGrowth = Comando_Alter_FILEGROWTH FROM #ComandosLOGINFO
     WHERE ID = @CONT 
     
     
     --Faz o ShrinkLog do arquivo de Log 
     print (@Shrink)
     
     --Altera o FILEGROWTH do banco da vez para evitar crescimentos desnecessários
     print (@FileGrowth)
     
     SET @CONT = @CONT + 1
    
    END






*/
