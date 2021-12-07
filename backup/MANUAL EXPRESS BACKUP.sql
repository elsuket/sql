SELECT	'BACKUP DATABASE [' + name + '] TO DISK = ''G:\MSSQL\Backup\' + name + '_FULL_MANUAL_20150325.bak'' WITH INIT, COMPRESSION, CHECKSUM, STATS = 1'
FROM	sys.databases
WHERE	database_id <> 2 -- Can't backup TempDB