/* =====================================================================
   01_crear_oltp.sql  ·  Base transaccional NotariaPeru (Notaría Lozano)
   Consolida "Base De Datos Notaria(Completo) (1).sql" + "EntidadesNuevas.sql"
   sin tablas duplicadas. Re-ejecutable: elimina y recrea la base.
   Cambios respecto al original:
     - Notario.Rol (Titular / Suplente)
     - TipoTramite.Categoria (Escrituras públicas / Extraprotocolares)
     - Tramite.IdNotario y Tramite.HoraInicio
     - Pago.MetodoPago admite 'Plin'
     - Nueva tabla AtencionEtapa (tiempos reales por etapa)
   ===================================================================== */
USE master;
GO
IF DB_ID('NotariaPeru') IS NOT NULL
BEGIN
    ALTER DATABASE NotariaPeru SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE NotariaPeru;
END
GO
CREATE DATABASE NotariaPeru;
GO
USE NotariaPeru;
GO

CREATE TABLE ColegioNotarios (
    IdColegioNotarios INT PRIMARY KEY IDENTITY(1,1),
    NombreColegio VARCHAR(150) NOT NULL,
    Departamento VARCHAR(100) NOT NULL,
    Direccion VARCHAR(200),
    Telefono VARCHAR(20),
    Correo VARCHAR(100)
);

CREATE TABLE Notario (
    IdNotario INT PRIMARY KEY IDENTITY(1,1),
    Nombres VARCHAR(100) NOT NULL,
    Apellidos VARCHAR(100) NOT NULL,
    NumeroColegiatura VARCHAR(20) NOT NULL UNIQUE,
    IdColegioNotarios INT NOT NULL REFERENCES ColegioNotarios(IdColegioNotarios),
    DistritoNotarial VARCHAR(50) NOT NULL,
    DireccionOficina VARCHAR(150),
    Telefono VARCHAR(15),
    Correo VARCHAR(100),
    FechaNombramiento DATE,
    Rol VARCHAR(20) NOT NULL DEFAULT 'Titular' CHECK (Rol IN ('Titular', 'Suplente')),
    Estado VARCHAR(20) DEFAULT 'Activo' CHECK (Estado IN ('Activo', 'Inactivo', 'Licencia'))
);

CREATE TABLE Empleado (
    IdEmpleado INT PRIMARY KEY IDENTITY(1,1),
    Nombres VARCHAR(100) NOT NULL,
    Apellidos VARCHAR(100) NOT NULL,
    DNI CHAR(8) NOT NULL UNIQUE,
    Cargo VARCHAR(50) NOT NULL,
    IdNotario INT NOT NULL REFERENCES Notario(IdNotario),
    FechaIngreso DATE,
    Telefono VARCHAR(15),
    Correo VARCHAR(100),
    Sueldo DECIMAL(8,2),
    Estado VARCHAR(20) DEFAULT 'Activo' CHECK (Estado IN ('Activo', 'Cesado'))
);

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
    Distrito VARCHAR(50),
    Telefono VARCHAR(15),
    Correo VARCHAR(100),
    FechaRegistro DATE DEFAULT GETDATE()
);

CREATE TABLE Arancel (
    IdArancel INT PRIMARY KEY IDENTITY(1,1),
    NombreArancel VARCHAR(100) NOT NULL,
    Descripcion VARCHAR(200),
    Monto DECIMAL(10,2) NOT NULL,
    Estado VARCHAR(20) NOT NULL
);

CREATE TABLE TipoTramite (
    IdTipoTramite INT PRIMARY KEY IDENTITY(1,1),
    NombreTramite VARCHAR(100) NOT NULL,
    Descripcion VARCHAR(255),
    Categoria VARCHAR(30) NOT NULL CHECK (Categoria IN ('Escrituras públicas', 'Extraprotocolares')),
    RequiereTestigos BIT DEFAULT 0,
    CostoBase DECIMAL(8,2) NOT NULL,
    TiempoEstimadoDias INT DEFAULT 1,
    PorcentajeCosto DECIMAL(4,2) NOT NULL DEFAULT 0.20,  -- costo asociado (insumos, tasas) / importe
    IdArancel INT NULL REFERENCES Arancel(IdArancel)
);

CREATE TABLE LibroKardex (
    IdLibroKardex INT PRIMARY KEY IDENTITY(1,1),
    NumeroLibro INT NOT NULL,
    Anio INT NOT NULL,
    IdNotario INT NOT NULL REFERENCES Notario(IdNotario),
    FolioInicio INT NOT NULL,
    FolioFin INT NOT NULL,
    Estado VARCHAR(20) DEFAULT 'Abierto' CHECK (Estado IN ('Abierto', 'Cerrado'))
);

CREATE TABLE EscrituraPublica (
    IdEscritura INT PRIMARY KEY IDENTITY(1,1),
    NumeroEscritura INT NOT NULL,
    KardexNo VARCHAR(20) NOT NULL UNIQUE,
    TipoActo VARCHAR(50) NOT NULL,
    FechaEscritura DATE NOT NULL,
    Tomo INT,
    Folio INT,
    IdNotario INT NOT NULL REFERENCES Notario(IdNotario),
    IdColegioNotarios INT NOT NULL REFERENCES ColegioNotarios(IdColegioNotarios),
    IdArancel INT NOT NULL REFERENCES Arancel(IdArancel),
    IdLibroKardex INT NULL REFERENCES LibroKardex(IdLibroKardex),
    Estado VARCHAR(20) DEFAULT 'Vigente' CHECK (Estado IN ('Vigente', 'Anulado', 'Rectificado'))
);

CREATE TABLE Testigo (
    IdTestigo INT PRIMARY KEY IDENTITY(1,1),
    DNI CHAR(8) NOT NULL UNIQUE,
    Nombres VARCHAR(100) NOT NULL,
    Apellidos VARCHAR(100) NOT NULL,
    Direccion VARCHAR(150),
    Telefono VARCHAR(20)
);

CREATE TABLE EscrituraTestigo (
    IdEscritura INT NOT NULL REFERENCES EscrituraPublica(IdEscritura),
    IdTestigo INT NOT NULL REFERENCES Testigo(IdTestigo),
    PRIMARY KEY (IdEscritura, IdTestigo)
);

CREATE TABLE CopiaCertificada (
    IdCopiaCertificada INT PRIMARY KEY IDENTITY(1,1),
    IdEscritura INT NOT NULL REFERENCES EscrituraPublica(IdEscritura),
    TipoCopia VARCHAR(100) NOT NULL,
    CantidadCopias INT NOT NULL,
    FechaSolicitud DATE NOT NULL,
    Observacion VARCHAR(200)
);

CREATE TABLE Inmueble (
    IdInmueble INT PRIMARY KEY IDENTITY(1,1),
    TipoInmueble VARCHAR(50),
    Direccion VARCHAR(255),
    Distrito VARCHAR(50),
    PartidaRegistral VARCHAR(30),
    AreaMetrosCuadrados DECIMAL(10,2)
);

CREATE TABLE Vehiculo (
    IdVehiculo INT PRIMARY KEY IDENTITY(1,1),
    Placa VARCHAR(10),
    Marca VARCHAR(50),
    Modelo VARCHAR(50),
    AnioFabricacion INT,
    NumeroTarjetaPropiedad VARCHAR(30)
);

CREATE TABLE ContratoCompraventa (
    IdContrato INT PRIMARY KEY IDENTITY(1,1),
    IdEscritura INT NOT NULL REFERENCES EscrituraPublica(IdEscritura),
    FechaContrato DATE NOT NULL,
    IdInmueble INT NULL REFERENCES Inmueble(IdInmueble),
    IdVehiculo INT NULL REFERENCES Vehiculo(IdVehiculo),
    IdVendedor INT NOT NULL REFERENCES Cliente(IdCliente),
    IdComprador INT NOT NULL REFERENCES Cliente(IdCliente),
    PrecioVenta DECIMAL(12,2),
    FormaPago VARCHAR(50),
    CONSTRAINT chk_UnBien CHECK (
        (IdInmueble IS NOT NULL AND IdVehiculo IS NULL) OR
        (IdInmueble IS NULL AND IdVehiculo IS NOT NULL))
);

CREATE TABLE Poder (
    IdPoder INT PRIMARY KEY IDENTITY(1,1),
    IdEscritura INT NOT NULL REFERENCES EscrituraPublica(IdEscritura),
    TipoPoder VARCHAR(50) NOT NULL,
    IdOtorgante INT NOT NULL REFERENCES Cliente(IdCliente),
    IdApoderado INT NOT NULL REFERENCES Cliente(IdCliente),
    Facultades VARCHAR(MAX) NOT NULL,
    FechaOtorgamiento DATE NOT NULL,
    FolioInicio INT NOT NULL,
    FolioFin INT NOT NULL,
    Estado VARCHAR(20) DEFAULT 'Vigente' CHECK (Estado IN ('Vigente', 'Revocado', 'Anulado'))
);

CREATE TABLE Testamento (
    IdTestamento INT PRIMARY KEY IDENTITY(1,1),
    IdEscritura INT NOT NULL REFERENCES EscrituraPublica(IdEscritura),
    TipoTestamento VARCHAR(50) NOT NULL,
    IdTestador INT NOT NULL REFERENCES Cliente(IdCliente),
    IdTestigo1 INT NOT NULL REFERENCES Testigo(IdTestigo),
    IdTestigo2 INT NOT NULL REFERENCES Testigo(IdTestigo),
    FechaOtorga DATE NOT NULL,
    HoraOtorga TIME NOT NULL,
    Tomo INT NOT NULL,
    Folio INT NOT NULL,
    Estado VARCHAR(20) DEFAULT 'Registrado' CHECK (Estado IN ('Registrado', 'Revocado', 'Ejecutado'))
);

CREATE TABLE PartidaRegistral (
    IdPartidaRegistral INT PRIMARY KEY IDENTITY(1,1),
    NumeroPartida VARCHAR(20) NOT NULL,
    OficinaRegistral VARCHAR(50) NOT NULL,
    Registro VARCHAR(50) NOT NULL,
    Asiento VARCHAR(10) NOT NULL,
    IdCliente INT NOT NULL REFERENCES Cliente(IdCliente),
    DescripcionActo VARCHAR(255) NOT NULL,
    FechaInscripcion DATE,
    EstadoTramite VARCHAR(30) DEFAULT 'En Trámite' CHECK (EstadoTramite IN ('En Trámite', 'Inscrito', 'Observado', 'Tachado'))
);

CREATE TABLE LegalizacionFirma (
    IdLegalizacion INT PRIMARY KEY IDENTITY(1,1),
    IdCliente INT NOT NULL REFERENCES Cliente(IdCliente),
    IdNotario INT NOT NULL REFERENCES Notario(IdNotario),
    TipoDocumento VARCHAR(100) NOT NULL,
    CantidadFirmas INT NOT NULL,
    FechaLegalizacion DATE NOT NULL,
    Costo DECIMAL(8,2) NOT NULL
);

CREATE TABLE Hipoteca (
    IdHipoteca INT PRIMARY KEY IDENTITY(1,1),
    IdEscritura INT NOT NULL REFERENCES EscrituraPublica(IdEscritura),
    IdInmueble INT NOT NULL REFERENCES Inmueble(IdInmueble),
    IdDeudor INT NOT NULL REFERENCES Cliente(IdCliente),
    IdAcreedor INT NOT NULL REFERENCES Cliente(IdCliente),
    MontoGarantia DECIMAL(12,2) NOT NULL,
    Moneda VARCHAR(5) NOT NULL CHECK (Moneda IN ('PEN', 'USD')),
    FechaInscripcion DATE,
    Estado VARCHAR(20) DEFAULT 'Vigente' CHECK (Estado IN ('Vigente', 'Cancelada', 'En Ejecucion'))
);

CREATE TABLE Tramite (
    IdTramite INT PRIMARY KEY IDENTITY(1,1),
    IdCliente INT NOT NULL REFERENCES Cliente(IdCliente),
    IdEmpleado INT REFERENCES Empleado(IdEmpleado),
    IdNotario INT NOT NULL REFERENCES Notario(IdNotario),
    IdTipoTramite INT NOT NULL REFERENCES TipoTramite(IdTipoTramite),
    IdEscritura INT NULL REFERENCES EscrituraPublica(IdEscritura),
    IdCopiaCertificada INT NULL REFERENCES CopiaCertificada(IdCopiaCertificada),
    IdPartidaRegistral INT NULL REFERENCES PartidaRegistral(IdPartidaRegistral),
    IdContrato INT NULL REFERENCES ContratoCompraventa(IdContrato),
    IdLegalizacion INT NULL REFERENCES LegalizacionFirma(IdLegalizacion),
    FechaInicio DATE NOT NULL,
    HoraInicio TIME(0) NOT NULL,
    FechaFin DATE,
    EstadoTramite VARCHAR(20) DEFAULT 'En Proceso' CHECK (EstadoTramite IN ('En Proceso', 'Finalizado', 'Observado', 'Anulado'))
);

CREATE TABLE Pago (
    IdPago INT PRIMARY KEY IDENTITY(1,1),
    IdTramite INT NOT NULL REFERENCES Tramite(IdTramite),
    FechaPago DATE NOT NULL,
    Monto DECIMAL(10,2) NOT NULL,
    MetodoPago VARCHAR(20) NOT NULL CHECK (MetodoPago IN ('Efectivo', 'Yape', 'Plin', 'Transferencia', 'Tarjeta')),
    NumeroComprobante VARCHAR(30) NOT NULL UNIQUE,
    Estado VARCHAR(20) DEFAULT 'Pagado' CHECK (Estado IN ('Pagado', 'Pendiente', 'Anulado'))
);

CREATE TABLE AtencionEtapa (
    IdAtencion INT PRIMARY KEY IDENTITY(1,1),
    IdTramite INT NOT NULL REFERENCES Tramite(IdTramite),
    IdEmpleado INT NOT NULL REFERENCES Empleado(IdEmpleado),
    Etapa VARCHAR(30) NOT NULL CHECK (Etapa IN ('Recepción', 'Revisión y redacción', 'Firma', 'Entrega')),
    OrdenEtapa TINYINT NOT NULL,
    InicioEspera DATETIME2(0) NOT NULL,
    InicioProceso DATETIME2(0) NOT NULL,
    Fin DATETIME2(0) NOT NULL,
    CONSTRAINT chk_AtencionOrden CHECK (InicioEspera <= InicioProceso AND InicioProceso < Fin)
);
GO

CREATE INDEX IX_Tramite_Fecha ON Tramite(FechaInicio) INCLUDE (IdTipoTramite, IdEmpleado, EstadoTramite);
CREATE INDEX IX_Pago_Tramite ON Pago(IdTramite);
CREATE INDEX IX_Atencion_Tramite ON AtencionEtapa(IdTramite);
GO
PRINT '01_crear_oltp: NotariaPeru creada';
