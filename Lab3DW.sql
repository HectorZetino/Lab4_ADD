/*******************************************************************/
/*			          HECTOR ZETINO 1295617                        */
/*******************************************************************/

/*******************************************************************/
/*			          Base de Datos para DWH                       */ 
/*******************************************************************/

SET NOCOUNT ON
GO

USE master
GO
if exists (select * from sysdatabases where name='LosMejoresDWH')
		drop database LosMejoresDWH
go

DECLARE @device_directory NVARCHAR(520)
SELECT @device_directory = SUBSTRING(filename, 1, CHARINDEX(N'master.mdf', LOWER(filename)) - 1)
FROM master.dbo.sysaltfiles WHERE dbid = 1 AND fileid = 1

EXECUTE (N'CREATE DATABASE LosMejoresDWH
  ON PRIMARY (NAME = N''LosMejoresDWH'', FILENAME = N''' + @device_directory + N'LosMejoresDWH.mdf'')
  LOG ON (NAME = N''LosMejoresDWH_log'',  FILENAME = N''' + @device_directory + N'LosMejoresDWH.ldf'')')
go

set quoted_identifier on
GO


/*******************************************************************/
/*			                     Dimensiones                       */ 
/*******************************************************************/

create schema dim
create schema fact

if OBJECT_ID('LosMejoresDWH..Dim_Clientes') is not null drop table LosMejoresDWH.dim.Dim_Clientes

CREATE TABLE LosMejoresDWH.[dim].[Dim_Clientes](
	[Id_Cliente] int identity(1,1) not null,
	[CustomerID] [nchar](5) NOT NULL,
	[CompanyName] [nvarchar](40) NOT NULL,
	[ContactName] [nvarchar](30) NULL,
	[ContactTitle] [nvarchar](30) NULL,
	[Address] [nvarchar](60) NULL,
	[City] [nvarchar](15) NULL,
	[Region] [nvarchar](15) NULL,
	[PostalCode] [nvarchar](10) NULL,
	[Country] [nvarchar](15) NULL,
	[Phone] [nvarchar](24) NULL,
	[Fax] [nvarchar](24) NULL
)
GO


if OBJECT_ID('LosMejoresDWH..Dim_Productos') is not null drop table LosMejoresDWH.dim.Dim_Productos

CREATE TABLE LosMejoresDWH.[dim].[Dim_Productos](
	[Id_Producto] int identity(1,1) not null,
	[ProductID] [int] NOT NULL,
	[ProductName] [nvarchar](40) NOT NULL,
	[SupplierID] [int] NULL,
	[CategoryID] [int] NULL,
	[QuantityPerUnit] [nvarchar](20) NULL,
	[UnitPrice] [money] NULL,
	[UnitsInStock] [smallint] NULL,
	[UnitsOnOrder] [smallint] NULL,
	[ReorderLevel] [smallint] NULL,
	[Discontinued] [bit] NOT NULL
) 
GO


if OBJECT_ID('LosMejoresDWH..Dim_Empleado') is not null drop table LosMejoresDWH.dim.Dim_Empleado

CREATE TABLE LosMejoresDWH.[dim].[Dim_Empleado]( 
    [Id_Empleado] int identity(1,1) not null,
	[EmployeeID] [int] NOT NULL,
	[FirstName] [nvarchar](10) NOT NULL,
	[LastName] [nvarchar](20) NOT NULL
) 
GO


if OBJECT_ID('LosMejoresDWH..fact_Invoices') is not null drop table LosMejoresDWH.fact.fact_Invoices

CREATE TABLE  LosMejoresDWH.[fact].fact_Invoices(
	InvoiceID int identity(1,1) not null,
	CustomerID [nchar](5) not null,
	ProductID [INT] not null,
	EmployeeID [INT] not null,
	Quantity [INT] not null,
	UnitPrice [MONEY] null,
	CreatedDate date default getdate()
)
GO


/*******************************************************************/
/*		            Relacionar Tablas Dim con H                    */ 
/*******************************************************************/

ALTER TABLE LosMejoresDWH.Dim.Dim_Clientes ADD PRIMARY KEY (CustomerID)
ALTER TABLE LosMejoresDWH.Dim.Dim_Productos ADD PRIMARY KEY (ProductID);
ALTER TABLE LosMejoresDWH.Dim.Dim_Empleado  ADD PRIMARY KEY (EmployeeID);



ALTER TABLE LosMejoresDWH.fact.fact_Invoices ADD CONSTRAINT FK_CustomerID FOREIGN KEY (CustomerID) REFERENCES LosMejoresDWH.dim.Dim_Clientes (CustomerID)
ALTER TABLE LosMejoresDWH.fact.fact_Invoices add CONSTRAINT FK_ProductID  FOREIGN KEY (ProductID) REFERENCES LosMejoresDWH.dim.Dim_Productos (ProductID)
ALTER TABLE LosMejoresDWH.fact.fact_Invoices add CONSTRAINT FK_EmployeeID FOREIGN KEY (EmployeeID) REFERENCES LosMejoresDWH.[dim].[Dim_Empleado] (EmployeeID)


/*******************************************************************/
/*			            Llenado de  Dimensiones                    */ 
/*******************************************************************/


--Llenado Tabla Clientes
insert into LosMejoresDWH.dim.Dim_Clientes
select 
	*
from Northwind.dbo.Customers
 --------------------------------------------------------------------
--Llenado tabla Productos
insert into LosMejoresDWH.dim.Dim_Productos
select 
* 
from Northwind.dbo.Products
  --------------------------------------------------------------------
--llenado de tabla Empleado
insert into LosMejoresDWH.dim.Dim_Empleado
Select 
	E.Employeeid,
	E.Firstname, 
	E.LastName
From Northwind.Dbo.Employees As E




-------------------------------------------------------------------
-- Llenado de tabla invoices
insert into LosMejoresDWH.fact.fact_Invoices
select 
	inv.CustomerID,
	Inv.ProductID,
	O.EmployeeID,
	Inv.Quantity,
	inv.UnitPrice,
	GETDATE()
from Northwind.dbo.Invoices as INV
left join Northwind.dbo.Orders AS O
on O.OrderID = INV.OrderID





CREATE TABLE LosMejoresDWH.dim.Dim_Fecha(
	[CalendarDate] [DATE] NOT NULL, 
	[dayOfWeekNum] [INT] NOT NULL,  
	[dayOfWeekName] [nvarchar](15) NOT NULL, 
	[dayOfCalendarMonthNum] [nvarchar](15) NOT NULL, 
	[dayOfCalendarYearNum] [nvarchar](15) NOT NULL, 
	[CalendarWeekNum] [nvarchar](15) NOT NULL,  
	[calendarMonthNum] [nvarchar](15) NOT NULL,
	[calendarMonthName] [nvarchar](15) NOT NULL,
	[calendarQuarterNum] [nvarchar](15) NOT NULL, 
	[calendarYearNum] [nvarchar](15) NOT NULL 
)
GO

CREATE OR ALTER PROCEDURE USP_FillDimDate @CurrentDate DATE = '1996-01-01', 
									@EndDate     DATE = '1998-12-31'
AS
BEGIN
	SET NOCOUNT ON;
	DELETE FROM LosMejoresDWH.dim.Dim_Fecha;

	WHILE @CurrentDate < @EndDate
	BEGIN
		INSERT INTO LosMejoresDWH.dim.Dim_Fecha
		(					 
		 [CalendarDate]--
		,[dayOfWeekNum]
		,[dayOfWeekName]--
		,[dayOfCalendarMonthNum]--
		,[dayOfCalendarYearNum]--
		,[CalendarWeekNum]--
		,[calendarMonthNum]--
		,[calendarMonthName]--
		,[calendarYearNum]-- 	
		,[calendarQuarterNum]--
						
		)
		SELECT 
			[CalendarDate] = @CurrentDate,
			[dayOfWeekNum] = DATEPART(dw,@CurrentDate), 
			[dayOfWeekName] = DATENAME(dw, @CurrentDate), 
			[dayOfCalendarMonthNum] = DAY(@CurrentDate),
			[dayOfCalendarYearNum] = DATENAME(dy, @CurrentDate), 
			[CalendarWeekNum] = DATEPART(wk, @CurrentDate), 
			[calendarMonthNum] = MONTH(@CurrentDate),
			[calendarMonthName] = FORMAT(@CurrentDate, 'MMMM'),
			[calendarYearNum] = YEAR(@CurrentDate), 
			[calendarQuarterNum] = CASE
								WHEN DATENAME(qq, @CurrentDate) = 1
								THEN 'First'
								WHEN DATENAME(qq, @CurrentDate) = 2
								THEN 'second'
								WHEN DATENAME(qq, @CurrentDate) = 3
								THEN 'third'
								WHEN DATENAME(qq, @CurrentDate) = 4
								THEN 'fourth'
							END; 					  
		SET @CurrentDate = DATEADD(DD, 1, @CurrentDate);
	END;
END;
go

EXEC USP_FillDimDate
