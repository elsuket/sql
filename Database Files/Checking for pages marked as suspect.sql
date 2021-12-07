SELECT		D.name AS database_name
		, MF.name AS file_logical_name
		, MF.physical_name AS file_physical_name
		, SP.page_id
		, CASE SP.event_type
			WHEN 1 THEN 'CRC check error'
			WHEN 2 THEN 'Bad checksum'
			WHEN 3 THEN 'Torn page'
			WHEN 4 THEN 'Restored'
			WHEN 5 THEN 'Repaired by DBCC'
			WHEN 7 THEN 'Deallocated by DBCC'
		END AS event_desc
		, SP.error_count
		, SP.last_update_date
FROM		msdb.dbo.suspect_pages AS SP
LEFT JOIN	sys.databases AS D
			ON D.database_id = SP.database_id
LEFT JOIN	sys.master_files AS MF
			ON MF.database_id = SP.database_id
			AND MF.file_id = SP.file_id
