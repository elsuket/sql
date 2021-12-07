USE Agoda_DBA
GO

DECLARE @t TABLE
(
	t smallint IDENTITY(0, 1)
	, database_name varchar(128)
	, log_year smallint
	, log_month tinyint
	, file_type varchar(60)
	, volume_letter char(1)
	, avg_database_size_MB int
)

;WITH
	CTE AS
	(
		SELECT		database_name
				, CAST(log_date_time AS date) AS log_date
				, file_type
				, LEFT(physical_name, 1) AS volume_letter
				, SUM(file_size_KB) / 1024 AS database_size_MB
		FROM		Agoda_dba.audit.database_file_space AS FS
		INNER JOIN	sys.databases AS S
					ON S.name = FS.database_name
		WHERE		S.database_id > 4
		--AND		file_logical_name LIKE 'k%'
		GROUP BY	database_name, CAST(log_date_time AS date), LEFT(physical_name, 1), file_type
	)
	, AGG AS
	(
		SELECT	database_name
			, YEAR(log_date) AS log_year
			, MONTH(log_date) AS log_month
			, file_type
			, volume_letter
			, AVG(database_size_MB) AS avg_database_size_MB
		FROM	CTE
		GROUP	BY database_name, YEAR(log_date), MONTH(log_date), volume_letter, file_type
	)
INSERT	INTO @t
(
	database_name
	, log_year
	, log_month
	, file_type
	, volume_letter
	, avg_database_size_MB
)
SELECT	database_name
	, log_year
	, log_month
	, file_type
	, UPPER(volume_letter)
	, avg_database_size_MB
FROM	AGG
ORDER	BY database_name, volume_letter, log_year, log_month

SELECT		A.database_name
		, A.volume_letter
		, A.log_year
		, A.log_month
		, A.file_type
		, A.avg_database_size_MB AS previous_avg_database_size_MB
		, B.avg_database_size_MB AS next_avg_database_size_MB
		, B.avg_database_size_MB - A.avg_database_size_MB AS month_growth_MB
FROM		@t AS A
LEFT JOIN	@t AS B
			ON A.t + 1 = B.t
			AND A.database_name = B.database_name
			AND A.volume_letter = B.volume_letter
--WHERE		B.avg_database_size_MB - A.avg_database_size_MB > 0
WHERE		A.database_name = 'Agoda_BI'
--WHERE		A.volume_letter = 'K'
ORDER BY	A.database_name
		, A.volume_letter
		, A.log_year
		, A.log_month
		, A.file_type

/*
SELECT	AVG(month_growth_MB)
FROM	(
		SELECT		A.log_year
				, A.log_month
				, A.avg_database_size_MB AS previous_avg_database_size_MB
				, B.avg_database_size_MB AS next_avg_database_size_MB
				, B.avg_database_size_MB - A.avg_database_size_MB AS month_growth_MB
				, A.volume_letter
		FROM		@t AS A
		LEFT JOIN	@t AS B
					ON A.t + 1 = B.t
	) AS S
*/