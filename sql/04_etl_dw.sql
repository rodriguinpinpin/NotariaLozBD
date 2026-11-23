/* =====================================================================
   04_etl_dw.sql  ·  ETL NotariaPeru -> DW_NotariaLozano en T-SQL
   Estrategia: borrar y recargar (truncate-and-load) en una transacción.
   Uso:  EXEC etl.usp_EjecutarTodo;            -- fecha de corte por defecto 2026-11-22
   ===================================================================== */
USE DW_NotariaLozano;
GO

CREATE OR ALTER PROCEDURE etl.usp_CargarDimensiones @FechaInicio DATE, @FechaCorte DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- DIM_TIEMPO: todos los días del periodo (incluye domingos para que los ejes no se corten)
    ;WITH N AS (SELECT TOP (DATEDIFF(DAY, @FechaInicio, @FechaCorte) + 1) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
                FROM sys.all_objects a CROSS JOIN sys.all_objects b),
     F AS (SELECT DATEADD(DAY, n, @FechaInicio) AS f FROM N)
    INSERT INTO DIM_TIEMPO (ID_Tiempo, Fecha_Exacta, Mes, Nombre_Mes, Trimestre, Semestre, Anio, Dia, Nombre_Dia, Dia_Semana,
                            Semana, Es_Fin_De_Mes, Es_Dia_Habil, Anio_Mes, Orden_Mes, Mes_Corto, Trimestre_Texto,
                            Mes_Etiqueta, Mes_Completo)
    SELECT CONVERT(INT, CONVERT(CHAR(8), f, 112)), f, MONTH(f),
           CHOOSE(MONTH(f), 'Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'),
           DATEPART(QUARTER, f), IIF(MONTH(f) <= 6, 1, 2), YEAR(f), DAY(f),
           CHOOSE(ds, 'Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'), ds,
           DATEPART(ISO_WEEK, f), IIF(DAY(f) >= DAY(EOMONTH(f)) - 3, 1, 0), IIF(ds <= 6, 1, 0),
           CONVERT(CHAR(7), f, 126), YEAR(f) * 100 + MONTH(f),
           CHOOSE(MONTH(f), 'Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'),
           CONCAT('T', DATEPART(QUARTER, f), ' ', YEAR(f)),
           CASE WHEN EOMONTH(f) > @FechaCorte THEN CONCAT(m.Corto, ' (al ', DAY(@FechaCorte), ')')
                WHEN DATEFROMPARTS(YEAR(f), MONTH(f), 1) < @FechaInicio THEN CONCAT(m.Corto, ' (desde ', DAY(@FechaInicio), ')')
                ELSE m.Corto END,
           IIF(EOMONTH(f) <= @FechaCorte AND DATEFROMPARTS(YEAR(f), MONTH(f), 1) >= @FechaInicio, 1, 0)
    FROM F CROSS APPLY (SELECT DATEDIFF(DAY, '2024-01-01', f) % 7 + 1 AS ds) d   -- 2024-01-01 fue lunes
    CROSS APPLY (SELECT CHOOSE(MONTH(f), 'Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic') AS Corto) m;

    INSERT INTO DIM_CLIENTE (ID_Cliente, DNI_RUC, Razon_Social_Nombre, Tipo_Cliente, Distrito, Segmento)
    SELECT c.IdCliente, LTRIM(RTRIM(c.NumeroDocumento)),
           ISNULL(c.RazonSocial, LTRIM(RTRIM(c.Nombres)) + ' ' + LTRIM(RTRIM(c.Apellidos))),
           c.TipoPersona, c.Distrito,
           CASE WHEN t.n > 1 THEN 'Recurrente' WHEN t.n = 1 THEN 'Nuevo' ELSE 'Sin trámites' END
    FROM NotariaPeru.dbo.Cliente c
    OUTER APPLY (SELECT COUNT(*) n FROM NotariaPeru.dbo.Tramite x WHERE x.IdCliente = c.IdCliente) t;

    INSERT INTO DIM_PERSONAL (ID_Personal, Nombre_Completo, Cargo, Area)
    SELECT IdEmpleado, Nombres + ' ' + Apellidos, Cargo,
           CASE Cargo WHEN 'Abogado' THEN 'Legal' WHEN 'Redactor' THEN 'Protocolo' WHEN 'Asistente notarial' THEN 'Protocolo'
                      WHEN 'Cajera' THEN 'Caja' WHEN 'Archivero' THEN 'Archivo' ELSE 'Atención al cliente' END
    FROM NotariaPeru.dbo.Empleado;

    INSERT INTO DIM_SERVICIO (ID_Servicio, Nombre_Tramite, Categoria, Descripcion)
    SELECT IdTipoTramite, NombreTramite, Categoria, Descripcion FROM NotariaPeru.dbo.TipoTramite;

    INSERT INTO DIM_METODO_PAGO (ID_Metodo, Tipo_Pago, Plataforma, Canal) VALUES
    (1, 'Efectivo', 'Caja', 'Efectivo'), (2, 'Yape', 'Billetera digital', 'Digital'), (3, 'Plin', 'Billetera digital', 'Digital'),
    (4, 'Transferencia', 'Banca por internet', 'Digital'), (5, 'Tarjeta', 'POS', 'Digital');

    INSERT INTO DIM_ESTADO_PAGO (ID_Estado_Pago, Estado) VALUES (1, 'Pagado'), (2, 'Pendiente'), (3, 'Anulado');

    INSERT INTO DIM_NOTARIO (ID_Notario, Nombre_Completo, Colegio_Notarios, Rol)
    SELECT n.IdNotario, n.Nombres + ' ' + n.Apellidos, cn.NombreColegio, n.Rol
    FROM NotariaPeru.dbo.Notario n JOIN NotariaPeru.dbo.ColegioNotarios cn ON cn.IdColegioNotarios = n.IdColegioNotarios;

    INSERT INTO DIM_ETAPA_TRAMITE (ID_Etapa, Nombre_Etapa, Descripcion, Orden) VALUES
    (1, 'Recepción', 'Ingreso del expediente en mesa de partes', 1),
    (2, 'Revisión y redacción', 'Calificación, redacción de minuta o documento', 2),
    (3, 'Firma', 'Firma de otorgantes y autorización notarial', 3),
    (4, 'Entrega', 'Entrega de testimonio, copias o documento legalizado', 4);

    INSERT INTO DIM_TURNO (ID_Turno, Nombre_Turno, Rango_Horario) VALUES (1, 'Mañana', '08:00 - 13:00'), (2, 'Tarde', '14:00 - 19:00');

    INSERT INTO DIM_TIPO_DOCUMENTO (ID_TipoDocumento, Nombre_TipoDocumento, Descripcion) VALUES
    (1, 'Testimonio de escritura', 'Traslado de la escritura pública entregado al cliente'),
    (2, 'Parte registral', 'Parte enviado a SUNARP para inscripción'),
    (3, 'Copia certificada', 'Copia certificada de escritura'),
    (4, 'Copia simple', 'Copia simple de escritura'),
    (5, 'Firma legalizada', 'Firma legalizada en documento privado');
END;
GO

CREATE OR ALTER PROCEDURE etl.usp_CargarHechos
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO FACT_TRAMITE_GENERAL (Nro_Tramite, ID_Tiempo, ID_Servicio, ID_Notario, ID_Cliente, ID_Personal, ID_Estado_Pago,
                                      Monto_Pagado, Monto_Arancel, Cantidad_Tramites, Estado_Tramite, Dias_Duracion, ID_Turno, ID_Metodo)
    SELECT t.IdTramite, CONVERT(INT, CONVERT(CHAR(8), t.FechaInicio, 112)), t.IdTipoTramite, t.IdNotario, t.IdCliente, t.IdEmpleado,
           CASE WHEN t.EstadoTramite = 'Anulado' THEN 3 WHEN pg.Pendiente > 0 THEN 2 ELSE 1 END,
           ISNULL(pg.Pagado, 0), ISNULL(pg.Emitido, 0), 1, t.EstadoTramite,
           DATEDIFF(DAY, t.FechaInicio, t.FechaFin), IIF(t.HoraInicio < '13:00', 1, 2), m.ID_Metodo
    FROM NotariaPeru.dbo.Tramite t
    OUTER APPLY (SELECT SUM(IIF(p.Estado = 'Pagado', p.Monto, 0)) Pagado, SUM(IIF(p.Estado = 'Pendiente', 1, 0)) Pendiente, SUM(p.Monto) Emitido
                 FROM NotariaPeru.dbo.Pago p WHERE p.IdTramite = t.IdTramite) pg
    OUTER APPLY (SELECT TOP 1 p.MetodoPago FROM NotariaPeru.dbo.Pago p WHERE p.IdTramite = t.IdTramite ORDER BY p.IdPago) mp
    LEFT JOIN DIM_METODO_PAGO m ON m.Tipo_Pago = mp.MetodoPago;

    INSERT INTO FACT_TRAMITES_FINANCIEROS (ID_Cliente, ID_Servicio, ID_Tiempo, ID_Personal, ID_Metodo, Monto_Cobrado, Costo_Asociado,
                                           Cantidad, Nro_Tramite, ID_Estado_Pago, Monto_Pendiente, Monto_Comprobante, ID_Turno, ID_Notario)
    SELECT t.IdCliente, t.IdTipoTramite, CONVERT(INT, CONVERT(CHAR(8), p.FechaPago, 112)), t.IdEmpleado, m.ID_Metodo,
           IIF(p.Estado = 'Pagado', p.Monto, 0),
           ROUND(IIF(p.Estado = 'Pagado', p.Monto, 0) * tt.PorcentajeCosto, 2),
           1, t.IdTramite, e.ID_Estado_Pago, IIF(p.Estado = 'Pendiente', p.Monto, 0), p.Monto,
           IIF(t.HoraInicio < '13:00', 1, 2), t.IdNotario
    FROM NotariaPeru.dbo.Pago p
    JOIN NotariaPeru.dbo.Tramite t ON t.IdTramite = p.IdTramite
    JOIN NotariaPeru.dbo.TipoTramite tt ON tt.IdTipoTramite = t.IdTipoTramite
    JOIN DIM_METODO_PAGO m ON m.Tipo_Pago = p.MetodoPago
    JOIN DIM_ESTADO_PAGO e ON e.Estado = p.Estado;

    INSERT INTO FACT_TIEMPOS_ATENCION (ID_Servicio, ID_Personal, ID_Tiempo, ID_Etapa, ID_Turno, Minutos_Espera, Minutos_Proceso, Minutos_Totales,
                                       Nro_Tramite, ID_Cliente, ID_Notario)
    SELECT t.IdTipoTramite, a.IdEmpleado, CONVERT(INT, CONVERT(CHAR(8), CAST(a.InicioEspera AS DATE), 112)), a.OrdenEtapa,
           IIF(t.HoraInicio < '13:00', 1, 2), x.Espera, x.Proceso, x.Espera + x.Proceso, t.IdTramite, t.IdCliente, t.IdNotario
    FROM NotariaPeru.dbo.AtencionEtapa a
    JOIN NotariaPeru.dbo.Tramite t ON t.IdTramite = a.IdTramite
    CROSS APPLY (SELECT DATEDIFF(MINUTE, a.InicioEspera, a.InicioProceso) Espera, DATEDIFF(MINUTE, a.InicioProceso, a.Fin) Proceso) x;

    -- Documentos otorgados (solo trámites no anulados)
    ;WITH D AS (
        -- Testimonio: escrituras finalizadas
        SELECT t.IdTramite, 1 AS TipoDoc, t.FechaFin AS Fecha, 1 AS Cant
        FROM NotariaPeru.dbo.Tramite t WHERE t.IdEscritura IS NOT NULL AND t.EstadoTramite = 'Finalizado'
        UNION ALL
        -- Parte registral: partidas inscritas
        SELECT t.IdTramite, 2, pr.FechaInscripcion, 1
        FROM NotariaPeru.dbo.Tramite t JOIN NotariaPeru.dbo.PartidaRegistral pr ON pr.IdPartidaRegistral = t.IdPartidaRegistral
        WHERE pr.EstadoTramite = 'Inscrito' AND t.EstadoTramite <> 'Anulado'
        UNION ALL
        -- Copias certificadas o simples
        SELECT t.IdTramite, IIF(cc.TipoCopia = 'Copia Simple', 4, 3), cc.FechaSolicitud, cc.CantidadCopias
        FROM NotariaPeru.dbo.Tramite t JOIN NotariaPeru.dbo.CopiaCertificada cc ON cc.IdCopiaCertificada = t.IdCopiaCertificada
        WHERE t.EstadoTramite <> 'Anulado'
        UNION ALL
        -- Firmas legalizadas
        SELECT t.IdTramite, 5, l.FechaLegalizacion, l.CantidadFirmas
        FROM NotariaPeru.dbo.Tramite t JOIN NotariaPeru.dbo.LegalizacionFirma l ON l.IdLegalizacion = t.IdLegalizacion
        WHERE t.EstadoTramite <> 'Anulado')
    INSERT INTO FACT_DOCUMENTOS_OTORGADOS (ID_Servicio, ID_Personal, ID_Tiempo, ID_TipoDocumento, ID_Cliente, Cantidad_Documentos, Nro_Tramite,
                                           ID_Turno, ID_Notario)
    SELECT t.IdTipoTramite, t.IdEmpleado, CONVERT(INT, CONVERT(CHAR(8), D.Fecha, 112)), D.TipoDoc, t.IdCliente, D.Cant, t.IdTramite,
           IIF(t.HoraInicio < '13:00', 1, 2), t.IdNotario
    FROM D JOIN NotariaPeru.dbo.Tramite t ON t.IdTramite = D.IdTramite;
END;
GO

CREATE OR ALTER PROCEDURE etl.usp_EjecutarTodo @FechaInicio DATE = '2026-06-01', @FechaCorte DATE = '2026-11-22'
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @id INT;
    INSERT INTO ETL_Auditoria (Paquete, Inicio, Estado) VALUES ('etl.usp_EjecutarTodo', SYSDATETIME(), 'En curso');
    SET @id = SCOPE_IDENTITY();
    BEGIN TRY
        BEGIN TRAN;
            DELETE FROM FACT_TRAMITE_GENERAL;  DELETE FROM FACT_TRAMITES_FINANCIEROS;
            DELETE FROM FACT_TIEMPOS_ATENCION; DELETE FROM FACT_DOCUMENTOS_OTORGADOS;
            DELETE FROM DIM_TIEMPO;  DELETE FROM DIM_CLIENTE; DELETE FROM DIM_PERSONAL; DELETE FROM DIM_SERVICIO;
            DELETE FROM DIM_METODO_PAGO; DELETE FROM DIM_ESTADO_PAGO; DELETE FROM DIM_NOTARIO;
            DELETE FROM DIM_ETAPA_TRAMITE; DELETE FROM DIM_TURNO; DELETE FROM DIM_TIPO_DOCUMENTO;
            EXEC etl.usp_CargarDimensiones @FechaInicio, @FechaCorte;
            EXEC etl.usp_CargarHechos;
        COMMIT;
        UPDATE ETL_Auditoria SET Fin = SYSDATETIME(), Estado = 'Exito',
            Filas = (SELECT COUNT(*) FROM FACT_TRAMITE_GENERAL) + (SELECT COUNT(*) FROM FACT_TRAMITES_FINANCIEROS)
                  + (SELECT COUNT(*) FROM FACT_TIEMPOS_ATENCION) + (SELECT COUNT(*) FROM FACT_DOCUMENTOS_OTORGADOS)
        WHERE Id = @id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        UPDATE ETL_Auditoria SET Fin = SYSDATETIME(), Estado = 'Error', Mensaje = ERROR_MESSAGE() WHERE Id = @id;
        THROW;
    END CATCH
END;
GO
EXEC etl.usp_EjecutarTodo;
GO
PRINT '04_etl_dw: ETL ejecutado';
