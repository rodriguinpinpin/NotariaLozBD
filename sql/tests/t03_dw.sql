-- Prueba T3: DW_NotariaLozano cargado por ETL (se ejecuta el ETL dos veces: debe ser idempotente)
SET NOCOUNT ON;
IF DB_ID('DW_NotariaLozano') IS NULL THROW 50300, 'No existe DW_NotariaLozano', 1;
GO
USE DW_NotariaLozano;
GO
EXEC etl.usp_EjecutarTodo;
EXEC etl.usp_EjecutarTodo;
GO
CREATE OR ALTER PROCEDURE #Afirmar @ok BIT, @msg NVARCHAR(300) AS
BEGIN IF ISNULL(@ok,0) = 0 THROW 50301, @msg, 1; END;
GO
DECLARE @ok BIT, @v NVARCHAR(300);

SELECT @ok = IIF(COUNT(*) = 175 AND MIN(Fecha_Exacta) = '2026-06-01' AND MAX(Fecha_Exacta) = '2026-11-22', 1, 0),
       @v = CONCAT('DIM_TIEMPO: ', COUNT(*), ' filas') FROM DIM_TIEMPO;                                                  EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(*) = 0, 1, 0), @v = 'Anio_Mes con formato incorrecto' FROM DIM_TIEMPO WHERE Anio_Mes NOT LIKE '2026-[01][0-9]'; EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(*) = 7, 1, 0), @v = 'Faltan nombres de dia' FROM (SELECT DISTINCT Nombre_Dia FROM DIM_TIEMPO) d;     EXEC #Afirmar @ok, @v;

SELECT @ok = IIF((SELECT COUNT(*) FROM FACT_TRAMITE_GENERAL) = (SELECT COUNT(*) FROM NotariaPeru.dbo.Tramite), 1, 0), @v = 'Conteo de tramites no cuadra'; EXEC #Afirmar @ok, @v;
SELECT @ok = IIF((SELECT SUM(Monto_Cobrado) FROM FACT_TRAMITES_FINANCIEROS) = (SELECT SUM(Monto) FROM NotariaPeru.dbo.Pago WHERE Estado = 'Pagado'), 1, 0), @v = 'Importe cobrado no cuadra'; EXEC #Afirmar @ok, @v;
SELECT @ok = IIF((SELECT SUM(Monto_Pendiente) FROM FACT_TRAMITES_FINANCIEROS) = (SELECT SUM(Monto) FROM NotariaPeru.dbo.Pago WHERE Estado = 'Pendiente'), 1, 0), @v = 'Por cobrar no cuadra'; EXEC #Afirmar @ok, @v;
SELECT @ok = IIF((SELECT COUNT(*) FROM FACT_TRAMITES_FINANCIEROS) = (SELECT COUNT(*) FROM NotariaPeru.dbo.Pago), 1, 0), @v = 'Filas financieras <> pagos'; EXEC #Afirmar @ok, @v;
SELECT @ok = IIF((SELECT COUNT(*) FROM FACT_TIEMPOS_ATENCION) = (SELECT COUNT(*) FROM NotariaPeru.dbo.AtencionEtapa), 1, 0), @v = 'Atenciones no cuadran'; EXEC #Afirmar @ok, @v;

-- Anulados no suman dinero
SELECT @ok = IIF(ISNULL(SUM(f.Monto_Cobrado + f.Monto_Pendiente), 0) = 0, 1, 0), @v = 'Pagos anulados con importe'
FROM FACT_TRAMITES_FINANCIEROS f WHERE f.ID_Estado_Pago = 3; EXEC #Afirmar @ok, @v;

-- Integridad referencial (incluye claves nulas)
SELECT @ok = IIF(COUNT(*) = 0, 1, 0), @v = CONCAT('Huérfanas en FACT_TRAMITE_GENERAL: ', COUNT(*)) FROM FACT_TRAMITE_GENERAL f
WHERE NOT EXISTS (SELECT 1 FROM DIM_TIEMPO d WHERE d.ID_Tiempo = f.ID_Tiempo) OR NOT EXISTS (SELECT 1 FROM DIM_SERVICIO d WHERE d.ID_Servicio = f.ID_Servicio)
   OR NOT EXISTS (SELECT 1 FROM DIM_NOTARIO d WHERE d.ID_Notario = f.ID_Notario) OR NOT EXISTS (SELECT 1 FROM DIM_CLIENTE d WHERE d.ID_Cliente = f.ID_Cliente)
   OR NOT EXISTS (SELECT 1 FROM DIM_PERSONAL d WHERE d.ID_Personal = f.ID_Personal) OR NOT EXISTS (SELECT 1 FROM DIM_ESTADO_PAGO d WHERE d.ID_Estado_Pago = f.ID_Estado_Pago)
   OR NOT EXISTS (SELECT 1 FROM DIM_TURNO d WHERE d.ID_Turno = f.ID_Turno);
EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(*) = 0, 1, 0), @v = CONCAT('Huérfanas en FACT_TRAMITES_FINANCIEROS: ', COUNT(*)) FROM FACT_TRAMITES_FINANCIEROS f
WHERE NOT EXISTS (SELECT 1 FROM DIM_TIEMPO d WHERE d.ID_Tiempo = f.ID_Tiempo) OR NOT EXISTS (SELECT 1 FROM DIM_METODO_PAGO d WHERE d.ID_Metodo = f.ID_Metodo)
   OR NOT EXISTS (SELECT 1 FROM DIM_CLIENTE d WHERE d.ID_Cliente = f.ID_Cliente) OR NOT EXISTS (SELECT 1 FROM DIM_PERSONAL d WHERE d.ID_Personal = f.ID_Personal)
   OR NOT EXISTS (SELECT 1 FROM DIM_SERVICIO d WHERE d.ID_Servicio = f.ID_Servicio) OR NOT EXISTS (SELECT 1 FROM DIM_ESTADO_PAGO d WHERE d.ID_Estado_Pago = f.ID_Estado_Pago);
EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(*) = 0, 1, 0), @v = CONCAT('Huérfanas en FACT_TIEMPOS_ATENCION: ', COUNT(*)) FROM FACT_TIEMPOS_ATENCION f
WHERE NOT EXISTS (SELECT 1 FROM DIM_TIEMPO d WHERE d.ID_Tiempo = f.ID_Tiempo) OR NOT EXISTS (SELECT 1 FROM DIM_ETAPA_TRAMITE d WHERE d.ID_Etapa = f.ID_Etapa)
   OR NOT EXISTS (SELECT 1 FROM DIM_TURNO d WHERE d.ID_Turno = f.ID_Turno) OR NOT EXISTS (SELECT 1 FROM DIM_PERSONAL d WHERE d.ID_Personal = f.ID_Personal)
   OR NOT EXISTS (SELECT 1 FROM DIM_SERVICIO d WHERE d.ID_Servicio = f.ID_Servicio);
EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(*) = 0, 1, 0), @v = CONCAT('Huérfanas en FACT_DOCUMENTOS_OTORGADOS: ', COUNT(*)) FROM FACT_DOCUMENTOS_OTORGADOS f
WHERE NOT EXISTS (SELECT 1 FROM DIM_TIEMPO d WHERE d.ID_Tiempo = f.ID_Tiempo) OR NOT EXISTS (SELECT 1 FROM DIM_TIPO_DOCUMENTO d WHERE d.ID_TipoDocumento = f.ID_TipoDocumento)
   OR NOT EXISTS (SELECT 1 FROM DIM_CLIENTE d WHERE d.ID_Cliente = f.ID_Cliente) OR NOT EXISTS (SELECT 1 FROM DIM_PERSONAL d WHERE d.ID_Personal = f.ID_Personal)
   OR NOT EXISTS (SELECT 1 FROM DIM_SERVICIO d WHERE d.ID_Servicio = f.ID_Servicio);
EXEC #Afirmar @ok, @v;

SELECT @ok = IIF(COUNT(*) = 0, 1, 0), @v = 'Minutos_Totales <> Espera + Proceso' FROM FACT_TIEMPOS_ATENCION WHERE Minutos_Totales <> Minutos_Espera + Minutos_Proceso; EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(*) = 0, 1, 0), @v = 'Categoria invalida' FROM DIM_SERVICIO WHERE Categoria NOT IN ('Escrituras públicas', 'Extraprotocolares'); EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(*) >= 4, 1, 0), @v = 'DIM_TIPO_DOCUMENTO con menos de 4 tipos con produccion'
FROM (SELECT DISTINCT ID_TipoDocumento FROM FACT_DOCUMENTOS_OTORGADOS) d; EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(*) >= 2, 1, 0), @v = 'ETL_Auditoria sin 2 ejecuciones exitosas' FROM ETL_Auditoria WHERE Estado = 'Exito'; EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(DISTINCT Segmento) = 2, 1, 0), @v = 'Segmento de cliente debe tener Nuevo y Recurrente' FROM DIM_CLIENTE WHERE Segmento IN ('Nuevo', 'Recurrente'); EXEC #Afirmar @ok, @v;

PRINT 't03_dw: PASS';
