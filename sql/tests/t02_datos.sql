-- Prueba T2: reglas de los datos generados en NotariaPeru
SET NOCOUNT ON;
USE NotariaPeru;
GO
CREATE OR ALTER PROCEDURE #Afirmar @ok BIT, @msg NVARCHAR(300) AS
BEGIN IF ISNULL(@ok,0) = 0 THROW 50100, @msg, 1; END;
GO
DECLARE @ok BIT, @v NVARCHAR(300);

-- Rango de fechas
SELECT @ok = IIF(MIN(FechaInicio) >= '2026-06-01' AND MAX(FechaInicio) <= '2026-11-22', 1, 0),
       @v = CONCAT('Rango fuera de 2026-06-01..2026-11-22: ', MIN(FechaInicio), ' / ', MAX(FechaInicio)) FROM Tramite;
EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(MIN(FechaPago) >= '2026-06-01' AND MAX(FechaPago) <= '2026-11-22', 1, 0), @v = 'Pagos fuera de rango' FROM Pago;
EXEC #Afirmar @ok, @v;

-- Volúmenes
SELECT @ok = IIF(COUNT(*) BETWEEN 700 AND 900, 1, 0), @v = CONCAT('Tramites: ', COUNT(*)) FROM Tramite;            EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(*) BETWEEN 180 AND 220, 1, 0), @v = CONCAT('Clientes: ', COUNT(*)) FROM Cliente;            EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(*) = 10, 1, 0), @v = CONCAT('Empleados: ', COUNT(*)) FROM Empleado;                           EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(*) = 2, 1, 0),  @v = CONCAT('Notarios: ', COUNT(*)) FROM Notario;                             EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(*) = 8, 1, 0),  @v = CONCAT('Servicios: ', COUNT(*)) FROM TipoTramite;                        EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(AVG(IIF(TipoPersona='Juridica',1.0,0)) BETWEEN 0.10 AND 0.20, 1, 0), @v = 'Proporcion juridicas fuera de 10-20%' FROM Cliente; EXEC #Afirmar @ok, @v;

-- Calendario y turnos (DATEDIFF desde un lunes conocido: 0=lunes ... 6=domingo)
SELECT @ok = IIF(COUNT(*) = 0, 1, 0), @v = CONCAT('Tramites en domingo: ', COUNT(*)) FROM Tramite WHERE DATEDIFF(DAY, '2024-01-01', FechaInicio) % 7 = 6; EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(*) = 0, 1, 0), @v = CONCAT('Tramites sabado tarde: ', COUNT(*)) FROM Tramite WHERE DATEDIFF(DAY, '2024-01-01', FechaInicio) % 7 = 5 AND HoraInicio >= '13:00'; EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(*) = 0, 1, 0), @v = 'Horas fuera de 08:00-19:00' FROM Tramite WHERE HoraInicio < '08:00' OR HoraInicio >= '19:00'; EXEC #Afirmar @ok, @v;

-- Montos
SELECT @ok = IIF(COUNT(*) = 0, 1, 0), @v = CONCAT('Legalizaciones con monto <> 18 x firmas: ', COUNT(*))
FROM Pago p JOIN Tramite t ON t.IdTramite = p.IdTramite JOIN LegalizacionFirma l ON l.IdLegalizacion = t.IdLegalizacion
WHERE p.Estado <> 'Anulado' AND p.Monto <> 18 * l.CantidadFirmas
  AND NOT EXISTS (SELECT 1 FROM Pago p2 WHERE p2.IdTramite = p.IdTramite AND p2.IdPago <> p.IdPago);
EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(DISTINCT Monto) > 50, 1, 0), @v = CONCAT('Montos distintos: ', COUNT(DISTINCT Monto)) FROM Pago; EXEC #Afirmar @ok, @v;

-- Demanda con forma
WITH M AS (SELECT MONTH(FechaInicio) m, COUNT(*) n FROM Tramite WHERE FechaInicio < '2026-11-01' GROUP BY MONTH(FechaInicio))
SELECT @ok = IIF(STDEV(n) > 0.05 * AVG(n * 1.0), 1, 0), @v = 'Conteos mensuales demasiado parejos' FROM M; EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(SUM(IIF(MONTH(FechaInicio)=7,1,0)) > SUM(IIF(MONTH(FechaInicio)=6,1,0)), 1, 0), @v = 'Julio debe superar a junio' FROM Tramite; EXEC #Afirmar @ok, @v;

-- Métodos de pago por tipo de cliente
SELECT @ok = IIF(AVG(IIF(p.MetodoPago='Transferencia',1.0,0)) >= 0.60, 1, 0), @v = 'Juridicas: transferencia < 60%'
FROM Pago p JOIN Tramite t ON t.IdTramite = p.IdTramite JOIN Cliente c ON c.IdCliente = t.IdCliente WHERE c.TipoPersona = 'Juridica';
EXEC #Afirmar @ok, @v;

-- Coherencia estado tramite / pago
SELECT @ok = IIF(COUNT(*) = 0, 1, 0), @v = CONCAT('Tramites anulados con pago no anulado: ', COUNT(*))
FROM Tramite t JOIN Pago p ON p.IdTramite = t.IdTramite WHERE t.EstadoTramite = 'Anulado' AND p.Estado <> 'Anulado'; EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(*) = 0, 1, 0), @v = CONCAT('Tramites en proceso sin pendiente: ', COUNT(*))
FROM Tramite t WHERE t.EstadoTramite = 'En Proceso' AND NOT EXISTS (SELECT 1 FROM Pago p WHERE p.IdTramite = t.IdTramite AND p.Estado = 'Pendiente'); EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(*) = 0, 1, 0), @v = CONCAT('Tramites sin pago: ', COUNT(*))
FROM Tramite t WHERE NOT EXISTS (SELECT 1 FROM Pago p WHERE p.IdTramite = t.IdTramite); EXEC #Afirmar @ok, @v;
SELECT @ok = IIF(COUNT(*) = 0, 1, 0), @v = CONCAT('Finalizados sin FechaFin: ', COUNT(*))
FROM Tramite WHERE EstadoTramite = 'Finalizado' AND (FechaFin IS NULL OR FechaFin < FechaInicio); EXEC #Afirmar @ok, @v;

-- Etapas de atención
SELECT @ok = IIF(COUNT(*) = 0, 1, 0), @v = CONCAT('Tramites no anulados sin 4 etapas: ', COUNT(*))
FROM Tramite t WHERE t.EstadoTramite <> 'Anulado' AND (SELECT COUNT(*) FROM AtencionEtapa a WHERE a.IdTramite = t.IdTramite) <> 4; EXEC #Afirmar @ok, @v;
WITH A AS (
  SELECT IIF(DATEPART(HOUR, t.HoraInicio) < 13, 'M', 'T') turno, DATEDIFF(MINUTE, a.InicioEspera, a.InicioProceso) espera
  FROM AtencionEtapa a JOIN Tramite t ON t.IdTramite = a.IdTramite)
SELECT @ok = IIF(AVG(IIF(turno='T', espera*1.0, NULL)) > AVG(IIF(turno='M', espera*1.0, NULL)), 1, 0), @v = 'Espera tarde debe ser > manana' FROM A;
EXEC #Afirmar @ok, @v;

-- Notario suplente ~10% de escrituras
SELECT @ok = IIF(AVG(IIF(n.Rol='Suplente',1.0,0)) BETWEEN 0.05 AND 0.15, 1, 0), @v = 'Suplente fuera de 5-15% de escrituras'
FROM EscrituraPublica e JOIN Notario n ON n.IdNotario = e.IdNotario; EXEC #Afirmar @ok, @v;

PRINT 't02_datos: PASS';
