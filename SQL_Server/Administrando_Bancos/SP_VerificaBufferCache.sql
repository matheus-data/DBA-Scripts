USE [DBADMIN]
GO
/*  
--Modelos de Execução  
EXEC DBADMIN.dbo.SP_VerificaBufferCache --Retorna os Top Databases que estão usando o Buffer Cache  
  
EXEC DBADMIN.dbo.SP_VerificaBufferCache 'NomeBanco' --Retorna as Top Tables do Banco Especificado que estão usando o Buffer Cache  
*/  
CREATE PROCEDURE [dbo].[SP_VerificaBufferCache]   
 
   @NomeBanco varchar(300) = NULL
  
   AS  
     SET NOCOUNT ON  
        
     IF OBJECT_ID ('tempdb..#dm_os_buffer_descriptors') IS NOT NULL       DROP TABLE #dm_os_buffer_descriptors     
     IF OBJECT_ID ('tempdb..#QTDPaginasBufferCachePorBanco') IS NOT NULL  DROP TABLE #QTDPaginasBufferCachePorBanco  
  
     CREATE TABLE #QTDPaginasBufferCachePorBanco  
     (NomeBanco VARCHAR(300),NomeObjeto VARCHAR(500),QTDPaginasEmCacheObjeto INT,ComandoSPSpaceUsed NVARCHAR(1000))  
  
       --Carrega a tabela temporária #dm_os_buffer_descriptors  
       SELECT  *   
       INTO #dm_os_buffer_descriptors  
       FROM sys.dm_os_buffer_descriptors  
  
         
       IF @NomeBanco IS NULL    
           
         BEGIN  
        --Top Databases pela Qtd de páginas  no buffer cache.        
        SELECT NomeBanco,
               QTDPaginasEmCacheDB, 
               CASE WHEN (QTDPaginasEmCacheDB * 8)/1024 = 0 THEN CONVERT(VARCHAR(30),(QTDPaginasEmCacheDB * 8)) + ' KB' 
                    WHEN (QTDPaginasEmCacheDB * 8)/1024/1024 = 0 THEN CONVERT(VARCHAR(30),((QTDPaginasEmCacheDB * 8)/1024)) + ' MB'                   
                    ELSE CONVERT(VARCHAR(30),((QTDPaginasEmCacheDB * 8)/1024/1024)) + ' GB'  
                END AS TamanhoBufferCacheDB, 
                CONVERT(DECIMAL(10,4),CONVERT(decimal(10,2),QTDPaginasEmCacheDB) * 100.00 /(SELECT CONVERT(decimal(10,2),COUNT(*)) FROM #dm_os_buffer_descriptors)) AS [PorcentagemUso], 
                CASE WHEN ((SELECT COUNT(*)  FROM #dm_os_buffer_descriptors) * 8)/1024 = 0 THEN CONVERT(VARCHAR(30),((SELECT COUNT(*)  FROM #dm_os_buffer_descriptors) * 8)) + ' KB' 
                    WHEN ((SELECT COUNT(*)  FROM #dm_os_buffer_descriptors) * 8)/1024/1024 = 0 THEN CONVERT(VARCHAR(30),(((SELECT COUNT(*)  FROM #dm_os_buffer_descriptors) * 8)/1024)) + ' MB'                   
                    ELSE CONVERT(VARCHAR(30),(((SELECT COUNT(*)  FROM #dm_os_buffer_descriptors) * 8)/1024/1024)) + ' GB'  
                END AS TamanhoTotalBufferCache
                     
  
               
         FROM ( 
        SELECT DB_NAME(database_id) as NomeBanco,   
               COUNT(*)AS QTDPaginasEmCacheDB
                FROM #dm_os_buffer_descriptors  
        GROUP BY DB_NAME(database_id) ) AS Top_DB  
          
        ORDER BY QTDPaginasEmCacheDB DESC;        
         END  
           
           
         IF @NomeBanco IS NOT NULL  
           
         BEGIN   

         DECLARE @Exec nvarchar(MAX) =  
         --Qtd Páginas por Objeto e Banco  
         ' USE '+@NomeBanco+'  
           
           INSERT INTO #QTDPaginasBufferCachePorBanco  
           SELECT   
                 db_name(database_id) as NomeBanco,  
                 name as NomeObjeto,  
                 COUNT(*) AS QTDPaginasEmCacheObjeto,  
                 ''EXEC '+@NomeBanco+'.dbo.sp_spaceused ''+name+''    '' As ComandoSPSpaceUsed    
            FROM #dm_os_buffer_descriptors AS bd   
           INNER JOIN     (SELECT object_name(object_id) AS name,  
                                  index_id,  
                                  allocation_unit_id  
                           FROM '+@NomeBanco+'.sys.allocation_units AS au  
                          INNER JOIN '+@NomeBanco+'.sys.partitions AS p ON au.container_id = p.hobt_id AND (au.type = 1 OR au.type = 3)  
             UNION ALL  
              
            SELECT   
                  object_name(object_id) AS name,  
                  index_id,   
                  allocation_unit_id  
            FROM '+@NomeBanco+'.sys.allocation_units AS au  
            INNER JOIN '+@NomeBanco+'.sys.partitions AS p ON au.container_id = p.partition_id AND au.type = 2 ) AS obj ON bd.allocation_unit_id = obj.allocation_unit_id  
            WHERE database_id = DB_ID('''+@NomeBanco+''')  
            GROUP BY name, db_name(database_id)  
            ORDER BY QTDPaginasEmCacheObjeto DESC'  
              
            --Insere na tabela temporária #QTDPaginasBufferCachePorBanco  
           EXEC (@Exec)     
      
             
           --Qtd de Páginas no Buffer Cache por Objeto de um Banco  
           SELECT t1.NomeBanco,
                  t1.NomeObjeto,
                  QTDPaginasEmCacheObjeto,
                  CASE WHEN (QTDPaginasEmCacheObjeto * 8)/1024 = 0 THEN CONVERT(VARCHAR(30),(QTDPaginasEmCacheObjeto * 8)) + ' KB' 
                    WHEN (QTDPaginasEmCacheObjeto * 8)/1024/1024 = 0 THEN CONVERT(VARCHAR(30),((QTDPaginasEmCacheObjeto * 8)/1024)) + ' MB'                   
                    ELSE CONVERT(VARCHAR(30),((QTDPaginasEmCacheObjeto * 8)/1024/1024)) + ' GB'  
                  END AS TamanhoBufferCacheObjeto,
                  CASE WHEN (QTDPaginasEmCacheDB * 8)/1024 = 0 THEN CONVERT(VARCHAR(30),(QTDPaginasEmCacheDB * 8)) + ' KB' 
                    WHEN (QTDPaginasEmCacheDB * 8)/1024/1024 = 0 THEN CONVERT(VARCHAR(30),((QTDPaginasEmCacheDB * 8)/1024)) + ' MB'                   
                    ELSE CONVERT(VARCHAR(30),((QTDPaginasEmCacheDB * 8)/1024/1024)) + ' GB'  
                  END AS TamanhoBufferCacheDB, 
                  convert(decimal(10,4),convert(decimal(10,2),QTDPaginasEmCacheObjeto) * 100.00 / CONVERT(decimal(10,2),QTDPaginasEmCacheDB))  AS [PorcentagemUso] , 
                  t1.ComandoSPSpaceUsed
                  
           FROM  #QTDPaginasBufferCachePorBanco t1
           inner join (SELECT DB_NAME(database_id) as NomeBanco,   
                              COUNT(*)AS QTDPaginasEmCacheDB
                       FROM #dm_os_buffer_descriptors  
                       --Aqui é filtrado o banco da tabela temporária #dm_os_buffer_descriptors
                       WHERE DB_NAME(database_id) = @NomeBanco 
                       GROUP BY DB_NAME(database_id)) t2 on t1.NomeBanco = t2.NomeBanco 
          
           ORDER BY QTDPaginasEmCacheObjeto DESC  
                    
         END
