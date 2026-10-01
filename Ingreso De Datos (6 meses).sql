--Ingreso de datos de 6 meses
USE NotariaPeru

INSERT INTO Cliente (TipoPersona, TipoDocumento, NumeroDocumento, Nombres, Apellidos, RazonSocial, EstadoCivil, Direccion, Telefono, Correo) VALUES
('Natural','DNI','75000000','Maria','Huaman Castro',NULL,'Soltero','Av. Atahualpa 278, Cajamarca','962341057','maria.huaman0@gmail.com'),
('Natural','DNI','75000137','Isabel','Castillo Rios',NULL,'Soltero','Jr. Tarapaca 482, Cajamarca','960533224','isabel.castillo1@gmail.com'),
('Natural','DNI','75000274','Wilson','Zelada Cueva',NULL,'Casado','Jr. Tarapaca 77, Cajamarca','969416129','wilson.zelada2@gmail.com'),
('Natural','DNI','75000411','Isabel','Guevara Pena',NULL,'Divorciado','Av. Atahualpa 509, Cajamarca','969886237','isabel.guevara3@gmail.com'),
('Natural','DNI','75000548','Maria','Chavez Soto',NULL,'Casado','Jr. Cruz de Piedra 398, Cajamarca','964661907','maria.chavez4@gmail.com'),
('Natural','DNI','75000685','Raul','Quispe Ortiz',NULL,'Divorciado','Av. Hoyos Rubio 439, Cajamarca','961622631','raul.quispe5@gmail.com'),
('Natural','DNI','75000822','Rocio','Huaman Castro',NULL,'Conviviente','Jr. Lima 797, Cajamarca','967707870','rocio.huaman6@gmail.com'),
('Natural','DNI','75000959','Edwin','Castillo Rios',NULL,'Conviviente','Jr. Dos de Mayo 350, Cajamarca','966067228','edwin.castillo7@gmail.com'),
('Natural','DNI','75001096','Luis','Vargas Mendez',NULL,'Soltero','Av. Atahualpa 841, Cajamarca','964855124','luis.vargas8@gmail.com'),
('Natural','DNI','75001233','Carmen','Rojas Vidal',NULL,'Casado','Jr. Amalia Puga 514, Cajamarca','966120868','carmen.rojas9@gmail.com'),
('Natural','DNI','75001370','Fernando','Huaman Castro',NULL,'Conviviente','Av. Hoyos Rubio 673, Cajamarca','962871230','fernando.huaman10@gmail.com'),
('Natural','DNI','75001507','Lucia','Cruz Alva',NULL,'Casado','Jr. Cruz de Piedra 326, Cajamarca','969344066','lucia.cruz11@gmail.com'),
('Natural','DNI','75001644','Rosa','Vasquez Diaz',NULL,'Viudo','Jr. Lima 874, Cajamarca','965292423','rosa.vasquez12@gmail.com'),
('Natural','DNI','75001781','Fernando','Mestanza Cabanillas',NULL,'Viudo','Av. Independencia 267, Cajamarca','968375710','fernando.mestanza13@gmail.com'),
('Natural','DNI','75001918','Patricia','Munoz Silva',NULL,'Conviviente','Jr. Amalia Puga 192, Cajamarca','964137722','patricia.munoz14@gmail.com'),
('Natural','DNI','75002055','Vanessa','Guevara Pena',NULL,'Casado','Jr. Tarapaca 458, Cajamarca','966073292','vanessa.guevara15@gmail.com'),
('Natural','DNI','75002192','Andrea','Zelada Cueva',NULL,'Soltero','Av. Via de Evitamiento 143, Cajamarca','960790481','andrea.zelada16@gmail.com'),
('Natural','DNI','75002329','Ricardo','Guevara Pena',NULL,'Viudo','Jr. Tarapaca 115, Cajamarca','966455324','ricardo.guevara17@gmail.com'),
('Natural','DNI','75002466','Patricia','Zelada Cueva',NULL,'Soltero','Jr. Amalia Puga 616, Cajamarca','960192619','patricia.zelada18@gmail.com'),
('Natural','DNI','75002603','Isabel','Huaman Castro',NULL,'Viudo','Av. Independencia 164, Cajamarca','964924115','isabel.huaman19@gmail.com'),
('Juridica','RUC','20498761234',NULL,NULL,'Constructora Andina SAC',NULL,'Av. Industrial 220, Cajamarca','976001122','contacto@andina.pe'),
('Juridica','RUC','20499887766',NULL,NULL,'Agropecuaria Maranon EIRL',NULL,'Jr. Comercio 115, Cajamarca','976002233','contacto@agromaranon.pe');

GO

INSERT INTO Testigo (DNI, Nombres, Apellidos, Direccion, Telefono) VALUES
('83000000','Carlos','Huaman Castro','Jr. Dos de Mayo 830, Cajamarca','962997281'),
('83000211','Carmen','Delgado Nunez','Jr. Dos de Mayo 673, Cajamarca','963337174'),
('83000422','Ricardo','Terrones Vega','Jr. Dos de Mayo 50, Cajamarca','965438436'),
('83000633','Miguel','Sanchez Lopez','Jr. Amalia Puga 295, Cajamarca','960971823'),
('83000844','Cesar','Castillo Rios','Av. Hoyos Rubio 799, Cajamarca','968153566'),
('83001055','Isabel','Munoz Silva','Jr. Junin 725, Cajamarca','967973915'),
('83001266','Lucia','Huaman Castro','Jr. Dos de Mayo 671, Cajamarca','967099076'),
('83001477','Isabel','Paredes Rojas','Jr. Amalia Puga 458, Cajamarca','966264956');

GO

INSERT INTO Inmueble (TipoInmueble, Direccion, Distrito, PartidaRegistral, AreaMetrosCuadrados) VALUES
('Local Comercial','Jr. Dos de Mayo 512','Cajamarca','PRT-11005500',193.87),
('Casa','Av. Independencia 71','Llacanora','PRT-11005537',359.12),
('Departamento','Jr. Lima 122','Cajamarca','PRT-11005574',183.63),
('Casa','Av. Independencia 122','Llacanora','PRT-11005611',188.52),
('Local Comercial','Av. Atahualpa 602','Banos del Inca','PRT-11005648',450.61),
('Local Comercial','Av. Atahualpa 853','Jesus','PRT-11005685',496.05),
('Departamento','Av. Hoyos Rubio 149','Jesus','PRT-11005722',251.32),
('Local Comercial','Av. Via de Evitamiento 796','Cajamarca','PRT-11005759',423.62),
('Casa','Jr. Lima 462','Namora','PRT-11005796',492.32),
('Casa','Av. Atahualpa 246','Banos del Inca','PRT-11005833',349.59);

GO

INSERT INTO Vehiculo (Placa, Marca, Modelo, AnioFabricacion, NumeroTarjetaPropiedad) VALUES
('ABC-100','Toyota','Hilux',2017,'TP-772000'),
('BCD-107','Hyundai','Accent',2021,'TP-772053'),
('CDE-114','Nissan','Sentra',2017,'TP-772106'),
('DEF-121','Kia','Rio',2019,'TP-772159'),
('EFG-128','Chevrolet','Sail',2022,'TP-772212'),
('FGH-135','Suzuki','Alto',2018,'TP-772265'),
('GHI-142','Honda','CRV',2016,'TP-772318'),
('HIJ-149','Toyota','Yaris',2022,'TP-772371'),
('IJK-156','Hyundai','Tucson',2023,'TP-772424'),
('JKL-163','Kia','Sportage',2016,'TP-772477');

GO

INSERT INTO EscrituraPublica (NumeroEscritura, KardexNo, TipoActo, FechaEscritura, Tomo, Folio, IdNotario, IdColegioNotarios, IdArancel, Estado) VALUES
(1004,'KDX-2026-004','Compraventa','2026-01-18',12,161,3,3,1,'Vigente'),
(1005,'KDX-2026-005','Compraventa','2026-01-06',12,165,1,1,1,'Vigente'),
(1006,'KDX-2026-006','Poder','2026-01-07',12,169,2,2,2,'Vigente'),
(1007,'KDX-2026-007','Compraventa','2026-01-13',12,170,1,1,1,'Vigente'),
(1008,'KDX-2026-008','Poder','2026-02-26',13,174,2,2,2,'Vigente'),
(1009,'KDX-2026-009','Poder','2026-02-23',13,178,2,2,2,'Vigente'),
(1010,'KDX-2026-010','Compraventa','2026-02-10',13,180,1,1,1,'Vigente'),
(1011,'KDX-2026-011','Compraventa','2026-02-24',13,181,3,3,1,'Vigente'),
(1012,'KDX-2026-012','Testamento','2026-03-02',13,182,2,2,3,'Vigente'),
(1013,'KDX-2026-013','Testamento','2026-03-17',13,184,2,2,3,'Vigente'),
(1014,'KDX-2026-014','Compraventa','2026-03-03',13,186,3,3,1,'Vigente'),
(1015,'KDX-2026-015','Compraventa','2026-03-03',13,188,3,3,1,'Vigente'),
(1016,'KDX-2026-016','Poder','2026-04-19',14,190,1,1,2,'Vigente'),
(1017,'KDX-2026-017','Testamento','2026-04-02',14,191,3,3,3,'Vigente'),
(1018,'KDX-2026-018','Poder','2026-04-19',14,194,3,3,2,'Vigente'),
(1019,'KDX-2026-019','Poder','2026-04-22',14,197,1,1,2,'Vigente'),
(1020,'KDX-2026-020','Compraventa','2026-05-13',14,199,2,2,1,'Vigente'),
(1021,'KDX-2026-021','Testamento','2026-05-10',14,203,3,3,3,'Vigente'),
(1022,'KDX-2026-022','Poder','2026-05-01',14,207,1,1,2,'Vigente'),
(1023,'KDX-2026-023','Testamento','2026-05-04',14,208,3,3,3,'Vigente'),
(1024,'KDX-2026-024','Testamento','2026-06-17',15,211,1,1,3,'Vigente'),
(1025,'KDX-2026-025','Compraventa','2026-06-03',15,213,2,2,1,'Vigente'),
(1026,'KDX-2026-026','Poder','2026-06-06',15,217,2,2,2,'Vigente'),
(1027,'KDX-2026-027','Testamento','2026-06-10',15,218,3,3,3,'Vigente');

GO

INSERT INTO EscrituraTestigo (IdEscritura, IdTestigo) VALUES
(12,8),
(12,9),
(13,5),
(13,11),
(17,8),
(17,4),
(21,5),
(21,9),
(23,6),
(23,11),
(24,8),
(24,11),
(27,7),
(27,9),
(19,8),
(8,11),
(26,8);

GO

INSERT INTO CopiaCertificada (IdEscritura, TipoCopia, CantidadCopias, FechaSolicitud, Observacion) VALUES
(4,'Copia Simple',1,'2026-01-18','Para herederos'),
(5,'Copia Certificada',1,'2026-01-06','Solicitada por el cliente'),
(6,'Copia Certificada',1,'2026-01-07','Para SUNARP'),
(7,'Copia Simple',3,'2026-01-13','Para herederos'),
(8,'Copia Certificada',3,'2026-02-26','Solicitada por el cliente'),
(9,'Copia Simple',1,'2026-02-23','Para tramite bancario'),
(10,'Copia Simple',2,'2026-02-10','Uso personal'),
(11,'Copia Simple',2,'2026-02-24','Para tramite bancario'),
(12,'Copia Simple',2,'2026-03-02','Para SUNARP'),
(13,'Copia Simple',2,'2026-03-17','Para tramite bancario'),
(14,'Copia Simple',3,'2026-03-03','Solicitada por el cliente'),
(15,'Copia Certificada',3,'2026-03-03','Para herederos'),
(16,'Copia Simple',1,'2026-04-19','Para tramite bancario'),
(17,'Copia Simple',2,'2026-04-02','Solicitada por el cliente'),
(18,'Copia Simple',3,'2026-04-19','Para SUNARP'),
(19,'Copia Certificada',3,'2026-04-22','Para tramite bancario'),
(20,'Copia Certificada',1,'2026-05-13','Solicitada por el cliente'),
(21,'Copia Certificada',1,'2026-05-10','Para herederos'),
(22,'Copia Simple',1,'2026-05-01','Para herederos'),
(23,'Copia Certificada',2,'2026-05-04','Para tramite bancario'),
(24,'Copia Simple',1,'2026-06-17','Para tramite bancario'),
(25,'Copia Certificada',2,'2026-06-03','Para SUNARP'),
(26,'Copia Simple',2,'2026-06-06','Para SUNARP'),
(27,'Copia Certificada',3,'2026-06-10','Uso personal');

GO

INSERT INTO ContratoCompraventa (IdEscritura, FechaContrato, IdInmueble, IdVehiculo, IdVendedor, IdComprador, PrecioVenta, FormaPago) VALUES
(4,'2026-01-18',8,NULL,7,10,88570.85,'Financiado'),
(5,'2026-01-06',9,NULL,26,20,176567.21,'Financiado'),
(7,'2026-01-13',10,NULL,23,10,203920.76,'Contado'),
(10,'2026-02-10',12,NULL,20,7,208092.03,'Letras'),
(11,'2026-02-24',NULL,9,28,13,40877.84,'Letras'),
(14,'2026-03-03',NULL,5,26,17,58185.26,'Financiado'),
(15,'2026-03-03',9,NULL,28,20,124384.06,'Financiado'),
(20,'2026-05-13',10,NULL,13,20,168370.87,'Contado'),
(25,'2026-06-03',NULL,12,16,19,65023.51,'Financiado');

GO

INSERT INTO Poder (IdEscritura, TipoPoder, IdOtorgante, IdApoderado, Facultades, FechaOtorgamiento, FolioInicio, FolioFin, Estado) VALUES
(6,'Poder Especial',16,13,'Representacion judicial en proceso civil','2026-01-07',160,163,'Vigente'),
(8,'Poder General',21,28,'Representacion judicial en proceso civil','2026-02-26',164,166,'Vigente'),
(9,'Poder General',12,28,'Representacion en tramites municipales y notariales','2026-02-23',167,170,'Vigente'),
(16,'Poder General',26,17,'Vender un bien especifico a nombre del otorgante','2026-04-19',171,174,'Vigente'),
(18,'Poder General',13,11,'Administrar bienes y representar en tramites bancarios','2026-04-19',175,176,'Revocado'),
(19,'Poder Especial',26,9,'Cobro de deudas y gestion de pagos','2026-04-22',177,180,'Vigente'),
(22,'Poder Especial',19,22,'Vender un bien especifico a nombre del otorgante','2026-05-01',181,182,'Vigente'),
(26,'Poder Especial',7,10,'Vender un bien especifico a nombre del otorgante','2026-06-06',183,184,'Vigente');

GO

INSERT INTO Testamento (IdEscritura, TipoTestamento, IdTestador, IdTestigo1, IdTestigo2, FechaOtorga, HoraOtorga, Tomo, Folio, Estado) VALUES
(12,'Escritura Publica',23,8,9,'2026-03-02','16:00:00',13,11,'Registrado'),
(13,'Cerrado',10,5,11,'2026-03-17','16:15:00',13,12,'Registrado'),
(17,'Cerrado',28,8,4,'2026-04-02','14:45:00',13,13,'Registrado'),
(21,'Cerrado',24,5,9,'2026-05-10','16:15:00',13,14,'Registrado'),
(23,'Cerrado',21,6,11,'2026-05-04','13:15:00',13,15,'Registrado'),
(24,'Cerrado',23,8,11,'2026-06-17','16:15:00',13,16,'Registrado'),
(27,'Escritura Publica',21,7,9,'2026-06-10','10:30:00',13,17,'Registrado');

GO

INSERT INTO PartidaRegistral (NumeroPartida, OficinaRegistral, Registro, Asiento, IdCliente, DescripcionActo, FechaInscripcion, EstadoTramite) VALUES
('11000548','SUNARP Cajamarca','Registro de Propiedad','A0004',10,'Transferencia de propiedad','2026-01-18','Inscrito'),
('11000685','SUNARP Cajamarca','Registro de Propiedad','A0005',20,'Transferencia de propiedad','2026-01-06','Inscrito'),
('11000822','SUNARP Cajamarca','Registro de Propiedad','A0006',10,'Transferencia de propiedad','2026-01-13','Inscrito'),
('11000959','SUNARP Cajamarca','Registro de Propiedad','A0007',7,'Transferencia de propiedad','2026-02-10','Inscrito'),
('11001096','SUNARP Cajamarca','Registro de Propiedad','A0008',13,'Transferencia de propiedad','2026-02-24','Inscrito'),
('11001233','SUNARP Cajamarca','Registro de Propiedad','A0009',17,'Transferencia de propiedad','2026-03-03','Inscrito'),
('11001370','SUNARP Cajamarca','Registro de Propiedad','A0010',20,'Transferencia de propiedad',NULL,'En Trámite'),
('11001507','SUNARP Cajamarca','Registro de Propiedad','A0011',20,'Transferencia de propiedad','2026-05-13','Inscrito'),
('11001644','SUNARP Cajamarca','Registro de Propiedad','A0012',19,'Transferencia de propiedad','2026-06-03','Inscrito');
 
GO

INSERT INTO Tramite (IdCliente, IdEmpleado, IdTipoTramite, IdEscritura, IdCopiaCertificada, IdPartidaRegistral, IdContrato, FechaInicio, FechaFin, EstadoTramite) VALUES
(10,3,1,4,4,4,4,'2026-01-18','2026-01-18','Finalizado'),
(20,1,1,5,5,5,5,'2026-01-06','2026-01-06','Finalizado'),
(16,2,2,6,6,NULL,NULL,'2026-01-07','2026-01-07','Finalizado'),
(10,3,1,7,7,6,6,'2026-01-13',NULL,'Observado'),
(21,1,2,8,8,NULL,NULL,'2026-02-26',NULL,'En Proceso'),
(12,3,2,9,9,NULL,NULL,'2026-02-23','2026-02-23','Finalizado'),
(7,1,1,10,10,7,7,'2026-02-10',NULL,'Observado'),
(13,2,1,11,11,8,8,'2026-02-24',NULL,'En Proceso'),
(23,2,3,12,12,NULL,NULL,'2026-03-02','2026-03-02','Finalizado'),
(10,3,3,13,13,NULL,NULL,'2026-03-17','2026-03-17','Finalizado'),
(17,3,1,14,14,9,9,'2026-03-03',NULL,'En Proceso'),
(20,2,1,15,15,10,10,'2026-03-03','2026-03-03','Finalizado'),
(26,2,2,16,16,NULL,NULL,'2026-04-19','2026-04-19','Finalizado'),
(28,2,3,17,17,NULL,NULL,'2026-04-02','2026-04-02','Finalizado'),
(13,3,2,18,18,NULL,NULL,'2026-04-19',NULL,'En Proceso'),
(26,3,2,19,19,NULL,NULL,'2026-04-22','2026-04-22','Finalizado'),
(20,2,1,20,20,11,11,'2026-05-13',NULL,'Observado'),
(24,3,3,21,21,NULL,NULL,'2026-05-10','2026-05-10','Finalizado'),
(19,2,2,22,22,NULL,NULL,'2026-05-01','2026-05-01','Finalizado'),
(21,3,3,23,23,NULL,NULL,'2026-05-04','2026-05-04','Finalizado'),
(23,3,3,24,24,NULL,NULL,'2026-06-17','2026-06-17','Finalizado'),
(19,2,1,25,25,12,12,'2026-06-03','2026-06-03','Finalizado'),
(7,2,2,26,26,NULL,NULL,'2026-06-06','2026-06-06','Finalizado'),
(21,1,3,27,27,NULL,NULL,'2026-06-10','2026-06-10','Finalizado');

GO

DELETE FROM PartidaRegistral WHERE IdPartidaRegistral >= 4;

Select * from Cliente