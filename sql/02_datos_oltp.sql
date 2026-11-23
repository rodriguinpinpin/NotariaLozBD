/* =====================================================================
   02_datos_oltp.sql  ·  Datos ficticios de la Notaría Lozano
   Periodo: 2026-06-01 a 2026-11-22 (últimos 6 meses). Lunes a sábado;
   sábado solo turno mañana. Generador DETERMINISTA: cada valor "variable"
   sale de dbo.fn_Azar(id, sal) = hash MD5 -> [0,1). Misma ejecución, mismos datos.
   Requiere 01_crear_oltp.sql recién ejecutado (base vacía).
   ===================================================================== */
USE NotariaPeru;
GO
SET NOCOUNT ON;
GO
CREATE OR ALTER FUNCTION dbo.fn_Azar(@a INT, @sal INT)
RETURNS FLOAT WITH SCHEMABINDING AS
BEGIN
    RETURN (ABS(CAST(CHECKSUM(HASHBYTES('MD5', CONCAT(@a, ':', @sal))) AS BIGINT)) % 1000000) / 1000000.0;
END;
GO

/* ---------------------------------------------------------------
   1. Catálogos
   --------------------------------------------------------------- */
INSERT INTO ColegioNotarios (NombreColegio, Departamento, Direccion, Telefono, Correo) VALUES
('Colegio de Notarios de Cajamarca', 'Cajamarca', 'Jr. Amazonas 450', '076221100', 'contacto@cnc.pe'),
('Colegio de Notarios de Lima', 'Lima', 'Av. Javier Prado 1200', '014452200', 'contacto@cnl.pe'),
('Colegio de Notarios de La Libertad', 'La Libertad', 'Av. España 780', '044295300', 'contacto@cnll.pe');

INSERT INTO Notario (Nombres, Apellidos, NumeroColegiatura, IdColegioNotarios, DistritoNotarial, DireccionOficina, Telefono, Correo, FechaNombramiento, Rol, Estado) VALUES
('Manuel Alberto', 'Lozano Cabrera', 'CAJ-0101', 1, 'Cajamarca', 'Jr. Cruz de Piedra 320', '976123456', 'mlozano@notarialozano.pe', '2009-04-15', 'Titular', 'Activo'),
('Carlos', 'Vásquez Rojas', 'CAJ-0125', 1, 'Cajamarca', 'Jr. Cruz de Piedra 320', '976654321', 'cvasquez@notarialozano.pe', '2015-03-10', 'Suplente', 'Activo');

INSERT INTO Empleado (Nombres, Apellidos, DNI, Cargo, IdNotario, FechaIngreso, Telefono, Correo, Sueldo, Estado) VALUES
('Ana Lucía', 'Ramos Díaz',      '45123456', 'Secretaria',         1, '2020-02-01', '976111222', 'aramos@notarialozano.pe',   1800.00, 'Activo'),
('Pedro',     'Salazar Núñez',   '46234567', 'Abogado',            1, '2018-05-10', '976222333', 'psalazar@notarialozano.pe', 3800.00, 'Activo'),
('Andrea',    'Flores Vega',     '47345678', 'Cajera',             1, '2019-09-15', '976333444', 'aflores@notarialozano.pe',  1900.00, 'Activo'),
('Jorge',     'Cueva Terrones',  '44871236', 'Abogado',            1, '2021-03-01', '976444555', 'jcueva@notarialozano.pe',   3600.00, 'Activo'),
('Milagros',  'Chávez Soto',     '48219034', 'Redactor',           1, '2022-01-17', '976555666', 'mchavez@notarialozano.pe',  2500.00, 'Activo'),
('Diego',     'Alcalde Mendoza', '47702918', 'Redactor',           1, '2023-06-05', '976666777', 'dalcalde@notarialozano.pe', 2400.00, 'Activo'),
('Rosa',      'Huamán Castro',   '46588120', 'Secretaria',         1, '2021-08-23', '976777888', 'rhuaman@notarialozano.pe',  1800.00, 'Activo'),
('Kevin',     'Tafur Vargas',    '72330145', 'Mesa de partes',     1, '2024-02-12', '976888999', 'ktafur@notarialozano.pe',   1500.00, 'Activo'),
('Elena',     'Quispe Ortiz',    '43190562', 'Archivero',          1, '2017-11-02', '976999000', 'equispe@notarialozano.pe',  1700.00, 'Activo'),
('Luis',      'Mestanza Rojas',  '45560781', 'Asistente notarial', 1, '2020-10-19', '976000111', 'lmestanza@notarialozano.pe',2900.00, 'Activo');

INSERT INTO Arancel (NombreArancel, Descripcion, Monto, Estado) VALUES
('Arancel Compraventa de inmueble', 'Escritura de compraventa de inmueble (más 0.1% del precio)', 350.00, 'Activo'),
('Arancel Transferencia vehicular', 'Acta/escritura de transferencia de vehículo', 220.00, 'Activo'),
('Arancel Poder', 'Otorgamiento de poder por escritura pública', 180.00, 'Activo'),
('Arancel Testamento', 'Testamento por escritura pública', 420.00, 'Activo'),
('Arancel Hipoteca', 'Constitución de hipoteca (más 0.08% de la garantía)', 450.00, 'Activo'),
('Arancel Constitución de empresa', 'Escritura de constitución de sociedad', 600.00, 'Activo'),
('Arancel Legalización de firma', 'Legalización por firma', 18.00, 'Activo'),
('Arancel Copia certificada', 'Copia certificada por ejemplar (simple: S/ 15)', 25.00, 'Activo');

INSERT INTO TipoTramite (NombreTramite, Descripcion, Categoria, RequiereTestigos, CostoBase, TiempoEstimadoDias, PorcentajeCosto, IdArancel) VALUES
('Compraventa de inmueble', 'Transferencia de bien inmueble',            'Escrituras públicas', 0, 350.00, 5, 0.32, 1),
('Transferencia vehicular', 'Transferencia de propiedad vehicular',      'Escrituras públicas', 0, 220.00, 2, 0.35, 2),
('Poder',                   'Otorgamiento de poder notarial',            'Escrituras públicas', 0, 180.00, 1, 0.18, 3),
('Testamento',              'Testamento por escritura pública',          'Escrituras públicas', 1, 420.00, 1, 0.22, 4),
('Hipoteca',                'Constitución de hipoteca sobre inmueble',   'Escrituras públicas', 0, 450.00, 7, 0.30, 5),
('Constitución de empresa', 'Escritura de constitución de sociedad',     'Escrituras públicas', 0, 600.00, 5, 0.40, 6),
('Legalización de firma',   'Legalización de firmas en documentos privados', 'Extraprotocolares', 0, 18.00, 0, 0.12, 7),
('Copia certificada',       'Expedición de copias certificadas o simples',   'Extraprotocolares', 0, 25.00, 0, 0.20, 8);

INSERT INTO Testigo (DNI, Nombres, Apellidos, Direccion, Telefono) VALUES
('80123456','Julio','Paredes Soto','Jr. Tarapacá 100, Cajamarca','966111222'),
('81234567','Carmen','Rojas Vidal','Av. Mario Urteaga 210, Cajamarca','966222333'),
('82345678','Wilson','Tafur Díaz','Jr. Dos de Mayo 55, Cajamarca','966333444'),
('83000211','Carmen','Delgado Núñez','Jr. Dos de Mayo 673, Cajamarca','963337174'),
('83000422','Ricardo','Terrones Vega','Jr. Dos de Mayo 50, Cajamarca','965438436'),
('83000633','Miguel','Sánchez López','Jr. Amalia Puga 295, Cajamarca','960971823'),
('83000844','César','Castillo Ríos','Av. Hoyos Rubio 799, Cajamarca','968153566'),
('83001055','Isabel','Muñoz Silva','Jr. Junín 725, Cajamarca','967973915'),
('83001266','Lucía','Bazán Castro','Jr. Dos de Mayo 671, Cajamarca','967099076'),
('83001477','Isabel','Paredes Rojas','Jr. Amalia Puga 458, Cajamarca','966264956'),
('83001688','Hugo','Cerna Alva','Jr. Silva Santisteban 120, Cajamarca','966551230'),
('83001899','Teresa','Gálvez Ruiz','Av. Independencia 310, Cajamarca','966774512');

-- Libros de kárdex: por notario y trimestre (II, III y IV de 2026)
INSERT INTO LibroKardex (NumeroLibro, Anio, IdNotario, FolioInicio, FolioFin, Estado)
SELECT q.Num, 2026, n.IdNotario, 1, 300, IIF(q.Num = 4, 'Abierto', 'Cerrado')
FROM Notario n CROSS JOIN (VALUES (2), (3), (4)) q(Num);

/* ---------------------------------------------------------------
   2. Clientes: 170 naturales + 30 jurídicas (las 4 primeras jurídicas
      son entidades financieras: acreedores de hipotecas)
   --------------------------------------------------------------- */
DECLARE @Nom TABLE (i INT PRIMARY KEY, v VARCHAR(30));
INSERT INTO @Nom VALUES (0,'María'),(1,'José'),(2,'Rosa'),(3,'Luis'),(4,'Carmen'),(5,'Juan'),(6,'Elena'),(7,'Carlos'),
 (8,'Patricia'),(9,'Miguel'),(10,'Lucía'),(11,'Fernando'),(12,'Isabel'),(13,'Raúl'),(14,'Rocío'),(15,'Edwin'),(16,'Vanessa'),
 (17,'Ricardo'),(18,'Andrea'),(19,'Wilson'),(20,'Gladys'),(21,'Segundo'),(22,'Yolanda'),(23,'Víctor'),(24,'Diana'),
 (25,'Óscar'),(26,'Marleny'),(27,'Walter'),(28,'Flor'),(29,'Alexander');
DECLARE @Ape TABLE (i INT PRIMARY KEY, v VARCHAR(30));
INSERT INTO @Ape VALUES (0,'Huamán'),(1,'Castillo'),(2,'Zelada'),(3,'Guevara'),(4,'Chávez'),(5,'Quispe'),(6,'Vargas'),(7,'Rojas'),
 (8,'Cruz'),(9,'Vásquez'),(10,'Mestanza'),(11,'Muñoz'),(12,'Terrones'),(13,'Cabanillas'),(14,'Sánchez'),(15,'Alva'),
 (16,'Cueva'),(17,'Peña'),(18,'Ortiz'),(19,'Silva'),(20,'Mendoza'),(21,'Rodríguez'),(22,'Bazán'),(23,'Díaz'),(24,'Torres'),
 (25,'Llanos'),(26,'Infante'),(27,'Chilón'),(28,'Tasilla'),(29,'Ventura'),(30,'Briones'),(31,'Mosqueira'),(32,'Aguilar'),
 (33,'Cotrina'),(34,'Gálvez'),(35,'Saldaña'),(36,'Cerna'),(37,'Tirado'),(38,'Marín'),(39,'Becerra');
DECLARE @Calle TABLE (i INT PRIMARY KEY, v VARCHAR(40));
INSERT INTO @Calle VALUES (0,'Jr. Lima'),(1,'Av. Atahualpa'),(2,'Jr. Amalia Puga'),(3,'Av. Hoyos Rubio'),(4,'Jr. Dos de Mayo'),
 (5,'Jr. Tarapacá'),(6,'Av. Independencia'),(7,'Jr. Junín'),(8,'Av. Vía de Evitamiento'),(9,'Jr. Cruz de Piedra');

;WITH N AS (SELECT TOP (170) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i FROM sys.all_objects)
INSERT INTO Cliente (TipoPersona, TipoDocumento, NumeroDocumento, Nombres, Apellidos, RazonSocial, EstadoCivil, Direccion, Distrito, Telefono, Correo, FechaRegistro)
SELECT 'Natural', 'DNI', CAST(76000000 + N.i * 389 AS VARCHAR(20)),
       nm.v, a1.v + ' ' + a2.v, NULL,
       CASE WHEN u.e < 0.38 THEN 'Soltero' WHEN u.e < 0.78 THEN 'Casado' WHEN u.e < 0.88 THEN 'Conviviente' WHEN u.e < 0.95 THEN 'Divorciado' ELSE 'Viudo' END,
       ca.v + ' ' + CAST(100 + (N.i * 37) % 800 AS VARCHAR(5)),
       CASE WHEN u.d < 0.55 THEN 'Cajamarca' WHEN u.d < 0.70 THEN 'Baños del Inca' WHEN u.d < 0.78 THEN 'Los Baños del Inca' WHEN u.d < 0.85 THEN 'Jesús'
            WHEN u.d < 0.90 THEN 'Llacanora' WHEN u.d < 0.94 THEN 'Namora' WHEN u.d < 0.97 THEN 'La Encañada' ELSE 'Matara' END,
       CAST(960000000 + (N.i * 123457) % 9999999 AS VARCHAR(15)),
       TRANSLATE(LOWER(LEFT(nm.v, CHARINDEX(' ', nm.v + ' ') - 1) + '.' + a1.v), 'áéíóúñ', 'aeioun') + CAST(N.i AS VARCHAR(4)) + '@gmail.com',
       '2026-06-01'
FROM N
CROSS APPLY (SELECT dbo.fn_Azar(N.i, 11) AS e, dbo.fn_Azar(N.i, 12) AS d) u
JOIN @Nom nm ON nm.i = (N.i * 7) % 30
JOIN @Ape a1 ON a1.i = (N.i * 11) % 40
JOIN @Ape a2 ON a2.i = (N.i * 17 + 3) % 40
JOIN @Calle ca ON ca.i = (N.i * 3) % 10;

UPDATE Cliente SET Distrito = 'Baños del Inca' WHERE Distrito = 'Los Baños del Inca';

INSERT INTO Cliente (TipoPersona, TipoDocumento, NumeroDocumento, RazonSocial, Direccion, Distrito, Telefono, Correo, FechaRegistro)
SELECT 'Juridica', 'RUC', CAST(20480000000 + j.i * 7919 AS VARCHAR(20)), j.v,
       'Av. Industrial ' + CAST(100 + j.i * 23 AS VARCHAR(5)), IIF(j.i % 5 = 0, 'Baños del Inca', 'Cajamarca'),
       CAST(976100000 + j.i * 3571 AS VARCHAR(15)), 'contacto' + CAST(j.i AS VARCHAR(3)) + '@empresa.pe', '2026-06-01'
FROM (VALUES
 (1,'Caja Rural Andina SA'),(2,'Banco Regional del Norte SA'),(3,'Cooperativa de Ahorro Marañón Ltda'),(4,'Financiera Cumbe SA'),
 (5,'Transportes San Martín SAC'),(6,'Constructora Andina SAC'),(7,'Agropecuaria Marañón EIRL'),(8,'Inmobiliaria Los Alisos SAC'),
 (9,'Lácteos El Porongo SAC'),(10,'Comercial Cumbemayo EIRL'),(11,'Servicios Mineros Yanacocha Norte SAC'),(12,'Hotel Plaza Atahualpa SAC'),
 (13,'Ferretería El Constructor EIRL'),(14,'Agroexportadora Jequetepeque SAC'),(15,'Transportes Turismo Cajamarca SRL'),(16,'Clínica San Lorenzo SAC'),
 (17,'Textiles Andinos EIRL'),(18,'Distribuidora La Collpa SAC'),(19,'Consultora Ambiental Sierra Verde SAC'),(20,'Panificadora Santa Apolonia EIRL'),
 (21,'Grifo Los Baños SAC'),(22,'Colegio Particular San Ramón SAC'),(23,'Inversiones Llacanora SAC'),(24,'Autoservicios Chontapaccha EIRL'),
 (25,'Maderera Porcón SAC'),(26,'Restaurante El Zarco EIRL'),(27,'Agencia de Viajes Inca Tour SAC'),(28,'Corporación Avícola Namora SAC'),
 (29,'Importadora Andina de Repuestos SAC'),(30,'Laboratorio Clínico Vida SAC')) j(i, v);

/* ---------------------------------------------------------------
   3. Calendario y cantidad de trámites por día
   --------------------------------------------------------------- */
CREATE TABLE #N (n INT PRIMARY KEY);
INSERT INTO #N SELECT TOP (2000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 FROM sys.all_objects a CROSS JOIN sys.all_objects b;

CREATE TABLE #Dia (DiaIdx INT PRIMARY KEY, Fecha DATE, EsSab BIT, EsFinMes BIT, Cant INT);
INSERT INTO #Dia (DiaIdx, Fecha, EsSab, EsFinMes, Cant)
SELECT n, f, IIF(dw = 5, 1, 0), IIF(DAY(f) >= DAY(EOMONTH(f)) - 3, 1, 0), 0
FROM #N
CROSS APPLY (SELECT DATEADD(DAY, n, CAST('2026-06-01' AS DATE)) AS f) x
CROSS APPLY (SELECT DATEDIFF(DAY, '2024-01-01', x.f) % 7 AS dw) y   -- 2024-01-01 fue lunes: 0=lun ... 6=dom
WHERE n <= DATEDIFF(DAY, '2026-06-01', '2026-11-22') AND dw <> 6;

UPDATE #Dia SET Cant = CAST(ROUND(
      5.0
    * (1 + 0.15 * DiaIdx / 175.0)                -- tendencia creciente
    * IIF(EsFinMes = 1, 1.35, 1.0)                -- cierre de mes
    * IIF(MONTH(Fecha) = 7, 1.25, 1.0)            -- julio (gratificaciones)
    * IIF(EsSab = 1, 0.45, 1.0)                   -- sábado medio turno
    * (0.6 + 0.8 * dbo.fn_Azar(DiaIdx, 900)), 0) AS INT);

/* ---------------------------------------------------------------
   4. Plan de trámites: una fila por trámite con todos sus atributos
   --------------------------------------------------------------- */
CREATE TABLE #P (
    IdTramite INT PRIMARY KEY, Fecha DATE, DiaIdx INT, EsSab BIT, EsFinMes BIT,
    Servicio INT, Hora TIME(0), Tarde BIT, EsJur BIT, IdCliente INT, IdEmpleado INT, IdNotario INT,
    DurDias INT, Estado VARCHAR(20), FechaFin DATE, Monto DECIMAL(10,2), Metodo VARCHAR(20),
    PagoParcial BIT, Firmas INT, Copias INT, CopiaSimple BIT, Precio DECIMAL(12,2), Garantia DECIMAL(12,2),
    IdEscritura INT, IdLegalizacion INT, IdCopia INT, IdContrato INT, IdPartida INT, IdInmueble INT, IdVehiculo INT,
    EscrituraRef INT);

INSERT INTO #P (IdTramite, Fecha, DiaIdx, EsSab, EsFinMes)
SELECT ROW_NUMBER() OVER (ORDER BY d.DiaIdx, k.n), d.Fecha, d.DiaIdx, d.EsSab, d.EsFinMes
FROM #Dia d JOIN #N k ON k.n < d.Cant;

-- Servicio (pesos: legalización 34, copia 12, poder 16, compraventa 12, vehicular 10, hipoteca 6, testamento 5, empresa 5)
UPDATE #P SET Servicio = CASE
    WHEN u < 0.34 THEN 7 WHEN u < 0.46 THEN IIF(DiaIdx < 2, 7, 8) WHEN u < 0.62 THEN 3 WHEN u < 0.74 THEN 1
    WHEN u < 0.84 THEN 2 WHEN u < 0.90 THEN 5 WHEN u < 0.95 THEN 4 ELSE 6 END
FROM #P CROSS APPLY (SELECT dbo.fn_Azar(IdTramite, 1) AS u) z;

-- Hora y turno (sábado solo mañana)
UPDATE #P SET Hora = CASE
        WHEN EsSab = 1 OR u < 0.62 THEN DATEADD(MINUTE, FLOOR(v * IIF(EsSab = 1, 270, 285)), CAST('08:00' AS TIME(0)))
        ELSE DATEADD(MINUTE, FLOOR(v * 270), CAST('14:00' AS TIME(0))) END
FROM #P CROSS APPLY (SELECT dbo.fn_Azar(IdTramite, 2) AS u, dbo.fn_Azar(IdTramite, 3) AS v) z;
UPDATE #P SET Tarde = IIF(Hora >= '13:00', 1, 0);

-- Cliente: probabilidad de persona jurídica según servicio; sesgo a clientes recurrentes
UPDATE #P SET EsJur = IIF(dbo.fn_Azar(IdTramite, 4) < CASE Servicio
        WHEN 6 THEN 0.70 WHEN 5 THEN 0.25 WHEN 2 THEN 0.22 WHEN 1 THEN 0.15 WHEN 3 THEN 0.15
        WHEN 7 THEN 0.08 WHEN 8 THEN 0.10 ELSE 0 END, 1, 0);
UPDATE #P SET IdCliente = IIF(EsJur = 1,
        175 + FLOOR(POWER(dbo.fn_Azar(IdTramite, 5), 1.6) * 26),   -- jurídicas no financieras: 175..200
          1 + FLOOR(POWER(dbo.fn_Azar(IdTramite, 5), 1.8) * 170)); -- naturales: 1..170

-- Responsable según servicio y cargo
UPDATE #P SET IdEmpleado = CASE
    WHEN Servicio IN (4, 5, 6) THEN CASE WHEN u < 0.42 THEN 2 WHEN u < 0.80 THEN 4 ELSE 10 END
    WHEN Servicio IN (1, 2, 3) THEN CASE WHEN u < 0.20 THEN 2 WHEN u < 0.36 THEN 4 WHEN u < 0.60 THEN 5 WHEN u < 0.82 THEN 6 ELSE 10 END
    WHEN Servicio = 7 THEN CASE WHEN u < 0.30 THEN 1 WHEN u < 0.58 THEN 7 WHEN u < 0.83 THEN 8 ELSE 3 END
    ELSE CASE WHEN u < 0.60 THEN 9 WHEN u < 0.80 THEN 1 ELSE 7 END END
FROM #P CROSS APPLY (SELECT dbo.fn_Azar(IdTramite, 6) AS u) z;

-- Notario: suplente firma ~10 % de escrituras y ~8 % de extraprotocolares
UPDATE #P SET IdNotario = IIF(dbo.fn_Azar(IdTramite, 7) < IIF(Servicio <= 6, 0.10, 0.08), 2, 1);

-- Duración y estado
UPDATE #P SET DurDias = CASE Servicio
    WHEN 1 THEN 3 + FLOOR(u * 6) WHEN 2 THEN 1 + FLOOR(u * 3) WHEN 3 THEN FLOOR(u * 3) WHEN 4 THEN FLOOR(u * 2)
    WHEN 5 THEN 4 + FLOOR(u * 7) WHEN 6 THEN 3 + FLOOR(u * 5) ELSE 0 END
FROM #P CROSS APPLY (SELECT dbo.fn_Azar(IdTramite, 8) AS u) z;

UPDATE #P SET Estado = CASE
        WHEN Servicio >= 7 THEN IIF(u < 0.015, 'Anulado', 'Finalizado')
        WHEN DATEADD(DAY, DurDias, Fecha) > '2026-11-22' THEN 'En Proceso'
        WHEN u < 0.03 THEN 'Anulado' WHEN u < 0.09 THEN 'Observado' WHEN u < 0.12 THEN 'En Proceso'
        ELSE 'Finalizado' END
FROM #P CROSS APPLY (SELECT dbo.fn_Azar(IdTramite, 9) AS u) z;
UPDATE #P SET FechaFin = IIF(Estado = 'Finalizado', DATEADD(DAY, DurDias, Fecha), NULL);

-- Cantidades y precios de los bienes
UPDATE #P SET
    Firmas = IIF(Servicio = 7, CASE WHEN u < 0.45 THEN 1 WHEN u < 0.80 THEN 2 WHEN u < 0.92 THEN 3 ELSE 4 END, NULL),
    Copias = CASE WHEN Servicio = 8 THEN 1 + FLOOR(u * 4)
                  WHEN Servicio <= 6 AND dbo.fn_Azar(IdTramite, 10) < 0.35 THEN 1 + FLOOR(u * 3) END,
    CopiaSimple = IIF(dbo.fn_Azar(IdTramite, 13) < 0.30, 1, 0),
    Precio = CASE Servicio WHEN 1 THEN ROUND(60000 + POWER(u, 1.4) * 320000, -2) WHEN 2 THEN ROUND(18000 + u * 77000, -2) END,
    Garantia = IIF(Servicio = 5, ROUND(40000 + POWER(u, 1.3) * 260000, -3), NULL)
FROM #P CROSS APPLY (SELECT dbo.fn_Azar(IdTramite, 14) AS u) z;

-- Importe: arancel ± complejidad; compraventa e hipoteca escalan con el valor del bien
UPDATE p SET Monto = CASE p.Servicio
        WHEN 7 THEN 18.00 * p.Firmas
        WHEN 8 THEN p.Copias * IIF(p.CopiaSimple = 1, 15.00, 25.00)
        WHEN 1 THEN ROUND((a.Monto + p.Precio * 0.001) * 2, 0) / 2
        WHEN 5 THEN ROUND((a.Monto + p.Garantia * 0.0008) * 2, 0) / 2
        ELSE ROUND(a.Monto * (1 + 0.25 * dbo.fn_Azar(p.IdTramite, 15)) * 2, 0) / 2 END
FROM #P p JOIN TipoTramite tt ON tt.IdTipoTramite = p.Servicio JOIN Arancel a ON a.IdArancel = tt.IdArancel;

-- Método de pago: empresas pagan por transferencia; personas sobre todo en efectivo y billeteras
UPDATE #P SET Metodo = CASE
        WHEN EsJur = 1 THEN CASE WHEN u < 0.75 THEN 'Transferencia' WHEN u < 0.90 THEN 'Tarjeta' ELSE 'Efectivo' END
        WHEN Monto >= 500 THEN CASE WHEN u < 0.30 THEN 'Efectivo' WHEN u < 0.60 THEN 'Transferencia' WHEN u < 0.85 THEN 'Tarjeta' ELSE 'Yape' END
        ELSE CASE WHEN u < 0.42 THEN 'Efectivo' WHEN u < 0.67 THEN 'Yape' WHEN u < 0.75 THEN 'Plin' WHEN u < 0.88 THEN 'Tarjeta' ELSE 'Transferencia' END END,
    PagoParcial = IIF(Estado = 'En Proceso' AND dbo.fn_Azar(IdTramite, 16) < 0.5, 1, 0)
FROM #P CROSS APPLY (SELECT dbo.fn_Azar(IdTramite, 17) AS u) z;

-- Claves de los documentos asociados (en orden cronológico)
UPDATE p SET IdEscritura = x.r FROM #P p JOIN (SELECT IdTramite, ROW_NUMBER() OVER (ORDER BY IdTramite) r FROM #P WHERE Servicio <= 6) x ON x.IdTramite = p.IdTramite;
UPDATE p SET IdLegalizacion = x.r FROM #P p JOIN (SELECT IdTramite, ROW_NUMBER() OVER (ORDER BY IdTramite) r FROM #P WHERE Servicio = 7) x ON x.IdTramite = p.IdTramite;
UPDATE p SET IdCopia = x.r FROM #P p JOIN (SELECT IdTramite, ROW_NUMBER() OVER (ORDER BY IdTramite) r FROM #P WHERE Copias IS NOT NULL) x ON x.IdTramite = p.IdTramite;
UPDATE p SET IdContrato = x.r FROM #P p JOIN (SELECT IdTramite, ROW_NUMBER() OVER (ORDER BY IdTramite) r FROM #P WHERE Servicio IN (1, 2)) x ON x.IdTramite = p.IdTramite;
UPDATE p SET IdInmueble = x.r FROM #P p JOIN (SELECT IdTramite, ROW_NUMBER() OVER (ORDER BY IdTramite) r FROM #P WHERE Servicio IN (1, 5)) x ON x.IdTramite = p.IdTramite;
UPDATE p SET IdVehiculo = x.r FROM #P p JOIN (SELECT IdTramite, ROW_NUMBER() OVER (ORDER BY IdTramite) r FROM #P WHERE Servicio = 2) x ON x.IdTramite = p.IdTramite;
UPDATE p SET IdPartida = x.r FROM #P p JOIN (SELECT IdTramite, ROW_NUMBER() OVER (ORDER BY IdTramite) r FROM #P WHERE Servicio IN (1, 2, 5) AND Estado IN ('Finalizado', 'Observado')) x ON x.IdTramite = p.IdTramite;
-- Copias certificadas como servicio: se expiden sobre una escritura anterior
UPDATE p SET EscrituraRef = 1 + FLOOR(dbo.fn_Azar(p.IdTramite, 18) * ISNULL(NULLIF(prev.c, 0), 1))
FROM #P p CROSS APPLY (SELECT COUNT(*) c FROM #P q WHERE q.Servicio <= 6 AND q.Fecha < p.Fecha) prev
WHERE p.Servicio = 8;

/* ---------------------------------------------------------------
   5. Bienes
   --------------------------------------------------------------- */
SET IDENTITY_INSERT Inmueble ON;
INSERT INTO Inmueble (IdInmueble, TipoInmueble, Direccion, Distrito, PartidaRegistral, AreaMetrosCuadrados)
SELECT p.IdInmueble,
       CASE WHEN u < 0.40 THEN 'Casa' WHEN u < 0.62 THEN 'Departamento' WHEN u < 0.85 THEN 'Terreno' ELSE 'Local Comercial' END,
       ca.v + ' ' + CAST(100 + (p.IdTramite * 13) % 900 AS VARCHAR(5)),
       CASE WHEN w < 0.60 THEN 'Cajamarca' WHEN w < 0.78 THEN 'Baños del Inca' WHEN w < 0.88 THEN 'Jesús' ELSE 'Llacanora' END,
       'PRT-' + CAST(11006000 + p.IdInmueble * 7 AS VARCHAR(10)),
       ROUND(70 + POWER(w, 1.5) * 480, 2)
FROM #P p CROSS APPLY (SELECT dbo.fn_Azar(p.IdTramite, 20) u, dbo.fn_Azar(p.IdTramite, 21) w) z
JOIN @Calle ca ON ca.i = p.IdTramite % 10
WHERE p.IdInmueble IS NOT NULL;
SET IDENTITY_INSERT Inmueble OFF;

SET IDENTITY_INSERT Vehiculo ON;
INSERT INTO Vehiculo (IdVehiculo, Placa, Marca, Modelo, AnioFabricacion, NumeroTarjetaPropiedad)
SELECT p.IdVehiculo,
       CONCAT(CHAR(65 + p.IdTramite % 26), p.IdTramite % 10, CHAR(65 + (p.IdTramite / 7) % 26), '-', 100 + (p.IdTramite * 37) % 900),
       m.Marca, m.Modelo, 2012 + FLOOR(dbo.fn_Azar(p.IdTramite, 22) * 14), 'TP-' + CAST(780000 + p.IdVehiculo * 53 AS VARCHAR(10))
FROM #P p
JOIN (VALUES (0,'Toyota','Hilux'),(1,'Hyundai','Accent'),(2,'Nissan','Frontier'),(3,'Kia','Rio'),(4,'Chevrolet','Sail'),
             (5,'Suzuki','Swift'),(6,'Honda','CR-V'),(7,'Toyota','Yaris'),(8,'Hyundai','Tucson'),(9,'Mitsubishi','L200')) m(i, Marca, Modelo)
  ON m.i = FLOOR(dbo.fn_Azar(p.IdTramite, 23) * 10)
WHERE p.IdVehiculo IS NOT NULL;
SET IDENTITY_INSERT Vehiculo OFF;

/* ---------------------------------------------------------------
   6. Escrituras públicas y sus actos
   --------------------------------------------------------------- */
SET IDENTITY_INSERT EscrituraPublica ON;
INSERT INTO EscrituraPublica (IdEscritura, NumeroEscritura, KardexNo, TipoActo, FechaEscritura, Tomo, Folio, IdNotario, IdColegioNotarios, IdArancel, IdLibroKardex, Estado)
SELECT p.IdEscritura, 3000 + p.IdEscritura, 'K-2026-' + RIGHT('0000' + CAST(p.IdEscritura AS VARCHAR(5)), 4),
       tt.NombreTramite, p.Fecha, DATEPART(QUARTER, p.Fecha), 1 + (p.IdEscritura * 4) % 296, p.IdNotario, 1, tt.IdArancel,
       lk.IdLibroKardex, IIF(p.Estado = 'Anulado', 'Anulado', 'Vigente')
FROM #P p JOIN TipoTramite tt ON tt.IdTipoTramite = p.Servicio
JOIN LibroKardex lk ON lk.IdNotario = p.IdNotario AND lk.NumeroLibro = DATEPART(QUARTER, p.Fecha)
WHERE p.IdEscritura IS NOT NULL;
SET IDENTITY_INSERT EscrituraPublica OFF;

SET IDENTITY_INSERT ContratoCompraventa ON;
INSERT INTO ContratoCompraventa (IdContrato, IdEscritura, FechaContrato, IdInmueble, IdVehiculo, IdVendedor, IdComprador, PrecioVenta, FormaPago)
SELECT p.IdContrato, p.IdEscritura, p.Fecha, IIF(p.Servicio = 1, p.IdInmueble, NULL), IIF(p.Servicio = 2, p.IdVehiculo, NULL),
       1 + (p.IdCliente + 36 + p.IdTramite % 50) % 170, p.IdCliente, p.Precio,
       CASE WHEN dbo.fn_Azar(p.IdTramite, 24) < 0.55 THEN 'Contado' WHEN dbo.fn_Azar(p.IdTramite, 24) < 0.85 THEN 'Financiado' ELSE 'Letras' END
FROM #P p WHERE p.IdContrato IS NOT NULL;
SET IDENTITY_INSERT ContratoCompraventa OFF;

INSERT INTO Poder (IdEscritura, TipoPoder, IdOtorgante, IdApoderado, Facultades, FechaOtorgamiento, FolioInicio, FolioFin, Estado)
SELECT p.IdEscritura, IIF(u < 0.45, 'Poder General', 'Poder Especial'), p.IdCliente, 1 + (p.IdCliente + 53) % 170,
       CHOOSE(1 + FLOOR(dbo.fn_Azar(p.IdTramite, 26) * 5),
              'Administrar bienes y representar en trámites bancarios', 'Representación judicial en proceso civil',
              'Vender un bien específico a nombre del otorgante', 'Cobro de deudas y gestión de pagos',
              'Representación en trámites municipales y notariales'),
       p.Fecha, 1 + (p.IdEscritura * 4) % 296, 3 + (p.IdEscritura * 4) % 296,
       CASE WHEN p.Estado = 'Anulado' THEN 'Anulado' WHEN u > 0.97 THEN 'Revocado' ELSE 'Vigente' END
FROM #P p CROSS APPLY (SELECT dbo.fn_Azar(p.IdTramite, 25) u) z WHERE p.Servicio = 3;

INSERT INTO Testamento (IdEscritura, TipoTestamento, IdTestador, IdTestigo1, IdTestigo2, FechaOtorga, HoraOtorga, Tomo, Folio, Estado)
SELECT p.IdEscritura, IIF(dbo.fn_Azar(p.IdTramite, 27) < 0.8, 'Escritura Publica', 'Cerrado'), p.IdCliente,
       1 + p.IdTramite % 12, 1 + (p.IdTramite + 5) % 12, p.Fecha, p.Hora, DATEPART(QUARTER, p.Fecha), 1 + (p.IdEscritura * 4) % 296, 'Registrado'
FROM #P p WHERE p.Servicio = 4 AND p.Estado <> 'Anulado';

INSERT INTO EscrituraTestigo (IdEscritura, IdTestigo)
SELECT p.IdEscritura, t.IdTestigo
FROM #P p CROSS APPLY (VALUES (1 + p.IdTramite % 12), (1 + (p.IdTramite + 5) % 12)) t(IdTestigo)
WHERE p.Servicio = 4 AND p.Estado <> 'Anulado';

INSERT INTO Hipoteca (IdEscritura, IdInmueble, IdDeudor, IdAcreedor, MontoGarantia, Moneda, FechaInscripcion, Estado)
SELECT p.IdEscritura, p.IdInmueble, p.IdCliente, 171 + FLOOR(dbo.fn_Azar(p.IdTramite, 28) * 4), p.Garantia,
       IIF(dbo.fn_Azar(p.IdTramite, 29) < 0.25, 'USD', 'PEN'),
       IIF(p.Estado = 'Finalizado' AND DATEADD(DAY, 5, p.FechaFin) <= '2026-11-22', DATEADD(DAY, 5, p.FechaFin), NULL),
       'Vigente'
FROM #P p WHERE p.Servicio = 5 AND p.Estado <> 'Anulado';

SET IDENTITY_INSERT PartidaRegistral ON;
INSERT INTO PartidaRegistral (IdPartidaRegistral, NumeroPartida, OficinaRegistral, Registro, Asiento, IdCliente, DescripcionActo, FechaInscripcion, EstadoTramite)
SELECT p.IdPartida, CAST(11100000 + p.IdPartida * 17 AS VARCHAR(20)), 'SUNARP Cajamarca',
       IIF(p.Servicio = 2, 'Registro de Propiedad Vehicular', 'Registro de Propiedad Inmueble'),
       'A' + RIGHT('0000' + CAST(p.IdPartida AS VARCHAR(5)), 4), p.IdCliente,
       CASE p.Servicio WHEN 1 THEN 'Compraventa de inmueble' WHEN 2 THEN 'Transferencia vehicular' ELSE 'Constitución de hipoteca' END,
       IIF(ins.f <= '2026-11-22' AND p.Estado = 'Finalizado' AND dbo.fn_Azar(p.IdTramite, 30) < 0.88, ins.f, NULL),
       CASE WHEN p.Estado = 'Observado' THEN 'Observado'
            WHEN ins.f <= '2026-11-22' AND dbo.fn_Azar(p.IdTramite, 30) < 0.88 THEN 'Inscrito' ELSE 'En Trámite' END
FROM #P p CROSS APPLY (SELECT DATEADD(DAY, 3 + FLOOR(dbo.fn_Azar(p.IdTramite, 31) * 10), ISNULL(p.FechaFin, p.Fecha)) f) ins
WHERE p.IdPartida IS NOT NULL;
SET IDENTITY_INSERT PartidaRegistral OFF;

SET IDENTITY_INSERT CopiaCertificada ON;
INSERT INTO CopiaCertificada (IdCopiaCertificada, IdEscritura, TipoCopia, CantidadCopias, FechaSolicitud, Observacion)
SELECT p.IdCopia, IIF(p.Servicio = 8, p.EscrituraRef, p.IdEscritura), IIF(p.CopiaSimple = 1, 'Copia Simple', 'Copia Certificada'),
       p.Copias, p.Fecha,
       CHOOSE(1 + FLOOR(dbo.fn_Azar(p.IdTramite, 32) * 5), 'Solicitada por el cliente', 'Para SUNARP', 'Para trámite bancario', 'Para herederos', 'Uso personal')
FROM #P p WHERE p.IdCopia IS NOT NULL;
SET IDENTITY_INSERT CopiaCertificada OFF;

SET IDENTITY_INSERT LegalizacionFirma ON;
INSERT INTO LegalizacionFirma (IdLegalizacion, IdCliente, IdNotario, TipoDocumento, CantidadFirmas, FechaLegalizacion, Costo)
SELECT p.IdLegalizacion, p.IdCliente, p.IdNotario,
       CHOOSE(1 + FLOOR(dbo.fn_Azar(p.IdTramite, 33) * 6), 'Contrato privado de alquiler', 'Carta poder simple', 'Declaración jurada',
              'Autorización de viaje de menor', 'Constancia de supervivencia', 'Contrato privado de prestación de servicios'),
       p.Firmas, p.Fecha, p.Monto
FROM #P p WHERE p.IdLegalizacion IS NOT NULL;
SET IDENTITY_INSERT LegalizacionFirma OFF;

/* ---------------------------------------------------------------
   7. Trámites, pagos y etapas de atención
   --------------------------------------------------------------- */
SET IDENTITY_INSERT Tramite ON;
INSERT INTO Tramite (IdTramite, IdCliente, IdEmpleado, IdNotario, IdTipoTramite, IdEscritura, IdCopiaCertificada, IdPartidaRegistral, IdContrato, IdLegalizacion, FechaInicio, HoraInicio, FechaFin, EstadoTramite)
SELECT IdTramite, IdCliente, IdEmpleado, IdNotario, Servicio, IdEscritura, IdCopia, IdPartida, IdContrato, IdLegalizacion, Fecha, Hora, FechaFin, Estado
FROM #P;
SET IDENTITY_INSERT Tramite OFF;

;WITH Pg AS (
    SELECT p.IdTramite, p.Fecha, p.Metodo, p.EsJur, p.Monto AS Monto,
           CASE p.Estado WHEN 'Anulado' THEN 'Anulado' WHEN 'En Proceso' THEN 'Pendiente' ELSE 'Pagado' END AS Estado
    FROM #P p WHERE p.PagoParcial = 0
    UNION ALL   -- adelanto del 50 %
    SELECT p.IdTramite, p.Fecha, p.Metodo, p.EsJur, ROUND(p.Monto / 2, 2), 'Pagado' FROM #P p WHERE p.PagoParcial = 1
    UNION ALL   -- saldo pendiente
    SELECT p.IdTramite, p.Fecha, p.Metodo, p.EsJur, p.Monto - ROUND(p.Monto / 2, 2), 'Pendiente' FROM #P p WHERE p.PagoParcial = 1
), Num AS (SELECT *, ROW_NUMBER() OVER (ORDER BY IdTramite, Estado DESC) AS IdPago FROM Pg)
INSERT INTO Pago (IdTramite, FechaPago, Monto, MetodoPago, NumeroComprobante, Estado)
SELECT IdTramite, Fecha, Monto, Metodo, IIF(EsJur = 1, 'F001-', 'B001-') + RIGHT('000000' + CAST(IdPago AS VARCHAR(6)), 6), Estado
FROM Num ORDER BY IdPago;

-- Minutos por etapa: espera crece por la tarde y al cierre de mes; proceso depende del servicio
;WITH M AS (
    SELECT p.IdTramite, p.Fecha, p.Hora, p.IdEmpleado, p.Servicio,
        e1 = 3 + FLOOR(dbo.fn_Azar(p.IdTramite, 40) * 12) + p.Tarde * 6 + p.EsFinMes * 4,
        p1 = 5 + FLOOR(dbo.fn_Azar(p.IdTramite, 41) * 8),
        e2 = IIF(p.Servicio >= 7, 2 + FLOOR(dbo.fn_Azar(p.IdTramite, 42) * 8) + p.Tarde * 5 + p.EsFinMes * 3,
                 10 + FLOOR(dbo.fn_Azar(p.IdTramite, 42) * 30) + p.Tarde * 12 + p.EsFinMes * 8 + IIF(p.Estado = 'Observado', 15, 0)),
        p2 = CASE p.Servicio WHEN 1 THEN 60 WHEN 2 THEN 40 WHEN 3 THEN 30 WHEN 4 THEN 70 WHEN 5 THEN 80 WHEN 6 THEN 70 WHEN 7 THEN 4 ELSE 8 END
           + FLOOR(dbo.fn_Azar(p.IdTramite, 43) * CASE p.Servicio WHEN 1 THEN 60 WHEN 2 THEN 40 WHEN 3 THEN 30 WHEN 4 THEN 60 WHEN 5 THEN 60 WHEN 6 THEN 50 WHEN 7 THEN 6 ELSE 10 END),
        e3 = IIF(p.Servicio >= 7, 1 + FLOOR(dbo.fn_Azar(p.IdTramite, 44) * 5) + p.Tarde * 3, 5 + FLOOR(dbo.fn_Azar(p.IdTramite, 44) * 20) + p.Tarde * 8),
        p3 = CASE WHEN p.Servicio = 7 THEN 2 + FLOOR(dbo.fn_Azar(p.IdTramite, 45) * 4)
                  WHEN p.Servicio = 8 THEN 3 + FLOOR(dbo.fn_Azar(p.IdTramite, 45) * 5)
                  ELSE 10 + FLOOR(dbo.fn_Azar(p.IdTramite, 45) * 20) END,
        e4 = 2 + FLOOR(dbo.fn_Azar(p.IdTramite, 46) * 10) + p.Tarde * 3,
        p4 = 3 + FLOOR(dbo.fn_Azar(p.IdTramite, 47) * 6),
        recep = CASE WHEN dbo.fn_Azar(p.IdTramite, 48) < 0.6 THEN 8 WHEN dbo.fn_Azar(p.IdTramite, 48) < 0.8 THEN 1 ELSE 7 END,
        entrega = CASE WHEN dbo.fn_Azar(p.IdTramite, 49) < 0.55 THEN 9 WHEN dbo.fn_Azar(p.IdTramite, 49) < 0.8 THEN 1 ELSE 7 END
    FROM #P p WHERE p.Estado <> 'Anulado'
), B AS (SELECT *, CAST(CAST(Fecha AS DATETIME) + CAST(Hora AS DATETIME) AS DATETIME2(0)) AS t0 FROM M)
INSERT INTO AtencionEtapa (IdTramite, IdEmpleado, Etapa, OrdenEtapa, InicioEspera, InicioProceso, Fin)
SELECT B.IdTramite, s.Emp, s.Etapa, s.Orden,
       DATEADD(MINUTE, s.Antes, B.t0), DATEADD(MINUTE, s.Antes + s.Esp, B.t0), DATEADD(MINUTE, s.Antes + s.Esp + s.Pro, B.t0)
FROM B CROSS APPLY (VALUES
    (1, 'Recepción',            B.recep,      0,                                   B.e1, B.p1),
    (2, 'Revisión y redacción', B.IdEmpleado, B.e1 + B.p1,                         B.e2, B.p2),
    (3, 'Firma',                B.IdEmpleado, B.e1 + B.p1 + B.e2 + B.p2,           B.e3, B.p3),
    (4, 'Entrega',              B.entrega,    B.e1 + B.p1 + B.e2 + B.p2 + B.e3 + B.p3, B.e4, B.p4)
) s(Orden, Etapa, Emp, Antes, Esp, Pro);

-- Fecha de registro del cliente = su primer trámite
UPDATE c SET FechaRegistro = ISNULL(f.Primera, '2026-06-01')
FROM Cliente c OUTER APPLY (SELECT MIN(FechaInicio) Primera FROM Tramite t WHERE t.IdCliente = c.IdCliente) f;

DROP FUNCTION dbo.fn_Azar;
GO
DECLARE @t INT = (SELECT COUNT(*) FROM Tramite), @p INT = (SELECT COUNT(*) FROM Pago), @a INT = (SELECT COUNT(*) FROM AtencionEtapa);
PRINT CONCAT('02_datos_oltp: ', @t, ' tramites, ', @p, ' pagos, ', @a, ' atenciones');
