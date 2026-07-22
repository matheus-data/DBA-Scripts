SELECT  [text], cp.size_in_bytes,plan_handle,usecounts
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle)
WHERE cp.cacheobjtype = N'Compiled Plan'
AND cp.objtype = N'Adhoc'

ORDER BY cp.size_in_bytes DESC;


