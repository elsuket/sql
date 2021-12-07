SELECT		ES.login_name AS login
		, DB_NAME(ER.database_id) AS DB
		, ES.session_id AS SPID
		, ER.blocking_session_id AS blkby
		, ER.wait_type
		, ER.wait_time
		, ER.last_wait_type
		, ER.cpu_time AS CPU, ER.reads AS reads
		, ER.writes AS writes
		, UPPER(ER.command) AS command
		, UPPER(ER.status) AS status
		, STUFF
		(
			CONVERT
			(
				varchar(8)
				, DATEADD(second, DATEDIFF(second, ER.start_time, GETDATE()), 0)
				, 108
			)
			, 1
			, 2
			, DATEDIFF(hour, 0, DATEADD(second, DATEDIFF(second, ER.start_time, GETDATE()),0))
		)  AS launched
		, CAST(ER.percent_complete AS decimal(5,2)) AS percent_complete
		, CASE WHEN ER.percent_complete = 0 THEN NULL ELSE DATEADD(millisecond, ER.estimated_completion_time, GETDATE()) END AS [est_cpl°_time]
		, SUBSTRING
		(
			ESQLT.text
			, ER.statement_start_offset / 2 + 1
			, (
				CASE
					WHEN ER.statement_end_offset = - 1 THEN LEN(CAST(ESQLT.text AS nvarchar(max))) * 2 
					ELSE ER.statement_end_offset 
				END - ER.statement_start_offset
			) / 2 + 1
		) AS stmt_in_batch
		, ESQLT.text AS batch
		, CASE WHEN ER.command = 'UPDATE STATISTIC' THEN 'Updating stats on ' + REPLACE(REPLACE(SUBSTRING(ESQLT.text, CHARINDEX('[dbo]', ESQLT.text), CHARINDEX(' ', ESQLT.text, CHARINDEX('[dbo]', ESQLT.text)) -  CHARINDEX('[dbo]', ESQLT.text)), '[', ''), ']', '') END AS info
		, CASE
			WHEN ES.program_name LIKE 'SQLAgent - TSQL JobStep%' THEN 'Job : ' + J.name
			WHEN ES.program_name LIKE 'Microsoft SQL Server Management Studio%' THEN 'SSMS'
			WHEN ES.program_name LIKE 'LiteSpeed for SQL Server%' THEN 'LiteSpeed'
			WHEN ES.program_name = 'Microsoft SQL Server Analysis Services' THEN 'SSAS'
			ELSE ES.program_name
		END AS program
		, ES.host_name AS host
		, EC.client_net_address AS IP
FROM		sys.dm_exec_sessions AS ES
INNER JOIN	sys.dm_exec_connections AS EC 
			ON ES.session_id = EC.session_id
INNER JOIN	sys.dm_exec_requests AS ER
			ON ES.session_id = ER.session_id
LEFT JOIN	sys.dm_exec_query_memory_grants AS QMG
			ON QMG.session_id = ER.session_id
LEFT JOIN	msdb.dbo.sysjobs AS J
			ON REPLACE(SUBSTRING(CAST(J.job_id AS char(36)), CHARINDEX('-', J.job_id, 18) + 1, LEN(J.job_id)), '-', '') =
				RIGHT(LEFT(REPLACE(ES.program_name, 'SQLAgent - TSQL JobStep (Job 0x', ''), 32), 16)
OUTER APPLY	sys.dm_exec_sql_text(ER.sql_handle) ESQLT
WHERE		ER.percent_complete > 0