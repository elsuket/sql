USE master
GO

DECLARE	@_with_system_process bit = 0
	, @_with_wait_details bit = 0
	, @_with_session_wait_stats bit = 0
	, @_with_sql bit = 1 -- Switch to zero if you can't get a result under a few seconds
	, @_with_lock_desc bit = 0
	, @_with_job bit = 0
	, @_with_plan bit = 0
	, @_with_SID bit = 0
	, @order_by varchar(32) = 'duration'
	, @order_by_desc bit = 1
	-------
	, @_login nvarchar(128) --= ''
	, @_login_different_than nvarchar(128) --= 'duration'
	, @_machine nvarchar(128) = NULL
	, @_object_id int = NULL 
	, @_database_name sysname --= 'buyer_danske_devevol13' -- Collects all databases (i.e. including the auxiliary ones) of an environment
	, @_spid int --= 446
	, @sql nvarchar(max)
	, @with_generated_sql bit = 0
/*
SELECT		tdt.database_transaction_log_bytes_reserved
		, tst.session_id 
FROM		sys.dm_tran_database_transactions AS tdt 
INNER JOIN	sys.dm_tran_session_transactions AS tst 
			ON tdt.transaction_id = tst.transaction_id 
WHERE		tdt.database_id = 2;
*/

DECLARE @sql_server_version tinyint = CAST(SERVERPROPERTY('ProductMajorVersion') AS tinyint)

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF @order_by NOT IN ('CPU', 'reads', 'writes', 'gtd_qry_mem', 'tempdb_usg_KB', 'query_cost', 'duration', 'plan_handle', 'spid')
BEGIN
	RAISERROR('Unrecognized ORDER BY column', 0, 1)
	RETURN
END

SELECT	@order_by = CASE
		WHEN @order_by = 'gtd_qry_mem' THEN 'R.granted_query_memory'
		ELSE @order_by
	END

SELECT	@order_by_desc = CASE WHEN @order_by = 'SPID' THEN 0 ELSE @order_by_desc END

IF OBJECT_ID('TempDB.dbo.#t_db_id', 'U') IS NOT NULL
BEGIN
	DROP TABLE #t_db_id
END

CREATE TABLE #t_db_id
(
	database_id int NOT NULL
)

INSERT INTO #t_db_id
(
	database_id
)
SELECT	database_id
FROM	sys.databases
WHERE	name LIKE @_database_name + '%'


SET @sql = '
SELECT		COALESCE(NULLIF(S.login_name, ''''), S.original_login_name) AS login_name
		' + CASE WHEN @_with_SID = 0 THEN '' ELSE ', SID_BINARY(S.login_name) AS login_sid' END + '
		, R.database_id AS db_id
		, DB_NAME(R.database_id) AS db_name	
		, S.session_id AS SPID
		, NULLIF(R.blocking_session_id, 0) AS blk_by
		, DATEADD(second, DATEDIFF(second, R.start_time, GETDATE()), CAST(''00:00:00'' AS time(0))) AS duration
		, TK.task_count
		, R.wait_type
		, NULLIF(WT.resource_description, '''') AS wait_rsc_desc
		, R.wait_time
		, R.last_wait_type
		' + CASE WHEN @_with_wait_details = 0 THEN '' ELSE ', WTD.wait_task_details' END + ' 
		' + CASE WHEN @_with_session_wait_stats = 0 THEN '' ELSE ', SWS.session_wait' END + ' 
		, CASE
			WHEN R.granted_query_memory * 8 >= 1024 THEN CAST(CAST((R.granted_query_memory * 8) / 1024.0 AS decimal(20,2)) AS varchar(50)) + '' MB''
			WHEN R.granted_query_memory * 8 >= 1 THEN CAST(CAST((R.granted_query_memory * 8) AS decimal(20,2)) AS varchar(50)) + '' KB''
			ELSE CAST(R.granted_query_memory AS varchar(50)) + '' B''
		END AS gtd_qry_mem			
		, R.cpu_time AS CPU
		, R.logical_reads AS reads
		, R.writes AS writes
		, D.recovery_model_desc + '' / '' + D.log_reuse_wait_desc AS db_rcv_mod__tl_wait
		, T.tempdb_usg_KB
		, TMTL.tempdb_tl_usg_KB
		, CAST(LS.active_log_size_mb AS int) AS active_log_size_mb
		, CAST(LS.total_log_size_mb AS int) AS total_log_size_mb
		, CAST(100 * LS.active_log_size_mb / LS.total_log_size_mb AS decimal(5,2)) AS [tl_usg_%]
		, UPPER(R.command) AS command
		, UPPER(R.status) AS status
		, R.open_transaction_count AS nbtran
		, CASE R.transaction_isolation_level
			WHEN 0 THEN ''Unspecified''
			WHEN 1 THEN ''READ UNCOMMITTED''
			WHEN 2 THEN ''READ COMMITTED''
			WHEN 3 THEN ''REPETABLE''
			WHEN 4 THEN ''SERIALIZABLE''
			WHEN 5 THEN ''SNAPSHOT''
		END AS tx_isolation_level
		, CAST(R.percent_complete AS decimal(5,2)) AS percent_complete
		, CASE WHEN R.percent_complete = 0 THEN NULL ELSE DATEADD(millisecond, R.estimated_completion_time, GETDATE()) END AS [est_cpl°_time]'
		+  CASE @_with_sql WHEN 0 THEN '' ELSE '
			, SQLT.objectid
			, R.executing_managed_code AS use_assembly
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
			, CASE WHEN R.command = ''UPDATE STATISTIC'' THEN ''Updating stats on '' + REPLACE(REPLACE(SUBSTRING(SQLT.text, CHARINDEX(''[dbo]'', SQLT.text), CHARINDEX('' '', SQLT.text, CHARINDEX(''[dbo]'', SQLT.text)) -  CHARINDEX(''[dbo]'', SQLT.text)), ''['', ''''), '']'', '''') END AS info
		' END + '
		, QMG.dop
		, CAST(QMG.query_cost AS decimal(38,4)) AS query_cost
		, TL.tran_log_usg_desc
		' +  CASE WHEN @_with_lock_desc = 0 THEN '' ELSE ', TLX.lock_desc' END + '
		, CASE
			' + CASE WHEN @_with_job = 1 THEN ' WHEN S.program_name LIKE ''SQLAgent - TSQL JobStep%'' THEN ''Job : '' + J.name' ELSE '' END
			+ ' WHEN S.program_name LIKE ''Microsoft SQL Server Management Studio%'' THEN ''SSMS''
			WHEN S.program_name LIKE ''SQL Management%'' THEN ''SSMS''			
			WHEN S.program_name LIKE ''LiteSpeed for SQL Server%'' THEN ''LiteSpeed''
			WHEN S.program_name = ''Microsoft SQL Server Analysis Services'' THEN ''SSAS''
			WHEN S.program_name LIKE ''SQL Server Profiler%'' THEN ''Profiler''
			ELSE S.program_name
		END AS app
		, S.host_name AS host
		, C.client_net_address AS IP
		, R.plan_handle
		, R.sql_handle
		, TA.name AS tx_name
		, TA.transaction_begin_time AS tx_begin_time
		, CASE TA.transaction_type
			WHEN 1 THEN ''Read/write''
			WHEN 2 THEN ''Read-only''
			WHEN 3 THEN ''System''
			WHEN 4 THEN ''Distributed''
		END AS tx_type
		, CASE TA.transaction_state
			WHEN 0 THEN ''Not completely initialized yet''
			WHEN 1 THEN ''Initialized but has not started''
			WHEN 2 THEN ''Active''
			WHEN 3 THEN ''Ended (read-only tx)''
			WHEN 4 THEN ''Commit process has been initiated on the distributed transaction''
			WHEN 5 THEN ''Prepared state and waiting resolution''
			WHEN 6 THEN ''Committed''
			WHEN 7 THEN ''Rolling back''
			WHEN 8 THEN ''Rolled back''
		END AS tx_state
		' +  CASE @_with_plan WHEN 0 THEN '' ELSE ', p.query_plan' END + '
FROM		sys.dm_exec_sessions AS S
INNER JOIN	sys.dm_exec_requests AS R
			ON S.session_id = R.session_id
LEFT JOIN	sys.databases AS D
			ON D.database_id = R.database_id'
		+ CASE WHEN @_database_name IS NULL THEN '' ELSE '
INNER JOIN	#t_db_id AS db
			ON db.database_id = R.database_id' END + '
OUTER APPLY	(
			SELECT	TOP 1 C.client_net_address
			FROM	sys.dm_exec_connections AS C
			WHERE	S.session_id = C.session_id
		) AS C
CROSS APPLY	sys.dm_db_log_stats(R.database_id) AS LS
LEFT JOIN	sys.dm_exec_query_memory_grants AS QMG
			ON QMG.session_id = R.session_id'
+ CASE WHEN @_with_job = 0 THEN '' ELSE ' 	LEFT JOIN	msdb.dbo.sysjobs AS J
				ON REPLACE(SUBSTRING(CAST(J.job_id AS char(36)), CHARINDEX(''-'', J.job_id, 18) + 1, LEN(J.job_id)), ''-'', '''') =
					RIGHT(LEFT(REPLACE(S.program_name, ''SQLAgent - TSQL JobStep (Job 0x'', ''''), 32), 16)' END
+ CASE WHEN @_with_wait_details = 0 THEN '' ELSE ' OUTER APPLY	(
				SELECT	CAST(COUNT(*) AS varchar(10)) + '' '' + WT.wait_type
						+ '' ('' + CAST(SUM(wait_duration_ms)  AS varchar(20)) + '') | ''
				FROM	sys.dm_os_waiting_tasks AS WT
				WHERE	WT.session_id = S.session_id
				GROUP	BY WT.wait_type
				FOR	XML PATH('''')
			) AS WTD(wait_task_details)' END + '
LEFT JOIN	sys.dm_tran_session_transactions AS ST
			ON ST.session_id = S.session_id
LEFT JOIN	sys.dm_tran_active_transactions AS TA
			ON TA.transaction_id = ST.transaction_id'
+ CASE WHEN @_with_sql = 0 THEN '' ELSE '
OUTER APPLY	sys.dm_exec_sql_text(R.sql_handle) AS SQLT' END + '
OUTER APPLY	(
			SELECT		CASE DT.database_transaction_log_bytes_reserved
						WHEN 0 THEN ''''
						ELSE DB_NAME(DT.database_id)
							+ '' : '' + CAST(DT.database_transaction_log_bytes_reserved / 1024 AS varchar(20)) + '' KB | ''
					END
					+ CASE
						WHEN DT.database_id <= 4 THEN ''''
						ELSE CASE DT.database_transaction_replicate_record_count
							WHEN 0 THEN ''''
							ELSE '' - Repl° recs : '' + CAST(DT.database_transaction_replicate_record_count AS varchar(20))
						END
					END
			FROM		sys.dm_tran_session_transactions AS ST
			INNER JOIN	sys.dm_tran_database_transactions AS DT
						ON DT.transaction_id = ST.transaction_id
			WHERE		S.session_id = ST.session_id
			FOR		XML PATH ('''')
		) AS TL (tran_log_usg_desc)
		' + CASE WHEN @_with_lock_desc = 0 THEN '' ELSE '
OUTER APPLY	(
			SELECT	TLX.resource_type + N'' '' + CAST(COUNT(*) AS nvarchar(10)) + '', ''
			FROM	sys.dm_tran_locks AS TLX
			WHERE	TLX.request_session_id = S.session_id
			AND	TLX.resource_type <> ''DATABASE''
			GROUP	BY TLX.resource_type
			FOR	XML PATH ('''')
		) AS TLX(lock_desc)' END + '
OUTER APPLY	(
			SELECT	SUM
				(
					(
						(TSU.user_objects_alloc_page_count - TSU.user_objects_dealloc_page_count)
						+ (TSU.internal_objects_alloc_page_count - TSU.internal_objects_dealloc_page_count)
					)
					* 8192 / 1024
				) AS tempdb_usg_KB
			FROM	sys.dm_db_task_space_usage AS TSU
			--FROM	sys.dm_db_session_space_usage AS TSU
			WHERE	TSU.session_id = R.session_id
			AND	TSU.database_id = 2
		) AS T
OUTER APPLY	(
			SELECT		tdt.database_transaction_log_bytes_reserved / 1024 AS tempdb_tl_usg_KB
			FROM		sys.dm_tran_database_transactions AS tdt 
			INNER JOIN	sys.dm_tran_session_transactions AS tst 
						ON tdt.transaction_id = tst.transaction_id 
			WHERE		tdt.database_id = 2
			AND		tst.session_id = R.session_id
		) AS TMTL
OUTER APPLY	(
			SELECT	COUNT(*) AS task_count
			FROM	sys.dm_os_tasks AS TK
			WHERE	TK.session_id = S.session_id
		) AS TK

OUTER APPLY	(
			SELECT	resource_description + ''|''
			FROM	sys.dm_os_waiting_tasks AS WT
			WHERE	WT.session_id = S.session_id
			FOR	XML PATH('''')
		) AS WT(resource_description)'
+ CASE WHEN @_with_session_wait_stats = 1 AND @sql_server_version >= 13 THEN '
OUTER APPLY	(
			SELECT	wait_type + ''(w : '' + CAST(SWS.wait_time_ms AS varchar(10))
					+ '' - rsc : '' + CAST(SWS.wait_time_ms - SWS.signal_wait_time_ms AS varchar(10))
					+ '' - sig : '' + CAST(SWS.signal_wait_time_ms AS varchar(10))
					+ '') |'' 
			FROM	sys.dm_exec_session_wait_stats AS SWS
			WHERE	SWS.session_id = S.session_id
			ORDER	BY SWS.wait_time_ms DESC
			FOR	XML PATH('''')
		) AS SWS(session_wait)' ELSE '' END
+ CASE WHEN @_with_plan = 0 THEN '' ELSE '
OUTER APPLY	sys.dm_exec_query_plan(R.plan_handle) AS p
' END
+ '
WHERE		1 = 1'
	+ CASE @_with_system_process WHEN 1 THEN '' ELSE ' AND	S.is_user_process = 1' END + '
AND		S.session_id <> @@SPID
AND		(
			R.wait_type <> ''BROKER_RECEIVE_WAITFOR''
			OR R.wait_type IS NULL
		)'
+ CASE WHEN @_spid IS NULL THEN '' ELSE ' AND S.session_id = @_spid' END 
+ CASE WHEN @_login IS NULL THEN '' ELSE ' AND S.login_name = @_login' END 
+ CASE WHEN @_login_different_than IS NULL THEN '' ELSE ' AND S.login_name <> @_login_different_than' END 
+ CASE WHEN @_machine IS NULL THEN '' ELSE ' AND S.host_name = @_machine' END 
+ CASE WHEN @_object_id IS NULL THEN '' ELSE ' AND SQLT.objectid = @_object_id' END 
+ CASE WHEN @order_by IS NULL THEN '' ELSE ' ORDER BY	' + @order_by END
+ CASE
	WHEN @order_by IS NULL THEN ''	
	WHEN @order_by_desc = 1 THEN ' DESC'
	ELSE ''
END

IF @with_generated_sql = 1
BEGIN
	SELECT @sql AS generated_sql
END

EXEC sys.sp_executesql
	@sql
	------
	, N'@_spid int
	, @_login nvarchar(128)
	, @_login_different_than nvarchar(128)
	, @_machine nvarchar(128)
	, @_object_id int'
	----
	, @_spid = @_spid
	, @_login = @_login
	, @_login_different_than = @_login_different_than
	, @_machine = @_machine
	, @_object_id = @_object_id


/*
DECLARE @handle varbinary(1024) = 0x06005D007B84A206F09394B9BA02000001000000000000000000000000000000000000000000000000000000
SELECT * FROM sys.dm_exec_query_plan(@handle)
SELECT * FROM sys.dm_exec_input_buffer(530, NULL)
DBCC FREEPROCCACHE (0x060005002EA4E21BD0E603181200000001000000000000000000000000000000000000000000000000000000)
*/

/*
DECLARE @plan_handle varbinary(64) = 0x0600050062EBA70170BE97929801000001000000000000000000000000000000000000000000000000000000

SELECT		qs.query_hash
		, qs.query_plan_hash
		, qs.sql_handle
		, qs.plan_handle
		, p.query_id
		, p.plan_id
FROM		sys.dm_exec_query_stats AS qs
INNER JOIN	sys.query_store_plan AS p
			ON qs.query_plan_hash = p.query_plan_hash
WHERE		qs.plan_handle = @plan_handle

DECLARE @sql_handle varbinary(64) = 0x0200000062EBA7014E9E36E8B37DC3927E592AD18B930B9C0000000000000000000000000000000000000000
SELECT		q.query_hash
		, p.query_plan_hash
		, q.last_compile_batch_sql_handle
		, p.query_id
		, p.plan_id
FROM		sys.query_store_query AS q
INNER JOIN	sys.query_store_plan AS p
			ON q.query_id = p.query_id
WHERE		q.last_compile_batch_sql_handle = @sql_handle
*/
