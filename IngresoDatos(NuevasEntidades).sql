Use NotariaPeru
GO

INSERT INTO Arancel (NombreArancel, Descripcion, Monto, Estado) VALUES
('Arancel Hipoteca', 'Tarifa por escritura de constitucion de hipoteca', 450.00, 'Activo');
GO

INSERT INTO TipoTramite (NombreTramite, Descripcion, RequiereTestigos, CostoBase, TiempoEstimadoDias) VALUES
('Hipoteca', 'Constitucion de hipoteca sobre inmueble', 0, 450.00, 7),
('Legalizacion de Firma', 'Legalizacion de firmas en documentos privados', 0, 18.00, 1);
GO

INSERT INTO LibroKardex (NumeroLibro, Anio, IdNotario, FolioInicio, FolioFin, Estado)
SELECT q.Num, 2026, n.IdNotario, (q.Num - 1) * 300 + 1, q.Num * 300, 'Cerrado'
FROM Notario n
CROSS JOIN (VALUES (1), (2)) AS q(Num);
GO

WITH N AS (
    SELECT TOP (8) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n FROM sys.all_objects
),
NT AS (
    SELECT IdNotario, IdColegioNotarios,
           ROW_NUMBER() OVER (ORDER BY IdNotario) - 1 AS rn,
           COUNT(*) OVER () AS total
    FROM Notario
)
INSERT INTO EscrituraPublica (NumeroEscritura, KardexNo, TipoActo, FechaEscritura, Tomo, Folio, IdNotario, IdColegioNotarios, IdArancel, Estado)
SELECT
    1100 + N.n,
    'KDX-2026-H' + RIGHT('00' + CAST(N.n + 1 AS VARCHAR(3)), 3),
    'Hipoteca',
    DATEADD(DAY, N.n * 21, '2026-01-12'),
    14,
    400 + N.n * 3,
    NT.IdNotario,
    NT.IdColegioNotarios,
    ar.IdArancel,
    'Vigente'
FROM N
JOIN NT ON NT.rn = N.n % NT.total
CROSS JOIN (SELECT IdArancel FROM Arancel WHERE NombreArancel = 'Arancel Hipoteca') ar;
GO

UPDATE ep
SET ep.IdLibroKardex = lk.IdLibroKardex
FROM EscrituraPublica ep
JOIN LibroKardex lk
    ON lk.IdNotario = ep.IdNotario
   AND lk.Anio = YEAR(ep.FechaEscritura)
   AND lk.NumeroLibro = (MONTH(ep.FechaEscritura) - 1) / 3 + 1
WHERE ep.IdLibroKardex IS NULL;
GO

WITH H AS (
    SELECT ep.IdEscritura, ep.FechaEscritura,
           ROW_NUMBER() OVER (ORDER BY ep.IdEscritura) - 1 AS n
    FROM EscrituraPublica ep
    WHERE ep.TipoActo = 'Hipoteca'
),
Inm AS (
    SELECT IdInmueble,
           ROW_NUMBER() OVER (ORDER BY IdInmueble) - 1 AS rn,
           COUNT(*) OVER () AS total
    FROM Inmueble
),
Nat AS (
    SELECT IdCliente,
           ROW_NUMBER() OVER (ORDER BY IdCliente) - 1 AS rn,
           COUNT(*) OVER () AS total
    FROM Cliente
    WHERE TipoPersona = 'Natural'
),
Jur AS (
    SELECT IdCliente,
           ROW_NUMBER() OVER (ORDER BY IdCliente) - 1 AS rn,
           COUNT(*) OVER () AS total
    FROM Cliente
    WHERE TipoPersona = 'Juridica'
)
INSERT INTO Hipoteca (IdEscritura, IdInmueble, IdDeudor, IdAcreedor, MontoGarantia, Moneda, FechaInscripcion, Estado)
SELECT
    H.IdEscritura,
    Inm.IdInmueble,
    Nat.IdCliente,
    Jur.IdCliente,
    60000 + H.n * 15000,
    CASE WHEN H.n % 3 = 0 THEN 'USD' ELSE 'PEN' END,
    DATEADD(DAY, 7, H.FechaEscritura),
    CASE H.n WHEN 2 THEN 'Cancelada' WHEN 7 THEN 'En Ejecucion' ELSE 'Vigente' END
FROM H
JOIN Inm ON Inm.rn = H.n % Inm.total
JOIN Nat ON Nat.rn = (H.n * 3) % Nat.total
JOIN Jur ON Jur.rn = H.n % Jur.total;
GO

WITH N AS (
    SELECT TOP (18) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n FROM sys.all_objects
),
C AS (
    SELECT IdCliente,
           ROW_NUMBER() OVER (ORDER BY IdCliente) - 1 AS rn,
           COUNT(*) OVER () AS total
    FROM Cliente
),
NT AS (
    SELECT IdNotario,
           ROW_NUMBER() OVER (ORDER BY IdNotario) - 1 AS rn,
           COUNT(*) OVER () AS total
    FROM Notario
)
INSERT INTO LegalizacionFirma (IdCliente, IdNotario, TipoDocumento, CantidadFirmas, FechaLegalizacion, Costo)
SELECT
    C.IdCliente,
    NT.IdNotario,
    CHOOSE(N.n % 6 + 1,
        'Contrato privado de alquiler',
        'Carta poder simple',
        'Declaracion jurada',
        'Autorizacion de viaje de menor',
        'Constancia de supervivencia',
        'Contrato privado de prestacion de servicios'),
    N.n % 4 + 1,
    DATEADD(DAY, N.n * 10, '2026-01-05'),
    (N.n % 4 + 1) * 18.00
FROM N
JOIN C ON C.rn = (N.n * 5) % C.total
JOIN NT ON NT.rn = N.n % NT.total;
GO

WITH HP AS (
    SELECT h.IdHipoteca, h.IdEscritura, h.IdDeudor,
           ROW_NUMBER() OVER (ORDER BY h.IdHipoteca) - 1 AS n
    FROM Hipoteca h
),
Emp AS (
    SELECT IdEmpleado,
           ROW_NUMBER() OVER (ORDER BY IdEmpleado) - 1 AS rn,
           COUNT(*) OVER () AS total
    FROM Empleado
)
INSERT INTO Tramite (IdCliente, IdEmpleado, IdTipoTramite, IdEscritura, IdCopiaCertificada, IdPartidaRegistral, IdContrato, IdLegalizacion, FechaInicio, FechaFin, EstadoTramite)
SELECT
    HP.IdDeudor,
    Emp.IdEmpleado,
    tt.IdTipoTramite,
    HP.IdEscritura,
    NULL, NULL, NULL, NULL,
    ep.FechaEscritura,
    CASE WHEN HP.n % 4 IN (1, 2) THEN DATEADD(DAY, tt.TiempoEstimadoDias, ep.FechaEscritura) END,
    CASE WHEN HP.n % 4 IN (1, 2) THEN 'Finalizado'
         WHEN HP.n % 4 = 3 THEN 'Observado'
         ELSE 'En Proceso' END
FROM HP
JOIN EscrituraPublica ep ON ep.IdEscritura = HP.IdEscritura
JOIN TipoTramite tt ON tt.NombreTramite = 'Hipoteca'
JOIN Emp ON Emp.rn = HP.n % Emp.total;
GO

WITH L AS (
    SELECT l.IdLegalizacion, l.IdCliente, l.FechaLegalizacion,
           ROW_NUMBER() OVER (ORDER BY l.IdLegalizacion) - 1 AS n
    FROM LegalizacionFirma l
),
Emp AS (
    SELECT IdEmpleado,
           ROW_NUMBER() OVER (ORDER BY IdEmpleado) - 1 AS rn,
           COUNT(*) OVER () AS total
    FROM Empleado
)
INSERT INTO Tramite (IdCliente, IdEmpleado, IdTipoTramite, IdEscritura, IdCopiaCertificada, IdPartidaRegistral, IdContrato, IdLegalizacion, FechaInicio, FechaFin, EstadoTramite)
SELECT
    L.IdCliente,
    Emp.IdEmpleado,
    tt.IdTipoTramite,
    NULL, NULL, NULL, NULL,
    L.IdLegalizacion,
    L.FechaLegalizacion,
    L.FechaLegalizacion,
    'Finalizado'
FROM L
JOIN TipoTramite tt ON tt.NombreTramite = 'Legalizacion de Firma'
JOIN Emp ON Emp.rn = L.n % Emp.total;
GO

WITH T AS (
    SELECT
        t.IdTramite,
        t.FechaInicio,
        t.EstadoTramite,
        COALESCE(a.Monto, l.Costo, tt.CostoBase) AS Monto,
        ROW_NUMBER() OVER (ORDER BY t.IdTramite) AS rn
    FROM Tramite t
    JOIN TipoTramite tt ON tt.IdTipoTramite = t.IdTipoTramite
    LEFT JOIN EscrituraPublica ep ON ep.IdEscritura = t.IdEscritura
    LEFT JOIN Arancel a ON a.IdArancel = ep.IdArancel
    LEFT JOIN LegalizacionFirma l ON l.IdLegalizacion = t.IdLegalizacion
    WHERE NOT EXISTS (SELECT 1 FROM Pago p WHERE p.IdTramite = t.IdTramite)
)
INSERT INTO Pago (IdTramite, FechaPago, Monto, MetodoPago, NumeroComprobante, Estado)
SELECT
    T.IdTramite,
    T.FechaInicio,
    T.Monto,
    CHOOSE(T.rn % 4 + 1, 'Efectivo', 'Yape', 'Transferencia', 'Tarjeta'),
    'B001-' + RIGHT('000000' + CAST(T.IdTramite AS VARCHAR(6)), 6),
    CASE T.EstadoTramite WHEN 'En Proceso' THEN 'Pendiente' ELSE 'Pagado' END
FROM T;
GO