USE NotariaPeru
GO 

--Vistas:
CREATE VIEW VistaTramitesActivos AS
SELECT
    t.IdTramite,
    c.IdCliente,
    ISNULL(c.RazonSocial, c.Nombres + ' ' + c.Apellidos) AS Cliente,
    e.Nombres + ' ' + e.Apellidos AS Empleado,
    tt.NombreTramite,
    t.FechaInicio,
    t.EstadoTramite
FROM Tramite t
JOIN Cliente c ON c.IdCliente = t.IdCliente
LEFT JOIN Empleado e ON e.IdEmpleado = t.IdEmpleado
JOIN TipoTramite tt ON tt.IdTipoTramite = t.IdTipoTramite
WHERE t.EstadoTramite = 'En Proceso';
GO
 
CREATE VIEW VistaEscrituraDetalle AS
SELECT
    ep.IdEscritura,
    ep.NumeroEscritura,
    ep.KardexNo,
    ep.TipoActo,
    ep.FechaEscritura,
    n.Nombres + ' ' + n.Apellidos AS Notario,
    cn.NombreColegio,
    a.NombreArancel,
    a.Monto,
    ep.Estado
FROM EscrituraPublica ep
JOIN Notario n ON n.IdNotario = ep.IdNotario
JOIN ColegioNotarios cn ON cn.IdColegioNotarios = ep.IdColegioNotarios
JOIN Arancel a ON a.IdArancel = ep.IdArancel;
GO
 
CREATE VIEW VistaPoderesVigentes AS
SELECT
    p.IdPoder,
    ep.KardexNo,
    p.TipoPoder,
    ot.Nombres + ' ' + ot.Apellidos AS Otorgante,
    ap.Nombres + ' ' + ap.Apellidos AS Apoderado,
    p.FechaOtorgamiento,
    p.Estado
FROM Poder p
JOIN EscrituraPublica ep ON ep.IdEscritura = p.IdEscritura
JOIN Cliente ot ON ot.IdCliente = p.IdOtorgante
JOIN Cliente ap ON ap.IdCliente = p.IdApoderado
WHERE p.Estado = 'Vigente';
GO
 
CREATE VIEW VistaTestamentosRegistrados AS
SELECT
    tm.IdTestamento,
    ep.KardexNo,
    tm.TipoTestamento,
    cl.Nombres + ' ' + cl.Apellidos AS Testador,
    t1.Nombres + ' ' + t1.Apellidos AS Testigo1,
    t2.Nombres + ' ' + t2.Apellidos AS Testigo2,
    tm.FechaOtorga,
    tm.Estado
FROM Testamento tm
JOIN EscrituraPublica ep ON ep.IdEscritura = tm.IdEscritura
JOIN Cliente cl ON cl.IdCliente = tm.IdTestador
JOIN Testigo t1 ON t1.IdTestigo = tm.IdTestigo1
JOIN Testigo t2 ON t2.IdTestigo = tm.IdTestigo2;
GO
 
CREATE VIEW VistaContratosCompraventa AS
SELECT
    cc.IdContrato,
    ep.KardexNo,
    cc.FechaContrato,
    CASE WHEN cc.IdInmueble IS NOT NULL THEN 'Inmueble' ELSE 'Vehiculo' END AS TipoBien,
    ISNULL(i.Direccion, v.Placa) AS DetalleBien,
    ve.Nombres + ' ' + ve.Apellidos AS Vendedor,
    co.Nombres + ' ' + co.Apellidos AS Comprador,
    cc.PrecioVenta,
    cc.FormaPago
FROM ContratoCompraventa cc
JOIN EscrituraPublica ep ON ep.IdEscritura = cc.IdEscritura
LEFT JOIN Inmueble i ON i.IdInmueble = cc.IdInmueble
LEFT JOIN Vehiculo v ON v.IdVehiculo = cc.IdVehiculo
JOIN Cliente ve ON ve.IdCliente = cc.IdVendedor
JOIN Cliente co ON co.IdCliente = cc.IdComprador;
GO
 
CREATE VIEW VistaCargaEmpleados AS
SELECT
    e.IdEmpleado,
    e.Nombres + ' ' + e.Apellidos AS Empleado,
    e.Cargo,
    COUNT(t.IdTramite) AS TotalTramites
FROM Empleado e
LEFT JOIN Tramite t ON t.IdEmpleado = e.IdEmpleado
GROUP BY e.IdEmpleado, e.Nombres, e.Apellidos, e.Cargo;
GO