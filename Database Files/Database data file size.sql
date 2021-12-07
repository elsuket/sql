SELECT		D.name AS database_name
		, SUM(CAST(MF.size AS bigint)) * 8192 / 1024 / 1024 AS file_size_MB
FROM		sys.databases AS D
INNER JOIN	sys.master_files AS MF
			ON D.database_id = MF.database_id
WHERE		MF.type_desc = 'ROWS'
--AND		D.name = 'msdb'
GROUP BY	D.name