DECLARE @database_name sysname = 'ELSUKET'
	, @backup_start_date datetime
	, @backup_set_id_start int
	, @backup_set_id_end int

SELECT	@backup_set_id_start = MAX(backup_set_id)
FROM	msdb.dbo.backupset
WHERE	database_name = @database_name
AND	type = 'D' -- Full database backup

SELECT	@backup_set_id_end = MIN(backup_set_id)
FROM	msdb.dbo.backupset
WHERE	database_name = @database_name
AND	type = 'D'
AND	backup_set_id > @backup_set_id_start

SELECT @backup_set_id_end = COALESCE(@backup_set_id_end, 999999999)

	SELECT		B.backup_set_id
			, 'RESTORE FILELISTONLY FROM DISK = ''' + MF.physical_device_name + ''' WITH NORECOVERY'
	FROM		msdb.dbo.backupset AS B
	INNER JOIN	msdb.dbo.backupmediafamily AS MF
				ON B.media_set_id = MF.media_set_id
	WHERE		B.database_name = @database_name
	AND		B.backup_set_id = @backup_set_id_start
UNION ALL
	SELECT		B.backup_set_id
			, 'RESTORE DATABASE ' + @database_name
				+ ' FROM DISK = ''' + MF.physical_device_name + ''' WITH NORECOVERY'
	FROM		msdb.dbo.backupset AS B
	INNER JOIN	msdb.dbo.backupmediafamily AS MF
				ON B.media_set_id = MF.media_set_id
	WHERE		B.database_name = @database_name
	AND		B.backup_set_id = @backup_set_id_start
UNION ALL
	SELECT		B.backup_set_id
			, 'RESTORE LOG ' + @database_name
				+ ' FROM DISK = ''' + MF.physical_device_name + ''' WITH NORECOVERY'
	FROM		msdb.dbo.backupset AS B
	INNER JOIN	msdb.dbo.backupmediafamily AS MF
				ON B.media_set_id = MF.media_set_id
	WHERE		B.database_name = @database_name
	AND		B.backup_set_id >= @backup_set_id_start
	AND		B.backup_set_id < @backup_set_id_end
	AND		B.type = 'L'
UNION ALL
	SELECT	999999999 AS backup_set_id
		, 'RESTORE DATABASE ' + @database_name + ' WITH RECOVERY'
ORDER BY backup_set_id