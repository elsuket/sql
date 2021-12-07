SELECT	name
	, log_reuse_wait_desc
	, recovery_model_desc
FROM	sys.databases

--DBCC SQLPERF(logspace)