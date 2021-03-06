-- =============================================
-- Author:		Steven Chong
-- Create date: 2009-03-11
-- Description:	Execute the sql statement with parameters in target linked server
-- =============================================
ALTER PROCEDURE [dbo].[ExecAt]
	@servername nvarchar(4000)
,	@statement nvarchar(max)
,	@paramname nvarchar(4000)=N''
,	@p01 sql_variant=NULL OUT,@p02 sql_variant=NULL OUT,@p03 sql_variant=NULL OUT
,	@p04 sql_variant=NULL OUT,@p05 sql_variant=NULL OUT,@p06 sql_variant=NULL OUT
,	@p07 sql_variant=NULL OUT,@p08 sql_variant=NULL OUT,@p09 sql_variant=NULL OUT
,	@p10 sql_variant=NULL OUT,@p11 sql_variant=NULL OUT,@p12 sql_variant=NULL OUT
,	@p13 sql_variant=NULL OUT,@p14 sql_variant=NULL OUT,@p15 sql_variant=NULL OUT
,	@p16 sql_variant=NULL OUT,@p17 sql_variant=NULL OUT,@p18 sql_variant=NULL OUT
,	@p19 sql_variant=NULL OUT,@p20 sql_variant=NULL OUT,@p21 sql_variant=NULL OUT
,	@p22 sql_variant=NULL OUT,@p23 sql_variant=NULL OUT,@p24 sql_variant=NULL OUT
,	@p25 sql_variant=NULL OUT,@p26 sql_variant=NULL OUT,@p27 sql_variant=NULL OUT
,	@p28 sql_variant=NULL OUT,@p29 sql_variant=NULL OUT,@p30 sql_variant=NULL OUT
,	@into sysname = NULL
,	@nocount bit=0
,	@debug bit=0
AS
BEGIN
	SET NOCOUNT ON;
	SET ARITHABORT ON;

	DECLARE @sql nvarchar(max),@NL nvarchar(max);SET @NL=CHAR(13)+CHAR(10);	
	
	IF @debug=1 BEGIN;
		PRINT '>>>>>> @servername';PRINT @servername;
		PRINT '>>>>>> @statement';PRINT @statement;
		PRINT '>>>>>> @paramname';PRINT @paramname;
	END;

	-- Retreive @paramname's Info
	DECLARE @param_tbl table(P varchar(100),Name nvarchar(max),IsOut bit);
	INSERT INTO @param_tbl SELECT 
		P='@p'+RIGHT('0'+
			CAST(ROW_NUMBER()OVER(ORDER BY @paramname) AS varchar(100)),2),
		Name=
			CASE WHEN LTRIM(RTRIM(Value)) LIKE '% OUT' THEN
				SUBSTRING(
					LTRIM(RTRIM(Value)),1,LEN(LTRIM(RTRIM(Value)))-LEN(' OUT'))
			ELSE
				LTRIM(RTRIM(Value))
			END,
		IsOut=CASE WHEN LTRIM(RTRIM(Value)) LIKE '% OUT' THEN 1 ELSE 0 END
	FROM dbo.str_split(@paramname,',') WHERE LTRIM(RTRIM(Value))<>'';
	
	-- Retrieve server's info
	DECLARE @is_foxpro bit;
	SET @is_foxpro = ISNULL((SELECT 1 FROM sys.servers 
		WHERE @servername IN(name,QUOTENAME(name)) 
		AND provider LIKE 'VFPOLEDB%'),0);
	IF @into LIKE '#%' SET @into = 'tempdb..'+@into;
	DECLARE @intoname sysname;
	SET @intoname = CASE PARSENAME(@into,3) WHEN 'tempdb' THEN 
		QUOTENAME(PARSENAME(@into,1)) ELSE @into END;
	
	-- init params
	DECLARE @param_declare nvarchar(4000),@param_values nvarchar(max);
	DECLARE @var_init nvarchar(max),@var_out nvarchar(max);
	DECLARE @var_declare nvarchar(max);
	SET @sql = (
		SELECT 
			-- replace @statement
			CASE WHEN Name LIKE '%[-_]' THEN CONVERT(nvarchar(max),'')+
				'SET @statement=REPLACE(@statement,'+
					'N'''+REPLACE(Name,'''','''''')+''','+
					'CONVERT(nvarchar(max),'+P+'));'+@NL
			ELSE
				'DECLARE '+P+'Type nvarchar(300), '+P+'Value nvarchar(max);'+@NL+
				'EXEC dbo.GetVariantType '+
					P+', '+P+'Type OUT, '+P+'Value OUT;'+@NL+
				CASE @is_foxpro WHEN 1 THEN CONVERT(nvarchar(max),'')+
					'IF '+P+'Type LIKE ''nvarchar%'' OR '+
					P+'Type LIKE ''nchar%'' OR '+P+'Type LIKE ''ntext%'' BEGIN;'+
						'SELECT '+P+'Type=STUFF('+P+'Type,1,1,''''),'+
						P+'Value=STUFF('+P+'Value,1,1,'''');'+
					'END;'
				ELSE '' END+
				CASE WHEN @servername<>'' AND (@into<>'' OR
					NOT EXISTS(SELECT * FROM @param_tbl WHERE IsOut=1)) THEN
					CONVERT(nvarchar(max),'')+
					'SET @statement=REPLACE(@statement,'+
						'N'''+REPLACE(Name,'''','''''')+''','+
						'CONVERT(nvarchar(max),'+P+'Value));'+@NL
				ELSE CONVERT(nvarchar(max),'')+
					--set @var_init
					'SET @var_init=ISNULL(@var_init+'','','''')+'+
						'N'''+Name+'=CONVERT(''+'+P+'Type+'','+P+')'';'+@NL+
					--set @var_out
					CASE WHEN IsOut=1 THEN
						'SET @var_out=ISNULL(@var_out+'','','''')+'+
							'N'''+P+'=CONVERT(sql_variant,'+Name+')'';'+@NL
					ELSE '' END+
					--set @var_declare
					'SET @var_declare=ISNULL(@var_declare+'','',+'''')+'+
						'N'''+Name+' ''+'+P+'Type;'+@NL+
					--set @param_declare
					'SET @param_declare=ISNULL(@param_declare+'','','''')+'+
						'N'''+Name+' ''+'+P+'Type'+
						CASE WHEN IsOut=1 THEN '+'' OUT''' ELSE '' END+';'+@NL+
					--set @param_values
					'SET @param_values=ISNULL(@param_values+'','','''')+'+
						'N'''+Name+''''+
						CASE WHEN IsOut=1 THEN '+'' OUT''' ELSE '' END+';'+@NL
				END
			END
		FROM @param_tbl ORDER BY LEN(Name) DESC FOR XML PATH(''),TYPE
	).value('text()[1]','nvarchar(max)');
	IF @debug = 1 BEGIN; PRINT '>>>>>> init params';PRINT @sql; END;
	EXEC dbo.sp_executesql @sql,
		N'@statement nvarchar(max) OUT,@var_declare nvarchar(max) OUT,
		@var_init nvarchar(max) OUT,@var_out nvarchar(max) OUT,
		@param_declare nvarchar(4000) OUT,@param_values nvarchar(max) OUT,
		@p01 sql_variant,@p02 sql_variant,@p03 sql_variant,
		@p04 sql_variant,@p05 sql_variant,@p06 sql_variant,
		@p07 sql_variant,@p08 sql_variant,@p09 sql_variant,
		@p10 sql_variant,@p11 sql_variant,@p12 sql_variant,
		@p13 sql_variant,@p14 sql_variant,@p15 sql_variant,
		@p16 sql_variant,@p17 sql_variant,@p18 sql_variant,
		@p19 sql_variant,@p20 sql_variant,@p21 sql_variant,
		@p22 sql_variant,@p23 sql_variant,@p24 sql_variant,
		@p25 sql_variant,@p26 sql_variant,@p27 sql_variant,
		@p28 sql_variant,@p29 sql_variant,@p30 sql_variant',
		@statement OUT,@var_declare OUT,
		@var_init OUT,@var_out OUT,
		@param_declare OUT,@param_values OUT,
		@p01, @p02, @p03, @p04, @p05, @p06,
		@p07, @p08, @p09, @p10, @p11, @p12, 
		@p13, @p14, @p15, @p16, @p17, @p18,
		@p19, @p20, @p21, @p22, @p23, @p24,
		@p25, @p26, @p27, @p28, @p29, @p30;
	
	IF @debug=1 BEGIN;
		PRINT '>>>>>> @statement';PRINT @statement;
		PRINT '>>>>>> @var_init';PRINT @var_init;
		PRINT '>>>>>> @var_out';PRINT @var_out;
		PRINT '>>>>>> @var_declare';PRINT @var_declare;
		PRINT '>>>>>> @param_declare';PRINT @param_declare;
		PRINT '>>>>>> @param_values';PRINT @param_values;
	END;
	
	/*
	BEGIN TRY;
	*/
	-- execute statement
	DECLARE @statement_declare nvarchar(4000);
	SET @statement_declare=CONVERT(nvarchar(4000),'')+
		'@p01 sql_variant OUT,@p02 sql_variant OUT,@p03 sql_variant OUT,'+
		'@p04 sql_variant OUT,@p05 sql_variant OUT,@p06 sql_variant OUT,'+
		'@p07 sql_variant OUT,@p08 sql_variant OUT,@p09 sql_variant OUT,'+
		'@p10 sql_variant OUT,@p11 sql_variant OUT,@p12 sql_variant OUT,'+
		'@p13 sql_variant OUT,@p14 sql_variant OUT,@p15 sql_variant OUT,'+
		'@p16 sql_variant OUT,@p17 sql_variant OUT,@p18 sql_variant OUT,'+
		'@p19 sql_variant OUT,@p20 sql_variant OUT,@p21 sql_variant OUT,'+
		'@p22 sql_variant OUT,@p23 sql_variant OUT,@p24 sql_variant OUT,'+
		'@p25 sql_variant OUT,@p26 sql_variant OUT,@p27 sql_variant OUT,'+
		'@p28 sql_variant OUT,@p29 sql_variant OUT,@p30 sql_variant OUT';
	SET @sql = CAST('' AS nvarchar(max))+
		ISNULL('DECLARE '+@var_declare+';'+@NL,'')+
		ISNULL('SELECT '+@var_init+';'+@NL,'')+
		CASE WHEN @nocount=1 THEN 'SET NOCOUNT ON;' ELSE 'SET NOCOUNT OFF;' END+@NL+
		CASE WHEN @servername<>'' THEN
			CASE WHEN OBJECT_ID(@into) IS NOT NULL THEN
				'INSERT INTO '+@intoname+' SELECT * FROM OPENQUERY('+
					@servername+',N'''+REPLACE(@statement,'''','''''')+''')'
			WHEN @into<>'' THEN
				'SELECT * INTO '+@intoname+' FROM OPENQUERY('+
					@servername+',N'''+REPLACE(@statement,'''','''''')+''')'
			WHEN EXISTS(SELECT * FROM @param_tbl WHERE IsOut=1) THEN
				CASE WHEN OBJECT_ID(@into) IS NOT NULL THEN
					'INSERT INTO '+@intoname+' '
				ELSE '' END+
				'EXEC '+@servername+'...sp_executesql'+
					' N'''+REPLACE(@statement,'''','''''')+''''+
					',N'''+ISNULL(@param_declare,'')+''''+
					ISNULL(','+@param_values,'')
			WHEN LTRIM(REPLACE(REPLACE(
				@statement,char(13)+char(10),''),'	',''))
				LIKE 'SELECT%' THEN
				'SELECT * FROM OPENQUERY('+
					@servername+',N'''+REPLACE(@statement,'''','''''')+''')'
			ELSE
				'EXEC(N'''+REPLACE(@statement,'''','''''')+''')AT '+
					@servername
			END
		ELSE
			CASE WHEN OBJECT_ID(@into) IS NOT NULL THEN
				'INSERT INTO '+@intoname+' '+@statement
			WHEN @into<>'' THEN
				'SELECT * INTO '+@intoname+' FROM('+
					CASE WHEN RTRIM(@statement) LIKE '%;' THEN
						SUBSTRING(RTRIM(@statement),1,LEN(RTRIM(@statement))-1)
					ELSE @statement END+')_'
			ELSE
				@statement
			END
		END+';'+@NL+
		'SET NOCOUNT ON;'+@NL+
		ISNULL('SELECT '+@var_out+';','');
	IF @debug=1 BEGIN;
		PRINT '>>>>>> @statement_declare';PRINT @statement_declare;
		PRINT '>>>>>> execute statement';PRINT @sql;
	END;
	EXEC dbo.sp_executesql @sql,@statement_declare,
		@p01 OUT,@p02 OUT,@p03 OUT,@p04 OUT,@p05 OUT,@p06 OUT,
		@p07 OUT,@p08 OUT,@p09 OUT,@p10 OUT,@p11 OUT,@p12 OUT,
		@p13 OUT,@p14 OUT,@p15 OUT,@p16 OUT,@p17 OUT,@p18 OUT,
		@p19 OUT,@p20 OUT,@p21 OUT,@p22 OUT,@p23 OUT,@p24 OUT,
		@p25 OUT,@p26 OUT,@p27 OUT,@p28 OUT,@p29 OUT,@p30 OUT;
	/*
	END TRY BEGIN CATCH;
		PRINT @sql;
		PRINT ERROR_MESSAGE();
	END CATCH;
	*/
END

