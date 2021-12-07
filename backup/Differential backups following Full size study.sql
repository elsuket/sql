WITH
	cte AS 
	(
		SELECT		f.database_name
				, f.backup_start_date AS full_backup_start_date
				, d.backup_start_date AS diff_backup_date
				, diff_backup_order
				, CAST(f.backup_size / (1024 * 1024) AS int) AS full_backup_size_MB
				, d.backup_size_MB AS diff_backup_size_MB
		FROM		msdb.dbo.backupset AS f
		CROSS APPLY	(
					SELECT	TOP 3 database_name
						, backup_start_date
						, backup_finish_date
						, CAST(backup_size / (1024 * 1024) AS int) AS backup_size_MB
						--, compressed_backup_size / (1024 * 1024)  AS compressed_backup_size_MB
						, ROW_NUMBER() OVER(PARTITION BY database_name ORDER BY backup_start_date) AS diff_backup_order
					FROM	msdb.dbo.backupset AS d
					WHERE	user_name = 'NT AUTHORITY\SYSTEM'
					AND	is_copy_only = 0
					AND	type = 'I'
					AND	f.database_name = d.database_name
					AND	f.first_lsn = d.differential_base_lsn
					AND	f.backup_start_date < d.backup_start_date
				) AS d
		WHERE		f.user_name = 'NT AUTHORITY\SYSTEM'
		AND		f.is_copy_only = 0
		AND		f.type = 'D'
		AND		f.database_name = 'buyer_flextronics_prod'
	)
SELECT	*
	, 100 * diff_backup_size_MB / full_backup_size_MB AS diff_vs_full_ratio_percent
FROM	cte
ORDER	BY full_backup_start_date