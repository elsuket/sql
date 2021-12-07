/*
CREATE DATABASE buyer_asianpaints_sandboxevol_snap
ON (
		NAME = ivalua_data
		, FILENAME = 'D:\SQL2017\MSSQL14.SQL2017\MSSQL\DATA\buyer_asianpaints_sandboxevol.snap'
	)
AS SNAPSHOT OF buyer_asianpaints_sandboxevol
*/

/*
USE master
GO

RESTORE DATABASE buyer_asianpaints_sandboxevol
FROM DATABASE_SNAPSHOT = 'buyer_asianpaints_sandboxevol_snap'
*/