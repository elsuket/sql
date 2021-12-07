/*
SELECT		D.name AS database_name
		, MF.name
		, MF.physical_name
		, VFS.io_stall_read_ms / CASE VFS.num_of_reads WHEN 0 THEN 1 ELSE VFS.num_of_reads END AS avg_read_latency_ms
		, VFS.io_stall_write_ms / CASE VFS.num_of_writes WHEN 0 THEN 1 ELSE VFS.num_of_writes END AS avg_write_latency_ms
		, VFS.io_stall / CASE VFS.io_stall_read_ms + VFS.io_stall_write_ms WHEN 0 THEN 1 ELSE VFS.io_stall_read_ms + VFS.io_stall_write_ms END AS avg_total_latency_ms
		, VFS.num_of_bytes_read / CASE VFS.num_of_reads WHEN 0 THEN 1 ELSE VFS.num_of_reads END AS avg_bytes_per_read
		, VFS.num_of_bytes_written / CASE VFS.num_of_writes WHEN 0 THEN 1 ELSE VFS.num_of_writes END AS avg_bytes_per_write
		, VFS.io_stall_read_ms
		, VFS.io_stall_write_ms
		, VFS.num_of_reads
		, VFS.num_of_writes
		, VFS.num_of_reads / CASE VFS.num_of_writes WHEN 0 THEN 1 ELSE VFS.num_of_writes END AS reads_over_writes_ratio
FROM		sys.databases AS D
INNER JOIN	sys.master_files AS MF
			ON D.database_id = MF.database_id
CROSS APPLY	sys.dm_io_virtual_file_stats(MF.database_id, MF.file_id) AS VFS
*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
GO

IF (SELECT OBJECT_ID('TEMPDB.dbo.#result')) IS NOT NULL
BEGIN
	DROP TABLE #result
END

CREATE TABLE #result
(
	database_name sysname
	, recovery_model_desc varchar(60)
	, database_id int
	, filegroup_name sysname
	, file_id int
	, logical_file_name sysname
	, physical_file_name nvarchar(512)
	, file_type varchar(60)
	, growth varchar(10)
	, max_size_MB varchar(20)
	, file_size_MB decimal(14,2)
	, occupied_size_MB decimal(14,2)
	, free_space_MB decimal(14,2)
	, [% occupied] decimal(10,2)
	, [% free] decimal(10,2)
)

DECLARE	@database_list TABLE
(
	database_name sysname
	, recovery_model_desc varchar(60)
	, processed bit NOT NULL
)

DECLARE @sql nvarchar(2048)
	, @database_name sysname
	, @name sysname

INSERT	INTO @database_list
SELECT	QUOTENAME(name), recovery_model_desc, 0
FROM	sys.databases
WHERE	source_database_id IS NULL
AND	state_desc = 'ONLINE'
AND	user_access_desc = 'MULTI_USER'
AND	database_id > 4

WHILE EXISTS
(
	SELECT	*
	FROM	@database_list
	WHERE	processed = 0
)
BEGIN
	SELECT	TOP 1 @database_name = database_name
	FROM	@database_list
	WHERE	processed = 0

	SET @sql = 'USE ' + @database_name
	+ ';WITH
		CTE AS
		(
			SELECT		DS.name AS filegroup_name
					, DF.file_id
					, DF.name AS logical_name
					, DF.physical_name AS physical_name
					, DF.type_desc AS file_type_desc
					, CASE DF.is_percent_growth
						WHEN 0 THEN CASE DF.growth WHEN 0 THEN ''DISABLED'' ELSE CAST(DF.growth * 8 / 1024 AS varchar(8)) + '' MB'' END
						ELSE CAST(DF.growth AS varchar(3)) + '' %''
					END AS growth
					, CAST(DF.size AS bigint) * 8192 AS file_size_b
					, CAST(FILEPROPERTY(DF.name, ''SpaceUsed'') AS bigint) * 8192 AS occupied_size_b
					, CASE DF.max_size
						WHEN -1 THEN ''UNLIMITED''
						WHEN 0 THEN ''DISABLED''
						ELSE CAST(CAST(DF.max_size AS bigint) * 8 / 1024 AS varchar(20)) 
					END AS max_size_MB
			FROM		sys.database_files AS DF
			LEFT JOIN	sys.data_spaces AS DS
						ON DF.data_space_id = DS.data_space_id
		)
		, SIZE AS
		(
			SELECT	COALESCE(filegroup_name, ''TRANSACTION_LOG'') AS filegroup_name
				, file_id
				, logical_name
				, physical_name
				, file_type_desc
				, growth
				, max_size_MB
				, file_size_b / 1024 / 1024 AS file_size_MB
				, occupied_size_b / 1024 / 1024 AS occupied_size_MB
			FROM	CTE
		)
	SELECT	QUOTENAME(DB_NAME())
		, DB_ID()
		, filegroup_name
		, file_id
		, logical_name
		, physical_name
		, file_type_desc
		, growth
		, max_size_MB
		, file_size_MB
		, occupied_size_MB
		, file_size_MB - occupied_size_MB AS free_space_MB
		, CAST((CAST(occupied_size_MB AS numeric(14, 2)) / CASE file_size_MB WHEN 0 THEN 1 ELSE file_size_MB END) * 100 AS numeric(14, 2)) AS [%occupied]
		, CAST((CAST(file_size_MB - occupied_size_MB AS numeric(14, 2)) / CASE file_size_MB WHEN 0 THEN 1 ELSE file_size_MB END) * 100 AS numeric(14, 2)) AS [%free]
	FROM	SIZE'

	INSERT	INTO #result
	(
		database_name
		, database_id
		, filegroup_name
		, file_id
		, logical_file_name
		, physical_file_name
		, file_type
		, growth
		, max_size_MB
		, file_size_MB
		, occupied_size_MB
		, free_space_MB
		, [% occupied]
		, [% free]
	)
	EXEC sp_executesql @sql

	UPDATE	@database_list
	SET	processed = 1
	WHERE	database_name = @database_name
END

;WITH
	DATA AS
	(
		SELECT		R.database_name
				, DL.recovery_model_desc
				, R.filegroup_name
				, R.logical_file_name
				, R.physical_file_name
				, R.file_type
				, R.growth
				, R.max_size_MB
				, R.file_size_MB
				, R.occupied_size_MB
				, R.free_space_MB
				, R.[% occupied]
				, R.[% free]
				, VFS.io_stall_read_ms / CASE VFS.num_of_reads WHEN 0 THEN 1 ELSE VFS.num_of_reads END AS avg_read_latency_ms
				, VFS.io_stall_write_ms / CASE VFS.num_of_writes WHEN 0 THEN 1 ELSE VFS.num_of_writes END AS avg_write_latency_ms
				, VFS.io_stall / CASE VFS.io_stall_read_ms + VFS.io_stall_write_ms WHEN 0 THEN 1 ELSE VFS.io_stall_read_ms + VFS.io_stall_write_ms END AS avg_total_latency_ms
				, VFS.num_of_bytes_read / CASE VFS.num_of_reads WHEN 0 THEN 1 ELSE VFS.num_of_reads END AS avg_bytes_per_read
				, VFS.num_of_bytes_written / CASE VFS.num_of_writes WHEN 0 THEN 1 ELSE VFS.num_of_writes END AS avg_bytes_per_write
				, VFS.io_stall_read_ms
				, VFS.io_stall_write_ms
				, VFS.num_of_reads
				, VFS.num_of_writes
				, VFS.num_of_reads / CASE VFS.num_of_writes WHEN 0 THEN 1 ELSE VFS.num_of_writes END AS reads_over_writes_ratio
		FROM		#result AS R
		INNER JOIN	sys.dm_io_virtual_file_stats(NULL, NULL) AS VFS
					ON R.database_id = VFS.database_id
					AND R.file_id = VFS.file_id
		INNER JOIN	@database_list AS DL
					ON DL.database_name = R.database_name COLLATE database_default
	)
SELECT	'USE ' + database_name + '; DBCC SHRINKFILE(' + logical_file_name + ', 0)'
	, *	
	, avg_bytes_per_read / NULLIF(avg_bytes_per_write, 0) AS bytes_per_read_over_bytes_per_write_ratio
	, io_stall_read_ms / NULLIF(io_stall_write_ms, 0) AS io_stall_read_over_io_stall_write_ratio
FROM	DATA
WHERE	1 = 1
AND	file_type = 'ROWS'
AND	physical_file_name LIKE 'd%' ESCAPE '?'
--AND	LEFT(physical_file_name, 1) = 'd'
--AND	R.file_size_MB = 1
--AND	R.physical_file_name LIKE '%%' ESCAPE '?'
--AND	database_name LIKE '%cultura%' ESCAPE '?'
--AND	R.[% occupied] > 70
--AND	database_name IN ('[StagingDB]') 
--AND	R.free_space_MB > 1000
--ORDER	BY database_name, file_type
--ORDER	BY database_name, filegroup_name
ORDER	BY file_size_MB DESC
--ORDER	BY free_space_MB DESC

/*
USE [buyer_fnac_rctevol6];
DBCC SHRINKFILE(ivalua_data, 37472)
*/
