--USE tempdb

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO

;WITH
	CTE AS
	(
		SELECT		DB_ID() AS database_id
				, DS.name AS filegroup_name
				, DF.file_id
				, DF.name AS logical_name
				, DF.physical_name AS physical_name
				, DF.type_desc AS file_type_desc
				, CASE DF.is_percent_growth
						WHEN 0 THEN CASE DF.growth WHEN 0 THEN 'DISABLED' ELSE CAST(DF.growth / 128 AS varchar(20)) + ' MB' END
						ELSE CAST(DF.growth AS varchar(3)) + ' %'
				END AS growth
				, CAST(DF.size / 128.0 AS decimal(14, 2)) AS file_size_MB
				, CAST(FILEPROPERTY(DF.name, 'SpaceUsed') / 128.0 AS decimal(14, 2)) AS occupied_size_MB
				, CASE DF.max_size
					WHEN -1 THEN 'UNLIMITED'
					WHEN 0 THEN 'DISABLED'
					ELSE CAST(CAST(DF.max_size / 128.0 AS bigint) AS varchar(20))
				END AS max_size_MB
		FROM		sys.database_files AS DF
		LEFT JOIN	sys.data_spaces AS DS
					ON DF.data_space_id = DS.data_space_id
	)
	, COMPUTATIONS AS
	(
		SELECT		COALESCE(C.filegroup_name, 'TRANSACTION_LOG') AS filegroup_name
				--, C.file_id
				, C.logical_name
				, C.physical_name
				, C.file_type_desc
				, C.growth
				, C.max_size_MB
				, C.file_size_MB
				, C.occupied_size_MB
				, C.file_size_MB - C.occupied_size_MB AS free_space_MB
				, CAST((CAST(C.occupied_size_MB AS numeric(14, 2)) / C.file_size_MB) * 100 AS numeric(14, 2)) AS [%occupied]
				, CAST((CAST(C.file_size_MB - C.occupied_size_MB AS numeric(14, 2)) / C.file_size_MB) * 100 AS numeric(14, 2)) AS [%free]
				, VFS.io_stall_read_ms / VFS.num_of_reads AS avg_read_latency_ms
				, VFS.io_stall_write_ms / CASE VFS.num_of_writes WHEN 0 THEN 1 ELSE VFS.num_of_writes END AS avg_write_latency_ms
				, VFS.io_stall / CASE VFS.io_stall_read_ms + VFS.io_stall_write_ms WHEN 0 THEN 1 ELSE VFS.io_stall_read_ms + VFS.io_stall_write_ms END AS avg_total_latency_ms
				, VFS.num_of_bytes_read / VFS.num_of_reads AS avg_bytes_per_read
				, VFS.num_of_bytes_written / CASE VFS.num_of_writes WHEN 0 THEN 1 ELSE VFS.num_of_writes END AS avg_bytes_per_write
				---
				, VFS.io_stall_read_ms
				, VFS.io_stall_write_ms
				, VFS.num_of_reads
				, VFS.num_of_writes
				--, CAST(VFS.num_of_reads / CAST(VFS.num_of_writes AS float) AS decimal(14,2)) AS reads_over_writes_ratio
		FROM		CTE AS C
		INNER JOIN	sys.dm_io_virtual_file_stats(NULL, NULL) AS VFS
					ON C.database_id = VFS.database_id
					AND C.file_id = VFS.file_id
	)
SELECT	*
	, avg_bytes_per_read / NULLIF(avg_bytes_per_write, 0) AS bytes_per_read_over_bytes_per_write_ratio
	, io_stall_read_ms / NULLIF(io_stall_write_ms, 0) AS io_stall_read_over_io_stall_write_ratio
FROM	COMPUTATIONS
WHERE	1 = 1
--AND	file_type_desc = 'ROWS'
--AND	physical_name LIKE 's%'
--ORDER	BY file_type_desc, free_space_MB DESC
ORDER	BY logical_name