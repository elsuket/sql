DECLARE @_database_name sysname = 'buyer_demo_v8_154_mdd_qst'

SET NOCOUNT ON

DECLARE @sql varchar(256)

DECLARE @free_disk_space TABLE
(
	drive_letter char(1) NOT NULL
	, free_space_MB int NOT NULL
)
INSERT	INTO @free_disk_space
EXEC	master.dbo.xp_fixeddrives

DECLARE @dbcc_sqlperf_logspace TABLE
(
	database_name sysname
	, log_size float
	, log_space_used_pct decimal (5,2)
	, status tinyint
)
INSERT	INTO @dbcc_sqlperf_logspace
EXEC	('DBCC SQLPERF(logspace)')

DECLARE @dbcc_loginfo TABLE
(
	recovery_unit_id tinyint NULL
	, fileid tinyint NOT NULL
	, file_size bigint NOT NULL
	, start_offset bigint NOT NULL
	, f_seq_no bigint NOT NULL
	, status tinyint NOT NULL
	, parity tinyint NOT NULL
	, create_LSN varbinary(max) NOT NULL
)

IF @_database_name IS NULL
BEGIN
	DECLARE @dbcc_loginfo_all_db TABLE
	(
		database_name varchar(128)
		, log_file_id tinyint
		, vlf_count smallint
	)

	INSERT	INTO @dbcc_loginfo_all_db
	(
		database_name
		, log_file_id
		, vlf_count
	)
	SELECT		D.name
			, MF.file_id
			, 0
	FROM		sys.databases AS D
	INNER JOIN	sys.master_files AS MF
				ON D.database_id = MF.database_id
	WHERE		D.source_database_id IS NULL
	AND		D.state_desc = 'ONLINE'
	AND		D.user_access_desc = 'MULTI_USER'
	AND		MF.type_desc = 'LOG'

	WHILE EXISTS
	(
		SELECT	*
		FROM	@dbcc_loginfo_all_db
		WHERE	vlf_count = 0
	)
	BEGIN
		SELECT	TOP 1 @_database_name = database_name
		FROM	@dbcc_loginfo_all_db
		WHERE	vlf_count = 0

		SET @sql = 'DBCC LOGINFO (''' + @_database_name + ''')'

		IF CAST(SERVERPROPERTY('ProductVersion') AS varchar(32)) LIKE '1[1-9]%'
		BEGIN
			INSERT	INTO @dbcc_loginfo
			EXEC	(@sql)
		END
		ELSE
		BEGIN
			INSERT	INTO @dbcc_loginfo
			(
				fileid
				, file_size
				, start_offset
				, f_seq_no
				, status
				, parity
				, create_LSN
			)
			EXEC	(@sql)
		END

		;WITH
			CTE AS
			(
				SELECT	fileid
					, COUNT(*) AS vlf_count
				FROM	@dbcc_loginfo
				GROUP	BY fileid
			)
		UPDATE		@dbcc_loginfo_all_db
		SET		vlf_count = C.vlf_count
		FROM		@dbcc_loginfo_all_db AS DLAD
		INNER JOIN	CTE AS C
					ON DLAD.log_file_id = C.fileid
		WHERE		DLAD.database_name = @_database_name

		DELETE	FROM @dbcc_loginfo
	END

	SELECT		LS.database_name
			, D.recovery_model_desc
			, MF.name AS logical_name
			, COALESCE(FDS.drive_letter, LEFT(MF.physical_name COLLATE database_default, 1)) AS transaction_log_file_stored_on
			, FDS.free_space_MB AS volume_free_space_MB
			, CAST(LS.log_size AS decimal(38,2)) AS transaction_log_file_size_MB
			, LS.log_space_used_pct
			, CAST((LS.log_space_used_pct / 100.0) * LS.log_size AS decimal(38,2)) AS log_used_size_MB
			, CASE MF.is_percent_growth
				WHEN 1 THEN CAST(MF.growth AS varchar(3)) + ' %'
				ELSE CAST(MF.growth / 128 AS varchar(20)) + ' MB'
			END AS growth				
			, D.log_reuse_wait_desc
			, LB.latest_backup_date
			, DLAD.vlf_count
			, MF.physical_name
	FROM		sys.master_files AS MF
	INNER JOIN	@dbcc_sqlperf_logspace AS LS
				ON LS.database_name = DB_NAME(MF.database_id)
	LEFT JOIN	@free_disk_space AS FDS
				ON FDS.drive_letter = LEFT(MF.physical_name, 1) COLLATE database_default
	INNER JOIN	sys.databases AS D
				ON D.name = LS.database_name COLLATE database_default
	INNER JOIN	@dbcc_loginfo_all_db AS DLAD
				ON DLAD.database_name = D.name COLLATE database_default
				AND DLAD.log_file_id = MF.file_id
				AND DLAD.database_name = DB_NAME(MF.database_id)
	CROSS APPLY	(
				SELECT	MAX(backup_finish_date) AS latest_backup_date
				FROM	msdb.dbo.backupset AS BS
				WHERE	BS.type = 'L'
				AND	BS.database_name = D.name
			) AS LB
	WHERE		MF.type_desc = 'LOG'
	AND		D.source_database_id IS NULL
	AND		D.state_desc = 'ONLINE'
	AND		D.user_access_desc = 'MULTI_USER'
END
ELSE
BEGIN
	IF DB_ID(@_database_name) IS NULL
	BEGIN
		RAISERROR('The database named ''%s'' does not exist', 16, 1, @_database_name)
		RETURN
	END
				
	DECLARE @vlf_count int
	SET @sql = 'DBCC LOGINFO (''' + @_database_name + ''')'

	IF CAST(SERVERPROPERTY('ProductVersion') AS varchar(32)) LIKE '11%'
	BEGIN
		INSERT	INTO @dbcc_loginfo
		EXEC	(@sql)
	END
	ELSE
	BEGIN
		INSERT	INTO @dbcc_loginfo
		(
			fileid
			, file_size
			, start_offset
			, f_seq_no
			, status
			, parity
			, create_LSN
		)
		EXEC	(@sql)
	END

	;WITH
		CTE AS
		(
			SELECT	fileid
				, COUNT(*) AS vlf_count
			FROM	@dbcc_loginfo
			GROUP	BY fileid
		)
	SELECT		LS.database_name
			, D.recovery_model_desc
			, MF.name AS logical_name
			, FDS.drive_letter AS transaction_log_file_stored_on
			, FDS.free_space_MB AS volume_free_space_MB
			, CAST(LS.log_size AS decimal(38,2)) AS transaction_log_file_size_MB
			, LS.log_space_used_pct
			, CAST((LS.log_space_used_pct / 100.0) * LS.log_size AS decimal(38,2)) AS log_used_size_MB
			, CASE MF.is_percent_growth
				WHEN 1 THEN CAST(MF.growth AS varchar(3)) + ' %'
				ELSE CAST(MF.growth / 128 AS varchar(20)) + ' MB'
			END AS growth
			, D.log_reuse_wait_desc
			, LB.latest_backup_date
			, C.vlf_count AS VLF_count
			, MF.physical_name
	FROM		sys.master_files AS MF
	INNER JOIN	@dbcc_sqlperf_logspace AS LS
				ON LS.database_name = DB_NAME(MF.database_id)
	INNER JOIN	@free_disk_space AS FDS
				ON FDS.drive_letter = LEFT(MF.physical_name, 1) COLLATE database_default
	INNER JOIN	sys.databases AS D
				ON D.name = LS.database_name COLLATE database_default
	INNER JOIN	CTE AS C
				ON C.fileid = MF.file_id
	CROSS APPLY	(
				SELECT	MAX(backup_finish_date) AS latest_backup_date
				FROM	msdb.dbo.backupset
				WHERE	type = 'L'
				AND	database_name = @_database_name
			) AS LB
	WHERE		MF.type_desc = 'LOG'
	AND		LS.database_name = @_database_name
	AND		D.source_database_id IS NULL
	AND		D.state_desc = 'ONLINE'
	AND		D.user_access_desc = 'MULTI_USER'
END
