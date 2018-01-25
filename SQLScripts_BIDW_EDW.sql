/**************************************************
SQLScripts_DW
v4.2.0
****************************************************/

---------------------------------------
--Indexes on DimItem
---------------------------------------
IF EXISTS (SELECT * FROM sys.indexes WHERE name='IX_dbo_DimDate_CalendarYearMonth' AND object_id = OBJECT_ID('dbo.DimDate'))
DROP INDEX [IX_dbo_DimDate_CalendarYearMonth] ON [dbo].[DimDate]
GO

CREATE NONCLUSTERED INDEX [IX_dbo_DimDate_CalendarYearMonth] ON [dbo].[DimDate]
(
	[CalendarYearMonth] ASC
)WITH (DROP_EXISTING = OFF)
GO
