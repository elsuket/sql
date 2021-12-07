-- FileID – the FileID number as found in sysfiles
-- FileSize – the size of the VLF in bytes
-- StartOffset – the start of the VLF in bytes, from the front of the transaction log
-- FSeqNo – indicates the order in which transactions have been written to the different VLF files. The VLF with the highest number is the VLF to which log records are currently being written.
-- Status – identifies whether or not a VLF contains part of the active log. A value of 2 indicates an active VLF that can't be overwritten.
-- Parity – the Parity Value, which can be 0, 64 or 128 (see the Additional Resources section at the end of this article for more information)
-- CreateLSN – Identifies the LSN when the VLF was created. A value of zero indicates that the VLF was created when the database was created. If two VLFs have the same number then they were created at the same time, via an auto-grow event. 

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
-------------------------------------------------------------------------------------------
DECLARE @database_name sysname = 'Agoda_staging'
-------------------------------------------------------------------------------------------
DECLARE @sql nvarchar(256) = 'DBCC LOGINFO (''' + @database_name + ''')'

DECLARE @vlf TABLE
(
	FileId tinyint
	, FileSize bigint
	, StartOffset bigint
	, FSeqNo int
	, Status tinyint
	, Parity tinyint
	, CreateLSN varchar(50)
)

INSERT	@vlf
EXEC (@sql)


;WITH
	VLF AS
	(
		SELECT		SUM(FileSize) / 1048576 AS total_file_size_MB
				, AVG(FileSize) / 1048576 AS avg_VLF_size_MB
				, SUM
				(
					CASE Status
						WHEN 2 THEN FileSize
						ELSE 0
					END
				) / 1048576 AS file_size_in_use_MB
				, COUNT(*) AS VLF_amount
				, SUM
				(
					CASE Status
						WHEN 2 THEN 1
						ELSE 0
					END
				) AS VLF_in_use

		FROM		@vlf
	)
SELECT		VLF.total_file_size_MB
		, VLF.avg_VLF_size_MB
		, VLF.file_size_in_use_MB
		, VLF.VLF_amount
		, VLF.VLF_in_use
		, F.name AS logical_name
		, F.physical_name
		, F.file_size_MB
		, F.file_space_used_MB
		, F.growth
FROM		VLF
CROSS JOIN	(
			SELECT	name
				, physical_name
				, CASE is_percent_growth
					WHEN 0 THEN CAST(growth / 128 AS varchar(20)) + ' MB'
					ELSE CAST(growth AS varchar(20)) + '%'
				END AS growth
				, size / 128 AS file_size_MB
				, FILEPROPERTY(name, 'SpaceUsed') / 128 AS file_space_used_MB
			FROM	sys.database_files
			WHERE	type = 1
		) AS F




--DBCC SHRINKFILE ('agoda_ppc_log', 51200)
--DBCC SQLPERF(logspace)

/*
ALTER DATABASE Agoda_PPC_v6
MODIFY FILE (NAME = 'agoda_ppc_log', SIZE = 10GB)
*/

/*
SELECT	name
	, log_reuse_wait_desc
	, recovery_model_desc
FROM	sys.databases
*/
--EXEC sp_removedbreplication


/*
DBCC SHRINKFILE (agoda_teamwork_log, 0)
GO

ALTER DATABASE Agoda_Core
MODIFY FILE (NAME = Agoda2006_log, SIZE = 10GB, FILEGROWTH = 128MB)
*/

/*
SELECT	*
FROM	sys.dm_os_performance_counters
WHERE	counter_name LIKE '%file%'
*/