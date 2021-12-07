SELECT	LEFT(@@SERVERNAME, CASE CHARINDEX('\', @@SERVERNAME)  WHEN 0 THEN LEN(@@SERVERNAME) ELSE CHARINDEX('\', @@SERVERNAME) - 1 END) AS srv_code
	, CASE CHARINDEX('\', @@SERVERNAME)
		WHEN 0 THEN 'MSSQLSERVER'
		ELSE RIGHT(@@SERVERNAME, LEN(@@SERVERNAME) - CHARINDEX('\', @@SERVERNAME))
	END AS inst_name
	, CASE WHEN EXISTS
	(
		SELECT	*
		FROM	sys.traces
		WHERE	(
				path LIKE '%\log?_[0-9].trc' ESCAPE '?'
				OR path LIKE '%\log?_[0-9][0-9].trc' ESCAPE '?'
				OR path LIKE '%\log?_[0-9][0-9][0-9].trc' ESCAPE '?'
				OR path LIKE '%\log?_[0-9][0-9][0-9][0-9].trc' ESCAPE '?'
			)
	) THEN 1 ELSE 0 END AS is_default_trace_started