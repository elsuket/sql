SELECT		DISTINCT vs.volume_mount_point
		, vs.total_bytes / 1024 / 1024 / 1024 AS volume_size_GB
		, vs.available_bytes / 1024 / 1024 / 1024 AS volume_free_space_GB
FROM		sys.master_files AS f  
CROSS APPLY	sys.dm_os_volume_stats(f.database_id, f.file_id) AS vs