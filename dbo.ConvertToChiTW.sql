-- =============================================
-- Author:		Steven Chong
-- Create date: 2009-03-11
-- Description:	Convert simplified chinese to traditional chinese
-- =============================================
ALTER PROCEDURE [dbo].[ConvertToChiTW](
	@tblname nvarchar(4000)
)
AS
BEGIN
	DECLARE @sql nvarchar(max), @comma varchar(1), @name sysname;

	IF PARSENAME(@tblname,4) IS NULL AND PARSENAME(@tblname,3) = 'tempdb' BEGIN;
		SET @name = PARSENAME(@tblname,1);
	END ELSE BEGIN;
		SET @name = @tblname;
	END;
	
	SET @sql = ISNULL(@sql, '') + '
	IF OBJECT_ID(''tempdb..#ConvertToChiTW'') IS NOT NULL DROP TABLE #ConvertToChiTW;
	SELECT * INTO #ConvertToChiTW FROM '+@name+';';

	SELECT @sql = @sql + '
	ALTER TABLE '+@name+' ALTER COLUMN '+QUOTENAME(name)+
		' varchar('+CAST(max_length AS varchar)+') COLLATE Chinese_Taiwan_Stroke_CI_AS;'
	FROM tempdb.sys.columns
	WHERE object_id=object_id(CASE WHEN @tblname LIKE '#%' THEN 'tempdb..'+@tblname ELSE @tblname END) AND 
		system_type_id=167;

	SET @sql = @sql + '
	TRUNCATE TABLE '+@name+';
	INSERT INTO '+@name+' SELECT ';

	SELECT
		@sql = @sql + ISNULL(@comma, '') + QUOTENAME(name)+
		CASE WHEN system_type_id=167 THEN
			'=CAST('+QUOTENAME(name)+' AS varbinary('+CAST(max_length AS varchar)+'))'
		ELSE '' END
	,	@comma = ','
	FROM tempdb.sys.columns
	WHERE object_id=object_id(CASE WHEN @tblname LIKE '#%' THEN 'tempdb..'+@tblname ELSE @tblname END);
	SET @sql = @sql + ' FROM #ConvertToChiTW;'
	EXEC(@sql);
END
