SELECT		ar.replica_server_name
		, adc.database_name
		, ag.name AS ag_name 
		, ar.failover_mode_desc
		, ar.availability_mode_desc
		, drs.is_local 
		, drs.is_primary_replica
		, drs.last_commit_time
		, drs.secondary_lag_seconds
		, drs.synchronization_state_desc
		, drs.synchronization_health_desc
		, drs.database_state_desc
		, drs.suspend_reason_desc
		---
		, drs.log_send_queue_size
		, drs.redo_queue_size
FROM		sys.dm_hadr_database_replica_states AS drs
INNER JOIN	sys.availability_databases_cluster AS adc 
			ON drs.group_id = adc.group_id
			AND drs.group_database_id = adc.group_database_id
INNER JOIN	sys.availability_groups AS ag
			ON ag.group_id = drs.group_id
INNER JOIN	sys.availability_replicas AS ar 
			ON drs.group_id = ar.group_id
			AND drs.replica_id = ar.replica_id


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
		WHERE		DF.type_desc = 'LOG'
	)
SELECT		COALESCE(C.filegroup_name, 'TRANSACTION_LOG') AS filegroup_name
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
FROM		CTE AS C
INNER JOIN	sys.dm_io_virtual_file_stats(NULL, NULL) AS VFS
			ON C.database_id = VFS.database_id
			AND C.file_id = VFS.file_id
