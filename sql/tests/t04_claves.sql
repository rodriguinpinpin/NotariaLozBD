-- Prueba T8 (revisión final): claves para que todas las segmentaciones filtren todos los hechos de su página,
-- y etiqueta de mes parcial para no mostrar caídas falsas.
SET NOCOUNT ON;
USE DW_NotariaLozano;
GO
DECLARE @faltan NVARCHAR(400) = '';
SELECT @faltan += c.t + '.' + c.col + ' '
FROM (VALUES ('FACT_TRAMITES_FINANCIEROS','ID_Turno'), ('FACT_TRAMITES_FINANCIEROS','ID_Notario'),
             ('FACT_TIEMPOS_ATENCION','ID_Cliente'), ('FACT_TIEMPOS_ATENCION','ID_Notario'),
             ('FACT_DOCUMENTOS_OTORGADOS','ID_Turno'), ('FACT_DOCUMENTOS_OTORGADOS','ID_Notario'),
             ('FACT_TRAMITE_GENERAL','ID_Metodo'), ('DIM_TIEMPO','Mes_Etiqueta'), ('DIM_TIEMPO','Mes_Completo')) c(t, col)
WHERE COL_LENGTH(c.t, c.col) IS NULL;
IF @faltan <> '' BEGIN DECLARE @m NVARCHAR(500) = 'Faltan columnas: ' + @faltan; THROW 50400, @m, 1; END;
GO
DECLARE @n INT;
SELECT @n = (SELECT COUNT(*) FROM FACT_TRAMITES_FINANCIEROS WHERE ID_Turno IS NULL OR ID_Notario IS NULL)
          + (SELECT COUNT(*) FROM FACT_TIEMPOS_ATENCION WHERE ID_Cliente IS NULL OR ID_Notario IS NULL)
          + (SELECT COUNT(*) FROM FACT_DOCUMENTOS_OTORGADOS WHERE ID_Turno IS NULL OR ID_Notario IS NULL)
          + (SELECT COUNT(*) FROM FACT_TRAMITE_GENERAL WHERE ID_Metodo IS NULL);
IF @n > 0 BEGIN DECLARE @m2 NVARCHAR(200) = CONCAT('Claves nuevas nulas: ', @n); THROW 50401, @m2, 1; END;
IF NOT EXISTS (SELECT 1 FROM DIM_TIEMPO WHERE Anio_Mes = '2026-11' AND Mes_Etiqueta = 'Nov (al 22)') THROW 50402, 'Noviembre debe etiquetarse "Nov (al 22)"', 1;
IF (SELECT COUNT(DISTINCT Anio_Mes) FROM DIM_TIEMPO WHERE Mes_Completo = 1) <> 5 THROW 50403, 'Deben existir 5 meses completos (jun-oct)', 1;
PRINT 't04_claves: PASS';
