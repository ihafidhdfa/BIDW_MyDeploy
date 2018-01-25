/**************************************************
SQLScripts_STAGE
v4.2.0
****************************************************/

USE [BIDW_STAGE]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[IMPORTS].[SalesBudget]') AND type in (N'U'))
ALTER TABLE [IMPORTS].[SalesBudget] DROP CONSTRAINT IF EXISTS [DF_IMPORTS_SalesBudget_ETLDateInserted]
GO
