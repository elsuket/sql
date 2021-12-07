SET NOCOUNT ON
GO
------------------------------------------------------------------------------------------
DECLARE @backup_file_path varchar(260) = '\\HK-AGPPCDB-2001\backup$\Agoda_PPC_v6_4.bak'
	, @database_name sysname = 'Agoda_PPC_v6'
------------------------------------------------------------------------------------------
	, @cr char(2) = CHAR(13) + CHAR(10)
	, @sql varchar(max)

DECLARE @restore_filelistonly TABLE
(
	logical_name varchar(128)
	, physical_name varchar(260)
	, file_type char(1)
	, file_group_name nvarchar(128)
	, file_size bigint
	, file_max_size bigint
	, file_id tinyint
	, create_LSN numeric(25,0)
	, drop_LSN numeric(25,0)
	, unique_id uniqueidentifier
	, read_only_LSN numeric(25,0)
	, read_write_LSN numeric(25,0)
	, backup_size_in_bytes bigint
	, source_block_size int
	, file_group_id int
	, log_group_GUID uniqueidentifier
	, differential_base_LSN numeric(25,0)
	, differential_base_GUID uniqueidentifier
	, is_read_only bit
	, is_present bit
	, TDE_thumbprint varbinary(32)
)

INSERT INTO @restore_filelistonly
EXEC('RESTORE FILELISTONLY FROM DISK = ''' + @backup_file_path + '''')

SELECT		@sql = CASE 
			WHEN @sql IS NULL THEN + 'WITH	MOVE ''' 
			ELSE @sql + '	, MOVE '''
		END + DF.name + ''' TO ''' + DF.physical_name + '''' + @cr
FROM		sys.database_files AS DF
INNER JOIN	@restore_filelistonly AS RF
			ON DF.name = RF.logical_name

SET @sql = 'RESTORE	DATABASE ' + @database_name + @cr
				+ 'FROM	DISK = ''' + @backup_file_path + '''' + @cr
				+ @sql

PRINT @sql