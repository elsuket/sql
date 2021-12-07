DECLARE @xp_fixeddrives TABLE
(
	drive_letter char(1) NOT NULL
	, free_MB int
)

DECLARE @drive_letter varchar(50)

INSERT	INTO @xp_fixeddrives
EXEC	xp_fixeddrives

SELECT	TOP 1 @drive_letter = drive_letter + ' : ' + CAST(free_MB AS VARCHAR(20))
FROM	@xp_fixeddrives
ORDER	BY free_MB DESC

SELECT		D.name AS database_name
		, SUM(((MF.size * CAST(8192 AS bigint)) / 1024) / 1024) AS total_file_size_MB
		, @drive_letter AS suggested_backup_drive
FROM		sys.databases AS D
INNER JOIN	sys.master_files AS MF
			ON D.database_id = MF.database_id
WHERE		D.database_id > 4
AND		D.name <> 'distribution'
AND		MF.type_desc = 'ROWS'
GROUP BY	D.name