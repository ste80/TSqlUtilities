-- =============================================
-- Author:		Steven Chong
-- Create date: 2009-03-11
-- Description:	Execute the sql statement with parameters
-- =============================================
ALTER PROC [dbo].[ExecSql]
	@statement nvarchar(max), @paramname nvarchar(4000) = N'',
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
	@svr nvarchar(4000) = NULL, @into sysname = NULL,
	@nocount bit = NULL, @debug bit = 0
AS
BEGIN
	SET @nocount = ISNULL(
		@nocount, CASE WHEN ( (512 & @@OPTIONS) = 512 ) THEN 1 ELSE 0 END );

	SET NOCOUNT ON;
	SET ARITHABORT ON;
	
	-- Retrieve server's info
	DECLARE @svrIsFoxPro bit;
	SET @svrIsFoxPro =
		(SELECT CASE WHEN s.provider LIKE 'VFPOLEDB%' THEN 1 ELSE 0 END
		FROM sys.servers s WHERE @svr IN(s.name,QUOTENAME(s.name)));
	SET @svr = (SELECT s.name
		FROM sys.servers s WHERE @svr IN(s.name,QUOTENAME(s.name)));

	-- into info
	DECLARE @intoObj nvarchar(max);
	SET @intoObj = CASE WHEN OBJECT_ID(@into) IS NOT NULL THEN @into
		WHEN OBJECT_ID('tempdb..' + @into) IS NOT NULL THEN 'tempdb..' + @into
		ELSE @into END;

	-- init params
	DECLARE @varDeclare nvarchar(max);
	DECLARE @varInit nvarchar(max)
	DECLARE @varOut nvarchar(max);
	DECLARE @paramDeclare nvarchar(4000)
	DECLARE @paramValues nvarchar(max);
	DECLARE @paramList nvarchar(max);
	DECLARE @useOpenQuery bit;
	SET @useOpenQuery =
		CASE WHEN @svr <> '' AND (
			@into <> ''
			OR LTRIM(REPLACE(REPLACE(@statement,char(13)+char(10),''),'	',''))
			LIKE 'SELECT%'
		) THEN 1 END;
	
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
		@useOpenQuery =
			CASE WHEN p.IsOutCount>0 THEN NULL ELSE @useOpenQuery END,
		@varDeclare =
			CASE WHEN p.Name LIKE '%[_-]' OR @useOpenQuery=1
				OR @svrIsFoxPro=1 THEN
				@varDeclare
			ELSE
				ISNULL(@varDeclare + ',', '' ) +
				p.Name + N' ' + t.ParamType
			END,
		@varInit =
			CASE WHEN p.Name LIKE '%[_-]' OR @useOpenQuery=1
				OR @svrIsFoxPro=1 THEN
				@varInit
			ELSE
				ISNULL(@varInit + N',', '') +
				p.Name + N'=CONVERT(' + t.ParamType + N',' + p.P + N')'
			END,
		@varOut = 
			CASE WHEN p.Name LIKE '%[_-]' OR @useOpenQuery=1
				OR @svrIsFoxPro=1 OR p.IsOut=0 THEN
				@varOut
			ELSE
				ISNULL(@varOut + N',', '') +
				p.P + N'=CONVERT(sql_variant,' + p.Name + N')'
			END,
		@paramDeclare =
			CASE WHEN p.Name LIKE '%[_-]' OR @useOpenQuery=1
				OR @svrIsFoxPro=1 THEN
				@paramDeclare
			ELSE
				ISNULL(@paramDeclare + N',', '') +
				p.Name + N' ' + t.ParamType +
				ISNULL(CASE WHEN p.IsOut = 1 THEN N' OUT' END, '')
			END,
		@paramValues =
			CASE WHEN p.Name LIKE '%[_-]' OR @useOpenQuery=1
				OR @svrIsFoxPro=1 THEN
				@paramValues
			ELSE
				ISNULL(@paramValues + ',', '') +
				p.Name +
				ISNULL(CASE WHEN p.IsOut = 1 THEN N' OUT' END, '')
			END,
		@statement =
			CASE WHEN p.Name LIKE '%[_-]' THEN
				REPLACE(@statement, p.Name, CONVERT(nvarchar(max),p.Value))
			WHEN @useOpenQuery=1 OR @svrIsFoxPro=1 THEN
				REPLACE( @statement, p.Name, CONVERT(nvarchar(max),'') + ISNULL(
					CASE 
					WHEN BaseType IN('bigint','bit','decimal','int','money',
					'numeric','smallint','smallmoney','tinyint','float','real'
					) THEN
						CONVERT(nvarchar(max),p.Value)
					WHEN BaseType IN('date','datetime2','datetime',
					'datetimeoffset','smalldatetime','time') THEN
						'{ts''' + REPLACE(
							CONVERT(nvarchar(max), p.Value, 21),
								'''','''''' ) + '''}'
					WHEN BaseType IN('char','varchar','text','binary','varbinary'
					) THEN
						'''' + REPLACE(CONVERT(varchar(max),p.Value),
							'''','''''') + ''''
					WHEN BaseType IN('nchar','nvarchar','ntext','image') THEN
						CASE WHEN @svrIsFoxPro=1 THEN
						'''' + REPLACE(CONVERT(varchar(max),p.Value),
							'''','''''') + ''''
						ELSE
						'N''' + REPLACE(CONVERT(varchar(max),p.Value),
							'''','''''') + ''''
						END
					END,'NULL') )
			ELSE
				@statement
			END,	
		@paramList = ISNULL(@paramList, '') + N',' +
			N'N''' + REPLACE(Name, '''', '''''') + N''''
	FROM (
		SELECT P = N'@_' + RIGHT( N'0' + CONVERT(varchar(100),RowNum), 2 ),
			Name = CASE WHEN Value LIKE '% OUT' THEN
					SUBSTRING( Value,1, LEN(Value) - LEN(N' OUT') )
				ELSE Value END,
			IsOut = CASE WHEN Value LIKE '% OUT' THEN 1 ELSE 0 END,
			IsOutCount =
				SUM(CASE WHEN Value LIKE '% OUT' THEN 1 ELSE 0 END)OVER(),
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
			SELECT Value = LTRIM(RTRIM( SUBSTRING(@paramname, idx1,
				COALESCE(NULLIF(idx2, 0), LEN(@paramname) + 1) - idx1) )),
				RowNum = ROW_NUMBER()OVER(ORDER BY @@ROWCOUNT)
			FROM param_split1 ) param_split2
		WHERE (Value<>'')
	) p
	CROSS APPLY ( SELECT BaseType,
		ParamType = ISNULL(BaseType,'sql_variant') + ISNULL(
			CASE WHEN BaseType IN('decimal','numeric') THEN
				'(' + CONVERT(varchar,Precision) + ',' +
				CONVERT(varchar,Scale) + ')'
			WHEN BaseType IN('datetimeoffset','datetime2','float','time') THEN
				'(' + CONVERT(varchar,Precision) + ')'
			WHEN BaseType IN('binary','char','varbinary','varchar','nchar',
			'nvarchar') THEN
					'(' + ISNULL(CONVERT(varchar,NULLIF(MaxLength,-1)),'max') +
					')'
			END, '' )
		FROM (
			SELECT *,
				MaxLength = CONVERT(int,
					SQL_VARIANT_PROPERTY(p.Value,'MaxLength')) / 
					CASE WHEN BaseType IN('nchar','nvarchar','ntext') 
						THEN 2 ELSE 1 END
			FROM ( SELECT
				BaseType = CONVERT(sysname,
					SQL_VARIANT_PROPERTY(p.Value,'BaseType')),
				Precision = CONVERT(int,
					SQL_VARIANT_PROPERTY(p.Value,'Precision')),
				Scale = CONVERT(int,SQL_VARIANT_PROPERTY(p.Value,'Scale')),
				Collation = CONVERT(sysname,
					SQL_VARIANT_PROPERTY(p.Value,'Collation'))
			) t
		) t
	) t;
	
	IF @debug=1 BEGIN;
		PRINT '>>>>>> @statement';PRINT @statement;
		PRINT '>>>>>> @paramname';PRINT @paramname;
		PRINT '>>>>>> @svr';PRINT @svr;
		PRINT '>>>>>> @varDeclare';PRINT @varDeclare;
		PRINT '>>>>>> @varInit';PRINT @varInit;
		PRINT '>>>>>> @varOut';PRINT @varOut;
		PRINT '>>>>>> @paramDeclare';PRINT @paramDeclare;
		PRINT '>>>>>> @paramValues';PRINT @paramValues;
		PRINT '>>>>>> @paramList';PRINT @paramList;
		PRINT '>>>>>> @useOpenQuery';PRINT @useOpenQuery;
	END;

	DECLARE @sql nvarchar(max);
	SET @sql = CONVERT(nvarchar(max),'') +
--rename variables
ISNULL(N'
DECLARE ' + @varDeclare + N';', '') +
ISNULL(N'
SELECT ' + @varInit + N';', '') +
-- execute statement
N'
SET NOCOUNT ' + CASE @nocount WHEN 1 THEN 'ON' ELSE 'OFF' END + N';
' +
CASE WHEN @useOpenQuery=1 THEN
	CASE WHEN OBJECT_ID(@intoObj) IS NOT NULL THEN
		N'INSERT INTO ' + @into + N' SELECT *' +
		N' FROM OPENQUERY(' + QUOTENAME(@svr) +
		N',N''' + REPLACE(@statement, '''', '''''') + ''')'
	WHEN @into <> '' THEN
		N'SELECT * INTO ' + @into +
		N' FROM OPENQUERY(' + QUOTENAME(@svr) +
		N',N''' + REPLACE(@statement, '''', '''''') + ''')'
	ELSE
		N'SELECT *' +
		N' FROM OPENQUERY(' + QUOTENAME(@svr) +
		N',N''' + REPLACE(@statement, '''', '''''') + ''')'
	END
WHEN @svr <> '' THEN
	CASE WHEN @varDeclare<>'' THEN
		N'EXEC ' + QUOTENAME(@svr) + '...sp_executesql' +
		N' N''' + REPLACE(@statement, '''', '''''') + ''',' +
		N' N''' + ISNULL(@paramDeclare, '') + ''''+
			ISNULL(','+@paramValues,'')
	ELSE
		N'EXEC(N''' + REPLACE(@statement, '''', '''''') + N''')AT'+
			QUOTENAME(@svr)
	END	
ELSE
	CASE WHEN OBJECT_ID(@intoObj) IS NOT NULL THEN
		N'INSERT INTO ' + @into + N' ' + @statement
	WHEN @into<>'' THEN
		N'SELECT * INTO ' + @into + N' FROM(
' + REPLACE(@statement, ';', '') + N'
)_'
	ELSE
		@statement
	END
END + N';
SET NOCOUNT ON;'+
ISNULL(N'
SELECT ' + @varOut + N';', '');

	IF @debug=1 BEGIN;
		PRINT '>>>>>> @sql';PRINT @sql;
	END;
	EXEC dbo.sp_executesql @sql, N'
		@_01 sql_variant OUT, @_02 sql_variant OUT, @_03 sql_variant OUT,
		@_04 sql_variant OUT, @_05 sql_variant OUT, @_06 sql_variant OUT,
		@_07 sql_variant OUT, @_08 sql_variant OUT, @_09 sql_variant OUT,
		@_10 sql_variant OUT, @_11 sql_variant OUT, @_12 sql_variant OUT,
		@_13 sql_variant OUT, @_14 sql_variant OUT, @_15 sql_variant OUT,
		@_16 sql_variant OUT, @_17 sql_variant OUT, @_18 sql_variant OUT,
		@_19 sql_variant OUT, @_20 sql_variant OUT, @_21 sql_variant OUT,
		@_22 sql_variant OUT, @_23 sql_variant OUT, @_24 sql_variant OUT,
		@_25 sql_variant OUT, @_26 sql_variant OUT, @_27 sql_variant OUT,
		@_28 sql_variant OUT, @_29 sql_variant OUT, @_30 sql_variant OUT',
		@p01 OUT, @p02 OUT, @p03 OUT, @p04 OUT, @p05 OUT, @p06 OUT,
		@p07 OUT, @p08 OUT, @p09 OUT, @p10 OUT, @p11 OUT, @p12 OUT,
		@p13 OUT, @p14 OUT, @p15 OUT, @p16 OUT, @p17 OUT, @p18 OUT,
		@p19 OUT, @p20 OUT, @p21 OUT, @p22 OUT, @p23 OUT, @p24 OUT,
		@p25 OUT, @p26 OUT, @p27 OUT, @p28 OUT, @p29 OUT, @p30 OUT;
END

