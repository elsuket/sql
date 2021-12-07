DECLARE @s TABLE
(
	drive_letter char(1) NOT NULL
	, free_space_MB int NOT NULL
)

INSERT INTO @s
(
	drive_letter
	, free_space_MB
)
EXEC xp_fixeddrives

SELECt		d.name
		, d.recovery_model_desc
		, d.log_reuse_wait_desc
		, d.target_recovery_time_in_seconds
		, ls.active_log_size_mb
		, ls.total_log_size_mb
		, CAST(100 * ls.active_log_size_mb / ls.total_log_size_mb AS int) AS log_occupation_percent
		, LEFT(f.physical_name, 1) AS log_file_volume
		, CAST(100 * ls.total_log_size_mb / s.free_space_MB AS int) AS log_file_disk_usage_percent
FROM		sys.databases AS d
CROSS APPLY	sys.dm_db_log_stats(d.database_id) AS ls
INNER JOIN	sys.master_files AS f
			ON d.database_id = f.database_id
INNER JOIN	@s AS s
			ON s.drive_letter = LEFT(f.physical_name, 1)
WHERE		(
			d.database_id  = 2
			OR d.database_id > 4
		)
AND		f.type_desc = 'LOG'

