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
CREATE TABLE LibroKardex (
    IdLibroKardex INT PRIMARY KEY IDENTITY(1,1),
    NumeroLibro INT NOT NULL,
    Anio INT NOT NULL,
    IdNotario INT NOT NULL,
    FolioInicio INT NOT NULL,
    FolioFin INT NOT NULL,
    Estado VARCHAR(20) DEFAULT 'Abierto' CHECK (Estado IN ('Abierto', 'Cerrado')),
    FOREIGN KEY (IdNotario) REFERENCES Notario(IdNotario)
);
GO

ALTER TABLE EscrituraPublica
ADD IdLibroKardex INT NULL
CONSTRAINT FK_EscrituraPublica_LibroKardex FOREIGN KEY REFERENCES LibroKardex(IdLibroKardex);
GO

CREATE TABLE Pago (
    IdPago INT PRIMARY KEY IDENTITY(1,1),
    IdTramite INT NOT NULL,
    FechaPago DATE NOT NULL,
    Monto DECIMAL(10,2) NOT NULL,
    MetodoPago VARCHAR(20) NOT NULL CHECK (MetodoPago IN ('Efectivo', 'Yape', 'Transferencia', 'Tarjeta')),
    NumeroComprobante VARCHAR(30) NOT NULL UNIQUE,
    Estado VARCHAR(20) DEFAULT 'Pagado' CHECK (Estado IN ('Pagado', 'Pendiente', 'Anulado')),
    FOREIGN KEY (IdTramite) REFERENCES Tramite(IdTramite)
);
GO

CREATE TABLE LegalizacionFirma (
    IdLegalizacion INT PRIMARY KEY IDENTITY(1,1),
    IdCliente INT NOT NULL,
    IdNotario INT NOT NULL,
    TipoDocumento VARCHAR(100) NOT NULL,
    CantidadFirmas INT NOT NULL,
    FechaLegalizacion DATE NOT NULL,
    Costo DECIMAL(8,2) NOT NULL,
    FOREIGN KEY (IdCliente) REFERENCES Cliente(IdCliente),
    FOREIGN KEY (IdNotario) REFERENCES Notario(IdNotario)
);
GO

ALTER TABLE Tramite
ADD IdLegalizacion INT NULL
CONSTRAINT FK_Tramite_LegalizacionFirma FOREIGN KEY REFERENCES LegalizacionFirma(IdLegalizacion);
GO

CREATE TABLE Hipoteca (
    IdHipoteca INT PRIMARY KEY IDENTITY(1,1),
    IdEscritura INT NOT NULL,
    IdInmueble INT NOT NULL,
    IdDeudor INT NOT NULL,
    IdAcreedor INT NOT NULL,
    MontoGarantia DECIMAL(12,2) NOT NULL,
    Moneda VARCHAR(5) NOT NULL CHECK (Moneda IN ('PEN', 'USD')),
    FechaInscripcion DATE,
    Estado VARCHAR(20) DEFAULT 'Vigente' CHECK (Estado IN ('Vigente', 'Cancelada', 'En Ejecucion')),
    FOREIGN KEY (IdEscritura) REFERENCES EscrituraPublica(IdEscritura),
    FOREIGN KEY (IdInmueble) REFERENCES Inmueble(IdInmueble),
    FOREIGN KEY (IdDeudor) REFERENCES Cliente(IdCliente),
    FOREIGN KEY (IdAcreedor) REFERENCES Cliente(IdCliente)
);
GO

