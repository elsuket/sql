SELECT		GETDATE() AS log_date_time
		, ST.session_id
		, ST.enlist_count AS active_requests
		, AT.transaction_id
		, AT.name AS tran_name
		, AT.transaction_begin_time AS tran_start_time
		, CASE AT.transaction_type
			WHEN 1 THEN 'Read/Write'
			WHEN 2 THEN 'Read-Only'
			WHEN 3 THEN 'System'
			WHEN 4 THEN 'Distributed'
			ELSE 'Unknown - ' + CONVERT(varchar(20), transaction_type)
		END AS transaction_type
		, CASE AT.transaction_state
			WHEN 0 THEN 'Uninitialized'
			WHEN 1 THEN 'Not Yet Started'
			WHEN 2 THEN 'Active'
			WHEN 3 THEN 'Ended (Read-Only)'
			WHEN 4 THEN 'Committing'
			WHEN 5 THEN 'Prepared'
			WHEN 6 THEN 'Committed'
			WHEN 7 THEN 'Rolling Back'
			WHEN 8 THEN 'Rolled Back'
			ELSE 'Unknown - ' + CONVERT(varchar(20), transaction_state)
		END AS transaction_state
		, CASE AT.dtc_state
			WHEN 0 THEN NULL
			WHEN 1 THEN 'Active'
			WHEN 2 THEN 'Prepared'
			WHEN 3 THEN 'Committed'
			WHEN 4 THEN 'Aborted'
			WHEN 5 THEN 'Recovered'
			ELSE 'Unknown - ' + CONVERT(varchar(20), dtc_state)
		END AS distributed_state
		, D.Name AS database_name
		, DBT.database_transaction_begin_time AS db_tran_begin_time
		, CASE DBT.database_transaction_type
			WHEN 1 THEN 'Read/Write'
			WHEN 2 THEN 'Read-Only'
			WHEN 3 THEN 'System'
			ELSE 'UNKNOWN - ' + CONVERT(varchar(20), database_transaction_type)
		END AS db_tran_type
		, CASE DBT.database_transaction_state
			WHEN 1 THEN 'Uninitialized'
			WHEN 3 THEN 'No Log Records'
			WHEN 4 THEN 'Log Records'
			WHEN 5 THEN 'Prepared'
			WHEN 10 THEN 'Committed'
			WHEN 11 THEN 'Rolled Back'
			WHEN 12 THEN 'Committing'
			ELSE 'Unknown - ' + CONVERT(varchar(20), database_transaction_state)
		END AS db_tran_state
		, DBT.database_transaction_log_record_count AS log_record_count
		, DBT.database_transaction_log_bytes_used / 1024 AS log_bytes_used
		, DBT.database_transaction_log_bytes_reserved / 1024 AS log_bytes_reserved
		, DBT.database_transaction_log_bytes_used_system / 1024 AS log_bytes_used_system
		, DBT.database_transaction_log_bytes_reserved_system / 1024 AS log_bytes_reserved_system
		, DBT.database_transaction_replicate_record_count AS record_count_for_replication
		, R.command
		, R.total_elapsed_time AS elapsed_time_ms
		, R.cpu_time AS CPU_time_ms
		, R.wait_type
		, R.wait_time AS wait_time_ms
		, R.wait_resource
		, R.reads
		, R.logical_reads
		, R.writes
		, R.open_transaction_count AS open_tran_count
		, R.open_resultset_count
		, R.row_count
		, R.nest_level
		, R.granted_query_memory AS query_memory
		, SUBSTRING
		(
			QT.text
			, R.statement_start_offset / 2
			, (
				CASE
					WHEN R.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max), QT.text)) * 2
					ELSE R.statement_end_offset
				END - R.statement_start_offset
			) / 2
		) AS query_text
FROM		sys.dm_tran_active_transactions AS AT
INNER JOIN	sys.dm_tran_database_transactions AS DBT
			ON DBT.transaction_id = AT.transaction_id
INNER JOIN	sys.databases AS D
			ON D.database_id = DBT.database_id
LEFT JOIN	sys.dm_tran_session_transactions AS ST
			ON ST.transaction_id = AT.transaction_id
LEFT JOIN	sys.dm_exec_requests AS R
			ON R.session_id = ST.session_id
			AND R.transaction_id = ST.transaction_id
OUTER APPLY	sys.dm_exec_sql_text(R.sql_handle) AS QT
WHERE		ST.session_id IS NOT NULL -- comment this out to see SQL Server internal processes
ORDER BY	session_id