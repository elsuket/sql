SELECT	*
FROM	sys.fn_dblog(NULL,NULL)
WHERE	Operation LIKE '%CKPT%'

/*
DBCC LOG(database_name[, info_level])

0 - Basic Log Information (default)
1 - Lengthy Info
2 - Very Length Info
3 - Detailed
4 - Full
*/
--DBCC LOG('Application_LEC')


/*
fn_db_log()

SELECT * FROM fn_dblog (
              NULL, -- Start LSN nvarchar(25)
              NULL  -- End LSN nvarchar(25)
       )

----------------------------------------------
fn_full_dblog()

SELECT * FROM sys.fn_full_dblog 
 (
  NULL, -- Start LSN nvarchar (25) 
  NULL, -- End LSN nvarchar (25)  
  NULL, -- Database ID int 
  NULL, -- Page file ID int 
  NULL, -- Page ID int 
  NULL, -- Logical Database ID nvarchar (260)
  NULL, -- Backup Account nvarchar (260)
  NULL -- Backup Container nvarchar (260)
 )
*/

DBCC TRACEON (2537); -- To view thei inactive portion of the log

SELECT		l.[Current LSN]
		, l.[Previous LSN]
		, l.Operation
		, l.Context
		, l.[Transaction ID]
		, l.[Log Record Length]
		, l.AllocUnitName
		, l.[Page ID]
		, l.SPID
		, l.[Xact ID]
		, l.[Begin Time]
		, l.[End Time]
		, l.[Transaction Name]
		, l.[Transaction SID]
		, l.[Parent Transaction ID]
		, l.[Transaction Begin]
		, l.[Number of Locks]
		, l.[Lock Information]
		, l.Description
		, l.[Log Record]
FROM		sys.allocation_units AS au
INNER JOIN	sys.partitions AS p
			ON p.hobt_id = au.container_id
INNER JOIN	sys.tables AS t
			ON t.object_id = p.object_id
INNER JOIN	sys.fn_dblog(NULL, NULL) AS l
			ON l.AllocUnitId = au.allocation_unit_id
WHERE		t.name = 't_bas_session'

/*
-- Run one of the following queries to get information about active transactions
SELECT * FROM sys.dm_tran_active_transactions 
SELECT * FROM sys.dm_tran_database_transactions
 
DBCC OPENTRAN();
 
-- Get Log usage for a specific transaction
SELECT *
FROM fn_dblog(NULL,NULL)
WHERE [Transaction ID] IN (SELECT [Transaction ID] FROM fn_dblog(null,null) WHERE [Transaction SID] = 0x6163d86d97bd6a4da016bac4330f975f)
 

-- Get Log usage for a specific SPID
SELECT *
FROM fn_dblog(NULL,NULL)
WHERE [Transaction ID] IN (SELECT [Transaction ID] FROM fn_dblog(null,null) WHERE [SPID] = 78)
 

-- Get Log usage for a specific user specified transaction
SELECT *
FROM fn_dblog(NULL,NULL)
WHERE [Transaction ID] IN (SELECT [Transaction ID] FROM fn_dblog(null,null) WHERE [Xact ID] = 277094)
 

-- Get the active part of the log for a specific transaction
SELECT	[Current LSN]
	, [Previous LSN]
	, [Operation]
	, [Context]
	, [Transaction ID]
	, [Log Record Length]
	, [AllocUnitName]
	, [Page ID]
	, [SPID]
	, [Xact ID]
	, [Begin Time]
	, [End Time]
	, [Transaction Name]
	, [Transaction SID] -- Performer of the transaction. Use SUSER_SNAME() to get the login name
	, [Parent Transaction ID]
	, [Transaction Begin]
	, [Number of Locks]
	, [Lock Information]
	, [Description]
	, [Log Record]
FROM	sys.fn_dblog(null,null)
WHERE	[Transaction ID] = '0000:00011043'
*/

/*
--*********************************
-- Reading a transaction log backup
--*********************************
SELECT	[Current LSN]
	, [Operation]
	, [Context]
	, [Transaction ID]
	, [Description]
FROM	sys.fn_dump_dblog
	(
		NULL, NULL, N'DISK', 1, N'D:\backup\FNDBLogTest_Log2.bak',
		DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
		DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
		DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
		DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
		DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
		DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
		DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
		DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
		DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT
	)
	, (
		SELECT	[Transaction ID] AS [tid]
		FROM	sys.fn_dump_dblog
			(
			    NULL, NULL, N'DISK', 1, N'D:\backup\FNDBLogTest_Log2.bak',
			    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
			    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
			    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
			    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
			    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
			    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
			    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
			    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
			    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT
			)
		WHERE	[Transaction Name] LIKE '%DROPOBJ%'
	) AS fd
WHERE	[Transaction ID] = fd.tid;

-- If the transaction log backup was taken over 2 files
SELECT
    COUNT (*)
FROM
    fn_dump_dblog (
        NULL, NULL, N'DISK', 1, N'D:\backup\FNDBLogTest_Log3_1.bak',
        N'D:\SQLskills\FNDBLogTest_Log3_2.bak', DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
        DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
        DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
        DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
        DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
        DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
        DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
        DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
        DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
GO
*/

/*
--******************************************************
-- Convert LSN from hexadecimal string to decimal string
--******************************************************
Declare @LSN varchar(22),
    @LSN1 varchar(11),
    @LSN2 varchar(10),
    @LSN3 varchar(5),
    @NewLSN varchar(26)

-- LSN to be converted to decimal
Set @LSN = '0000001e:00000038:0001';

-- Split LSN into segments at colon
Set @LSN1 = LEFT(@LSN, 8);
Set @LSN2 = SUBSTRING(@LSN, 10, 8);
Set @LSN3 = RIGHT(@LSN, 4);

-- Convert to binary style 1 -> int
Set @LSN1 = CAST(CONVERT(VARBINARY, '0x' +
        RIGHT(REPLICATE('0', 8) + @LSN1, 8), 1) As int);

Set @LSN2 = CAST(CONVERT(VARBINARY, '0x' +
        RIGHT(REPLICATE('0', 8) + @LSN2, 8), 1) As int);

Set @LSN3 = CAST(CONVERT(VARBINARY, '0x' +
        RIGHT(REPLICATE('0', 8) + @LSN3, 8), 1) As int);

-- Add padded 0's to 2nd and 3rd string
Select CAST(@LSN1 as varchar(8)) +
    CAST(RIGHT(REPLICATE('0', 10) + @LSN2, 10) as varchar(10)) +
    CAST(RIGHT(REPLICATE('0', 5) + @LSN3, 5) as varchar(5));
*/