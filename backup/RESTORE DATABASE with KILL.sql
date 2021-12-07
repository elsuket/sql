------------------------------------------------------------
DECLARE @database_to_be_dropped sysname = 'PPC'
------------------------------------------------------------
IF @database_to_be_dropped IS NULL
BEGIN
	RAISERROR('The database name cannot be NULL', 16, 1)
	RETURN
END

IF NOT EXISTS
(
	SELECT	*
	FROM	sys.databases
	WHERE	name = @database_to_be_dropped
)
BEGIN
	RAISERROR('The ''%s'' database does not exist', 16, 1, @database_to_be_dropped)
	RETURN
END

-------------------------------------------------------
-- Ending processes that are connected to that database
-------------------------------------------------------
DECLARE @sql varchar(max)

SELECT	@sql = CASE
			WHEN @sql IS NULL THEN 'KILL ' + CAST(spid AS varchar(10))
			ELSE @sql + '; KILL ' + CAST(spid AS varchar(10))
		END
FROM	sys.sysprocesses
WHERE	dbid = DB_ID(@database_to_be_dropped)

PRINT @sql
EXEC (@sql)

-------------------------
-- Restoring the database
-------------------------
RESTORE DATABASE PPC
FROM DISK = 'Y:\Agoda\database\backup\PPC\PPC_backup_2013_09_23_060006_5640391.bak'
WITH STATS = 1