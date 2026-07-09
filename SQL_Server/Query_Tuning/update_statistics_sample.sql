USE AdventureWorks2025;
GO

SELECT
    SchemaName = SCHEMA_NAME(t.schema_id),
    TableName = t.name,
    StatsName = s.name,
    StatsLastUpdated = sp.last_updated,
    RowsOnLastStatsUpdate = sp.rows,
    RowsModifiedSinceLastUpdate = sp.modification_counter,
    PercentModified =
        CAST(
            sp.modification_counter * 100.0 / NULLIF(sp.rows, 0)
            AS DECIMAL(10,2)
        ),
    StatsType =
        CASE
            WHEN s.auto_created = 1 THEN 'Auto Created'
            WHEN s.user_created = 1 THEN 'User Created'
            ELSE 'Index Statistics'
        END,
    UpdateCommand =
        'UPDATE STATISTICS '
        + QUOTENAME(SCHEMA_NAME(t.schema_id))
        + '.'
        + QUOTENAME(t.name)
        + ' '
        + QUOTENAME(s.name)
        + ' WITH SAMPLE 20 PERCENT, MAXDOP = 4;'
FROM sys.tables t
JOIN sys.stats s
    ON s.object_id = t.object_id
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) sp
WHERE sp.modification_counter > 1000
ORDER BY PercentModified DESC;
