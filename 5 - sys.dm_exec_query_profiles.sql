SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
GO

DECLARE @session_id int = 95
	, @delay varchar(8) --= '00:00:00.100'
	, @i int = 1

IF OBJECT_ID('TempDB.dbo.#query_profile_global') IS NOT NULL
	DROP TABLE #query_profile_global

CREATE TABLE #query_profile_global
(
	physical_operator_name nvarchar(256) NULL
	, node_id int NULL
	, elapsed_time_ms bigint NULL
	, cpu_time_ms bigint NULL
	, row_count bigint NULL
	, estimate_row_count bigint NULL
	, logical_read_count bigint NULL
	, rewind_count bigint NULL
	, rebind_count bigint NULL
	, operator_execution_time_ms bigint NULL
	, objet_name sysname NULL
	, index_name sysname NULL
	, scan_count bigint NULL
	, time_stamp datetime NULL
)

DECLARE @query_profile TABLE
(
	physical_operator_name nvarchar(256) NULL
	, node_id int NULL
	, elapsed_time_ms bigint NULL
	, cpu_time_ms bigint NULL
	, row_count bigint NULL
	, estimate_row_count bigint NULL
	, logical_read_count bigint NULL
	, rewind_count bigint NULL
	, rebind_count bigint NULL
	, operator_execution_time_ms bigint NULL
	, objet_name sysname NULL
	, index_name sysname NULL
	, scan_count bigint NULL
	, time_stamp datetime NULL
)

WHILE EXISTS
(
	SELECT	*
	FROM	sys.dm_exec_requests
	WHERE	session_id = @session_id
)
BEGIN
	INSERT		INTO @query_profile
	SELECT		QP.physical_operator_name
			, QP.node_id
			, QP.elapsed_time_ms
			, QP.cpu_time_ms
			, QP.row_count
			, QP.estimate_row_count
			, QP.logical_read_count
			, QP.rewind_count
			, QP.rebind_count
			, QP.last_active_time - QP.first_active_time AS operator_execution_time_ms
			, O.name AS objet_name
			, I.name AS index_name
			, QP.scan_count
			, GETDATE() AS time_stamp
	FROM		sys.dm_exec_query_profiles AS QP
	LEFT JOIN	sys.objects AS O
				ON QP.object_id = O.object_id
	LEFT JOIN	sys.indexes AS I
				ON QP.index_id = I.index_id
				AND QP.object_id = I.object_id
	WHERE		QP.session_id = @session_id -- spid running query

	IF @i = 1
	BEGIN
		INSERT	INTO #query_profile_global
		SELECT	*
		FROM	@query_profile
	END
	ELSE
	BEGIN
		UPDATE		#query_profile_global
		SET		physical_operator_name = QP.physical_operator_name
				, node_id = QP.node_id
				, elapsed_time_ms = QP.elapsed_time_ms
				, cpu_time_ms = QP.cpu_time_ms
				, row_count = QP.row_count
				, estimate_row_count = QP.estimate_row_count
				, logical_read_count = QP.logical_read_count
				, rewind_count = QP.rewind_count
				, rebind_count = QP.rebind_count
				, operator_execution_time_ms = QP.operator_execution_time_ms
				, objet_name = QP.objet_name
				, index_name = QP.index_name
				, scan_count = QP.scan_count
				, time_stamp = QP.time_stamp
		FROM		@query_profile AS QP
		INNER JOIN	#query_profile_global AS QFG
					ON QFG.node_id = QP.node_id
	END

	--WAITFOR DELAY @delay

	DELETE FROM @query_profile

	SET @i += 1
END

SELECT	DISTINCT *
FROM	#query_profile_global
ORDER	BY node_id
--ORDER	BY elapsed_time_ms DESC