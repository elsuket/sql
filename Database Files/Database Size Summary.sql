SET NOCOUNT ON
GO

DECLARE @sql nvarchar(2048)
	, @database_name sysname
	, @total_size_MB int
	, @space_used_MB int

DECLARE @database_list TABLE
(
	database_name varchar(128)
	, total_size_MB int
	, space_used_MB int
	, free_space_MB AS (total_size_MB - space_used_MB)
)

INSERT	INTO @database_list (database_name)
SELECT	name
FROM	sys.databases
WHERE	source_database_id IS NULL
AND	state_desc = 'ONLINE'
AND	database_id <> 2

WHILE EXISTS
(
	SELECT	*
	FROM	@database_list
	WHERE	total_size_MB IS NULL
)
BEGIN
	SELECT TOP 1 @database_name = database_name
		, @total_size_MB = NULL
		, @space_used_MB = NULL
	FROM	@database_list
	WHERE	total_size_MB IS NULL

	SET @sql = 'USE [' + @database_name + '];
	SELECT	@total_size_MB = SUM(size) / 128
		, @space_used_MB = SUM(CAST(FILEPROPERTY(name, ''SpaceUsed'') / 128 AS int))
	FROM	sys.master_files
	WHERE	type_desc = ''ROWS''
	AND	database_id = DB_ID(''' + @database_name + ''')'

	EXEC sp_executesql
		@sql
		, N'@total_size_MB int OUTPUT, @space_used_MB int OUTPUT'
		, @space_used_MB = @space_used_MB OUTPUT
		, @total_size_MB = @total_size_MB OUTPUT
	
	UPDATE	@database_list
	SET	total_size_MB = @total_size_MB
		, space_used_MB = @space_used_MB
	WHERE	database_name = @database_name
END

SELECT	*
FROM	@database_list
ORDER	BY total_size_MB