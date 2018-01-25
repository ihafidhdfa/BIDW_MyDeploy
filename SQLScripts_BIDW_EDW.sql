/**************************************************
v4.2.0_SQLScripts_DW

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

---------------------------------------
--AB Add Distribution Center START--
---------------------------------------
/****** Object:  Table [dbo].[DimDistributionCenter]    Script Date: 1/3/2018 9:44:10 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DimDistributionCenter]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].DimDistributionCenter
(
	[DistributionCenter] [varchar](10) NOT NULL,
	[InsertAuditKey] [int]  NULL,
	[UpdateAuditKey] [int]  NULL,
	[ETLDateInserted] [datetime2](0) NOT NULL 
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
END
GO


Truncate Table DimDistributionCenter

insert into DimDistributionCenter
select distinct ISNULL(DistCenterNumber,0) DistributionCenter
,0
,0
,sysutcdatetime()
from factsales 

/****** Object:  View [dbo].[Distribution Center]    Script Date: 1/5/2018 8:21:24 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[Distribution Center]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[Distribution Center] AS SELECT 
      [DistributionCenter]		AS [Distribution Center]
      ,[ETLDateInserted]	AS [ETLDateInserted]
  FROM [dbo].[DimDistributionCenter];' 
GO

---------------------------------------
--AB Add Distribution Center END--
---------------------------------------

--/****** Object:  Table [dbo].[FactSalesBudget]    Script Date: 1/5/2018 3:29:47 PM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

--IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactSalesBudget]') AND type in (N'U'))
--BEGIN
--CREATE TABLE [dbo].[FactSalesBudget]
--(
--	[HistBusinessUnit] [int] NOT NULL,
--	[CustomerCode] [varchar](20) NOT NULL,
--	[ItemNumber] [varchar](20) NULL,
--	[Month] [int] NULL,
--	[Year] [int] NULL,
--	[SalesVolume] [decimal](20, 8) NULL,
--	[GLDate] [int] NOT NULL,
--	[CustomerDimKey] [int] NULL,
--	[ItemDimKey] [int] NULL
--)
--WITH
--(
--	DISTRIBUTION = ROUND_ROBIN,
--	CLUSTERED COLUMNSTORE INDEX
--)
--END
--GO

--/****** Object:  Table [dbo].[FactSalesBudget]    Script Date: 1/11/2018 2:18:18 PM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FactSalesBudget]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[FactSalesBudget]
(
	[HistBusinessUnit] [int] NOT NULL,
	[ShipToNumber] [varchar](20) NOT NULL,
	[ItemNumber] [varchar](20) NULL,
	[Month] [int] NULL,
	[Year] [int] NULL,
	[SalesVolume] [decimal](15, 5) NULL,
	[GLDate] [int] NOT NULL,
	[CustomerDimKey] [int] NULL,
	[ItemDimKey] [int] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
END
GO



/****** Object:  Table [stage].[erms_SalesRebate]    Script Date: 1/5/2018 11:31:25 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[stage].[erms_SalesRebate]') AND type in (N'U'))
BEGIN
CREATE TABLE [stage].[erms_SalesRebate]
(
	[ChainNumber] [INT] NOT NULL,
	[CustomerNumber] [INT] NOT NULL,
	[SalesNumber] [bigint] NOT NULL,
	[ItemNumber] [varchar](20) NULL,
	[RebateAmount] [decimal](38, 5) NULL,
	[TrxDate] [int] NOT NULL,
	[TrxYearMonth] [varchar](10) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
END
GO


--======================================
-------------------GL-------------------
---======================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DimChartOfAccounts]') AND type in (N'U'))
BEGIN
DROP TABLE  dbo.[DimChartOfAccounts]
END
GO

CREATE TABLE [dbo].[DimChartOfAccounts]
(
	[BusinessUnit] [int] NULL,
	[AccountID] [varchar](8) NULL,
	[BusinessUnitCostCenter] [int] NULL,
	[BusinessUnitCostCenterDesc] [varchar](50) NULL,
	[Subsidiary] [varchar](50) NULL,
	[SubsidiaryDesc] [varchar](50) NULL,
	[ObjectAccount] [varchar](50) NULL,
	[AccountNumberInput] [varchar](50) NULL,
	[AccountDesc] [varchar](150) NULL,
	[ParentID] [varchar](50) NULL,
	[AccountLevelOfDetail] [int] NULL,
	[BusinessUnitType] [varchar](50) NULL,
	[BusinessUnitTypeDesc] [varchar](50) NULL,
	[CostCenterCode] [varchar](10) NULL,
	[CostCenterDesc] [varchar](50) NULL,
	[LocationCode] [varchar](10) NULL,
	[LocationDesc] [varchar](50) NULL,
	[NetSalesCode] [varchar](10) NULL,
	[NetSalesDesc] [varchar](50) NULL,
	[GrossMarginCode] [varchar](10) NULL,
	[GrossMarginDesc] [varchar](50) NULL,
	[Future1Code] [varchar](10) NULL,
	[Future1Desc] [varchar](50) NULL,
	[Future2Code] [varchar](10) NULL,
	[Future2Desc] [varchar](50) NULL,
	[Future3Code] [varchar](10) NULL,
	[Future3Desc] [varchar](50) NULL,
	[ProductCategory] [varchar](10) NULL,
	[ProductCategoryDesc] [varchar](50) NULL,
	[sysDisabled] [bit] NOT NULL,
	[ETLDateInserted] [datetime2](0) NOT NULL,
	[InsertAuditKey] [int] NOT NULL,
	[UpdateAuditKey] [int] NOT NULL,
	[SourceSystem] [varchar](4) NOT NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
GO


IF EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[Date]'))
DROP VIEW [dbo].[Date]
GO

IF EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[GLDate]'))
DROP VIEW [dbo].[GLDate]
GO

IF EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[ChartOfAccounts]'))
DROP VIEW [dbo].[ChartOfAccounts]
GO

IF EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[GL]'))
DROP VIEW [dbo].[GL]
GO

CREATE VIEW [dbo].[GL] AS SELECT  [Company]
		,[DocumentType]
		,[Document]
		,[GLDGJ]
		,[GLDate]
		,[JournalEntryLineNumber]
		,[LineExtensionCode]
		,[PostedCode]
		,[BatchNumber]
		,[BatchType]
		,CASE WHEN [DateBatch] = 0 THEN NULL
			ELSE CAST(dateadd(dd, (cast([DateBatch] as int) - ((cast([DateBatch] as int)/1000) * 1000)) - 1, dateadd(yy, cast([DateBatch] as int)/1000, 0)) as date) END AS BatchDate
		,[DateBatchSystem]
		,[BatchTime]
		,[BusinessUnitID]
		,[AccountNumberInput]
		,[AccountMode]
		,[AccountID]
		,[BusinessUnitCostCenter]
		,[ObjectAccount]
		,[Subsidiary]
		,[LedgerTypes]
		,[Amount]
		,CASE WHEN [ObjectAccount] = '30100' OR [ObjectAccount] >= '90000' THEN Points ELSE NULL END AS [Points]
		,[UnitOfMeasure]
		,[ReverseVoid]
		,[AlphaExplanation]
		,[RemarkExplanation]
		,[Reference1]
		,[Reference2]
		,[InvoiceNumber]
		,[CustomerDimKey]
		,[SubLedger]
		,[SubLedgerType]
		,[GLUSER] AS UserID
		,[GLPID]
		,[GLUPMJ]
		,[GLUPMT]
		,[ETLDateInserted]
		,[SourceSystem]
  FROM [dbo].[FactGL];
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[ChartOfAccounts] AS SELECT [BusinessUnit]
		,[AccountID]
		,[BusinessUnitCostCenter]
		,[BusinessUnitCostCenterDesc]
		,[ObjectAccount]
		,[AccountDesc] AS [ObjectAccountDesc]
		,[Subsidiary]
		,[Subsidiary] AS PCAT2
		,[SubsidiaryDesc]
		,[AccountNumberInput]
		,[ParentID]
		,[AccountNumberInput] AS [AccountNumber]
		,[AccountDesc] AS [AccountNumberDesc]
		,[AccountNumberInput] +  ' - '  + [AccountDesc] AS Account
		,[AccountLevelOfDetail]
		,[BusinessUnitType]
		,[BusinessUnitTypeDesc]
		,[CostCenterCode]
		,[CostCenterDesc]
		,CASE WHEN [CostCenterCode]  = '' THEN ''
			ELSE [CostCenterCode] + ' - ' + ISNULL([CostCenterDesc], '') 
			END AS CostCenter
		,[LocationCode]
		,[LocationDesc]
		,CASE WHEN [LocationCode] = '' THEN ''
			ELSE [LocationCode] + ' - ' + ISNULL([LocationDesc], '') 
			END AS [Location]
		,[NetSalesCode] AS [NetSalesRptCatCode]
		,[NetSalesDesc] AS [NetSalesRptCatDesc]
		,CASE WHEN [NetSalesCode] = '' THEN '' 
			ELSE CONCAT([NetSalesCode], ' - ', [NetSalesDesc]) 
			END AS NetSales
		,[GrossMarginCode] AS [GrossMarginRptCatCode]
		,[GrossMarginDesc] AS [GrossMarginRptCatDesc]
		,CASE WHEN [GrossMarginCode] = '' THEN ''
			ELSE CONCAT([GrossMarginCode], ' - ', [GrossMarginDesc])  
			END AS GrossMargin
		,[Future1Code]
		,[Future1Desc]
		,CASE WHEN [Future1Code] = '' THEN ''
			ELSE [Future1Code] + ' - ' + ISNULL([Future1Desc], '') 
			END AS Future1
		,[Future2Code]
		,[Future2Desc]
		,CASE WHEN [Future2Code] = '' THEN '' 
			ELSE [Future2Code] + ' - ' + ISNULL([Future2Desc], '') 
			END AS Future2
		,[Future3Code]
		,[Future3Desc]
		,CASE WHEN [Future3Code] = '' THEN '' 
			ELSE [Future3Code] + ' - ' + ISNULL([Future3Desc], '') 
			END AS Future3
		,[ProductCategory]
		,[ProductCategoryDesc]
		,[ETLDateInserted]
		,[InsertAuditKey]
		,[UpdateAuditKey]
		,[SourceSystem]
		,CASE 
			WHEN ObjectAccount BETWEEN '10000' AND '29999' THEN 'Balance Sheet'
			WHEN ObjectAccount BETWEEN '30000' AND '89999' THEN 'Income Statement'
			WHEN ObjectAccount BETWEEN '90000' AND '99999' THEN 'Statistical Accounts'
			ELSE 'N/A'
		END AS [ChartOfAccountsType]
  FROM [dbo].[DimChartOfAccounts]
  WHERE sysDisabled = 0;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[GLDate] AS SELECT [DateDimKey] AS [Date Dim Key]
, [FullDate] AS [GL Date]
, [DateName] AS [GL Date Name]
, [DayOfWeek] AS [Day Of Week]
, [DayNameOfWeek] AS [Day Name Of Week]
, [DayOfMonth] AS [Day Of Month]
, [DayOfYear] AS [Day Of Year]
, [WeekdayWeekend] AS [Weekday Weekend]
, [WeekOfYear] AS [Week Of Year]
, [WeekEndingName] AS [Week Ending Name]
, [MonthName] AS [Month Name]
, [MonthOfYear] AS [Month Of Year]
, [IsLastDayOfMonth] AS [Is Last Day Of Month]
, [CalendarQuarter] AS [Calendar Qtr Of Year]
, [CalendarYear] AS [Calendar Year]
, [CalendarYearMonth] AS [Calendar Year Month]
, [CalendarYearQtr] AS [Calendar Year Qtr]
, [MonthNameEnglish] AS [Month Name English]
, [QuarterNameEnglish] AS [Quarter Name English]
, [FiscalMonthOfYear] AS [Fiscal Month Of Year]
, [FiscalQuarter] AS [Fiscal Qtr Of Year]
, [FiscalYear] AS [Fiscal Year]
, [FiscalYearMonth] AS [Fiscal Year Month]
, [FiscalYearQtr] AS [Fiscal Year Qtr]
, CAST([CalendarYearMonth] + '-01' AS date) AS [CalendarYearMonthStart]
FROM dbo.DimDate
WHERE DateDimKey >= 20150101;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[Date] AS SELECT [DateDimKey] AS [Date Dim Key]
, [FullDate] AS [Full Date]
, [DateName] AS [Date Name]
, [DayOfWeek] AS [Day Of Week]
, [DayNameOfWeek] AS [Day Name Of Week]
, [DayOfMonth] AS [Day Of Month]
, [DayOfYear] AS [Day Of Year]
, [WeekdayWeekend] AS [Weekday Weekend]
, [WeekOfYear] AS [Week Of Year]
, [WeekEndingName] AS [Week Ending Name]
, [MonthName] AS [Month Name]
, [MonthOfYear] AS [Month Of Year]
, [IsLastDayOfMonth] AS [Is Last Day Of Month]
, [CalendarQuarter] AS [Calendar Qtr Of Year]
, [CalendarYear] AS [Calendar Year]
, [CalendarYearMonth] AS [Calendar Year Month]
, [CalendarYearQtr] AS [Calendar Year Qtr]
, [MonthNameEnglish] AS [Month Name English]
, [QuarterNameEnglish] AS [Quarter Name English]
, [FiscalMonthOfYear] AS [Fiscal Month Of Year]
, [FiscalQuarter] AS [Fiscal Qtr Of Year]
, [FiscalYear] AS [Fiscal Year]
, [FiscalYearMonth] AS [Fiscal Year Month]
, [FiscalYearQtr] AS [Fiscal Year Qtr]
FROM dbo.DimDate
WHERE DateDimKey >= 20150101;
GO

/****** Object:  View [dbo].[SalesBudgetVolume]    Script Date: 1/16/2018 3:30:02 PM ******/
DROP VIEW [dbo].[SalesBudgetVolume]
GO

/****** Object:  View [dbo].[SalesBudgetVolume]    Script Date: 1/16/2018 3:30:02 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[SalesBudgetVolume]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[SalesBudgetVolume] AS SELECT 
	[HistBusinessUnit] AS [Business Unit]		
	,CustomerDimKey
	--[ShipToNumber]
	,[ItemDimKey]
	,[GLDate]
	,[SalesVolume]

FROM [dbo].[FactSalesBudget];' 
GO
