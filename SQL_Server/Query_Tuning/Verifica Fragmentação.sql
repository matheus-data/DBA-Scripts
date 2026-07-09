use master
GO
CREATE PROCEDURE dbo.USP_VerificaFragmentacao 

/*Modelo de Execução*/
--EXEC dbo.USP_VerificaFragmentacao 'BANCO','NOME_OBJETO','DETAILED'


--Nome do Banco a ser pesquisado, parâmetro obrigatório
@NomeBanco VARCHAR(300),
--Nome do Objeto a ser pesquisado, parâmetro opcional
@NomeObjeto VARCHAR(500) = NULL,
--Último Parâmetro "DETAILED" da Function Dinânima sys.dm_db_index_physical_stats, parâmetro opcional
@Detailed CHAR(8) = NULL 

AS

BEGIN 

declare  @exec nvarchar(max)

IF OBJECT_ID ('tempdb..#Fragmentacao') IS NOT NULL
    BEGIN
    DROP TABLE #Fragmentacao
	END

CREATE TABLE #Fragmentacao (NomeBanco varchar(300),EsquemaObjeto varchar(100), NomeObjeto varchar(500),NomeIndice varchar(300), TipoIndice varchar(300),
                            MediaFragmentacao decimal(18,2),QtdPaginas BIGINT, QtdRegistrosIndice BIGINT, Fill_Factor BIGINT,ComandoRebuild NVARCHAR(1000))


SELECT @exec =
N'USE '+@NomeBanco+'

INSERT INTO #Fragmentacao
select 
      db_name(database_id) as NomeBanco, 
	  OBJECT_SCHEMA_NAME (I.object_id) as EsquemaObjeto,
      object_name(i.object_id) as NomeObjeto, 
	  i.name as NomeIndice,
	  index_type_desc as TipoIndice,
      avg_fragmentation_in_percent as MediaFragmentacao,
	  page_count as QtdPaginas, 
	  p."rows" as QtdRegistrosIndice,
	  i.fill_factor as Fill_Factor,
	  CASE WHEN index_type_desc = ''HEAP'' THEN ''ALTER TABLE ''+OBJECT_SCHEMA_NAME (I.object_id) + ''.''+ (object_name(I.object_id)) + '' REBUILD ''
	       ELSE ''ALTER INDEX ''+i.name + '' ON ''+ OBJECT_SCHEMA_NAME (I.object_id) + ''.''+ (object_name(I.object_id)) +'' REBUILD WITH (ONLINE = ON)'' 
	  END AS ComandoRebuild

	  FROM '+@NomeBanco+'.sys.dm_db_index_physical_stats (db_id('''+@NomeBanco+'''), '
	                                                      +case when @NomeObjeto is null then 'NULL' ELSE 'object_id('''+@NomeObjeto+''')'END  +',NULL,NULL,'
	                                                      +case when @Detailed is null then 'NULL' ELSE '''DETAILED'''END+')  dmi
inner join '+@NomeBanco+'.sys.indexes i on i.index_id = dmi.index_id and i.object_id = dmi.object_id
inner join '+@NomeBanco+'.sys.partitions p on p.index_id = dmi.index_id and p.object_id = dmi.object_id
WHERE page_count > 1000 and  avg_fragmentation_in_percent > 10'

--Insere as informações na tabela temporária #Fragmentacao
EXEC (@EXEC)

SELECT * FROM #Fragmentacao
ORDER BY MediaFragmentacao DESC

END
