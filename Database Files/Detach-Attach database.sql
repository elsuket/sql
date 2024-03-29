USE [master]
GO

ALTER DATABASE [myDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO

EXEC master.dbo.sp_detach_db
	@dbname = 'myDB'
	@keepfulltextindexfile = N'true'

-- Rattachement 
CREATE DATABASE maBD
ON (FILENAME = 'C:\myDB.mdf'),
	, (FILENAME = 'C:\myDB_log.ldf')
FOR ATTACH
GO

IF EXISTS
(
	SELECT name
	FROM sys.databases
	WHERE name = N'myDB'
	AND owner_sid <> 0x01
)
EXEC myDB.dbo.sp_changedbowner @loginame = N'sa', @map = false
GO
