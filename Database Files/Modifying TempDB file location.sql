SELECT	name
	, physical_name
	, size * 8192.0 / 1024 / 1024 AS file_size_MB
	,'ALTER DATABASE TempDB MODIFY FILE (NAME = ''' + name
		+ ''', FILENAME = ''' + REPLACE(LEFT(physical_name, LEN(physical_name) - CHARINDEX('\', REVERSE(physical_name)) + 1), 'D:\', 'S:\')
		+ CASE name 
			WHEN 'tempdev' THEN + 'tempdb.mdf'''
			ELSE name + '.ndf'''
		END
		+ ', SIZE = 1GB)'
FROM	sys.master_files
WHERE	database_id = 2
--AND	type_desc = 'ROWS'
AND	physical_name NOT LIKE 'S:\%'