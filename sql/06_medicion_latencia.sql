USE DW_NotariaLozano;
GO
SET NOCOUNT ON;

CREATE TABLE #res (Escala VARCHAR(30), Filas BIGINT, Rep INT, Ms DECIMAL(12,3));
CREATE TABLE #prueba (ID_Servicio INT, Estado_Tramite VARCHAR(20));

DECLARE @escalas TABLE (Escala VARCHAR(30), Filas BIGINT);
INSERT @escalas VALUES ('Escala 1 (x1)', 27), ('Escala 2 (x1,000)', 27000), ('Escala 3 (x10,000)', 270000);

DECLARE @escala VARCHAR(30), @filas BIGINT, @base INT, @copias INT, @rep INT, @t0 DATETIME2(7);
SELECT @base = COUNT(*) FROM dbo.FACT_TRAMITE_GENERAL;

DECLARE c CURSOR FOR SELECT Escala, Filas FROM @escalas ORDER BY Filas;
OPEN c; FETCH NEXT FROM c INTO @escala, @filas;
WHILE @@FETCH_STATUS = 0
BEGIN
    TRUNCATE TABLE #prueba;
    SET @copias = CEILING(@filas * 1.0 / @base);

    ;WITH n AS (
        SELECT TOP (@copias) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS r
        FROM sys.all_objects a CROSS JOIN sys.all_objects b
    )
    INSERT #prueba
    SELECT TOP (@filas) g.ID_Servicio, g.Estado_Tramite
    FROM dbo.FACT_TRAMITE_GENERAL g CROSS JOIN n;

    -- Repetición 0 = calentamiento (no se guarda); 1 a 5 = mediciones
    SET @rep = 0;
    WHILE @rep <= 5
    BEGIN
        SET @t0 = SYSDATETIME();
        SELECT s.Nombre_Tramite, p.Estado_Tramite, COUNT(*) AS Cantidad
        INTO #salida
        FROM #prueba p
        JOIN dbo.DIM_SERVICIO s ON s.ID_Servicio = p.ID_Servicio
        GROUP BY s.Nombre_Tramite, p.Estado_Tramite;

        IF @rep > 0
            INSERT #res VALUES (@escala, @filas, @rep,
                DATEDIFF_BIG(MICROSECOND, @t0, SYSDATETIME()) / 1000.0);
        DROP TABLE #salida;
        SET @rep += 1;
    END

    FETCH NEXT FROM c INTO @escala, @filas;
END
CLOSE c; DEALLOCATE c;

SELECT Escala, Filas,
       CAST(AVG(Ms) AS DECIMAL(12,1))                      AS Latencia_media_ms,
       CAST(Filas / (AVG(Ms) / 1000.0) AS BIGINT)          AS Throughput_filas_s
FROM #res
GROUP BY Escala, Filas
ORDER BY Filas;

SELECT @@VERSION AS Version_SQL_Server;   -- para la Tabla 24

DROP TABLE #res; DROP TABLE #prueba;