USE NotariaPeru;
GO
--Creacion de Dimensiones

CREATE TABLE DIM_TIEMPO (
    ID_Tiempo INT PRIMARY KEY,
    Fecha_Exacta DATE,
    Mes INT,
    Nombre_Mes VARCHAR(20),
    Trimestre INT,
    Semestre INT,
    Anio INT
);

CREATE TABLE DIM_CLIENTE (
    ID_Cliente INT PRIMARY KEY,
    DNI_RUC VARCHAR(20),
    Razon_Social_Nombre VARCHAR(250),
    Tipo_Cliente VARCHAR(50)
);


CREATE TABLE DIM_PERSONAL ( 
    ID_Personal INT PRIMARY KEY,
    Nombre_Completo VARCHAR(200),
    Cargo VARCHAR(100)
);


CREATE TABLE DIM_SERVICIO ( 
    ID_Servicio INT PRIMARY KEY,
    Nombre_Tramite VARCHAR(150),
    Categoria VARCHAR(100)
);


CREATE TABLE DIM_METODO_PAGO (
    ID_Metodo INT PRIMARY KEY,
    Tipo_Pago VARCHAR(50),
    Plataforma VARCHAR(50)
);


CREATE TABLE DIM_ESTADO_PAGO (
    ID_Estado_Pago INT PRIMARY KEY,
    Estado VARCHAR(50)
);

CREATE TABLE DIM_NOTARIO (
    ID_Notario INT PRIMARY KEY,
    Nombre_Completo VARCHAR(200),
    Colegio_Notarios VARCHAR(150)
);


CREATE TABLE DIM_ETAPA_TRAMITE (
    ID_Etapa INT PRIMARY KEY,
    Nombre_Etapa VARCHAR(100),
    Descripcion VARCHAR(255)
);

CREATE TABLE DIM_TURNO (
    ID_Turno INT PRIMARY KEY,
    Nombre_Turno VARCHAR(50),
    Rango_Horario VARCHAR(50)
);


CREATE TABLE DIM_TIPO_DOCUMENTO (
    ID_TipoDocumento INT PRIMARY KEY,
    Nombre_TipoDocumento VARCHAR(100),
    Descripcion VARCHAR(255)
);

-- Creacion de hechos 
CREATE TABLE FACT_TRAMITES_FINANCIEROS (
    ID_Cliente INT,
    ID_Servicio INT,
    ID_Tiempo INT,
    ID_Personal INT,
    ID_Metodo INT,
    Monto_Cobrado DECIMAL(10,2),
    Costo_Asociado DECIMAL(10,2),
    Cantidad INT,
    FOREIGN KEY (ID_Cliente) REFERENCES DIM_CLIENTE(ID_Cliente),
    FOREIGN KEY (ID_Servicio) REFERENCES DIM_SERVICIO(ID_Servicio),
    FOREIGN KEY (ID_Tiempo) REFERENCES DIM_TIEMPO(ID_Tiempo),
    FOREIGN KEY (ID_Personal) REFERENCES DIM_PERSONAL(ID_Personal),
    FOREIGN KEY (ID_Metodo) REFERENCES DIM_METODO_PAGO(ID_Metodo)
);


CREATE TABLE FACT_TIEMPOS_ATENCION (
    ID_Servicio INT,
    ID_Personal INT,
    ID_Tiempo INT,
    ID_Etapa INT,
    ID_Turno INT,
    Minutos_Espera INT,
    Minutos_Proceso INT,
    Minutos_Totales INT,
    FOREIGN KEY (ID_Servicio) REFERENCES DIM_SERVICIO(ID_Servicio),
    FOREIGN KEY (ID_Personal) REFERENCES DIM_PERSONAL(ID_Personal),
    FOREIGN KEY (ID_Tiempo) REFERENCES DIM_TIEMPO(ID_Tiempo),
    FOREIGN KEY (ID_Etapa) REFERENCES DIM_ETAPA_TRAMITE(ID_Etapa),
    FOREIGN KEY (ID_Turno) REFERENCES DIM_TURNO(ID_Turno)
);


CREATE TABLE FACT_DOCUMENTOS_OTORGADOS (
    ID_Servicio INT,
    ID_Personal INT,
    ID_Tiempo INT,
    ID_TipoDocumento INT,
    ID_Cliente INT,
    Cantidad_Documentos INT,
    FOREIGN KEY (ID_Servicio) REFERENCES DIM_SERVICIO(ID_Servicio),
    FOREIGN KEY (ID_Personal) REFERENCES DIM_PERSONAL(ID_Personal),
    FOREIGN KEY (ID_Tiempo) REFERENCES DIM_TIEMPO(ID_Tiempo),
    FOREIGN KEY (ID_TipoDocumento) REFERENCES DIM_TIPO_DOCUMENTO(ID_TipoDocumento),
    FOREIGN KEY (ID_Cliente) REFERENCES DIM_CLIENTE(ID_Cliente)
);


CREATE TABLE FACT_TRAMITE_GENERAL (
    Nro_Tramite INT PRIMARY KEY,
    ID_Tiempo INT,
    ID_Servicio INT,
    ID_Notario INT,
    ID_Cliente INT,
    ID_Personal INT, 
    ID_Estado_Pago INT,
    Monto_Pagado DECIMAL(10,2),
    Monto_Arancel DECIMAL(10,2),
    Cantidad_Tramites INT,
    FOREIGN KEY (ID_Tiempo) REFERENCES DIM_TIEMPO(ID_Tiempo),
    FOREIGN KEY (ID_Servicio) REFERENCES DIM_SERVICIO(ID_Servicio),
    FOREIGN KEY (ID_Notario) REFERENCES DIM_NOTARIO(ID_Notario),
    FOREIGN KEY (ID_Cliente) REFERENCES DIM_CLIENTE(ID_Cliente),
    FOREIGN KEY (ID_Personal) REFERENCES DIM_PERSONAL(ID_Personal),
    FOREIGN KEY (ID_Estado_Pago) REFERENCES DIM_ESTADO_PAGO(ID_Estado_Pago)
);
GO