SELECT		D.name AS database_name
		, SUM(MF.size) / 128 AS database_size_MB
		, D.recovery_model_desc
		, P.name AS database_owner_name
		, D.compatibility_level
		, D.page_verify_option_desc
FROM		sys.databases AS D
INNER JOIN	sys.master_files AS MF
			ON D.database_id = MF.database_id
INNER JOIN	sys.server_principals AS P
			ON P.sid = D.owner_sid
WHERE		MF.type_desc = 'ROWS'
AND		D.database_id > 4
AND		D.is_distributor = 0
GROUP BY	D.name, D.recovery_model_desc, P.name, D.compatibility_level, D.page_verify_option_desc