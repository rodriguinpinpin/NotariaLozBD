# Diseño: Base de datos ampliada y dashboard profesional — Notaría Lozano

Fecha: 2026-11-22 · Carpeta: `BD_NOTARIALOZ`

## 1. Intención y por qué

Proyecto académico (Base de Datos Avanzadas y Big Data, 2026-2). El informe
`INFORME FINAL NOTARIA LOZANO.docx` define 8 preguntas de negocio y 3 dashboards
(finanzas, operaciones, documentos). El dashboard actual se ve plano porque los
hechos se cargan con montos fijos (`350.00` / `50.00`) y claves aleatorias
(`NEWID()` en `SQLQuery10.sql`): línea mensual recta, 7 trámites por mes, todo
"Pagado", legalización de S/ 18 cobrando S/ 350. Además la base no existe en el
SQL Server local y faltan scripts de varias dimensiones.

Objetivo: una base coherente con más datos que responda bien las 8 preguntas, y
un reporte de Power BI conectado a SQL Server local, más profesional, limpio,
interactivo, con imágenes y movimiento.

## 2. Metas, no-metas, anti-metas

**Metas**
- Base reproducible desde cero ejecutando scripts en orden.
- Datos **solo de los últimos 6 meses: 2026-06-01 a 2026-11-22** (decisión del usuario).
- Volumen: ~800 trámites, ~200 clientes, 10 empleados, 3 notarios, 8 servicios.
- Data warehouse separado `DW_NotariaLozano` (como describe el informe) cargado por ETL en T-SQL.
- Reporte responde las 8 preguntas del informe con visuales explícitos.
- Power BI conectado a `.\SQLEXPRESS` (importación, autenticación Windows) y actualizable con "Actualizar".

**No-metas**
- No se modifica el paquete SSIS existente (`ETL_DIM_CLIENTE.dtsx`, no está en la carpeta).
- No se publica en Power BI Service.
- No se actualiza el informe Word en esta tarea (las cifras cambiarán; se puede hacer después).
- Solución Big Data: fuera de alcance.

**Anti-metas (sería un fracaso aunque "funcione")**
- Datos que se vean aleatorios o planos (montos iguales, conteos idénticos por mes).
- Cifras que no cuadren entre SQL y Power BI con los mismos filtros.
- Dashboard recargado o con efectos que distraigan de leer las cifras.
- Datos personales que parezcan reales (todo es ficticio; DNIs en rango ficticio).

## 3. Restricciones

- SQL Server 2025 Express en `.\SQLEXPRESS` (instancia `RODZ\SQLEXPRESS`), `sqlcmd` disponible.
- Power BI Desktop versión Microsoft Store; el .pbix ya usa formato PBIR.
- Sin licencias pagas ni visuales de pago. Sin descargar visuales del marketplace salvo aprobación expresa.
- Power BI no tiene animaciones libres: el "movimiento" se logra con lo nativo (abajo).
- Mantener nombres de tablas/columnas del modelo estrella actual (`MODELOS ESTRELLA.sql`) para que el informe y el SSIS sigan siendo válidos; solo se **agregan** columnas.

## 4. Enfoques considerados

| Enfoque | Qué es | Trade-off |
|---|---|---|
| **A. PBIP + scripts (elegido)** | Guardar el .pbix como .pbip y editar modelo (TMDL) y visuales (PBIR) como texto; SQL nuevo con generador y ETL | Control total y reproducible; requiere un "Guardar como .pbip" en Power BI Desktop |
| B. Todo con clics (control de pantalla) | Construir en Power BI Desktop clic a clic | Lento y frágil con 40+ visuales |
| C. Solo datos | Regenerar datos y repuntar el .pbix actual | Rápido, pero el diseño casi no mejora |

El usuario eligió **A**.

## 5. Diseño de la base de datos

### 5.1 Archivos nuevos (carpeta `sql/`, en orden de ejecución)
1. `01_crear_oltp.sql` — crea `NotariaPeru` (esquema actual consolidado; `LibroKardex`, `Pago`, `LegalizacionFirma`, `Hipoteca` incluidos sin duplicar). Agrega a `Tramite`: `HoraInicio TIME`, `Turno` derivable; agrega tabla `AtencionEtapa` (IdTramite, Etapa, InicioEspera, InicioProceso, Fin) para tiempos reales.
2. `02_datos_oltp.sql` — generador determinista (sin `NEWID()`; usa números de fila y fórmulas) para 2026-06-01..2026-11-22.
3. `03_crear_dw.sql` — crea `DW_NotariaLozano` con el modelo estrella actual + columnas nuevas + `ETL_Auditoria`.
4. `04_etl_dw.sql` — procedimientos `etl.usp_CargarDimensiones`, `etl.usp_CargarHechos`, `etl.usp_EjecutarTodo` (truncate-and-load, registra en `ETL_Auditoria`).
5. `05_validacion.sql` — conteos, nulos, FKs huérfanas, y totales de referencia para conciliar con Power BI.

Los scripts antiguos se conservan sin cambios en la raíz (evidencia del informe).

### 5.2 Datos (reglas de generación)
- **Calendario:** solo días hábiles lunes–sábado (sábado medio turno); `DIM_TIEMPO` cubre todo el rango día por día, incluyendo días sin trámites.
- **Servicios (8):** Compraventa de inmueble, Transferencia vehicular, Poder, Testamento, Hipoteca, Constitución de empresa, Legalización de firma, Copia certificada. Categorías: *Escrituras públicas* (protocolares) vs *Extraprotocolares*. Montos desde `Arancel`/`CostoBase` con variación por complejidad (±0–25 %); legalización = S/ 18 × firmas.
- **Costo asociado:** % por servicio (insumos, registros, tasas SUNARP) para poder calcular margen.
- **Demanda con forma:** tendencia creciente moderada, picos a fin de mes y en julio (gratificación) y noviembre; legalizaciones son las más frecuentes, testamentos las menos.
- **Personal (10):** Notario titular, 2 abogados/asistentes legales, 2 redactores, 2 secretarias, 1 cajera, 1 mesa de partes, 1 archivero; cada cargo atiende servicios acordes.
- **Clientes (~200):** ~85 % natural, ~15 % jurídica; distritos de Cajamarca; clientes recurrentes (empresas y algunos naturales) además de únicos.
- **Pagos:** método según tipo de cliente (empresas → transferencia; naturales → efectivo/Yape/tarjeta); estados Pagado/Pendiente/Anulado coherentes con el estado del trámite; algunos pagos parciales.
- **Tiempos:** 4 etapas (Recepción, Revisión/Redacción, Firma, Entrega); espera mayor en turno tarde y fin de mes; proceso según servicio. `Minutos_Totales = Espera + Proceso` (garantizado).
- **Documentos otorgados:** se derivan del trámite (escritura/testimonio, copias, partes registrales, legalizaciones) con su tipo documental real.

### 5.3 Data warehouse
Mismas tablas de `MODELOS ESTRELLA.sql`. Columnas agregadas:
- `DIM_TIEMPO`: `Dia`, `Nombre_Dia`, `Dia_Semana`, `Semana`, `Es_Fin_De_Mes`, `Anio_Mes` (texto `2026-06`), `Orden_Mes`.
- `DIM_CLIENTE`: `Distrito`, `Segmento` (Nuevo/Recurrente).
- `DIM_PERSONAL`: `Area`.
- `DIM_SERVICIO`: `Categoria` pasa a ser categoría real (antes guardaba la descripción); se agrega `Descripcion`.
- `FACT_TRAMITE_GENERAL`: `Estado_Tramite`, `Dias_Duracion`.
- `FACT_TIEMPOS_ATENCION`: `Nro_Tramite` (para trazabilidad).
- `FACT_TRAMITES_FINANCIEROS`: `Nro_Tramite`, `ID_Estado_Pago`.

Granularidad: financieros = 1 fila por pago; tiempos = 1 fila por trámite × etapa; documentos = 1 fila por trámite × tipo documental; general = 1 fila por trámite.

## 6. Diseño del reporte Power BI

### 6.1 Conexión y modelo
- Archivo de trabajo: `powerbi/NOTARIA_LOZANO.pbip` (copia; el `.pbix` original se conserva intacto).
- Origen: `Sql.Database(".\SQLEXPRESS", "DW_NotariaLozano")`, modo Importación.
- Relaciones uno-a-varios desde dimensiones; `DIM_TIEMPO` marcada como tabla de fechas; jerarquía Año › Trimestre › Mes › Día.
- Tabla `_Medidas` con carpetas: Finanzas, Operaciones, Documentos, Clientes, Visual (SVG/colores).
- Medidas nuevas además de las actuales: Margen, % Margen, Variación mensual (sin depender de seleccionar un mes: compara con el mes anterior en el contexto), Ticket medio, % Efectivo, Trámites por cargo (escrituras públicas), Tasa de finalización, Días promedio de duración, Clientes únicos/recurrentes, Ranking de servicio, colores condicionales.

### 6.2 Páginas
1. **Resumen ejecutivo (nueva):** 6 tarjetas KPI con tendencia, ingresos vs costo por mes, top servicios, mapa de calor día × turno, botones a cada área.
2. **Gestión financiera e ingresos** (preguntas 1, 2, 3).
3. **Eficiencia operacional y tiempos** (preguntas 7, 8).
4. **Producción documental y trámites** (preguntas 4, 5, 6).
5. **Clientes (nueva):** natural vs jurídica, recurrencia, distritos, top clientes.
6. **Tooltip** (oculta): mini-detalle al pasar el mouse sobre servicios/meses.

Las 3 páginas existentes conservan su estructura general (menú lateral, encabezado, filtros arriba, KPIs, 6 gráficos, detalle) pero se rediseñan.

### 6.3 Look & feel, imágenes y movimiento
- Paleta institucional actual (azul `#0876AA` / `#173D64`, rojo `#BE263E`, turquesa `#168D9C`), más aire, tipografía Segoe UI, bordes redondeados y sombras suaves.
- **Imágenes:** fondos nuevos 1920×1080 por página (PNG generados), logo actual, íconos SVG por KPI y por servicio, ilustración en el encabezado.
- **Movimiento (nativo):** animación de carga/filtrado de los gráficos; botones de navegación con estados hover/presionado; panel de filtros que se abre/cierra con marcadores; mini-gráficos SVG en tarjetas KPI; tooltips de página; botón "Restablecer filtros".
- Lienzo 1920×1080 (16:9) en lugar del actual 1920×1280.

## 7. Verificación
- `05_validacion.sql` produce totales de referencia (importe, trámites, documentos, minutos promedio por página y por las 8 preguntas).
- Cada total se compara con la medida DAX equivalente (consulta DAX o lectura visual).
- Captura de cada página tras actualizar; revisión de que no haya visuales con error ni en blanco.

## 7b. Decisiones tomadas tras la revisión (criterio de Claude, corregibles)
- **Ingresos:** `Importe cobrado` = suma de pagos con estado *Pagado* (dinero recibido). `Importe facturado` = suma de `Monto_Arancel` de trámites no anulados. `Por cobrar` = pagos *Pendiente*. Los *Anulado* no suman en ningún KPI. Margen = cobrado − costo asociado de esos mismos pagos. `05_validacion.sql` usa exactamente estas definiciones.
- **Tablas estrella en `NotariaPeru`:** no se recrean; el DW vive solo en `DW_NotariaLozano` (como dice el informe: ETL de NotariaPeru → DW). Si se reutiliza el SSIS, basta con apuntar su conexión destino al DW; los nombres de columnas originales se conservan.
- **Noviembre parcial (hasta el 22):** no se fuerza un pico en noviembre. La variación mensual compara el mes contra los mismos días transcurridos del mes anterior (mes a la fecha), para no mostrar una caída falsa. El pico estacional queda en julio y fin de cada mes.
- **Notarios:** la notaría tiene 1 notario titular (Notario Lozano) y 1 notario suplente que firma en sus ausencias (~10 % de escrituras). Ambos solo en `DIM_NOTARIO`; los 10 empleados de `DIM_PERSONAL` no incluyen al notario. Los otros colegios se mantienen como catálogo.
- **Pasos en Power BI Desktop:** los hace Claude con control de pantalla (decisión del usuario), pidiendo acceso a Power BI Desktop.
- **Preguntas de negocio:** tomadas del informe (Tablas 5–12), con el mapeo a páginas de la sección 6.2.

## 8. Lo que queda a criterio del constructor
- Nombres exactos de clientes/empleados ficticios, fórmulas concretas del generador.
- Disposición fina de cada visual, tamaños y textos de ayuda.
- Qué tipo de gráfico usar para cada análisis, mientras responda la pregunta.

## 9. Riesgos
- Power BI Desktop (Store) debe tener habilitado "Guardar como proyecto (.pbip)"; si no, se activa en Opciones › Características en vista previa.
- Ediciones de TMDL/PBIR con errores impiden abrir el proyecto: validar abriendo en Desktop tras cada bloque de cambios.
- El paso de abrir/guardar en Desktop requiere control de pantalla (con permiso) o un par de clics del usuario.
