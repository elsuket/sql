DECLARE @database_name varchar(128) = 'buyer_edf_prepmaint' COLLATE database_default

DECLARE @dbcc_sqlperf TABLE
(
	database_name sysname COLLATE database_default
	, log_size_MB decimal(11,2)
	, log_space_used_pct decimal(5,2)
	, log_status int
)

INSERT	INTO @dbcc_sqlperf
EXEC	('DBCC SQLPERF(logspace)')

;WITH
	CTE AS
	(
		SELECT		D.name AS database_name
				, D.log_reuse_wait_desc
				, D.recovery_model_desc
				, MF.physical_name
				, MF.name AS logical_name
		FROM		sys.databases AS D
		INNER JOIN	sys.master_files AS MF
					ON D.database_id = MF.database_id
		WHERE		MF.type_desc = 'LOG'
		AND		(
					@database_name IS NULL
					OR D.name = @database_name
				)
	)
SELECT		DSP.database_name
		, C.logical_name
		, DSP.log_size_MB
		, DSP.log_space_used_pct
		, C.log_reuse_wait_desc
		, C.recovery_model_desc
		, C.physical_name
FROM		@dbcc_sqlperf AS DSP
INNER JOIN	CTE AS C
			ON DSP.database_name = C.database_name COLLATE database_default