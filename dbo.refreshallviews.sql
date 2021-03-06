-- =============================================
-- Author:		Steven Chong
-- Create date: 2009-03-11
-- Description:	Refresh all views in all databases
-- =============================================
ALTER PROC [dbo].[refreshallviews]
AS
BEGIN
SET NOCOUNT ON;
IF OBJECT_ID('tempdb..#d') IS NOT NULL DROP TABLE #d;
SELECT name INTO #d FROM master.dbo.sysdatabases WHERE name NOT IN('master','tempdb','msdb','model') and status & 512 =0;
--IN('EMS_HONGKONG','EMSMASTER');
EXEC master.dbo.ForEach 'tempdb..#d', '
PRINT QUOTENAME(@name);
PRINT ''>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'';
IF OBJECT_ID(''tempdb..#v'') IS NOT NULL DROP TABLE #v;
CREATE TABLE #v(name nvarchar(max));
DECLARE @sql nvarchar(max);
SET @sql=''SELECT name=TABLE_SCHEMA+''''.''''+TABLE_NAME FROM ''+QUOTENAME(@name)+''.INFORMATION_SCHEMA.VIEWS'';
INSERT INTO #v EXEC(@sql);

IF OBJECT_ID(''tempdb..#t'') IS NOT NULL DROP TABLE #t;
SELECT Q=''EXEC ''+QUOTENAME(@name)+''.dbo.sp_refreshview ''+QUOTENAME(name) INTO #t FROM #v;
EXEC master.dbo.ForEach ''tempdb..#t'', ''
	PRINT @Q;
	BEGIN TRY;
		EXEC(@Q);
	END TRY BEGIN CATCH;
		PRINT ''''------------------------------------- ''''+ERROR_MESSAGE();
	END CATCH;
	BEGIN TRY;
		ROLLBACK;
	END TRY BEGIN CATCH END CATCH'';';
END
