SELECT start_time
	, status
	, command
	, database_id
	, blocking_session_id
	, wait_time
	, wait_type
	, last_wait_type
	, wait_resource
	, open_transaction_count
	, percent_complete
	, estimated_completion_time
	, cpu_time
	, writes
	, logical_reads
FROM sys.dm_exec_requests
WHERE command = 'LAZY WRITER'
OR command = 'CHECKPOINT'
OR command LIKE '%GHOST%'