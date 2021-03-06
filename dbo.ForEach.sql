-- =============================================
-- Author:		Steven Chong
-- Create date: 2009-03-11
-- Description:	Loop the table as convert all field as variable
-- =============================================
ALTER PROCEDURE [dbo].[ForEach]
	@source nvarchar(max), @statement nvarchar(max), @paramname nvarchar(4000) = N'',
	@p01 sql_variant = NULL OUT, @p02 sql_variant = NULL OUT,
	@p03 sql_variant = NULL OUT, @p04 sql_variant = NULL OUT,
	@p05 sql_variant = NULL OUT, @p06 sql_variant = NULL OUT,
	@p07 sql_variant = NULL OUT, @p08 sql_variant = NULL OUT,
	@p09 sql_variant = NULL OUT, @p10 sql_variant = NULL OUT,
	@p11 sql_variant = NULL OUT, @p12 sql_variant = NULL OUT,
	@p13 sql_variant = NULL OUT, @p14 sql_variant = NULL OUT,
	@p15 sql_variant = NULL OUT, @p16 sql_variant = NULL OUT,
	@p17 sql_variant = NULL OUT, @p18 sql_variant = NULL OUT,
	@p19 sql_variant = NULL OUT, @p20 sql_variant = NULL OUT,
	@p21 sql_variant = NULL OUT, @p22 sql_variant = NULL OUT,
	@p23 sql_variant = NULL OUT, @p24 sql_variant = NULL OUT,
	@p25 sql_variant = NULL OUT, @p26 sql_variant = NULL OUT,
	@p27 sql_variant = NULL OUT, @p28 sql_variant = NULL OUT,
	@p29 sql_variant = NULL OUT, @p30 sql_variant = NULL OUT,
	@nocount bit = NULL, @debug bit = 0
AS
BEGIN
	SET @nocount = ISNULL(
		@nocount, CASE WHEN ( (512 & @@OPTIONS) = 512 ) THEN 1 ELSE 0 END );

	SET NOCOUNT ON;
	SET ARITHABORT ON;

	DECLARE @id nvarchar(max);
	SET @id = REPLACE( CONVERT(varchar(36),NEWID()), '-', '' );

	-- init params
	DECLARE @varDeclare nvarchar(max);
	DECLARE @varInit nvarchar(max)
	DECLARE @varOut nvarchar(max);
	DECLARE @paramDeclare nvarchar(4000)
	DECLARE @paramValues nvarchar(max);
	DECLARE @paramList nvarchar(max);

	-- Retreive list of P, e.g. '@_01', '@_02', '@_03', ......
	SET @paramname = REPLACE(REPLACE(@paramname, '	', ''), '
', '');
	WITH param_split1 AS(
		SELECT idx1 = CONVERT(bigint,0),
			idx2 = CHARINDEX(',', @paramname) UNION ALL
		SELECT idx1 = CONVERT(bigint,idx2 + 1),
			idx2 = CHARINDEX(',', @paramname, idx2 + 1)
		FROM param_split1 WHERE (idx2 > 0)
	)
	SELECT 
		@varDeclare =
			CASE WHEN (p.Name LIKE '%[_-]') THEN @varDeclare ELSE
				ISNULL(@varDeclare + ',', '' ) +
				p.Name + N' ' + t.ParamType
			END,
		@varInit =
			CASE WHEN (p.Name LIKE '%[_-]') THEN @varInit ELSE
				ISNULL(@varInit + N',', '') +
				p.Name + N'=CONVERT(' + t.ParamType + N',' + p.P + N')'
			END,
		@varOut = 
			CASE WHEN (p.Name LIKE '%[_-]' AND p.IsOut = 1) THEN @varOut ELSE
				ISNULL(@varOut + N',', '') +
				p.P + N'=CONVERT(sql_variant,' + p.Name + N')'
			END,
		@paramDeclare =
			CASE WHEN (p.Name LIKE '%[_-]') THEN @paramDeclare ELSE
				ISNULL(@paramDeclare + N',', '') +
				p.Name + N' ' + t.ParamType +
				ISNULL(CASE WHEN p.IsOut = 1 THEN N' OUT' END, '')
			END,
		@paramValues =
			CASE WHEN (p.Name LIKE '%[_-]') THEN @paramValues ELSE
				ISNULL(@paramValues + ',', '') +
				p.Name +
				ISNULL(CASE WHEN p.IsOut = 1 THEN N' OUT' END, '')
			END,
		@statement =
			CASE WHEN (p.Name LIKE '%[_-]') THEN
				REPLACE(@statement, p.Name, CONVERT(nvarchar(max),p.Value))
			ELSE @statement END,
		@paramList = ISNULL(@paramList, '') + N',' +
			N'N''' + REPLACE(Name, '''', '''''') + N''''
	FROM (
		SELECT P = N'@_' + RIGHT( N'0' + CONVERT(varchar(100),RowNum), 2 ),
			Name = CASE WHEN Value LIKE '% OUT' THEN
					SUBSTRING( Value,1, LEN(Value) - LEN(N' OUT') )
				ELSE Value END,
			IsOut = CASE WHEN Value LIKE '% OUT' THEN 1 ELSE 0 END,
			Value = CASE RowNum
				WHEN 1  THEN @p01 WHEN 2  THEN @p02 WHEN 3  THEN @p03
				WHEN 4  THEN @p04 WHEN 5  THEN @p05 WHEN 6  THEN @p06
				WHEN 7  THEN @p07 WHEN 8  THEN @p08 WHEN 9  THEN @p09
				WHEN 10 THEN @p10 WHEN 11 THEN @p11 WHEN 12 THEN @p12
				WHEN 13 THEN @p13 WHEN 14 THEN @p14 WHEN 15 THEN @p15
				WHEN 16 THEN @p16 WHEN 17 THEN @p17 WHEN 18 THEN @p18
				WHEN 19 THEN @p19 WHEN 20 THEN @p20 WHEN 21 THEN @p21
				WHEN 22 THEN @p22 WHEN 23 THEN @p23 WHEN 24 THEN @p24
				WHEN 25 THEN @p25 WHEN 26 THEN @p26 WHEN 27 THEN @p27
				WHEN 28 THEN @p28 WHEN 29 THEN @p29 WHEN 30 THEN @p30 END
		FROM (
			SELECT Value = LTRIM(RTRIM( SUBSTRING(@paramname, 
					idx1, COALESCE(NULLIF(idx2, 0), LEN(@paramname) + 1) - idx1) )),
				RowNum = ROW_NUMBER()OVER(ORDER BY @@ROWCOUNT)
			FROM param_split1 ) param_split2
		WHERE (Value<>'')
	) p
	CROSS APPLY ( SELECT 
		ParamType = ISNULL(BaseType,'sql_variant') + ISNULL(
			CASE WHEN BaseType IN('decimal','numeric') THEN
				'(' + CONVERT(varchar,Precision) + ',' + CONVERT(varchar,Scale) + ')'
			WHEN BaseType IN('datetimeoffset','datetime2','float','time') THEN
				'(' + CONVERT(varchar,Precision) + ')'
			WHEN BaseType IN('binary','char','varbinary','varchar','nchar',
			'nvarchar') THEN
					'(' + ISNULL(CONVERT(varchar,NULLIF(MaxLength,-1)),'max') + ')'
			END, '' )
		FROM (
			SELECT *,
				MaxLength = CONVERT(int,SQL_VARIANT_PROPERTY(p.Value,'MaxLength')) / 
					CASE WHEN BaseType IN('nchar','nvarchar','ntext') THEN 2 ELSE 1 END
			FROM ( SELECT
				BaseType = CONVERT(sysname,SQL_VARIANT_PROPERTY(p.Value,'BaseType')),
				Precision = CONVERT(int,SQL_VARIANT_PROPERTY(p.Value,'Precision')),
				Scale = CONVERT(int,SQL_VARIANT_PROPERTY(p.Value,'Scale')),
				Collation = CONVERT(sysname,SQL_VARIANT_PROPERTY(p.Value,'Collation'))
			) t
		) t
	) t;
	
	DECLARE @sourceTbl nvarchar(max);
	DECLARE @sourceObj nvarchar(max);
	DECLARE @sql nvarchar(max);
	SET @sourceTbl = CASE WHEN OBJECT_ID(@source) IS NOT NULL THEN @source
		WHEN OBJECT_ID('tempdb..' + @source) IS NOT NULL THEN @source
		ELSE QUOTENAME('#' + @id) END;
	SET @sourceObj = CASE WHEN OBJECT_ID(@sourceTbl) IS NOT NULL THEN @sourceTbl
		ELSE 'tempdb..' + @sourceTbl END;
	
	IF @debug=1 BEGIN;
		PRINT '>>>>>> @source'; PRINT @source;
		PRINT '>>>>>> @statement'; PRINT @statement;
		PRINT '>>>>>> @paramname'; PRINT @paramname;
		PRINT '>>>>>> @varDeclare'; PRINT @varDeclare;
		PRINT '>>>>>> @varInit'; PRINT @varInit;
		PRINT '>>>>>> @varOut'; PRINT @varOut;
		PRINT '>>>>>> @paramDeclare'; PRINT @paramDeclare;
		PRINT '>>>>>> @paramValues'; PRINT @paramValues;
		PRINT '>>>>>> @paramValues'; PRINT @paramValues;
		PRINT '>>>>>> @sourceTbl'; PRINT @sourceTbl;
		PRINT '>>>>>> @sourceObj'; PRINT @sourceObj;
	END
	
	SET @sql = CONVERT(nvarchar(max),'') +
--create temp table
CASE WHEN OBJECT_ID(@sourceObj) IS NULL THEN
N'SELECT * INTO' + @sourceTbl + N'FROM(
' + REPLACE(@source, ';', N'
') + N'
)_;'
ELSE N'' END+
--rename variables
ISNULL(N'
DECLARE ' + @varDeclare + N';', '') +
ISNULL(N'
SELECT ' + @varInit + N';', '') +
-- init columns
N'
DECLARE @_colDeclare nvarchar(max);
DECLARE @_colSelect nvarchar(max);
DECLARE @_colValues nvarchar(max);
DECLARE @_colReplace nvarchar(max);
SET @_colDeclare = N''DECLARE @sql' + @id + N' nvarchar(max)''
SET @_colReplace = N''@statement' + @id + N''';
SELECT' +
	-- set @_colDeclare
N'
	@_colDeclare = @_colDeclare + N'',@'' + Name + N'' '' +
		CASE WHEN Name LIKE ''%[_-]'' THEN
			N''nvarchar(max)''
		ELSE
			Type
		END,' +
	-- set @_colSelect
N'
	@_colSelect = ISNULL(@_colSelect + N'','', '''') +
		QUOTENAME(Name),' +
	-- set @_colValues
N'
	@_colValues = ISNULL(@_colValues + N'','', '''') +
		N''@'' + Name,' +
	-- set @_colReplace
N'
	@_colReplace =
		CASE WHEN Name LIKE ''%[_-]'' THEN
			N''REPLACE('' + @_colReplace + N'','' +
''N'''''' + REPLACE(N''@'' + Name, '''''''', '''''''' + '''''''') + '''''''' +
			N'',@'' + Name + N'')''
		ELSE @_colReplace END,' +
	-- set @_paramDeclare
N'
	@_paramDeclare = ISNULL(@_paramDeclare + N'','', '''') +
		N''@'' + Name + N'' '' + Type,' +
	-- set @_paramValues
N'
	@_paramValues = ISNULL(@_paramValues + N'','', '''') +
		N''@'' + Name
FROM (	
	SELECT Name = COLUMN_NAME,
		Type = CASE WHEN COLUMN_NAME LIKE ''%[_-]'' THEN ''nvarchar(max)'' ELSE
		ISNULL( DATA_TYPE, ''sql_variant'' ) +
		ISNULL(
			CASE 
			WHEN DATA_TYPE IN(''decimal'',''numeric'') THEN
				''('' + CONVERT(varchar,NUMERIC_PRECISION) +
				'','' + CONVERT(varchar,NUMERIC_SCALE) + '')''
			WHEN DATA_TYPE IN(''datetimeoffset'',''datetime2'',''float'',''time'') THEN
				''('' + CONVERT(varchar,NUMERIC_PRECISION) + '')''
			WHEN DATA_TYPE IN(''binary'',''char'',''varbinary'',''varchar'',''nchar'',
				''nvarchar'') THEN
				''('' + ISNULL(
					CONVERT(varchar,NULLIF(CHARACTER_OCTET_LENGTH, -1)),''max'' ) + '')''
			END
		, '''' ) END
	FROM tempdb.INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = OBJECT_NAME(
		OBJECT_ID(''' + @sourceObj + N'''),DB_ID(''' + PARSENAME(@sourceObj, 3) + N''') )
	AND COLUMN_NAME NOT IN(N''' + REPLACE(@id, '''', '''''') + N'''' +
		ISNULL(@paramList, '') + N')
)_;' +

-- execute statement
N'
DECLARE @_sql nvarchar(max);
SET @_sql = 
@_colDeclare + N'';
DECLARE cur' + @id + N' CURSOR LOCAL FAST_FORWARD FOR
	SELECT '' + @_colSelect + N'' FROM ' + @sourceTbl + N';
OPEN cur' + @id + N';
FETCH NEXT FROM cur' + @id + N' INTO '' + @_colValues + N'';
WHILE @@FETCH_STATUS = 0 BEGIN;
	SET NOCOUNT ' + CASE @nocount WHEN 1 THEN 'ON' ELSE 'OFF' END + N';
	SET @sql' + @id + N' = '' + @_colReplace + N'';' +
	CASE WHEN @debug = 1 THEN REPLACE(N'
	PRINT ''>>>>>> @sql' + @id + N''';PRINT @sql' + @id + N';','''','''''')
	ELSE N'' END + N'
	EXEC sp_executesql @sql' + @id + N''' + ISNULL( '','' +
		''N'''''' + REPLACE(@_paramDeclare, '''''''', '''''''' + '''''''') + ''''''''
		, '''' ) + ISNULL('','' + @_paramValues, '''' ) + '';
	SET NOCOUNT ON;
	FETCH NEXT FROM cur' + @id + N' INTO '' + @_colValues + N'';
END;
CLOSE cur' + @id + N';
DEALLOCATE cur' + @id + N';'';' +
CASE WHEN @debug = 1 THEN N'
PRINT ''>>>>>> @_sql'';PRINT @_sql;'
ELSE N'' END + N'
EXEC dbo.sp_executesql @_sql,
	N''@statement' + @id + N' nvarchar(max)' +
	ISNULL(',' + @paramDeclare, '') + N''',
	@_statement'+ISNULL(',' + @paramValues, '') + N';'+
ISNULL(N'
SELECT ' + @varOut + N';', '');

	IF (@debug = 1) BEGIN;
		PRINT '>>>>>> @sql'; PRINT @sql;
	END;
	EXEC dbo.sp_executesql @sql, N'
		@_statement nvarchar(max),
		@_01 sql_variant OUT, @_02 sql_variant OUT, @_03 sql_variant OUT,
		@_04 sql_variant OUT, @_05 sql_variant OUT, @_06 sql_variant OUT,
		@_07 sql_variant OUT, @_08 sql_variant OUT, @_09 sql_variant OUT,
		@_10 sql_variant OUT, @_11 sql_variant OUT, @_12 sql_variant OUT,
		@_13 sql_variant OUT, @_14 sql_variant OUT, @_15 sql_variant OUT,
		@_16 sql_variant OUT, @_17 sql_variant OUT, @_18 sql_variant OUT,
		@_19 sql_variant OUT, @_20 sql_variant OUT, @_21 sql_variant OUT,
		@_22 sql_variant OUT, @_23 sql_variant OUT, @_24 sql_variant OUT,
		@_25 sql_variant OUT, @_26 sql_variant OUT, @_27 sql_variant OUT,
		@_28 sql_variant OUT, @_29 sql_variant OUT, @_30 sql_variant OUT,
		@_paramDeclare nvarchar(4000), @_paramValues nvarchar(max)',
		@statement, 
		@p01 OUT, @p02 OUT, @p03 OUT, @p04 OUT, @p05 OUT, @p06 OUT,
		@p07 OUT, @p08 OUT, @p09 OUT, @p10 OUT, @p11 OUT, @p12 OUT,
		@p13 OUT, @p14 OUT, @p15 OUT, @p16 OUT, @p17 OUT, @p18 OUT,
		@p19 OUT, @p20 OUT, @p21 OUT, @p22 OUT, @p23 OUT, @p24 OUT,
		@p25 OUT, @p26 OUT, @p27 OUT, @p28 OUT, @p29 OUT, @p30 OUT,
		@paramDeclare, @paramValues;
END

