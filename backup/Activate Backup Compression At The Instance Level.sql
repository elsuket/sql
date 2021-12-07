SELECT	*
FROM	sys.configurations
WHERE	name LIKE '%compress%'


EXEC sys.sp_configure 'backup compression default', 1
GO

RECONFIGURE
GO