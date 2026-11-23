-- Prueba T1: esquema OLTP NotariaPeru
SET NOCOUNT ON;
IF DB_ID('NotariaPeru') IS NULL THROW 50000, 'No existe la base NotariaPeru', 1;
GO
USE NotariaPeru;
GO
DECLARE @n INT = (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0);
IF @n <> 22 BEGIN DECLARE @m NVARCHAR(200) = CONCAT('Se esperaban 22 tablas y hay ', @n); THROW 50001, @m, 1; END;
IF COL_LENGTH('dbo.Tramite', 'HoraInicio') IS NULL THROW 50002, 'Falta Tramite.HoraInicio', 1;
IF OBJECT_ID('dbo.AtencionEtapa') IS NULL THROW 50003, 'Falta AtencionEtapa', 1;
IF COL_LENGTH('dbo.TipoTramite', 'Categoria') IS NULL THROW 50004, 'Falta TipoTramite.Categoria', 1;
PRINT 't01_oltp: PASS';
