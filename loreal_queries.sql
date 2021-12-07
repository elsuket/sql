SELECT	start_time
	, CAST(start_time AS date) AS execution_date
	, duration_ms
	, cpu AS cpu_ms
	, reads
	, writes
	, text_data
	, error
	, row_count
	, database_name
	, event_type_id
	, query_hash
	, has_perimeter_subqueries
	, partitionning_key
FROM	dbo.t_trace_event
WHERE	1 = 1
AND	partitionning_key = CAST(ABS(CHECKSUM('buyer_loreal_prod')) % 5000 AS smallint)
AND	database_name = 'buyer_loreal_prod'
AND	start_time > '2021-04-19'
AND	text_data LIKE '%INSERT INTO @tmp_item_fields%'
/*
AND	text_data LIKE '%p?_pdt?_item?_tag%' ESCAPE '?'
AND	start_time > '2021-02-02 17:30'
AND	start_time < '2021-02-02 18:30'
*/