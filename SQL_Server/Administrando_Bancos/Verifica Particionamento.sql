SELECT 
	OBJECT_NAME(P.object_id)   AS ObjectName
,	P.partition_number         AS PartitionNumber
,	FG.name                    AS FGName
,	P.rows                     AS [Rows]
,	(f.size * 8) / 1024        AS SizeMB
,	AU.used_pages              AS UsedPages
,	F.filename                 AS [FileName]
--,	P.data_compression_desc    AS [Compression]
,	AU.type_desc               AS TypeDesc
,	S.name                     AS PartitionSchemeName
,	PF.name                    AS PartitionFunctionName
,	PF.boundary_value_on_right AS IsRightBoundary
,	R.value                    AS BoundaryValue


FROM 
			sys.tables AS T  
INNER JOIN	sys.indexes AS i  
				ON T.object_id = I.object_id  
INNER JOIN	sys.partitions AS P 
				ON i.object_id = p.object_id AND i.index_id = p.index_id   
INNER JOIN	sys.system_internals_allocation_units AS AU
				ON P.partition_id = AU.container_id
INNER JOIN	sys.filegroups AS FG
				ON AU.filegroup_id = FG.data_space_id 
INNER JOIN	sys.sysfiles AS F
				ON FG.data_space_id = F.groupid
INNER JOIN  sys.partition_schemes AS S   
				ON I.data_space_id = S.data_space_id  
INNER JOIN	sys.partition_functions AS PF   
				ON S.function_id = PF.function_id  
LEFT JOIN	sys.partition_range_values AS R
				ON PF.function_id = R.function_id 
				and R.boundary_id = P.partition_number  
WHERE 
	P.object_id = object_id('tabela específica')
AND I.type <= 1
