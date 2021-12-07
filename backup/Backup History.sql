--DBCC TRACEOFF (3605, 3213, -1)

USE msdb
GO
--------------------------------------------------------------------------------
DECLARE	@database_name sysname = 'buyer_axa_prod' -- Can be NULL so as to display all DBs
	, @backup_type varchar(21) --= 'Full Database' -- Full Database | Differential database | Transaction Log | File or filegroup | Differential file | Partial | Differential partial
	, @start_search_date_time datetime = DATEADD(day, 30 * 1440 * -1, CAST(CAST(GETDATE() AS date) AS datetime))
--------------------------------------------------------------------------------
IF @backup_type IS NOT NULL
BEGIN
	SELECT	@backup_type = CASE @backup_type
			WHEN 'Full Database' THEN 'D' 
			WHEN 'Differential database' THEN 'I'
			WHEN 'Transaction Log' THEN 'L'
			WHEN 'File or filegroup' THEN 'F'
			WHEN 'Differential file' THEN 'G'
			WHEN 'Partial' THEN 'P'
			WHEN 'Differential partial' THEN 'Q'
		END

	IF @backup_type IS NULL
	BEGIN
		RAISERROR('Incorrect backup type', 16, 1)
		RETURN
	END
END

;WITH
	CTE AS
	(
		SELECT	database_name
			, user_name
			, last_backup_start_date_time
			, last_backup_end_date_time
			, DATEDIFF(minute, last_backup_end_date_time, GETDATE()) AS backup_taken_ago_min
			, DATEDIFF(second, last_backup_start_date_time, last_backup_end_date_time) AS backup_duration_s
			, backup_type
			, physical_device_name
			, backup_size / (1024 * 1024) AS backup_size_MB
			, compressed_backup_size / (1024 * 1024)  AS compressed_backup_size_MB
			, CAST(backup_size / compressed_backup_size AS decimal(5,2)) AS compression_ratio			
			, is_copy_only
			, recovery_model
			, has_backup_checksums
			, first_lsn
			, last_lsn
			, checkpoint_lsn
			, database_backup_lsn
			, fork_point_lsn
			, differential_base_lsn
		FROM	(
				SELECT		S.database_name
						, S.user_name
						, MAX(S.backup_start_date) AS last_backup_start_date_time
						, MAX(S.backup_finish_date) AS last_backup_end_date_time
						, CASE S.type
							WHEN 'D' THEN 'Full Database'
							WHEN 'I' THEN 'Differential database'
							WHEN 'L' THEN 'Transaction Log'
							WHEN 'F' THEN 'File or filegroup'
							WHEN 'G' THEN 'Differential file'
							WHEN 'P' THEN 'Partial'
							WHEN 'Q' THEN 'Differential partial'
						END AS backup_type
						, MF.physical_device_name
						, S.backup_size
						, S.compressed_backup_size
						, S.is_copy_only
						, S.recovery_model
						, S.has_backup_checksums
						, S.first_lsn
						, S.last_lsn
						, S.checkpoint_lsn
						, S.database_backup_lsn
						, S.fork_point_lsn
						, S.differential_base_lsn
				FROM		msdb.dbo.backupset AS S
				INNER JOIN	msdb.dbo.backupmediafamily AS MF
							ON S.media_set_id = MF.media_set_id
				WHERE		(
							S.database_name LIKE @database_name
							OR @database_name IS NULL
						)
				AND		(
							S.type = @backup_type
							OR @backup_type IS NULL
						)
				AND		(
							S.backup_start_date >= @start_search_date_time
							OR @start_search_date_time IS NULL
						)
				GROUP BY	S.database_name
						, S.type
						, MF.physical_device_name
						, S.backup_size
						, S.compressed_backup_size
						, S.user_name
						, S.is_copy_only
						, S.recovery_model
						, S.has_backup_checksums
						, S.first_lsn
						, S.last_lsn
						, S.checkpoint_lsn
						, S.database_backup_lsn
						, S.fork_point_lsn
						, S.differential_base_lsn

			) AS BH
	)
SELECT		D.name AS database_name
		, C.user_name
		, C.last_backup_start_date_time
		, C.last_backup_end_date_time
		, CAST(C.backup_duration_s / 60.0 AS int) AS backup_duration_min
		, CAST((C.backup_duration_s / 3600) AS varchar(2)) + 'h '
			+ CAST(C.backup_duration_s / 60 % 60 AS varchar(2)) + '" '
			+ CAST(C.backup_duration_s % 60 AS varchar(2)) + '''' AS backup_duration
		, CAST(C.backup_taken_ago_min / 1440 AS varchar(3)) + 'd '
			+ CAST((C.backup_taken_ago_min % 1440) / 60 AS varchar(2)) + 'h '
			+ CAST(C.backup_taken_ago_min % 60 AS varchar(2)) + '"' AS backup_taken_ago
		, C.backup_type
		, C.physical_device_name
		, CAST(C.backup_size_MB AS decimal(15,2)) AS backup_size_MB
		, CAST(C.compressed_backup_size_MB AS decimal(15,2)) AS compressed_backup_size_MB
		, compression_ratio		
		, C.is_copy_only
		, C.recovery_model
		, C.has_backup_checksums
		, C.first_lsn
		, C.last_lsn
		, C.checkpoint_lsn
		, C.database_backup_lsn
		, C.fork_point_lsn
		, C.differential_base_lsn
FROM		sys.databases AS D
INNER JOIN	CTE AS C
			ON D.name = C.database_name
-- WHERE		D.name LIKE '%log%'
--ORDER BY	C.last_backup_end_date_time 
ORDER BY	C.last_backup_end_date_time DESC
--ORDER BY	backup_size_MB DESC

/*
SELECT	CAST(last_backup_end_date_time AS date) AS backup_date
	, backup_duration_min
	, backup_size_MB
FROM	#TOTO
ORDER	BY backup_date
*/

/*
DECLARE @cmd nvarchar(max)

SET @cmd = 'BACKUP DATABASE [' + DB_NAME() +']
TO  DISK = N''E:\backup\' + LOWER(CAST(SERVERPROPERTY('MachineName') AS nvarchar(max)))
	+'_sql_' + LOWER(CAST(SERVERPROPERTY('InstanceName') AS nvarchar(max))) + '_' + DB_NAME() +'_'
	+ RIGHT(('0000' + CAST(YEAR(GETDATE()) AS varchar(4))), 4) + RIGHT(('00' + CAST(MONTH(GETDATE()) AS varchar(4))), 2)
		+ RIGHT(('00' + CAST(DAY(GETDATE()) AS varchar(4))), 2) + RIGHT(('00' + CAST(DATEPART(HOUR, GETDATE()) AS varchar(4))), 2)
		+ RIGHT(('00' + CAST(DATEPART(MINUTE, GETDATE()) AS varchar(4))), 2)
	+'_diff.bak'' 
WITH DIFFERENTIAL, CHECKSUM, NAME = N''' + DB_NAME() + ' Differential bkup by '+ SYSTEM_USER +''', COPY_ONLY, STATS = 1'
+ CASE WHEN CAST(SERVERPROPERTY('Edition') AS varchar(50)) LIKE 'Standard%'
	AND (CAST(SERVERPROPERTY('ProductVersion') AS varchar(50)) LIKE '9%' OR CAST(SERVERPROPERTY('ProductVersion') AS varchar(50)) LIKE '10.0%') THEN '' ELSE ', COMPRESSION' END

PRINT @cmd

EXEC sp_executesql @cmd
*/
/*
Start-BackupSql -force *DBName*
Start-BackupSql -force full *DBName*
*/
