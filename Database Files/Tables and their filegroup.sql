-- To retrieve tables and the filegroup they are stored in
SELECT		t.name AS table_name
		, i.name AS index_name
		, fg.name AS filegroup_name
FROM		sys.tables AS t
INNER JOIN	sys.indexes AS i
			ON i.object_id = t.object_id
INNER JOIN	sys.filegroups AS fg
			ON fg.data_space_id = i.data_space_id
WHERE		i.index_id BETWEEN 0 AND 1
AND		t.name LIKE 't?_log?_iis?_2[0-1][0-9][0-9][0-9][0-9]%' ESCAPE '?'
ORDER BY	t.name