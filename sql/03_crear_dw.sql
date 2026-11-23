/* =====================================================================
   03_crear_dw.sql  ·  Data warehouse DW_NotariaLozano (modelo estrella)
   Conserva tablas y columnas de "MODELOS ESTRELLA.sql"; solo AGREGA columnas.
   Re-ejecutable: elimina y recrea la base.
   ===================================================================== */
USE master;
GO
IF DB_ID('DW_NotariaLozano') IS NOT NULL
BEGIN
    ALTER DATABASE DW_NotariaLozano SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DW_NotariaLozano;
END
GO
CREATE DATABASE DW_NotariaLozano;
GO
USE DW_NotariaLozano;
GO
CREATE SCHEMA etl;
GO

/* ---------------- Dimensiones ---------------- */
CREATE TABLE DIM_TIEMPO (
    ID_Tiempo INT PRIMARY KEY,            -- yyyymmdd
    Fecha_Exacta DATE NOT NULL,
    Mes INT, Nombre_Mes VARCHAR(20), Trimestre INT, Semestre INT, Anio INT,
    -- agregadas
    Dia INT, Nombre_Dia VARCHAR(15), Dia_Semana INT,          -- 1 = lunes ... 7 = domingo
    Semana INT, Es_Fin_De_Mes BIT, Es_Dia_Habil BIT,
    Anio_Mes VARCHAR(7), Orden_Mes INT, Mes_Corto VARCHAR(5), Trimestre_Texto VARCHAR(10),
    Mes_Etiqueta VARCHAR(20),             -- 'Nov (al 22)' cuando el mes está incompleto
    Mes_Completo BIT
);

CREATE TABLE DIM_CLIENTE (
    ID_Cliente INT PRIMARY KEY,
    DNI_RUC VARCHAR(20),
    Razon_Social_Nombre VARCHAR(250),
    Tipo_Cliente VARCHAR(50),
    -- agregadas
    Distrito VARCHAR(50), Segmento VARCHAR(20)
);

CREATE TABLE DIM_PERSONAL (
    ID_Personal INT PRIMARY KEY,
    Nombre_Completo VARCHAR(200),
    Cargo VARCHAR(100),
    Area VARCHAR(50)                      -- agregada
);

CREATE TABLE DIM_SERVICIO (
    ID_Servicio INT PRIMARY KEY,
    Nombre_Tramite VARCHAR(150),
    Categoria VARCHAR(100),               -- ahora categoría real
    Descripcion VARCHAR(255)              -- agregada
);

CREATE TABLE DIM_METODO_PAGO (
    ID_Metodo INT PRIMARY KEY,
    Tipo_Pago VARCHAR(50),
    Plataforma VARCHAR(50),
    Canal VARCHAR(20)                     -- agregada: Efectivo / Digital
);

CREATE TABLE DIM_ESTADO_PAGO (ID_Estado_Pago INT PRIMARY KEY, Estado VARCHAR(50));

CREATE TABLE DIM_NOTARIO (
    ID_Notario INT PRIMARY KEY,
    Nombre_Completo VARCHAR(200),
    Colegio_Notarios VARCHAR(150),
    Rol VARCHAR(20)                       -- agregada
);

CREATE TABLE DIM_ETAPA_TRAMITE (ID_Etapa INT PRIMARY KEY, Nombre_Etapa VARCHAR(100), Descripcion VARCHAR(255), Orden INT);

CREATE TABLE DIM_TURNO (ID_Turno INT PRIMARY KEY, Nombre_Turno VARCHAR(50), Rango_Horario VARCHAR(50));

CREATE TABLE DIM_TIPO_DOCUMENTO (ID_TipoDocumento INT PRIMARY KEY, Nombre_TipoDocumento VARCHAR(100), Descripcion VARCHAR(255));

/* ---------------- Hechos ---------------- */
-- Granularidad: 1 fila por pago
CREATE TABLE FACT_TRAMITES_FINANCIEROS (
    ID_Cliente INT REFERENCES DIM_CLIENTE(ID_Cliente),
    ID_Servicio INT REFERENCES DIM_SERVICIO(ID_Servicio),
    ID_Tiempo INT REFERENCES DIM_TIEMPO(ID_Tiempo),
    ID_Personal INT REFERENCES DIM_PERSONAL(ID_Personal),
    ID_Metodo INT REFERENCES DIM_METODO_PAGO(ID_Metodo),
    Monto_Cobrado DECIMAL(10,2),          -- solo pagos 'Pagado'
    Costo_Asociado DECIMAL(10,2),         -- costo del importe cobrado
    Cantidad INT,
    -- agregadas
    Nro_Tramite INT,
    ID_Estado_Pago INT REFERENCES DIM_ESTADO_PAGO(ID_Estado_Pago),
    Monto_Pendiente DECIMAL(10,2),        -- solo pagos 'Pendiente'
    Monto_Comprobante DECIMAL(10,2),      -- importe emitido en el comprobante (cualquier estado)
    ID_Turno INT REFERENCES DIM_TURNO(ID_Turno),          -- del trámite: para que todas las segmentaciones filtren
    ID_Notario INT REFERENCES DIM_NOTARIO(ID_Notario)
);

-- Granularidad: 1 fila por trámite y etapa
CREATE TABLE FACT_TIEMPOS_ATENCION (
    ID_Servicio INT REFERENCES DIM_SERVICIO(ID_Servicio),
    ID_Personal INT REFERENCES DIM_PERSONAL(ID_Personal),
    ID_Tiempo INT REFERENCES DIM_TIEMPO(ID_Tiempo),
    ID_Etapa INT REFERENCES DIM_ETAPA_TRAMITE(ID_Etapa),
    ID_Turno INT REFERENCES DIM_TURNO(ID_Turno),
    Minutos_Espera INT, Minutos_Proceso INT, Minutos_Totales INT,
    Nro_Tramite INT,                       -- agregada
    ID_Cliente INT REFERENCES DIM_CLIENTE(ID_Cliente),
    ID_Notario INT REFERENCES DIM_NOTARIO(ID_Notario)
);

-- Granularidad: 1 fila por trámite y tipo de documento
CREATE TABLE FACT_DOCUMENTOS_OTORGADOS (
    ID_Servicio INT REFERENCES DIM_SERVICIO(ID_Servicio),
    ID_Personal INT REFERENCES DIM_PERSONAL(ID_Personal),
    ID_Tiempo INT REFERENCES DIM_TIEMPO(ID_Tiempo),
    ID_TipoDocumento INT REFERENCES DIM_TIPO_DOCUMENTO(ID_TipoDocumento),
    ID_Cliente INT REFERENCES DIM_CLIENTE(ID_Cliente),
    Cantidad_Documentos INT,
    Nro_Tramite INT,                       -- agregada
    ID_Turno INT REFERENCES DIM_TURNO(ID_Turno),
    ID_Notario INT REFERENCES DIM_NOTARIO(ID_Notario)
);

-- Granularidad: 1 fila por trámite
CREATE TABLE FACT_TRAMITE_GENERAL (
    Nro_Tramite INT PRIMARY KEY,
    ID_Tiempo INT REFERENCES DIM_TIEMPO(ID_Tiempo),
    ID_Servicio INT REFERENCES DIM_SERVICIO(ID_Servicio),
    ID_Notario INT REFERENCES DIM_NOTARIO(ID_Notario),
    ID_Cliente INT REFERENCES DIM_CLIENTE(ID_Cliente),
    ID_Personal INT REFERENCES DIM_PERSONAL(ID_Personal),
    ID_Estado_Pago INT REFERENCES DIM_ESTADO_PAGO(ID_Estado_Pago),
    Monto_Pagado DECIMAL(10,2),           -- suma de pagos 'Pagado'
    Monto_Arancel DECIMAL(10,2),          -- importe facturado del trámite
    Cantidad_Tramites INT,
    -- agregadas
    Estado_Tramite VARCHAR(20),
    Dias_Duracion INT,
    ID_Turno INT REFERENCES DIM_TURNO(ID_Turno),
    ID_Metodo INT REFERENCES DIM_METODO_PAGO(ID_Metodo)  -- método de pago del trámite
);

/* ---------------- Auditoría ETL ---------------- */
CREATE TABLE ETL_Auditoria (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Paquete VARCHAR(100) NOT NULL,
    Inicio DATETIME2(0) NOT NULL,
    Fin DATETIME2(0) NULL,
    Estado VARCHAR(20) NOT NULL,          -- En curso / Exito / Error
    Filas INT NULL,
    Mensaje NVARCHAR(4000) NULL
);
GO
PRINT '03_crear_dw: DW_NotariaLozano creada';
