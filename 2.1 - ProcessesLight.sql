USE master
GO

SELECT		S.host_name
		, COALESCE(NULLIF(S.login_name, ''), S.original_login_name) AS login_name
		, DB_NAME(R.database_id) AS db_name	
		, S.session_id AS SPID
		, NULLIF(R.blocking_session_id, 0) AS blk_by
		, DATEADD(second, DATEDIFF(second, R.start_time, GETDATE()), CAST('00:00:00' AS time(0))) AS started_ago
		, R.command
		, R.wait_type
		, R.last_wait_type
		, CASE
			WHEN R.granted_query_memory * 8 >= 1024 THEN CAST(CAST((R.granted_query_memory * 8) / 1024.0 AS decimal(20,2)) AS varchar(50)) + ' MB'
			WHEN R.granted_query_memory * 8 >= 1 THEN CAST(CAST((R.granted_query_memory * 8) AS decimal(20,2)) AS varchar(50)) + ' KB'
			ELSE CAST(R.granted_query_memory AS varchar(50)) + ' B'
		END AS gtd_qry_mem			
		, R.cpu_time AS CPU
		, R.logical_reads AS reads
		, R.writes AS writes
		, R.open_transaction_count AS nbtran
		, CASE R.transaction_isolation_level
			WHEN 0 THEN 'Unspecified'
			WHEN 1 THEN 'READ UNCOMMITTED'
			WHEN 2 THEN 'READ COMMITTED'
			WHEN 3 THEN 'REPETABLE'
			WHEN 4 THEN 'SERIALIZABLE'
			WHEN 5 THEN 'SNAPSHOT'
		END AS tx_isolation_level
		, CAST(R.percent_complete AS decimal(5,2)) AS percent_complete
		, CASE WHEN R.percent_complete = 0 THEN NULL ELSE DATEADD(millisecond, R.estimated_completion_time, GETDATE()) END AS [est_cpl°_time]
		, R.plan_handle
		, SQLT.text
		, SUBSTRING
		(
			SQLT.text
			, (R.statement_start_offset / 2) + 1
			, (
				(
					CASE R.statement_end_offset
						WHEN -1 THEN DATALENGTH(SQLT.text)
						ELSE R.statement_end_offset
					END - R.statement_start_offset
				) / 2
			) + 1
		) AS stmt_in_batch
FROM		sys.dm_exec_sessions AS S
INNER JOIN	sys.dm_exec_requests AS R
			ON S.session_id = R.session_id
OUTER APPLY	sys.dm_exec_sql_text(R.sql_handle) AS SQLT
WHERE		1 = 1
--AND		S.session_id > 50
AND		S.session_id <> @@SPID
AND		(
			R.wait_type <> 'BROKER_RECEIVE_WAITFOR'
			OR R.wait_type IS NULL
		)
AND		R.database_id > 4
ORDER BY	CPU DESC

/*
DECLARE @handle varbinary(1024) = 0x06000600D2A2583190DC00025E01000001000000000000000000000000000000000000000000000000000000
SELECT * FROM sys.dm_exec_query_plan(@handle)
SELECT	* FROM sys.dm_exec_input_buffer(360, NULL)
*/
