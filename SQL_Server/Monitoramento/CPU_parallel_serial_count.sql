USE [DBADMIN]
GO

create view [dbo].[vw_session_cpu]

as

with cte_cpu as 
(
SELECT
    
   count(distinct  s.cpu_id) as qtd_cpu,

    t.session_id

  
FROM  sys.dm_os_Schedulers s 
JOIN sys.dm_os_workers w 
    ON w.scheduler_address = s.scheduler_address
JOIN sys.dm_os_tasks t 
    ON t.task_address = w.task_address   
where     t.session_id is not null
and t.session_id > 50
group by  
    t.session_id
	)

select  
DATEDIFF (minute,last_request_end_time, getdate()) as minutes_running,
qtd_cpu,
t1.session_id as spid,
t5.blocking_session_id,
t5.percent_complete,
host_name as  Host, 
login_name  as Login,
Program_name as Program,
text as SQLStatement
from sys.dm_exec_sessions t1
JOIN sys.dm_exec_connections t2 on t1.session_id = t2.session_id
CROSS APPLY sys.dm_exec_sql_text(t2.most_recent_sql_handle) AS t3
JOIN cte_cpu t4 on t1.session_id = t4.session_id
join sys.dm_exec_requests t5 on t1.session_id = t5.session_id
GO


