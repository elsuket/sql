USE tempdb
GO

SELECT		MF.physical_name
		, MF.size as entire_file_page_count
		, DFSU.unallocated_extent_page_count
		, DFSU.user_object_reserved_page_count
		, DFSU.internal_object_reserved_page_count
		, DFSU.mixed_extent_page_count
FROM		sys.dm_db_file_space_usage DFSU
INNER JOIN	sys.master_files AS MF
			ON MF.database_id = DFSU.database_id
                         AND MF.file_id = DFSU.file_id