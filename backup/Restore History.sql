USE msdb
GO

SELECT		RH.*
		, BMF.physical_device_name
FROM		msdb.dbo.restorehistory AS RH
LEFT JOIN	msdb.dbo.backupset AS BS
			ON RH.backup_set_id = BS.backup_set_id
LEFT JOIN	msdb.dbo.backupmediaset AS BMS
			ON BS.media_set_id = BMS.media_set_id
LEFT JOIN	msdb.dbo.backupmediafamily AS BMF
			ON BS.media_set_id = BMF.media_set_id
WHERE		1 = 1
AND		RH.destination_database_name LIKE 'buyer_plasticomnium_prepmaint4%' ESCAPE '?'
--AND		RH.restore_date > '2021-02-15'
ORDER BY	RH.restore_date DESC

/*
RESTORE DATABASE buyer_jti_prepnso
FROM DISK = '\\fr3psqadp.hosted.hq.ivalua.com\last\sql2017_buyer_jti_prod_202109191523_full.bak'
WITH MOVE 'ivalua_data' TO 'D:\SQL2017\MSSQL14.SQL2017\MSSQL\DATA\buyer_jti_prepnso.mdf'
	, MOVE 'ivalua_log' TO 'D:\SQL2017\MSSQL14.SQL2017\MSSQL\DATA\buyer_jti_prepnso_log.ldf'
	, NORECOVERY
	, STATS = 1



RESTORE DATABASE buyer_jti_prepnso
FROM DISK = '\\fr3psqadp.hosted.hq.ivalua.com\last\sql2017_buyer_jti_prod_202109231005_diff.bak'
WITH STATS = 1
*/