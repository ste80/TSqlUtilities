-- =============================================
-- Author:		Steven Chong
-- Create date: 2009-03-11
-- Description:	Get Variant Type by column defination
-- =============================================
ALTER PROC [dbo].[GetVariantType](
	@Param sql_variant
,	@ParamType nvarchar(300) = NULL OUT
,	@ParamValue nvarchar(max) OUT)
AS
BEGIN
--	DECLARE @ParamType nvarchar(300), @ParamValue nvarchar(max), @Param sql_variant
	DECLARE @BaseType sysname, @Precision int, @Scale varchar, @Collation sysname, @MaxLength int;

	SELECT
		@BaseType = CAST(SQL_VARIANT_PROPERTY(@Param,'BaseType') AS sysname)
	,	@Precision = CAST(SQL_VARIANT_PROPERTY(@Param,'Precision') AS int)
	,	@Scale = CAST(SQL_VARIANT_PROPERTY(@Param,'Scale') AS int)
	,	@Collation = CAST(SQL_VARIANT_PROPERTY(@Param,'Collation') AS sysname)
	,	@MaxLength = CAST(SQL_VARIANT_PROPERTY(@Param,'MaxLength') AS int) / 
			CASE WHEN @BaseType IN('nchar','nvarchar','ntext') THEN 2 ELSE 1 END
	,	@ParamType = ISNULL(@BaseType,'sql_variant') + ISNULL(CASE 
				WHEN @BaseType IN('decimal','numeric') THEN
					'(' + CAST(@Precision AS varchar) + ',' + CAST(@Scale AS varchar) + ')'
				WHEN @BaseType IN('datetimeoffset','datetime2','float','time') THEN
					'(' + CAST(@Precision AS varchar) + ')'
				WHEN @BaseType IN('binary','char','varbinary','varchar','nchar','nvarchar') THEN
					'(' + ISNULL(CAST(NULLIF(@MaxLength,-1) AS varchar),'max') + ')'
			END, '')
	,	@ParamValue = CAST('' AS nvarchar(max)) + ISNULL(CASE 
				WHEN @BaseType IN('bigint','bit','decimal','int','money','numeric','smallint','smallmoney','tinyint','float','real') THEN
					CAST(@Param AS nvarchar(max))
				WHEN @BaseType IN('date','datetime2','datetime','datetimeoffset','smalldatetime','time') THEN
					'{ts''' + REPLACE(CONVERT(nvarchar(max), @Param, 21),'''','''''') + '''}'
				WHEN @BaseType IN('char','varchar','text','binary','varbinary') THEN
					'''' + REPLACE(CAST(@Param AS varchar(max)),'''','''''') + ''''
				WHEN @BaseType IN('nchar','nvarchar','ntext','image') THEN
					'N''' + REPLACE(CAST(@Param AS varchar(max)),'''','''''') + ''''
			END,'NULL');
END
