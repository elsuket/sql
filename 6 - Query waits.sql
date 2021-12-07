DECLARE @session_id int = 106

IF CAST(SERVERPROPERTY('ProductMajorVersion') AS int) >= 13 -- SQL Server 2016
BEGIN
	SELECT	*
	FROM	sys.dm_exec_session_wait_stats
	WHERE	session_id = @session_id
	ORDER	BY wait_time_ms DESC
END
ELSE
BEGIN
	IF OBJECT_ID('TempDB.dbo.#query_waits') IS NOT NULL
	BEGIN
		DROP TABLE #query_waits
	END

	CREATE TABLE #query_waits
	(
		log_id int NOT NULL
		, waiting_task_address varbinary(8) NOT NULL
		, session_id smallint NULL
		, exec_context_id int NULL
		, wait_duration_ms bigint NULL
		, wait_type nvarchar(60) NULL
		, resource_address varbinary(8) NULL
		, blocking_task_address varbinary(8) NULL
		, blocking_session_id smallint NULL
		, blocking_exec_context_id int NULL
		, resource_description nvarchar(2048) NULL
	)

	SET NOCOUNT ON

	DECLARE @i int = 0

	WHILE EXISTS
	(
		SELECT	*
		FROM	sys.dm_exec_requests
		WHERE	session_id = @session_id
	)
	BEGIN
		INSERT INTO #query_waits
		SELECT	@i
			, *
		FROM	sys.dm_os_waiting_tasks
		WHERE	session_id = @session_id

		SET @i += 1
	END

	SELECT	wait_type
		, SUM(wait_duration_ms) AS wait_duration_ms
		, COUNT(*) AS wait_count
		, CAST(SUM(wait_duration_ms) / CAST(COUNT(*) AS decimal) AS decimal(5,2)) avg_wait_duration_ms
	FROM	#query_waits
	GROUP	BY wait_type
	ORDER	BY wait_duration_ms DESC
END