USE [master]
GO

EXEC master.dbo.sp_addumpdevice 
	@devtype = N'disk'
	, @logicalname = N'Agoda_Core'
	, @physicalname = N'J:\agoda\database\backup\Agoda_Core.bak'
