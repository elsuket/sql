WITH
	CTE AS
	(
		SELECT		S.name AS schema_name
				, O.name AS table_name
				, I.name AS index_name
				, C.name AS column_name
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
		--ORDER BY	O.name, I.name, IC.index_column_id
	)
SELECT		DISTINCT A.schema_name
		, A.table_name
		, A.index_name
		, A.column_name
FROM		CTE AS A
INNER JOIN	CTE AS B
			ON A.schema_name = B.schema_name
			AND A.table_name = B.table_name
			AND A.index_name <> B.index_name
			AND A.column_name = B.column_name
			AND A.key_ordinal = B.key_ordinal