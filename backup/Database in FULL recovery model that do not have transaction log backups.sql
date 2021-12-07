SELECT		D.name AS database_name
		, D.recovery_model_desc
		, MF.physical_name
		, ((MF.size * CAST(8192 AS bigint)) / 1024) / 1024 AS file_size_MB
FROM		sys.databases AS D
LEFT JOIN	msdb.dbo.backupset AS S
			ON D.name = S.database_name
			AND S.type = 'L'
INNER JOIN	sys.master_files AS MF
			ON MF.database_id = D.database_id
WHERE		D.recovery_model BETWEEN 1 AND 2 -- FULL, BULK_LOGGED
AND		S.type IS NULL
AND		D.database_id NOT BETWEEN 2 AND 3 -- TempDB and model
AND		MF.type_desc = 'LOG'