-- =============================================
-- Author:		Steven Chong
-- Create date: 2009-03-11
-- Description:	Splits a string into table(value nvarchar(max)) that are based on the @sep parameter.
-- =============================================
ALTER FUNCTION [dbo].[str_split](@str nvarchar(max),@sep nvarchar(max)=',')
RETURNS @t TABLE
(value nvarchar(max) )
AS
Begin 
	WITH a AS(
		SELECT
			idx1 = CAST(0 AS BIGINT)
		,	idx2 = CHARINDEX(@sep, @str)

		UNION ALL

		SELECT
			idx1 = CAST(idx2 + 1 AS BIGINT)
		,	idx2 = CHARINDEX(@sep, @str, idx2 + 1)
		FROM a
		WHERE idx2 > 0
	)
	Insert Into @t
	SELECT value = 
		SUBSTRING(
			@str
		,	idx1
		,	COALESCE(NULLIF(idx2, 0), LEN(@str) + 1) - idx1
		)
	FROM a	OPTION (MAXRECURSION 500)
	 Return
End
