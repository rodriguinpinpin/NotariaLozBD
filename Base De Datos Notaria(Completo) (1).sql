CREATE DATABASE NotariaPeru
GO
USE NotariaPeru
GO

CREATE TABLE ColegioNotarios (
    IdColegioNotarios INT PRIMARY KEY IDENTITY(1,1),
    NombreColegio VARCHAR(150) NOT NULL,
    Departamento VARCHAR(100) NOT NULL,
    Direccion VARCHAR(200),
    Telefono VARCHAR(20),
    Correo VARCHAR(100)
);
GO

CREATE TABLE Notario (
    IdNotario INT PRIMARY KEY IDENTITY(1,1),
    Nombres VARCHAR(100) NOT NULL,
    Apellidos VARCHAR(100) NOT NULL,
    NumeroColegiatura VARCHAR(20) NOT NULL UNIQUE,
    IdColegioNotarios INT NOT NULL,
    DistritoNotarial VARCHAR(50) NOT NULL,
    DireccionOficina VARCHAR(150),
    Telefono VARCHAR(15),
    Correo VARCHAR(100),
    FechaNombramiento DATE,
    Estado VARCHAR(20) DEFAULT 'Activo' CHECK (Estado IN ('Activo', 'Inactivo', 'Licencia')),
    FOREIGN KEY (IdColegioNotarios) REFERENCES ColegioNotarios(IdColegioNotarios)
);
GO

CREATE TABLE Empleado (
    IdEmpleado INT PRIMARY KEY IDENTITY(1,1),
    Nombres VARCHAR(100) NOT NULL,
    Apellidos VARCHAR(100) NOT NULL,
    DNI CHAR(8) NOT NULL UNIQUE,
    Cargo VARCHAR(50) NOT NULL,
    IdNotario INT NOT NULL,
    FechaIngreso DATE,
    Telefono VARCHAR(15),
    Correo VARCHAR(100),
    Sueldo DECIMAL(8,2),
    Estado VARCHAR(20) DEFAULT 'Activo' CHECK (Estado IN ('Activo', 'Cesado')),
    FOREIGN KEY (IdNotario) REFERENCES Notario(IdNotario)
);
GO

CREATE TABLE Cliente (
    IdCliente INT PRIMARY KEY IDENTITY(1,1),
    TipoPersona VARCHAR(20) NOT NULL CHECK (TipoPersona IN ('Natural', 'Juridica')),
    TipoDocumento VARCHAR(20) NOT NULL CHECK (TipoDocumento IN ('DNI', 'RUC', 'CE', 'Pasaporte')),
    NumeroDocumento VARCHAR(20) NOT NULL UNIQUE,
    Nombres VARCHAR(100),
    Apellidos VARCHAR(100),
    RazonSocial VARCHAR(150),
    EstadoCivil VARCHAR(20) CHECK (EstadoCivil IN ('Soltero', 'Casado', 'Divorciado', 'Viudo', 'Conviviente')),
    Direccion VARCHAR(150),
    Telefono VARCHAR(15),
    Correo VARCHAR(100),
    FechaRegistro DATE DEFAULT GETDATE()
);
GO

CREATE TABLE Arancel (
    IdArancel INT PRIMARY KEY IDENTITY(1,1),
    NombreArancel VARCHAR(100) NOT NULL,
    Descripcion VARCHAR(200),
    Monto DECIMAL(10,2) NOT NULL,
    Estado VARCHAR(20) NOT NULL
);
GO

CREATE TABLE TipoTramite (
    IdTipoTramite INT PRIMARY KEY IDENTITY(1,1),
    NombreTramite VARCHAR(100) NOT NULL,
    Descripcion VARCHAR(255),
    RequiereTestigos BIT DEFAULT 0,
    CostoBase DECIMAL(8,2) NOT NULL,
    TiempoEstimadoDias INT DEFAULT 1
);
GO

CREATE TABLE EscrituraPublica (
    IdEscritura INT PRIMARY KEY IDENTITY(1,1),
    NumeroEscritura INT NOT NULL,
    KardexNo VARCHAR(20) NOT NULL UNIQUE,
    TipoActo VARCHAR(50) NOT NULL,
    FechaEscritura DATE NOT NULL,
    Tomo INT,
    Folio INT,
    IdNotario INT NOT NULL,
    IdColegioNotarios INT NOT NULL,
    IdArancel INT NOT NULL,
    Estado VARCHAR(20) DEFAULT 'Vigente' CHECK (Estado IN ('Vigente', 'Anulado', 'Rectificado')),
    FOREIGN KEY (IdNotario) REFERENCES Notario(IdNotario),
    FOREIGN KEY (IdColegioNotarios) REFERENCES ColegioNotarios(IdColegioNotarios),
    FOREIGN KEY (IdArancel) REFERENCES Arancel(IdArancel)
);
GO

CREATE TABLE Testigo (
    IdTestigo INT PRIMARY KEY IDENTITY(1,1),
    DNI CHAR(8) NOT NULL UNIQUE,
    Nombres VARCHAR(100) NOT NULL,
    Apellidos VARCHAR(100) NOT NULL,
    Direccion VARCHAR(150),
    Telefono VARCHAR(20)
);
GO

CREATE TABLE EscrituraTestigo (
    IdEscritura INT NOT NULL,
    IdTestigo INT NOT NULL,
    PRIMARY KEY (IdEscritura, IdTestigo),
    FOREIGN KEY (IdEscritura) REFERENCES EscrituraPublica(IdEscritura),
    FOREIGN KEY (IdTestigo) REFERENCES Testigo(IdTestigo)
);
GO

CREATE TABLE CopiaCertificada (
    IdCopiaCertificada INT PRIMARY KEY IDENTITY(1,1),
    IdEscritura INT NOT NULL,
    TipoCopia VARCHAR(100) NOT NULL,
    CantidadCopias INT NOT NULL,
    FechaSolicitud DATE NOT NULL,
    Observacion VARCHAR(200),
    FOREIGN KEY (IdEscritura) REFERENCES EscrituraPublica(IdEscritura)
);
GO

CREATE TABLE Inmueble (
    IdInmueble INT PRIMARY KEY IDENTITY(1,1),
    TipoInmueble VARCHAR(50),
    Direccion VARCHAR(255),
    Distrito VARCHAR(50),
    PartidaRegistral VARCHAR(30),
    AreaMetrosCuadrados DECIMAL(10,2)
);
GO

CREATE TABLE Vehiculo (
    IdVehiculo INT PRIMARY KEY IDENTITY(1,1),
    Placa VARCHAR(10),
    Marca VARCHAR(50),
    Modelo VARCHAR(50),
    AnioFabricacion INT,
    NumeroTarjetaPropiedad VARCHAR(30)
);
GO

CREATE TABLE ContratoCompraventa (
    IdContrato INT PRIMARY KEY IDENTITY(1,1),
    IdEscritura INT NOT NULL,
    FechaContrato DATE NOT NULL,
    IdInmueble INT NULL,
    IdVehiculo INT NULL,
    IdVendedor INT NOT NULL,
    IdComprador INT NOT NULL,
    PrecioVenta DECIMAL(10,2),
    FormaPago VARCHAR(50),
    FOREIGN KEY (IdEscritura) REFERENCES EscrituraPublica(IdEscritura),
    FOREIGN KEY (IdInmueble) REFERENCES Inmueble(IdInmueble),
    FOREIGN KEY (IdVehiculo) REFERENCES Vehiculo(IdVehiculo),
    FOREIGN KEY (IdVendedor) REFERENCES Cliente(IdCliente),
    FOREIGN KEY (IdComprador) REFERENCES Cliente(IdCliente),
    CONSTRAINT chk_UnBien CHECK (
        (IdInmueble IS NOT NULL AND IdVehiculo IS NULL) OR
        (IdInmueble IS NULL AND IdVehiculo IS NOT NULL)
    )
);
GO

CREATE TABLE Poder (
    IdPoder INT PRIMARY KEY IDENTITY(1,1),
    IdEscritura INT NOT NULL,
    TipoPoder VARCHAR(50) NOT NULL,
    IdOtorgante INT NOT NULL,
    IdApoderado INT NOT NULL,
    Facultades TEXT NOT NULL,
    FechaOtorgamiento DATE NOT NULL,
    FolioInicio INT NOT NULL,
    FolioFin INT NOT NULL,
    Estado VARCHAR(20) DEFAULT 'Vigente' CHECK (Estado IN ('Vigente', 'Revocado', 'Anulado')),
    FOREIGN KEY (IdEscritura) REFERENCES EscrituraPublica(IdEscritura),
    FOREIGN KEY (IdOtorgante) REFERENCES Cliente(IdCliente),
    FOREIGN KEY (IdApoderado) REFERENCES Cliente(IdCliente)
);
GO

CREATE TABLE Testamento (
    IdTestamento INT PRIMARY KEY IDENTITY(1,1),
    IdEscritura INT NOT NULL,
    TipoTestamento VARCHAR(50) NOT NULL,
    IdTestador INT NOT NULL,
    IdTestigo1 INT NOT NULL,
    IdTestigo2 INT NOT NULL,
    FechaOtorga DATE NOT NULL,
    HoraOtorga TIME NOT NULL,
    Tomo INT NOT NULL,
    Folio INT NOT NULL,
    Estado VARCHAR(20) DEFAULT 'Registrado' CHECK (Estado IN ('Registrado', 'Revocado', 'Ejecutado')),
    FOREIGN KEY (IdEscritura) REFERENCES EscrituraPublica(IdEscritura),
    FOREIGN KEY (IdTestador) REFERENCES Cliente(IdCliente),
    FOREIGN KEY (IdTestigo1) REFERENCES Testigo(IdTestigo),
    FOREIGN KEY (IdTestigo2) REFERENCES Testigo(IdTestigo)
);
GO

CREATE TABLE PartidaRegistral (
    IdPartidaRegistral INT PRIMARY KEY IDENTITY(1,1),
    NumeroPartida VARCHAR(20) NOT NULL,
    OficinaRegistral VARCHAR(50) NOT NULL,
    Registro VARCHAR(50) NOT NULL,
    Asiento VARCHAR(10) NOT NULL,
    IdCliente INT NOT NULL,
    DescripcionActo VARCHAR(255) NOT NULL,
    FechaInscripcion DATE,
    EstadoTramite VARCHAR(30) DEFAULT 'En Trámite' CHECK (EstadoTramite IN ('En Trámite', 'Inscrito', 'Observado', 'Tachado')),
    FOREIGN KEY (IdCliente) REFERENCES Cliente(IdCliente)
);
GO

CREATE TABLE Tramite (
    IdTramite INT PRIMARY KEY IDENTITY(1,1),
    IdCliente INT NOT NULL,
    IdEmpleado INT,
    IdTipoTramite INT NOT NULL,
    IdEscritura INT NULL,
    IdCopiaCertificada INT NULL,
    IdPartidaRegistral INT NULL,
    IdContrato INT NULL,
    FechaInicio DATE NOT NULL,
    FechaFin DATE,
    EstadoTramite VARCHAR(20) DEFAULT 'En Proceso' CHECK (EstadoTramite IN ('En Proceso', 'Finalizado', 'Observado', 'Anulado')),
    FOREIGN KEY (IdCliente) REFERENCES Cliente(IdCliente),
    FOREIGN KEY (IdEmpleado) REFERENCES Empleado(IdEmpleado),
    FOREIGN KEY (IdTipoTramite) REFERENCES TipoTramite(IdTipoTramite),
    FOREIGN KEY (IdEscritura) REFERENCES EscrituraPublica(IdEscritura),
    FOREIGN KEY (IdCopiaCertificada) REFERENCES CopiaCertificada(IdCopiaCertificada),
    FOREIGN KEY (IdPartidaRegistral) REFERENCES PartidaRegistral(IdPartidaRegistral),
    FOREIGN KEY (IdContrato) REFERENCES ContratoCompraventa(IdContrato)
);
GO
--Ingreso de datos:

INSERT INTO ColegioNotarios (NombreColegio, Departamento, Direccion, Telefono, Correo) VALUES
('Colegio de Notarios de Cajamarca', 'Cajamarca', 'Jr. Amazonas 450', '076221100', 'contacto@cnc.pe'),
('Colegio de Notarios de Lima', 'Lima', 'Av. Javier Prado 1200', '014452200', 'contacto@cnl.pe'),
('Colegio de Notarios de La Libertad', 'La Libertad', 'Av. España 780', '044295300', 'contacto@cnll.pe');
GO

INSERT INTO Notario (Nombres, Apellidos, NumeroColegiatura, IdColegioNotarios, DistritoNotarial, DireccionOficina, Telefono, Correo, FechaNombramiento, Estado) VALUES
('Carlos', 'Vasquez Rojas', 'CAJ-0125', 1, 'Cajamarca', 'Jr. Cruz de Piedra 320', '976123456', 'cvasquez@notaria.pe', '2015-03-10', 'Activo'),
('Maria', 'Delgado Torres', 'LIM-0891', 2, 'Miraflores', 'Av. Larco 940', '987654321', 'mdelgado@notaria.pe', '2012-07-22', 'Activo'),
('Jorge', 'Huaman Castro', 'TRU-0342', 3, 'Trujillo', 'Jr. Pizarro 560', '944556677', 'jhuaman@notaria.pe', '2018-01-15', 'Activo');
GO

INSERT INTO Empleado (Nombres, Apellidos, DNI, Cargo, IdNotario, FechaIngreso, Telefono, Correo, Sueldo, Estado) VALUES
('Lucia', 'Ramos Diaz', '45123456', 'Secretaria', 1, '2020-02-01', '976111222', 'lramos@notaria.pe', 1800.00, 'Activo'),
('Pedro', 'Salazar Nunez', '46234567', 'Asistente Legal', 1, '2021-05-10', '976222333', 'psalazar@notaria.pe', 2200.00, 'Activo'),
('Andrea', 'Flores Vega', '47345678', 'Cajera', 2, '2019-09-15', '987222333', 'aflores@notaria.pe', 1700.00, 'Activo');
GO

INSERT INTO Cliente (TipoPersona, TipoDocumento, NumeroDocumento, Nombres, Apellidos, RazonSocial, EstadoCivil, Direccion, Telefono, Correo) VALUES
('Natural', 'DNI', '70123456', 'Miguel', 'Torres Leon', NULL, 'Soltero', 'Jr. Lima 234, Cajamarca', '965111222', 'mtorres@gmail.com'),
('Natural', 'DNI', '71234567', 'Rosa', 'Vargas Mendez', NULL, 'Casado', 'Av. Hoyos Rubio 120, Cajamarca', '965222333', 'rvargas@gmail.com'),
('Natural', 'DNI', '72345678', 'Fernando', 'Castillo Rios', NULL, 'Soltero', 'Jr. Junin 88, Cajamarca', '965333444', 'fcastillo@gmail.com'),
('Juridica', 'RUC', '20481234567', NULL, NULL, 'Transportes San Martin SAC', NULL, 'Av. Industrial 500, Cajamarca', '965444555', 'contacto@tsm.pe'),
('Natural', 'DNI', '73456789', 'Elena', 'Quispe Ortiz', NULL, 'Viudo', 'Jr. Amalia Puga 210, Cajamarca', '965555666', 'equispe@gmail.com'),
('Natural', 'DNI', '74567890', 'Ricardo', 'Munoz Silva', NULL, 'Casado', 'Av. Atahualpa 340, Cajamarca', '965666777', 'rmunoz@gmail.com');
GO

INSERT INTO Arancel (NombreArancel, Descripcion, Monto, Estado) VALUES
('Arancel Escritura Compraventa', 'Tarifa por escritura de compraventa', 350.00, 'Activo'),
('Arancel Poder General', 'Tarifa por otorgamiento de poder general', 180.00, 'Activo'),
('Arancel Testamento', 'Tarifa por testamento por escritura publica', 420.00, 'Activo');
GO

INSERT INTO TipoTramite (NombreTramite, Descripcion, RequiereTestigos, CostoBase, TiempoEstimadoDias) VALUES
('Compraventa', 'Transferencia de bien inmueble o vehicular', 0, 350.00, 5),
('Poder', 'Otorgamiento de poder notarial', 0, 180.00, 2),
('Testamento', 'Testamento por escritura publica', 1, 420.00, 3);
GO

INSERT INTO EscrituraPublica (NumeroEscritura, KardexNo, TipoActo, FechaEscritura, Tomo, Folio, IdNotario, IdColegioNotarios, IdArancel, Estado) VALUES
(1001, 'KDX-2026-001', 'Compraventa', '2026-01-15', 12, 145, 1, 1, 1, 'Vigente'),
(1002, 'KDX-2026-002', 'Poder', '2026-02-03', 12, 150, 1, 1, 2, 'Vigente'),
(1003, 'KDX-2026-003', 'Testamento', '2026-03-20', 13, 12, 2, 2, 3, 'Vigente');
GO

INSERT INTO Testigo (DNI, Nombres, Apellidos, Direccion, Telefono) VALUES
('80123456', 'Julio', 'Paredes Soto', 'Jr. Tarapaca 100, Cajamarca', '966111222'),
('81234567', 'Carmen', 'Rojas Vidal', 'Av. Mario Urteaga 210, Cajamarca', '966222333'),
('82345678', 'Wilson', 'Tafur Diaz', 'Jr. Dos de Mayo 55, Cajamarca', '966333444');
GO

INSERT INTO EscrituraTestigo (IdEscritura, IdTestigo) VALUES
(3, 1),
(3, 2),
(1, 3);
GO

INSERT INTO CopiaCertificada (IdEscritura, TipoCopia, CantidadCopias, FechaSolicitud, Observacion) VALUES
(1, 'Copia Simple', 2, '2026-01-16', 'Solicitada por el comprador'),
(2, 'Copia Certificada', 1, '2026-02-04', 'Para tramite bancario'),
(3, 'Copia Certificada', 3, '2026-03-21', 'Para herederos');
GO

INSERT INTO Inmueble (TipoInmueble, Direccion, Distrito, PartidaRegistral, AreaMetrosCuadrados) VALUES
('Casa', 'Jr. Sucre 450', 'Cajamarca', 'PRT-11004521', 180.50),
('Departamento', 'Av. Hoyos Rubio 220, Dpto 302', 'Cajamarca', 'PRT-11004890', 95.00),
('Terreno', 'Sector Chontapaccha s/n', 'Baños del Inca', 'PRT-11005120', 500.00);
GO

INSERT INTO Vehiculo (Placa, Marca, Modelo, AnioFabricacion, NumeroTarjetaPropiedad) VALUES
('ABC-123', 'Toyota', 'Hilux', 2019, 'TP-778899'),
('XYZ-789', 'Hyundai', 'Accent', 2021, 'TP-664532'),
('QRS-456', 'Nissan', 'Sentra', 2020, 'TP-991122');
GO

INSERT INTO ContratoCompraventa (IdEscritura, FechaContrato, IdInmueble, IdVehiculo, IdVendedor, IdComprador, PrecioVenta, FormaPago) VALUES
(1, '2026-01-15', 1, NULL, 5, 1, 145000.00, 'Contado'),
(1, '2026-01-15', NULL, 1, 6, 2, 62000.00, 'Financiado'),
(1, '2026-01-15', 2, NULL, 5, 3, 98000.00, 'Contado');
GO

INSERT INTO Poder (IdEscritura, TipoPoder, IdOtorgante, IdApoderado, Facultades, FechaOtorgamiento, FolioInicio, FolioFin, Estado) VALUES
(2, 'Poder General', 1, 2, 'Administrar bienes, representar en tramites bancarios y judiciales', '2026-02-03', 150, 152, 'Vigente'),
(2, 'Poder Especial', 3, 4, 'Vender un vehiculo especifico placa ABC-123', '2026-02-03', 153, 154, 'Vigente'),
(2, 'Poder General', 5, 6, 'Representacion en tramites municipales', '2026-02-03', 155, 157, 'Vigente');
GO

INSERT INTO Testamento (IdEscritura, TipoTestamento, IdTestador, IdTestigo1, IdTestigo2, FechaOtorga, HoraOtorga, Tomo, Folio, Estado) VALUES
(3, 'Escritura Publica', 5, 1, 2, '2026-03-20', '10:30:00', 13, 12, 'Registrado'),
(3, 'Escritura Publica', 6, 2, 3, '2026-03-20', '11:15:00', 13, 13, 'Registrado'),
(3, 'Cerrado', 3, 1, 3, '2026-03-20', '12:00:00', 13, 14, 'Registrado');
GO

INSERT INTO PartidaRegistral (NumeroPartida, OficinaRegistral, Registro, Asiento, IdCliente, DescripcionActo, FechaInscripcion, EstadoTramite) VALUES
('11004521', 'SUNARP Cajamarca', 'Registro de Propiedad Inmueble', 'A0003', 1, 'Compraventa de inmueble', '2026-01-20', 'Inscrito'),
('11004890', 'SUNARP Cajamarca', 'Registro de Propiedad Inmueble', 'A0002', 3, 'Compraventa de inmueble', '2026-01-22', 'Inscrito'),
('TP-778899', 'SUNARP Cajamarca', 'Registro de Propiedad Vehicular', 'A0001', 2, 'Transferencia vehicular', NULL, 'En Tramite');
GO

INSERT INTO Tramite (IdCliente, IdEmpleado, IdTipoTramite, IdEscritura, IdCopiaCertificada, IdPartidaRegistral, IdContrato, FechaInicio, FechaFin, EstadoTramite) VALUES
(1, 1, 1, 1, 1, 1, 1, '2026-01-14', '2026-01-20', 'Finalizado'),
(1, 2, 2, 2, 2, NULL, NULL, '2026-02-02', NULL, 'En Proceso'),
(5, 3, 3, 3, 3, NULL, NULL, '2026-03-19', '2026-03-21', 'Finalizado');
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