SELECT	COUNT(*)
FROM	sys.dm_os_schedulers
WHERE	scheduler_id < 255
AND	is_online = 1

SELECT	database_id
	, file_id
	, type_desc
	, data_space_id
	, name
	, physical_name
	, state_desc
	, size / 128 AS file_size_MB
	, max_size / 128 AS max_file_size_MB
	, growth / 128 AS file_growth_size_MB
FROM	sys.master_files
WHERE	database_id = 2
AND	type_desc = 'ROWS'

EXEC xp_fixeddrives

/*
ALTER DATABASE TempDB ADD FILE (NAME = 'temp5', FILENAME = 'S:\SQL2017\MSSQL14.SQL2017\MSSQL\DATA\temp5.ndf', SIZE = 10GB, FILEGROWTH = 1GB, MAXSIZE = 10GB)
ALTER DATABASE TempDB ADD FILE (NAME = 'temp6', FILENAME = 'S:\SQL2017\MSSQL14.SQL2017\MSSQL\DATA\temp6.ndf', SIZE = 10GB, FILEGROWTH = 1GB, MAXSIZE = 10GB)
ALTER DATABASE TempDB ADD FILE (NAME = 'temp7', FILENAME = 'S:\SQL2017\MSSQL14.SQL2017\MSSQL\DATA\temp7.ndf', SIZE = 10GB, FILEGROWTH = 1GB, MAXSIZE = 10GB)
ALTER DATABASE TempDB ADD FILE (NAME = 'temp8', FILENAME = 'S:\SQL2017\MSSQL14.SQL2017\MSSQL\DATA\temp8.ndf', SIZE = 10GB, FILEGROWTH = 1GB, MAXSIZE = 10GB)

ALTER DATABASE TempDB ADD FILE (NAME = 'temp9', FILENAME = 'S:\SQL2017\MSSQL14.SQL2017\MSSQL\DATA\temp9.ndf', SIZE = 10GB, FILEGROWTH = 1GB, MAXSIZE = 10GB)
ALTER DATABASE TempDB ADD FILE (NAME = 'temp10', FILENAME = 'S:\SQL2017\MSSQL14.SQL2017\MSSQL\DATA\temp10.ndf', SIZE = 10GB, FILEGROWTH = 1GB, MAXSIZE = 10GB)
ALTER DATABASE TempDB ADD FILE (NAME = 'temp11', FILENAME = 'S:\SQL2017\MSSQL14.SQL2017\MSSQL\DATA\temp11.ndf', SIZE = 10GB, FILEGROWTH = 1GB, MAXSIZE = 10GB)
ALTER DATABASE TempDB ADD FILE (NAME = 'temp12', FILENAME = 'S:\SQL2017\MSSQL14.SQL2017\MSSQL\DATA\temp12.ndf', SIZE = 10GB, FILEGROWTH = 1GB, MAXSIZE = 10GB)

ALTER DATABASE TempDB ADD FILE (NAME = 'temp13', FILENAME = 'S:\SQL2017\MSSQL14.SQL2017\MSSQL\DATA\temp13.ndf', SIZE = 10GB, FILEGROWTH = 1GB, MAXSIZE = 10GB)
ALTER DATABASE TempDB ADD FILE (NAME = 'temp14', FILENAME = 'S:\SQL2017\MSSQL14.SQL2017\MSSQL\DATA\temp14.ndf', SIZE = 10GB, FILEGROWTH = 1GB, MAXSIZE = 10GB)
ALTER DATABASE TempDB ADD FILE (NAME = 'temp15', FILENAME = 'S:\SQL2017\MSSQL14.SQL2017\MSSQL\DATA\temp15.ndf', SIZE = 10GB, FILEGROWTH = 1GB, MAXSIZE = 10GB)
ALTER DATABASE TempDB ADD FILE (NAME = 'temp16', FILENAME = 'S:\SQL2017\MSSQL14.SQL2017\MSSQL\DATA\temp16.ndf', SIZE = 10GB, FILEGROWTH = 1GB, MAXSIZE = 10GB)
*/