SELECT		D.name AS database_name
		, D.recovery_model_desc
		, CASE B.type
			WHEN 'D' THEN 'Full Database'
			WHEN 'I' THEN 'Differential database'
			WHEN 'L' THEN 'Transaction Log'
			WHEN 'F' THEN 'File or filegroup'
			WHEN 'G' THEN 'Differential file'
			WHEN 'P' THEN 'Partial'
			WHEN 'Q' THEN 'Differential partial'
		END AS backup_type
		, MIN(B.backup_start_date) AS oldest_backup
		, MAX(B.backup_start_date) AS latest_backup
		, DATEDIFF(DAY, MIN(B.backup_start_date), MAX(B.backup_start_date)) AS day_count
		, COUNT(*) AS backup_count
FROM		sys.databases AS D
LEFT JOIN	msdb.dbo.backupset AS B
			ON D.name = B.database_name
GROUP BY	D.name, D.recovery_model_desc, CASE B.type
			WHEN 'D' THEN 'Full Database'
			WHEN 'I' THEN 'Differential database'
			WHEN 'L' THEN 'Transaction Log'
			WHEN 'F' THEN 'File or filegroup'
			WHEN 'G' THEN 'Differential file'
			WHEN 'P' THEN 'Partial'
			WHEN 'Q' THEN 'Differential partial'
		END