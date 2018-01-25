/**************************************************
v4.2.0_SQLScripts_STAGE

****************************************************/

USE [BIDW_STAGE]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[IMPORTS].[SalesBudget]') AND type in (N'U'))
ALTER TABLE [IMPORTS].[SalesBudget] DROP CONSTRAINT IF EXISTS [DF_IMPORTS_SalesBudget_ETLDateInserted]
GO

/****** Object:  Table [IMPORTS].[SalesBudget]    Script Date: 1/8/2018 11:21:36 AM ******/
DROP TABLE IF EXISTS [IMPORTS].[SalesBudget]
GO

/****** Object:  Table [IMPORTS].[SalesBudget]    Script Date: 1/8/2018 11:21:36 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[IMPORTS].[SalesBudget]') AND type in (N'U'))
BEGIN
CREATE TABLE [IMPORTS].[SalesBudget](
	[Historical Business Unit Code] [nvarchar](255) NULL,
	[Ship To Number] [nvarchar](255) NULL,
	[Ship To Name] [nvarchar](255) NULL,
	[Item Number] [nvarchar](255) NULL,
	[Month] [int] NULL,
	[Year] [int] NULL,
	[Sales Volume] [decimal](15,5) NULL,
	[SheetName] [nvarchar](50) NOT NULL,
	[FileName] [nvarchar](255) NOT NULL,
	[ETLDateInserted] [datetime2](0) NOT NULL
) ON [PRIMARY]
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[IMPORTS].[DF_IMPORTS_SalesBudget_ETLDateInserted]') AND type = 'D')
BEGIN
ALTER TABLE [IMPORTS].[SalesBudget] ADD  CONSTRAINT [DF_IMPORTS_SalesBudget_ETLDateInserted]  DEFAULT (sysutcdatetime()) FOR [ETLDateInserted]
END
GO


/****** Object:  Table [stage].[FactSalesBudget]    Script Date: 1/8/2018 3:42:59 PM ******/
DROP TABLE IF EXISTS [stage].[FactSalesBudget]
GO

/****** Object:  Table [stage].[FactSalesBudget]    Script Date: 1/8/2018 3:42:59 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[stage].[FactSalesBudget]') AND type in (N'U'))
BEGIN
CREATE TABLE [stage].[FactSalesBudget](
	[HistBusinessUnit] [int] NOT NULL,
	[ShipToNumber] [varchar](20) NOT NULL,
	[ItemNumber] [varchar](20) NULL,
	[Month] [int] NULL,
	[Year] [int] NULL,
	[SalesVolume] [decimal](15,5) NULL,
	[GLDate] [int] NOT NULL,
	[CustomerDimKey] [int] NULL,
	[ItemDimKey] [int] NULL
) ON [PRIMARY]
END
GO

/****** Object:  View [IMPORTS].[SalesBudgetVolume]    Script Date: 1/11/2018 1:27:43 PM ******/
DROP VIEW IF EXISTS [IMPORTS].[SalesBudgetVolume]
GO

/****** Object:  View [IMPORTS].[SalesBudgetVolume]    Script Date: 1/11/2018 1:27:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[IMPORTS].[SalesBudgetVolume]'))
EXEC dbo.sp_executesql @statement = N'
--IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[imports].[SalesBudgetVolume]'') AND type in (N''U''))

CREATE VIEW [IMPORTS].[SalesBudgetVolume] AS SELECT

     convert(int, [Historical Business Unit Code]) AS BusinessUnit
	,convert(varchar(20), [Ship To Number]) AS ShipToNumber
	,convert(varchar (20), [Item Number]) AS ItemNumber
	,convert(decimal (15,5), [Sales Volume]) AS SalesVolume
	,convert(varchar (2), [Month]) AS Month
	,[Year] AS Year
	,CONVERT(int, CONCAT([Year], right(''0''+[Month],2),''01'')) AS GLDate

FROM [IMPORTS].[SalesBudget]

' 
GO

/****** Object:  View [ERMS].[SalesRebate]    Script Date: 1/11/2018 1:23:27 PM ******/
DROP VIEW IF EXISTS [ERMS].[SalesRebate]
GO

/****** Object:  View [ERMS].[SalesRebate]    Script Date: 1/11/2018 1:23:27 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[ERMS].[SalesRebate]'))
EXEC dbo.sp_executesql @statement = N'



CREATE VIEW [ERMS].[SalesRebate] AS


SELECT  
 [HRHCUSCHN] AS ChainNumber
,[HRHCUSNUM] AS CustomerNumber
,[HRHSLSNBR] AS SalesNumber
,LTRIM(RTRIM([HRDITMNUM])) AS ItemNumber
,SUM([HRDTOTDSC]) AS RebateAmount
,[HRHTRNDTE] AS TrxDate
,CAST(LEFT(HRHTRNDTE, 4) + ''-'' + SUBSTRING(cast(HRHTRNDTE as varchar), 5, 2) AS varchar(10)) AS TrxYearMonth
--, [HRDUNTDSC], [HRDSLSAMT], [HRDSLSQTY]
FROM ERMS.RMHRHP as rh 
INNER JOIN  ERMS.RMHRDP as rd on rd.HRDHRHREC = rh.HRHRECNUM
--WHERE rh.HRHCRTDTE > 20170101 
--WHERE HRHSLSNBR = 1806566
GROUP BY  [HRHCUSCHN]
		 ,[HRHCUSNUM]
		 ,[HRHSLSNBR]
		 ,[HRDITMNUM]
		 ,[HRHTRNDTE]


' 
GO




--==============================================
----------------------- GL ---------------------
--==============================================
DROP TABLE IF EXISTS [JDE].[ChartOfAccounts]
GO

DROP TABLE IF EXISTS [JDE].[ChartOfAccounts_temp]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [JDE].[ChartOfAccounts_temp](
	[BusinessUnit] [varchar](5) NULL,
	[AccountID] [varchar](8) NULL,
	[BusinessUnitCostCenter] [varchar](12) NULL,
	[ObjectAccount] [varchar](6) NULL,
	[Subsidiary] [varchar](8) NULL,
	[AccountNumber3rd] [varchar](25) NULL,
	[AcctDesc] [varchar](30) NULL,
	[AccountLevelOfDetail] [varchar](1) NULL,
	[ParentID] [varchar](6) NULL,
	[rownum] [int] NULL,
	[GMR001] [varchar](3) NULL,
	[GMR002] [varchar](3) NULL,
	[GMR003] [varchar](3) NULL,
	[GMR005] [varchar](3) NULL,
	[GMR006] [varchar](3) NULL,
	[GMR007] [varchar](3) NULL
)
GO

SET ANSI_PADDING ON
GO

CREATE CLUSTERED INDEX [IX_JChartOfAccounts_temp_AccountID] ON [JDE].[ChartOfAccounts_temp]
(
	[AccountID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [JDE].[ChartOfAccounts](
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
	[ETLDateInserted] [datetime2](0) NOT NULL
)
GO

SET ANSI_PADDING ON
GO

CREATE CLUSTERED INDEX [IX_JChartOfAccounts_AccountID] ON [JDE].[ChartOfAccounts]
(
	[AccountID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IX_JChartOfAccounts_temp_BusinessUnit] ON [JDE].[ChartOfAccounts_temp]
(
	[BusinessUnit] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IX_JChartOfAccounts_temp_BusinessUnitCostCenter] ON [JDE].[ChartOfAccounts_temp]
(
	[BusinessUnitCostCenter] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IX_JChartOfAccounts_temp_Subsidiary] ON [JDE].[ChartOfAccounts_temp]
(
	[Subsidiary] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IX_JChartOfAccounts_AccountNumberInput] ON [JDE].[ChartOfAccounts]
(
	[AccountNumberInput] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

CREATE NONCLUSTERED INDEX [IX_JChartOfAccounts_BusinessUnit] ON [JDE].[ChartOfAccounts]
(
	[BusinessUnit] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

CREATE NONCLUSTERED INDEX [IX_JChartOfAccounts_BusinessUnitCostCenter] ON [JDE].[ChartOfAccounts]
(
	[BusinessUnitCostCenter] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IX_JChartOfAccounts_Subsidiary] ON [JDE].[ChartOfAccounts]
(
	[Subsidiary] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

ALTER TABLE [JDE].[ChartOfAccounts] ADD  CONSTRAINT [DF_JDE_ChartOfAccounts]  DEFAULT ((0)) FOR [sysDisabled]
GO

ALTER TABLE [JDE].[ChartOfAccounts] ADD  CONSTRAINT [DF_JDE_ChartOfAccounts_ETLDateInserted]  DEFAULT (sysutcdatetime()) FOR [ETLDateInserted]
GO


-- GL Views
DROP VIEW  IF EXISTS [JDE].[GlChartOfAccounts]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [JDE].[GlChartOfAccounts]
AS 

SELECT  [BusinessUnit]
      ,[AccountID]
      ,[BusinessUnitCostCenter]
      ,[BusinessUnitCostCenterDesc]
      ,[Subsidiary]
      ,[SubsidiaryDesc]
      ,[ObjectAccount]
      ,[AccountNumberInput]
      ,[AccountDesc]
      ,[ParentID]
      ,[AccountLevelOfDetail]
	  ,[AccountNumberInput] +  ' - '  + [AccountDesc] AS Account	  
      ,[BusinessUnitType]
      ,[BusinessUnitTypeDesc]
      ,[CostCenterCode]
      ,[CostCenterDesc]
      ,[LocationCode]
      ,[LocationDesc]
      ,[NetSalesCode]
      ,[NetSalesDesc]
      ,[GrossMarginCode]
      ,[GrossMarginDesc]
      ,[Future1Code]
      ,[Future1Desc]
      ,[Future2Code]
      ,[Future2Desc]
      ,[Future3Code]
      ,[Future3Desc]
      ,[ProductCategory]
      ,[ProductCategoryDesc]
      ,[sysDisabled]

FROM JDE.ChartOfAccounts
;
GO
--=========================== F0006 and F0901


DROP TABLE IF EXISTS [JDE].[F0006]
GO

DROP TABLE IF EXISTS [JDE].[F0901]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [JDE].[F0901](
	[GMCO] [varchar](5) NULL,
	[GMAID] [varchar](8) NULL,
	[GMMCU] [varchar](12) NULL,
	[GMOBJ] [varchar](6) NULL,
	[GMSUB] [varchar](8) NULL,
	[GMANS] [varchar](25) NULL,
	[GMDL01] [varchar](30) NULL,
	[GMLDA] [varchar](1) NULL,
	[GMBPC] [varchar](3) NULL,
	[GMPEC] [varchar](1) NULL,
	[GMSTPC] [varchar](1) NULL,
	[GMFPEC] [varchar](1) NULL,
	[GMBILL] [varchar](1) NULL,
	[GMCRCD] [varchar](3) NULL,
	[GMUM] [varchar](2) NULL,
	[GMR001] [varchar](3) NULL,
	[GMR002] [varchar](3) NULL,
	[GMR003] [varchar](3) NULL,
	[GMR004] [varchar](3) NULL,
	[GMR005] [varchar](3) NULL,
	[GMR006] [varchar](3) NULL,
	[GMR007] [varchar](3) NULL,
	[GMR008] [varchar](3) NULL,
	[GMR009] [varchar](3) NULL,
	[GMR010] [varchar](3) NULL,
	[GMR011] [varchar](3) NULL,
	[GMR012] [varchar](3) NULL,
	[GMR013] [varchar](3) NULL,
	[GMR014] [varchar](3) NULL,
	[GMR015] [varchar](3) NULL,
	[GMR016] [varchar](3) NULL,
	[GMR017] [varchar](3) NULL,
	[GMR018] [varchar](3) NULL,
	[GMR019] [varchar](3) NULL,
	[GMR020] [varchar](3) NULL,
	[GMR021] [varchar](10) NULL,
	[GMR022] [varchar](10) NULL,
	[GMR023] [varchar](10) NULL,
	[GMOBJA] [varchar](6) NULL,
	[GMSUBA] [varchar](8) NULL,
	[GMWCMP] [varchar](4) NULL,
	[GMCCT] [varchar](1) NULL,
	[GMERC] [varchar](2) NULL,
	[GMHTC] [varchar](1) NULL,
	[GMQLDA] [varchar](1) NULL,
	[GMCCC] [varchar](1) NULL,
	[GMFMOD] [varchar](1) NULL,
	[GMDTFR] [numeric](6, 0) NULL,
	[GMDTTO] [numeric](6, 0) NULL,
	[GMCEDF] [varchar](1) NULL,
	[GMTOBJ] [varchar](6) NULL,
	[GMTSUB] [varchar](8) NULL,
	[GMTXA1] [varchar](10) NULL,
	[GMEXR1] [varchar](2) NULL,
	[GMTXA2] [varchar](10) NULL,
	[GMEXR2] [varchar](2) NULL,
	[GMTXGL] [varchar](1) NULL,
	[GMUSER] [varchar](10) NULL,
	[GMPID] [varchar](10) NULL,
	[GMJOBN] [varchar](10) NULL,
	[GMUPMJ] [numeric](6, 0) NULL,
	[GMUPMT] [numeric](6, 0) NULL,
	[ETLDateInserted] [datetime2](0) NOT NULL
)
GO

SET ANSI_PADDING ON
GO

CREATE CLUSTERED INDEX [IX_JDE_F0901_GMAID] ON [JDE].[F0901]
(
	[GMAID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [JDE].[F0006](
	[MCMCU] [varchar](12) NULL,
	[MCSTYL] [varchar](2) NULL,
	[MCDC] [varchar](40) NULL,
	[MCLDM] [varchar](1) NULL,
	[MCCO] [varchar](5) NULL,
	[MCAN8] [numeric](8, 0) NULL,
	[MCAN8O] [numeric](8, 0) NULL,
	[MCCNTY] [varchar](3) NULL,
	[MCADDS] [varchar](3) NULL,
	[MCFMOD] [varchar](1) NULL,
	[MCDL01] [varchar](30) NULL,
	[MCDL02] [varchar](30) NULL,
	[MCDL03] [varchar](30) NULL,
	[MCDL04] [varchar](30) NULL,
	[MCRP01] [varchar](3) NULL,
	[MCRP02] [varchar](3) NULL,
	[MCRP03] [varchar](3) NULL,
	[MCRP04] [varchar](3) NULL,
	[MCRP05] [varchar](3) NULL,
	[MCRP06] [varchar](3) NULL,
	[MCRP07] [varchar](3) NULL,
	[MCRP08] [varchar](3) NULL,
	[MCRP09] [varchar](3) NULL,
	[MCRP10] [varchar](3) NULL,
	[MCRP11] [varchar](3) NULL,
	[MCRP12] [varchar](3) NULL,
	[MCRP13] [varchar](3) NULL,
	[MCRP14] [varchar](3) NULL,
	[MCRP15] [varchar](3) NULL,
	[MCRP16] [varchar](3) NULL,
	[MCRP17] [varchar](3) NULL,
	[MCRP18] [varchar](3) NULL,
	[MCRP19] [varchar](3) NULL,
	[MCRP20] [varchar](3) NULL,
	[MCRP21] [varchar](10) NULL,
	[MCRP22] [varchar](10) NULL,
	[MCRP23] [varchar](10) NULL,
	[MCRP24] [varchar](10) NULL,
	[MCRP25] [varchar](10) NULL,
	[MCRP26] [varchar](10) NULL,
	[MCRP27] [varchar](10) NULL,
	[MCRP28] [varchar](10) NULL,
	[MCRP29] [varchar](10) NULL,
	[MCRP30] [varchar](10) NULL,
	[MCTA] [varchar](10) NULL,
	[MCTXJS] [numeric](8, 0) NULL,
	[MCTXA1] [varchar](10) NULL,
	[MCEXR1] [varchar](2) NULL,
	[MCTC01] [varchar](4) NULL,
	[MCTC02] [varchar](4) NULL,
	[MCTC03] [varchar](4) NULL,
	[MCTC04] [varchar](4) NULL,
	[MCTC05] [varchar](4) NULL,
	[MCTC06] [varchar](4) NULL,
	[MCTC07] [varchar](4) NULL,
	[MCTC08] [varchar](4) NULL,
	[MCTC09] [varchar](4) NULL,
	[MCTC10] [varchar](4) NULL,
	[MCND01] [varchar](1) NULL,
	[MCND02] [varchar](1) NULL,
	[MCND03] [varchar](1) NULL,
	[MCND04] [varchar](1) NULL,
	[MCND05] [varchar](1) NULL,
	[MCND06] [varchar](1) NULL,
	[MCND07] [varchar](1) NULL,
	[MCND08] [varchar](1) NULL,
	[MCND09] [varchar](1) NULL,
	[MCND10] [varchar](1) NULL,
	[MCCC01] [varchar](1) NULL,
	[MCCC02] [varchar](1) NULL,
	[MCCC03] [varchar](1) NULL,
	[MCCC04] [varchar](1) NULL,
	[MCCC05] [varchar](1) NULL,
	[MCCC06] [varchar](1) NULL,
	[MCCC07] [varchar](1) NULL,
	[MCCC08] [varchar](1) NULL,
	[MCCC09] [varchar](1) NULL,
	[MCCC10] [varchar](1) NULL,
	[MCPECC] [varchar](1) NULL,
	[MCALS] [varchar](1) NULL,
	[MCISS] [varchar](1) NULL,
	[MCGLBA] [varchar](8) NULL,
	[MCALCL] [varchar](2) NULL,
	[MCLMTH] [varchar](1) NULL,
	[MCLF] [decimal](28, 0) NULL,
	[MCOBJ1] [varchar](6) NULL,
	[MCOBJ2] [varchar](6) NULL,
	[MCOBJ3] [varchar](6) NULL,
	[MCSUB1] [varchar](8) NULL,
	[MCTOU] [decimal](28, 0) NULL,
	[MCSBLI] [varchar](1) NULL,
	[MCANPA] [numeric](8, 0) NULL,
	[MCCT] [varchar](4) NULL,
	[MCCERT] [varchar](1) NULL,
	[MCMCUS] [varchar](12) NULL,
	[MCBTYP] [varchar](1) NULL,
	[MCPC] [decimal](28, 2) NULL,
	[MCPCA] [decimal](28, 0) NULL,
	[MCPCC] [decimal](28, 0) NULL,
	[MCINTA] [varchar](4) NULL,
	[MCINTL] [varchar](4) NULL,
	[MCD1J] [numeric](6, 0) NULL,
	[MCD2J] [numeric](6, 0) NULL,
	[MCD3J] [numeric](6, 0) NULL,
	[MCD4J] [numeric](6, 0) NULL,
	[MCD5J] [numeric](6, 0) NULL,
	[MCD6J] [numeric](6, 0) NULL,
	[MCFPDJ] [numeric](6, 0) NULL,
	[MCCAC] [decimal](28, 0) NULL,
	[MCPAC] [decimal](28, 0) NULL,
	[MCEEO] [varchar](1) NULL,
	[MCERC] [varchar](2) NULL,
	[MCAFE] [varchar](12) NULL,
	[MCTSBU] [varchar](12) NULL,
	[MCDTFR] [numeric](6, 0) NULL,
	[MCDTTO] [numeric](6, 0) NULL,
	[MCCEDF] [varchar](1) NULL,
	[MCUSER] [varchar](10) NULL,
	[MCPID] [varchar](10) NULL,
	[MCUPMJ] [numeric](6, 0) NULL,
	[MCJOBN] [varchar](10) NULL,
	[MCUPMT] [numeric](6, 0) NULL,
	[ETLInsertedDate] [datetime2](0) NULL,
	[ETLDateInserted] [datetime2](0) NOT NULL
)
GO

SET ANSI_PADDING ON
GO

CREATE CLUSTERED INDEX [IX_JDE_F0006_MCMCU] ON [JDE].[F0006]
(
	[MCMCU] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IX_JDE_F0901_GMCO] ON [JDE].[F0901]
(
	[GMCO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IX_JDE_F0901_GMLDA] ON [JDE].[F0901]
(
	[GMLDA] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IX_JDE_F0901_GMMCU] ON [JDE].[F0901]
(
	[GMMCU] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IX_JDE_F0901_GMOBJ] ON [JDE].[F0901]
(
	[GMOBJ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IX_JDE_F0901_GMSUB] ON [JDE].[F0901]
(
	[GMSUB] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

CREATE NONCLUSTERED INDEX [IX_JDE_F0901_GMUPMJ] ON [JDE].[F0901]
(
	[GMUPMJ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

CREATE NONCLUSTERED INDEX [IX_JDE_F0901_GMUPMT] ON [JDE].[F0901]
(
	[GMUPMT] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IX_JDE_F0006_MCRP01] ON [JDE].[F0006]
(
	[MCRP01] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IX_JDE_F0006_MCRP02] ON [JDE].[F0006]
(
	[MCRP02] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IX_JDE_F0006_MCRP03] ON [JDE].[F0006]
(
	[MCRP03] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

SET ANSI_PADDING ON
GO

CREATE NONCLUSTERED INDEX [IX_JDE_F0006_MCSTYL] ON [JDE].[F0006]
(
	[MCSTYL] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

ALTER TABLE [JDE].[F0901] ADD  CONSTRAINT [DF_JDE_F0901_ETLDateInserted]  DEFAULT (sysutcdatetime()) FOR [ETLDateInserted]
GO

ALTER TABLE [JDE].[F0006] ADD  DEFAULT (sysutcdatetime()) FOR [ETLInsertedDate]
GO

ALTER TABLE [JDE].[F0006] ADD  CONSTRAINT [DF_JDE_F0006_ETLDateInserted]  DEFAULT (sysutcdatetime()) FOR [ETLDateInserted]
GO






DROP TABLE IF EXISTS [ERMS].[RMVEOP]
GO

DROP TABLE IF EXISTS [ERMS].[RMVEHP]
GO

DROP TABLE IF EXISTS [ERMS].[RMROPP]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [ERMS].[RMROPP](
	[ROPRTENUM] [decimal](6, 0) NOT NULL,
	[ROPCODTYP] [char](10) NOT NULL,
	[ROPCODNUM] [char](10) NOT NULL,
	[ROPCODVAL] [char](30) NOT NULL,
	[ROPFACN3] [decimal](3, 0) NOT NULL,
	[ROPFACN9] [decimal](9, 0) NOT NULL,
	[ROPFACA1] [char](1) NOT NULL,
	[ROPFACA15] [char](15) NOT NULL,
	[ROPCRTUSR] [char](10) NOT NULL,
	[ROPCRTDTE] [decimal](8, 0) NOT NULL,
	[ROPCRTTIM] [decimal](6, 0) NOT NULL,
	[ROPCHGUSR] [char](10) NOT NULL,
	[ROPCHGDTE] [decimal](8, 0) NOT NULL,
	[ROPCHGTIM] [decimal](6, 0) NOT NULL,
	[X_UPID] [decimal](7, 0) NOT NULL,
	[X_RRNO] [decimal](15, 0) NOT NULL,
	[ETLDateInserted] [datetime2](0) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ROPCODTYP] ASC,
	[ROPRTENUM] ASC,
	[ROPCODNUM] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [ERMS].[RMVEHP](
	[VEHVEHNUM] [decimal](6, 0) NOT NULL,
	[VEHTRLOWN] [char](30) NOT NULL,
	[VEHTRLCUB] [decimal](7, 2) NOT NULL,
	[VEHTRLHFT] [decimal](3, 0) NOT NULL,
	[VEHTRLHIN] [decimal](3, 0) NOT NULL,
	[VEHTRLWFT] [decimal](3, 0) NOT NULL,
	[VEHTRLWIN] [decimal](3, 0) NOT NULL,
	[VEHTRLLFT] [decimal](3, 0) NOT NULL,
	[VEHTRLLIN] [decimal](3, 0) NOT NULL,
	[VEHTRLSIZ] [char](35) NOT NULL,
	[VEHCUB001] [decimal](7, 2) NOT NULL,
	[VEHCUB002] [decimal](7, 2) NOT NULL,
	[VEHCUB003] [decimal](7, 2) NOT NULL,
	[VEHCUB004] [decimal](7, 2) NOT NULL,
	[VEHCUB005] [decimal](7, 2) NOT NULL,
	[VEHCUB006] [decimal](7, 2) NOT NULL,
	[VEHCUB007] [decimal](7, 2) NOT NULL,
	[VEHCUB008] [decimal](7, 2) NOT NULL,
	[VEHCUB009] [decimal](7, 2) NOT NULL,
	[VEHCNT001] [decimal](11, 2) NOT NULL,
	[VEHCNT002] [decimal](11, 2) NOT NULL,
	[VEHCNT003] [decimal](11, 2) NOT NULL,
	[VEHCNT004] [decimal](11, 2) NOT NULL,
	[VEHCNT005] [decimal](11, 2) NOT NULL,
	[VEHCNT006] [decimal](11, 2) NOT NULL,
	[VEHCNT007] [decimal](11, 2) NOT NULL,
	[VEHCNT008] [decimal](11, 2) NOT NULL,
	[VEHCNT009] [decimal](11, 2) NOT NULL,
	[VEHCRTUSR] [char](10) NOT NULL,
	[VEHCRTDTE] [decimal](8, 0) NOT NULL,
	[VEHCRTTIM] [decimal](6, 0) NOT NULL,
	[VEHCHGUSR] [char](10) NOT NULL,
	[VEHCHGDTE] [decimal](8, 0) NOT NULL,
	[VEHCHGTIM] [decimal](6, 0) NOT NULL,
	[VEHTOTWGT] [decimal](5, 0) NOT NULL,
	[VEHTOTCAS] [decimal](5, 0) NOT NULL,
	[X_UPID] [decimal](7, 0) NOT NULL,
	[X_RRNO] [decimal](15, 0) NOT NULL,
	[ETLDateInserted] [datetime2](0) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[VEHVEHNUM] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [ERMS].[RMVEOP](
	[VEOCODTYP] [char](10) NOT NULL,
	[VEOVEHNUM] [decimal](6, 0) NOT NULL,
	[VEOCODNUM] [char](10) NOT NULL,
	[VEOCODVAL] [char](30) NOT NULL,
	[VEOVALNUM] [decimal](1, 0) NOT NULL,
	[VEOCRTUSR] [char](10) NOT NULL,
	[VEOCRTDTE] [decimal](8, 0) NOT NULL,
	[VEOCRTTIM] [decimal](6, 0) NOT NULL,
	[VEOCHGUSR] [char](10) NOT NULL,
	[VEOCHGDTE] [decimal](8, 0) NOT NULL,
	[VEOCHGTIM] [decimal](6, 0) NOT NULL,
	[X_UPID] [decimal](7, 0) NOT NULL,
	[X_RRNO] [decimal](15, 0) NOT NULL,
	[ETLDateInserted] [datetime2](0) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[VEOCODTYP] ASC,
	[VEOVEHNUM] ASC,
	[VEOCODNUM] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)
GO

ALTER TABLE [ERMS].[RMROPP] ADD  CONSTRAINT [DF_ERMS_RMROPP_ETLDateInserted]  DEFAULT (sysutcdatetime()) FOR [ETLDateInserted]
GO

ALTER TABLE [ERMS].[RMVEHP] ADD  CONSTRAINT [DF_ERMS_RMVEHP_ETLDateInserted]  DEFAULT (sysutcdatetime()) FOR [ETLDateInserted]
GO

ALTER TABLE [ERMS].[RMVEOP] ADD  CONSTRAINT [DF_ERMS_RMVEOP_ETLDateInserted]  DEFAULT (sysutcdatetime()) FOR [ETLDateInserted]
GO


