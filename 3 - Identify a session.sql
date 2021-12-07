SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT		S.session_id
		, S.login_time
		, S.host_name
		, S.program_name
		, S.host_process_id
		, S.login_name
		, S.original_login_name
		, S.status
		, S.last_request_end_time
		, ST.text
		, R.command
		, R.percent_complete
		, DB_NAME(R.database_id) AS database_name
		, R.open_transaction_count
		, C.client_net_address
FROM		sys.dm_exec_sessions AS S
LEFT JOIN	sys.dm_exec_requests AS R
			ON S.session_id = R.session_id
OUTER APPLY	sys.dm_exec_sql_text(R.plan_handle) AS ST
OUTER APPLY	sys.dm_exec_input_buffer(S.session_id, R.request_id)
LEFT JOIN	sys.dm_exec_connections AS C
			ON C.session_id = S.session_id
WHERE		S.session_id = 56
--WHERE		S.database_id = DB_ID('master_ivalua_test')

/*
SELECT		S.session_id
		, S.login_time
		, S.host_name
		, S.program_name
		, S.host_process_id
		, S.client_interface_name
		, S.login_name
		, S.status
		, IB.event_info
		, C.client_net_address
		, 'KILL ' + CAST(s.session_id AS varchar) AS kill_sql
FROM		sys.dm_exec_sessions AS s
CROSS APPLY	sys.dm_exec_input_buffer(s.session_id, NULL) AS IB
LEFT JOIN	sys.dm_exec_connections AS C
			ON C.session_id = S.session_id
WHERE		s.database_id = DB_ID('buyer_ft_prod')
*/
