WITH
	INDEX_DEFINITION AS
	(
		SELECT		S.schema_id
				, O.object_id
				, I.index_id
				, C.column_id
				, IC.key_ordinal
		FROM		sys.schemas AS S
		INNER JOIN	sys.objects AS O
					ON S.schema_id = O.schema_id
		INNER JOIN	sys.indexes AS I
					ON O.object_id = I.object_id
		INNER JOIN	sys.index_columns AS IC
					ON IC.object_id = I.object_id
					AND IC.index_id = I.index_id
		INNER JOIN	sys.columns AS C
					ON IC.object_id = C.object_id
					AND IC.column_id = C.column_id
		WHERE		S.name <> 'sys'
		AND		I.index_id > 0 -- Excluding heaps
		--ORDER BY	O.name, I.name, IC.index_column_id
	)
	, INDEX_DUPLICATES AS
	(
		SELECT		DISTINCT A.schema_id
				, A.object_id
				, A.index_id
				, A.column_id
		FROM		INDEX_DEFINITION AS A
		INNER JOIN	INDEX_DEFINITION AS B
					ON A.schema_id = B.schema_id
					AND A.object_id = B.object_id
					AND A.index_id <> B.index_id
					AND A.column_id = B.column_id
					AND A.key_ordinal = B.key_ordinal
	)
SELECT		DISTINCT S.name AS schema_name
		, O.name AS table_name
		, I.name AS index_name
		, LEFT(KCL.key_column_list, LEN(KCL.key_column_list) - 1) AS key_column_list
		, LEFT(ICL.included_column_list, LEN(ICL.included_column_list) - 1) AS included_column_list
		, I.filter_definition
		, I.is_unique
		, I.is_unique_constraint
		, I.is_primary_key
		, IUS.user_seeks
		, IUS.user_scans
		, IUS.user_lookups
		, IUS.user_updates
		, (
			SELECT	MAX(last_user_search)
			FROM	(
					VALUES (IUS.last_user_seek), (IUS.last_user_scan), (IUS.last_user_lookup)
				) AS V (last_user_search)
		) AS last_user_search
FROM		INDEX_DUPLICATES AS ID
INNER JOIN	sys.objects AS O
			ON ID.object_id = O.object_id
INNER JOIN	sys.schemas AS S
			ON O.schema_id = S.schema_id
INNER JOIN	sys.indexes AS I
			ON I.object_id = ID.object_id
			AND I.index_id = ID.index_id
LEFT JOIN	sys.dm_db_index_usage_stats AS IUS
			ON I.object_id = IUS.object_id
			AND I.index_id = IUS.index_id
			AND IUS.database_id = DB_ID()
CROSS APPLY	(
			SELECT		C.name + ', '
			FROM		sys.index_columns AS IC
			INNER JOIN	sys.columns AS C
						ON IC.object_id = C.object_id
						AND IC.column_id = C.column_id
			WHERE		I.object_id = IC.object_id
			AND		I.index_id = IC.index_id
			AND		IC.is_included_column = 0
			ORDER BY	IC.index_column_id
			FOR		XML PATH ('')
		) AS KCL(key_column_list)
OUTER APPLY	(
			SELECT		C.name + ', '
			FROM		sys.index_columns AS IC
			INNER JOIN	sys.columns AS C
						ON IC.object_id = C.object_id
						AND IC.column_id = C.column_id
			WHERE		I.object_id = IC.object_id
			AND		I.index_id = IC.index_id
			AND		IC.is_included_column = 1
			ORDER BY	IC.index_column_id
			FOR		XML PATH ('')
		) AS ICL(included_column_list)