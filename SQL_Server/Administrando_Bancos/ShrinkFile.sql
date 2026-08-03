select DB_NAME(database_id) as banco,
       name, 
       convert(decimal(18,2),convert(decimal(18,2),size*8)/1024/1024) as tamanho,
       'use '+ DB_NAME(database_id)+ ' DBCC SHRINKFILE (['+name+ '],1)' AS "DBCC"
       
      from sys.master_files
where type_desc = 'log' and database_id > 4
AND database_id  IN (select database_id from sys.databases where state_desc = 'online')
order by tamanho desc
