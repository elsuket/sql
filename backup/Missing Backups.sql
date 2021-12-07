SELECT		D.name
		, D.recovery_model_desc
		, B.recovery_model AS backup_recovery_model
		, B.backup_start_date
		, B.backup_finish_date
		, B.backup_size
		, CASE B.type
			WHEN 'D' THEN 'Full Database'
			WHEN 'I' THEN 'Differential database'
			WHEN 'L' THEN 'Transaction Log'
			WHEN 'F' THEN 'File or filegroup'
			WHEN 'G' THEN 'Differential file'
			WHEN 'P' THEN 'Partial'
			WHEN 'Q' THEN 'Differential partial'
		END AS backup_type
		, B.user_name
FROM		sys.databases AS D
LEFT JOIN	msdb.dbo.backupset AS B
			ON D.name = B.database_name
			AND B.backup_start_date >= '20130123'
WHERE		D.name <> 'TempDB'