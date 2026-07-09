USE [DBADMIN]
GO

CREATE VIEW [dbo].[VW_TopQueryStats]  
AS  
SELECT   
          
       DB_NAME(t.dbid) as NomeBanco,  
       t.text as InstrucaoSQLTotal,
       substring(t.text,(qs.statement_start_offset+2)/2 ,(case when qs.statement_end_offset = -1 then len(convert(nvarchar(MAX),t.text))*2 else qs.statement_end_offset end - qs.statement_start_offset)/2 )as InstrucaoSQLProblematica,
       p.query_plan as PlanoDeExecucao,  
       qs.creation_time as TempoPlanoCompilado,  
       qs.last_execution_time AS TempoUltimaExecucacaoPlano,  
       qs.execution_count AS QTDExecucaoPlano,  
       qs.total_worker_time AS TotalTempoCPU, 
       qs.total_logical_reads AS TotalLeiturasLogicas, 
      (qs.total_logical_reads/128)/qs.execution_count as MediaLeiturasMB,
       qs.total_logical_reads/128 as TotalLeiturasMB, 
       qs.total_logical_writes AS TotalEscritasLogicas,
       qs.total_physical_reads AS TotalLeiturasFisicas,        
       qs.total_rows AS TotalLinhasConsulta  
  
FROM sys.dm_exec_query_stats qs  
CROSS APPLY sys.dm_exec_sql_text (qs.sql_handle) t  
CROSS APPLY sys.dm_exec_query_plan (qs.plan_handle) p
