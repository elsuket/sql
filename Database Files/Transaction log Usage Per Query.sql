 SELECT		tst.session_id
		, s.login_name
		, DB_NAME (tdt.database_id) AS database_name
		, tdt.database_transaction_begin_time AS tx_begin_time
		, tdt.database_transaction_log_record_count AS log_record_count
		, tdt.database_transaction_log_bytes_used AS log_used_bytes
		, tdt.database_transaction_log_bytes_reserved AS log_bytes_reserved
		, SUBSTRING
		(
			st.text
			, (r.statement_start_offset / 2) + 1
			, (
				(
					CASE r.statement_end_offset
						WHEN -1 THEN DATALENGTH(st.text)
						ELSE r.statement_end_offset
					END - r.statement_start_offset
				) / 2
			) + 1
		) AS statement_text
		, st.text AS last_sql
		, qp.query_plan
FROM		sys.dm_tran_database_transactions tdt
INNER JOIN	sys.dm_tran_session_transactions tst
			ON tst.transaction_id = tdt.transaction_id
INNER JOIN	sys.dm_exec_sessions s
			ON s.session_id = tst.session_id
INNER JOIN	sys.dm_exec_connections c
			ON c.session_id = tst.session_id
LEFT JOIN	sys.dm_exec_requests r
			ON r.session_id = tst.session_id
CROSS APPLY	sys.dm_exec_sql_text (c.most_recent_sql_handle) AS st
OUTER APPLY	sys.dm_exec_query_plan (r.plan_handle) AS qp
--WHERE		DB_NAME (tdt.database_id) = 'tempdb'
ORDER BY	log_used_bytes