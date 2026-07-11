if object_id ('tempdb..#free_space') is not null
begin
drop table #free_space
end 

create table #free_space
(db varchar(300),
  FileName varchar(300),
 size_free_gb decimal(18,2),
  Letter char(5),
  comando varchar(1000))


exec sp_MSforeachdb

'use [?]
insert into #free_space
SELECT DB_NAME() AS DbName, 
    name AS FileName,  
    CONVERT(DECIMAL(10,2),size/128.0/1024 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0/1024) AS FreeSpaceGB,
	left(physical_name,3) as Letter,
	''USE ['' +  DB_NAME() + ''] dbcc shrinkfile ([''+NAME+''],1)'' as comando
	FROM sys.database_files
WHERE type IN (1)'

select * from #free_space
order by size_free_gb desc
