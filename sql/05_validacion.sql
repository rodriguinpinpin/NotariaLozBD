/* =====================================================================
   05_validacion.sql  ·  Totales de referencia para conciliar Power BI
   Salida: una tabla (Indicador; Filtro; Valor) -> sql/referencia.csv
   Definiciones (iguales a las medidas DAX):
     Importe cobrado   = SUM(FACT_TRAMITES_FINANCIEROS.Monto_Cobrado)      (pagos 'Pagado')
     Importe facturado = SUM(FACT_TRAMITE_GENERAL.Monto_Arancel) de trámites no anulados
     Por cobrar        = SUM(FACT_TRAMITES_FINANCIEROS.Monto_Pendiente)
     Margen            = Importe cobrado - Costo asociado
   ===================================================================== */
USE DW_NotariaLozano;
SET NOCOUNT ON;

DECLARE @R TABLE (Orden INT IDENTITY, Indicador VARCHAR(60), Filtro VARCHAR(80), Valor VARCHAR(200));
DECLARE @Meses TABLE (Filtro VARCHAR(80), AnioMes VARCHAR(7));
INSERT INTO @Meses SELECT 'Total', NULL UNION ALL SELECT DISTINCT 'Mes=' + Anio_Mes, Anio_Mes FROM DIM_TIEMPO;

INSERT INTO @R (Indicador, Filtro, Valor)
SELECT i.Indicador, m.Filtro, CAST(CAST(i.Valor AS DECIMAL(18,2)) AS VARCHAR(40))
FROM @Meses m
CROSS APPLY (
    SELECT 'Importe cobrado', SUM(f.Monto_Cobrado) FROM FACT_TRAMITES_FINANCIEROS f JOIN DIM_TIEMPO d ON d.ID_Tiempo = f.ID_Tiempo WHERE m.AnioMes IS NULL OR d.Anio_Mes = m.AnioMes
    UNION ALL SELECT 'Importe facturado', SUM(f.Monto_Arancel) FROM FACT_TRAMITE_GENERAL f JOIN DIM_TIEMPO d ON d.ID_Tiempo = f.ID_Tiempo WHERE f.Estado_Tramite <> 'Anulado' AND (m.AnioMes IS NULL OR d.Anio_Mes = m.AnioMes)
    UNION ALL SELECT 'Por cobrar', SUM(f.Monto_Pendiente) FROM FACT_TRAMITES_FINANCIEROS f JOIN DIM_TIEMPO d ON d.ID_Tiempo = f.ID_Tiempo WHERE m.AnioMes IS NULL OR d.Anio_Mes = m.AnioMes
    UNION ALL SELECT 'Costo asociado', SUM(f.Costo_Asociado) FROM FACT_TRAMITES_FINANCIEROS f JOIN DIM_TIEMPO d ON d.ID_Tiempo = f.ID_Tiempo WHERE m.AnioMes IS NULL OR d.Anio_Mes = m.AnioMes
    UNION ALL SELECT 'Margen', SUM(f.Monto_Cobrado - f.Costo_Asociado) FROM FACT_TRAMITES_FINANCIEROS f JOIN DIM_TIEMPO d ON d.ID_Tiempo = f.ID_Tiempo WHERE m.AnioMes IS NULL OR d.Anio_Mes = m.AnioMes
    UNION ALL SELECT 'Tramites registrados', COUNT(*) FROM FACT_TRAMITE_GENERAL f JOIN DIM_TIEMPO d ON d.ID_Tiempo = f.ID_Tiempo WHERE m.AnioMes IS NULL OR d.Anio_Mes = m.AnioMes
    UNION ALL SELECT 'Atenciones registradas', COUNT(*) FROM FACT_TIEMPOS_ATENCION f JOIN DIM_TIEMPO d ON d.ID_Tiempo = f.ID_Tiempo WHERE m.AnioMes IS NULL OR d.Anio_Mes = m.AnioMes
    UNION ALL SELECT 'Atencion media minutos', AVG(f.Minutos_Totales * 1.0) FROM FACT_TIEMPOS_ATENCION f JOIN DIM_TIEMPO d ON d.ID_Tiempo = f.ID_Tiempo WHERE m.AnioMes IS NULL OR d.Anio_Mes = m.AnioMes
    UNION ALL SELECT 'Espera media minutos', AVG(f.Minutos_Espera * 1.0) FROM FACT_TIEMPOS_ATENCION f JOIN DIM_TIEMPO d ON d.ID_Tiempo = f.ID_Tiempo WHERE m.AnioMes IS NULL OR d.Anio_Mes = m.AnioMes
    UNION ALL SELECT 'Documentos otorgados', SUM(f.Cantidad_Documentos) FROM FACT_DOCUMENTOS_OTORGADOS f JOIN DIM_TIEMPO d ON d.ID_Tiempo = f.ID_Tiempo WHERE m.AnioMes IS NULL OR d.Anio_Mes = m.AnioMes
    UNION ALL SELECT 'Clientes unicos', COUNT(DISTINCT f.ID_Cliente) FROM FACT_TRAMITE_GENERAL f JOIN DIM_TIEMPO d ON d.ID_Tiempo = f.ID_Tiempo WHERE m.AnioMes IS NULL OR d.Anio_Mes = m.AnioMes
) i(Indicador, Valor);

-- Respuestas a las 8 preguntas del informe (ganador|valor)
INSERT INTO @R (Indicador, Filtro, Valor)
SELECT TOP 1 'P1', 'Servicio con mayor margen', s.Nombre_Tramite + '|' + CAST(CAST(SUM(f.Monto_Cobrado - f.Costo_Asociado) AS DECIMAL(18,2)) AS VARCHAR(30))
FROM FACT_TRAMITES_FINANCIEROS f JOIN DIM_SERVICIO s ON s.ID_Servicio = f.ID_Servicio GROUP BY s.Nombre_Tramite ORDER BY SUM(f.Monto_Cobrado - f.Costo_Asociado) DESC;
INSERT INTO @R (Indicador, Filtro, Valor)
SELECT TOP 1 'P1', 'Trimestre con mas tramites', d.Trimestre_Texto + '|' + CAST(COUNT(*) AS VARCHAR(10))
FROM FACT_TRAMITE_GENERAL f JOIN DIM_TIEMPO d ON d.ID_Tiempo = f.ID_Tiempo GROUP BY d.Trimestre_Texto ORDER BY COUNT(*) DESC;
INSERT INTO @R (Indicador, Filtro, Valor)
SELECT TOP 1 'P2', 'Empleado con mas efectivo', p.Nombre_Completo + '|' + CAST(CAST(SUM(f.Monto_Cobrado) AS DECIMAL(18,2)) AS VARCHAR(30))
FROM FACT_TRAMITES_FINANCIEROS f JOIN DIM_PERSONAL p ON p.ID_Personal = f.ID_Personal JOIN DIM_METODO_PAGO m ON m.ID_Metodo = f.ID_Metodo
WHERE m.Tipo_Pago = 'Efectivo' GROUP BY p.Nombre_Completo ORDER BY SUM(f.Monto_Cobrado) DESC;
INSERT INTO @R (Indicador, Filtro, Valor)
SELECT x.Ind, x.Filtro, x.Valor FROM (
    SELECT 'P3' Ind, 'Metodo preferido ' + c.Tipo_Cliente Filtro, m.Tipo_Pago + '|' + CAST(COUNT(*) AS VARCHAR(10)) Valor,
           ROW_NUMBER() OVER (PARTITION BY c.Tipo_Cliente ORDER BY COUNT(*) DESC) rn
    FROM FACT_TRAMITES_FINANCIEROS f JOIN DIM_CLIENTE c ON c.ID_Cliente = f.ID_Cliente JOIN DIM_METODO_PAGO m ON m.ID_Metodo = f.ID_Metodo
    GROUP BY c.Tipo_Cliente, m.Tipo_Pago) x WHERE x.rn = 1;
INSERT INTO @R (Indicador, Filtro, Valor)
SELECT TOP 1 'P4', 'Cargo con mas escrituras publicas', p.Cargo + '|' + CAST(COUNT(*) AS VARCHAR(10))
FROM FACT_TRAMITE_GENERAL f JOIN DIM_PERSONAL p ON p.ID_Personal = f.ID_Personal JOIN DIM_SERVICIO s ON s.ID_Servicio = f.ID_Servicio
WHERE s.Categoria = 'Escrituras públicas' GROUP BY p.Cargo ORDER BY COUNT(*) DESC;
INSERT INTO @R (Indicador, Filtro, Valor)
SELECT TOP 1 'P5', 'Tipo documental con mas documentos', t.Nombre_TipoDocumento + '|' + CAST(SUM(f.Cantidad_Documentos) AS VARCHAR(10))
FROM FACT_DOCUMENTOS_OTORGADOS f JOIN DIM_TIPO_DOCUMENTO t ON t.ID_TipoDocumento = f.ID_TipoDocumento GROUP BY t.Nombre_TipoDocumento ORDER BY SUM(f.Cantidad_Documentos) DESC;
INSERT INTO @R (Indicador, Filtro, Valor)
SELECT TOP 1 'P6', 'Empleado con mas documentos', p.Nombre_Completo + '|' + CAST(SUM(f.Cantidad_Documentos) AS VARCHAR(10))
FROM FACT_DOCUMENTOS_OTORGADOS f JOIN DIM_PERSONAL p ON p.ID_Personal = f.ID_Personal GROUP BY p.Nombre_Completo ORDER BY SUM(f.Cantidad_Documentos) DESC;
INSERT INTO @R (Indicador, Filtro, Valor)
SELECT TOP 1 'P7', 'Servicio con mayor atencion media', s.Nombre_Tramite + '|' + CAST(CAST(AVG(f.Minutos_Totales * 1.0) AS DECIMAL(18,2)) AS VARCHAR(30))
FROM FACT_TIEMPOS_ATENCION f JOIN DIM_SERVICIO s ON s.ID_Servicio = f.ID_Servicio GROUP BY s.Nombre_Tramite ORDER BY AVG(f.Minutos_Totales * 1.0) DESC;
INSERT INTO @R (Indicador, Filtro, Valor)
SELECT TOP 1 'P7', 'Turno con mayor atencion media', t.Nombre_Turno + '|' + CAST(CAST(AVG(f.Minutos_Totales * 1.0) AS DECIMAL(18,2)) AS VARCHAR(30))
FROM FACT_TIEMPOS_ATENCION f JOIN DIM_TURNO t ON t.ID_Turno = f.ID_Turno GROUP BY t.Nombre_Turno ORDER BY AVG(f.Minutos_Totales * 1.0) DESC;
INSERT INTO @R (Indicador, Filtro, Valor)
SELECT TOP 1 'P8', 'Etapa con mayor espera media', e.Nombre_Etapa + '|' + CAST(CAST(AVG(f.Minutos_Espera * 1.0) AS DECIMAL(18,2)) AS VARCHAR(30))
FROM FACT_TIEMPOS_ATENCION f JOIN DIM_ETAPA_TRAMITE e ON e.ID_Etapa = f.ID_Etapa GROUP BY e.Nombre_Etapa ORDER BY AVG(f.Minutos_Espera * 1.0) DESC;

SELECT Indicador, Filtro, ISNULL(Valor, '0.00') AS Valor FROM @R ORDER BY Orden;
