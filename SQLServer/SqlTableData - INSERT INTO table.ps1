# select data from one DB and insert into another -> it creates the new table DatabaseSizeHistory (INSERT INTO) as the output for the SELECT

Invoke-Sqlcmd -ServerInstance . -Database master -OutputAs DataTables -Query "
SELECT @@ServerName AS 'ServerName'
            , DB_NAME(dbid) AS 'DatabaseName'
            , name AS 'LogicalName'
            , GETDATE() AS 'CheckDate'
            , CONVERT(BIGINT, size) * 8 AS 'SizeInKB'
            , filename AS 'DBFileName'
            , SYSDATETIMEOFFSET() 'DiscoveryOccured'
  FROM master..sysaltfiles
 WHERE dbid != 32767" | Write-SqlTableData -ServerInstance . -DatabaseName test4 -SchemaName dbo -TableName DatabaseSizeHistory -Force;