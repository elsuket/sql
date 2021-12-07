SET NOCOUNT ON
GO

DECLARE @default_trace_file_path nvarchar(1024)
	, @trace_file_index_current int
	, @trace_file_index_oldest int

SELECt	@default_trace_file_path = path
	, @trace_file_index_current = REPLACE(RIGHT(path, CHARINDEX('_', REVERSE(path)) - 1), '.trc', '')
FROM	sys.traces
WHERE	is_default = 1

SELECT	@trace_file_index_oldest = @trace_file_index_current - 4 -- Sometimes 5 works too

SELECT	@default_trace_file_path = REPLACE(@default_trace_file_path, CAST(@trace_file_index_current AS varchar(10)), CAST(@trace_file_index_oldest AS varchar(10)))
SELECT	@default_trace_file_path

SELECT	CASE EventClass
		WHEN 92 THEN 'Data file auto-growth'
		WHEN 93 THEN 'Log file auto-growth'
	END AS event_class
	, StartTime
	, EndTime
	, Duration
	, ApplicationName
	, DatabaseID
	, DatabaseName
	, FileName
	, SessionLoginName
	, LoginName
	, NTDomainName
	, HostName
	, ClientProcessID
	, SPID
FROM	sys.fn_trace_gettable(@default_trace_file_path, DEFAULT)
WHERE	1 = 1
AND	EventClass IN (92, 93)

/*
SELECT		D.DatabaseName
		, D.FileName
		, D.physical_name
		, D.type_desc
		, D.HostName
		, D.ApplicationName
		, J.name AS job_name
		, SUBSTRING(D.ApplicationName, 29, 36)
		, D.SessionLoginName
		, D.growth
		, D.avg_Duration_ms
		, D.growth_occurences
		, D.min_StartTime
		, D.growth_occurences * REPLACE(D.growth, ' MB', '') AS total_file_growth_MB
FROM		CTE AS D
LEFT JOIN	msdb.dbo.sysjobs AS J
			ON J.job_id = CASE WHEN D.ApplicationName LIKE 'SQLAgent - TSQL JobStep (Job %' THEN SUBSTRING(D.ApplicationName, 29, 36) ELSE NULL END
ORDER BY	D.max_StartTime

SELECT	*
FROM	msdb.dbo.sysjobs
WHERE	job_id = 0x6B4311925C39A74DABCF6D84F343FBF4
*/
/*
DECLARE @s varchar(max) = 'SQLAgent - TSQL JobStep (Job 0x4CAB3385E40CC5499A7D825DA11D600B : Step 1)'

SELECT SUBSTRING(@s, 29, 36)
*/


