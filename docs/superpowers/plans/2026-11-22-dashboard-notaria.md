# Base ampliada y dashboard profesional — Notaría Lozano · Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Regenerar la base `NotariaPeru` con 6 meses de datos coherentes, construir `DW_NotariaLozano` con ETL en T-SQL y rehacer el reporte de Power BI (PBIP) conectado a SQL Server local.

**Architecture:** Scripts T-SQL numerados en `sql/` crean OLTP → datos → DW → ETL → validación; las pruebas son scripts T-SQL que lanzan `THROW` si una regla falla (`sqlcmd -b`). El reporte se convierte a `.pbip`; el modelo se edita en TMDL y los visuales en PBIR; las medidas se verifican con consultas DAX contra el motor local de Power BI Desktop.

**Tech Stack:** SQL Server 2025 Express (`.\SQLEXPRESS`, auth Windows), `sqlcmd`, Power BI Desktop (Store) con PBIP/TMDL/PBIR, PowerShell 5.1, Python (Pillow) para imágenes, computer-use para Power BI Desktop.

**Spec:** `docs/superpowers/specs/2026-11-22-dashboard-notaria-design.md`

## Global Constraints

- Rango de datos: **2026-06-01 a 2026-11-22**, nada fuera de él.
- Volumen: ~800 trámites (700–900), ~200 clientes (85 % Natural / 15 % Jurídica), 10 empleados, 2 notarios (titular Lozano + suplente ~10 % de escrituras), 8 servicios.
- Servicios: Compraventa de inmueble, Transferencia vehicular, Poder, Testamento, Hipoteca, Constitución de empresa, Legalización de firma, Copia certificada. Categorías: `Escrituras públicas` / `Extraprotocolares`.
- Legalización = S/ 18 × firmas. Otros montos = arancel/costo base ± 0–25 %.
- `Minutos_Totales = Minutos_Espera + Minutos_Proceso` siempre.
- Importe cobrado = pagos `Pagado`; Facturado = `Monto_Arancel` de trámites no `Anulado`; Por cobrar = pagos `Pendiente`; `Anulado` no suma.
- Variación mensual = mes a la fecha vs mismos días del mes anterior.
- Generador determinista: prohibido `NEWID()`/`RAND()` sin semilla; usar fórmulas sobre números de fila.
- Nombres de tablas/columnas de `MODELOS ESTRELLA.sql` se conservan; solo se agregan columnas.
- Scripts antiguos de la raíz y `NOTARIA_LOZANO_COLOR.pbix` no se modifican.
- Lienzo 1920×1080; paleta `#0876AA`, `#173D64`, `#BE263E`, `#168D9C`, `#8196B0`, `#D5A76F`; Segoe UI.
- Sin visuales del marketplace ni descargas.
- La carpeta no es repositorio git: los pasos "Commit" se omiten salvo que el usuario pida inicializar git.

## Review Focus

1. Re-ejecutar los scripts sobre una base ya existente → deben recrear limpio (DROP IF EXISTS), sin duplicados. Prueba en Task 1 y Task 3.
2. Ejecutar el ETL dos veces → mismos totales (idempotente). Prueba en Task 3.
3. Días sin trámites (domingos) → existen en `DIM_TIEMPO` y los gráficos no se cortan. Prueba en Task 3.
4. Filtrar un mes sin mes anterior (junio) → variación en blanco, no error ni infinito. Prueba en Task 5.
5. Trámite anulado con pago anulado → no aparece en cobrado, facturado ni por cobrar. Prueba en Task 2 y Task 5.

---

### Task 1: Esquema OLTP `NotariaPeru`

**Files:**
- Create: `sql/01_crear_oltp.sql`
- Create: `sql/tests/t01_oltp.sql`
- Create: `sql/run.ps1` (ejecuta un script con `sqlcmd -S .\SQLEXPRESS -E -C -b -i <archivo>`)

**Interfaces:**
- Produces: base `NotariaPeru` con las 21 tablas de `Base De Datos Notaria(Completo) (1).sql` + `Tramite.HoraInicio TIME NOT NULL` + tabla `AtencionEtapa(IdAtencion PK, IdTramite FK, Etapa VARCHAR(30), InicioEspera DATETIME2, InicioProceso DATETIME2, Fin DATETIME2)`; `TipoTramite.Categoria VARCHAR(30)`; `Pago.MetodoPago` admite además `'Plin'`.

- [ ] **Step 1: Prueba** `t01_oltp.sql`: `THROW` si `(SELECT COUNT(*) FROM sys.tables) <> 22` (21 originales + `AtencionEtapa`), si falta la columna `Tramite.HoraInicio`, o si falta `AtencionEtapa`.
- [ ] **Step 2:** `./sql/run.ps1 sql/tests/t01_oltp.sql` → falla (la base no existe).
- [ ] **Step 3:** Escribir `01_crear_oltp.sql`: `DROP DATABASE IF EXISTS NotariaPeru` (con `SET SINGLE_USER WITH ROLLBACK IMMEDIATE` si existe), crear todo en un solo script sin repetir las tablas de `EntidadesNuevas.sql`.
- [ ] **Step 4:** Ejecutar 01 dos veces seguidas y luego la prueba → PASS.

### Task 2: Generador de datos OLTP

**Files:**
- Create: `sql/02_datos_oltp.sql`
- Create: `sql/tests/t02_datos.sql`

**Interfaces:**
- Consumes: esquema de Task 1.
- Produces: datos con las reglas de la sección 5.2 del spec. Estados de trámite: `Finalizado`, `En Proceso`, `Observado`, `Anulado`. Etapas de `AtencionEtapa`: `Recepción`, `Revisión y redacción`, `Firma`, `Entrega`. Turnos: mañana 08:00–13:00, tarde 14:00–19:00; sábado solo mañana.

- [ ] **Step 1: Prueba** `t02_datos.sql`, cada una con `THROW` si falla:
  - `MIN(FechaInicio) >= '2026-06-01' AND MAX(FechaInicio) <= '2026-11-22'`
  - `COUNT(Tramite) BETWEEN 700 AND 900`; `COUNT(Cliente) BETWEEN 180 AND 220`; `COUNT(Empleado) = 10`; `COUNT(Notario) = 2`; `COUNT(TipoTramite) = 8`
  - Ningún trámite en domingo; ninguno sábado ≥ 13:00
  - Legalizaciones: `Pago.Monto = 18 * CantidadFirmas` para pagos no anulados
  - `COUNT(DISTINCT Monto)` de pagos > 50 (no montos planos)
  - Conteo de trámites por mes: desviación estándar > 5 % del promedio (no conteos idénticos); julio > junio
  - Clientes jurídicos: ≥ 60 % de sus pagos por `Transferencia`
  - Trámite `Anulado` ⇒ su pago `Anulado`; trámite `En Proceso` ⇒ pago `Pendiente` o parcial
  - 4 filas `AtencionEtapa` por trámite no anulado; `InicioEspera < InicioProceso < Fin`
  - Turno tarde: espera media > turno mañana
  - El texto del script no contiene `NEWID(` ni `RAND(` (verificado en `run.ps1` con `Select-String` antes de ejecutar 02)
- [ ] **Step 2:** Ejecutar la prueba → falla.
- [ ] **Step 3:** Escribir `02_datos_oltp.sql`: tabla de números con `ROW_NUMBER()`, calendario de días hábiles, demanda diaria = base por servicio × factor fin de mes × factor julio × tendencia; asignar empleado por cargo/servicio; nombres de una lista fija combinada por índice. DNIs ficticios en el rango `76000000–76999999`.
- [ ] **Step 4:** `01` + `02` + prueba → PASS.

### Task 3: Data warehouse `DW_NotariaLozano` y ETL

**Files:**
- Create: `sql/03_crear_dw.sql`, `sql/04_etl_dw.sql`
- Create: `sql/tests/t03_dw.sql`

**Interfaces:**
- Consumes: `NotariaPeru` (Tasks 1–2).
- Produces: tablas de `MODELOS ESTRELLA.sql` con las columnas nuevas de la sección 5.3 del spec; `ETL_Auditoria(Id, Paquete, Inicio, Fin, Estado, Filas, Mensaje)`; procedimientos `etl.usp_CargarDimensiones`, `etl.usp_CargarHechos`, `etl.usp_EjecutarTodo` (truncate-and-load en transacción, registra en auditoría, `THROW` en error). `DIM_TIEMPO.ID_Tiempo = yyyymmdd`.

- [ ] **Step 1: Prueba** `t03_dw.sql` (ejecuta `EXEC etl.usp_EjecutarTodo` dos veces antes de comprobar):
  - `DIM_TIEMPO` tiene 175 filas (2026-06-01..2026-11-22, días corridos) y `Anio_Mes` en formato `2026-06`
  - Conteo `FACT_TRAMITE_GENERAL` = conteo `NotariaPeru.dbo.Tramite`
  - `SUM(Monto_Cobrado)` de `FACT_TRAMITES_FINANCIEROS` con estado Pagado = `SUM(Pago.Monto WHERE Estado='Pagado')`
  - 0 claves foráneas huérfanas en los 4 hechos (incluye `ID_Notario`)
  - `FACT_TIEMPOS_ATENCION`: 0 filas con `Minutos_Totales <> Minutos_Espera + Minutos_Proceso`
  - `DIM_SERVICIO.Categoria IN ('Escrituras públicas','Extraprotocolares')`
  - `ETL_Auditoria` tiene ≥ 2 filas con `Estado='Exito'`
- [ ] **Step 2:** Ejecutar → falla.
- [ ] **Step 3:** Escribir `03_crear_dw.sql` (DROP/CREATE base, esquema `etl`) y `04_etl_dw.sql`.
- [ ] **Step 4:** `01`→`04` + prueba → PASS.

### Task 4: Validación y totales de referencia

**Files:**
- Create: `sql/05_validacion.sql`, `sql/ejecutar_todo.ps1` (corre 01→05 y todas las pruebas, se detiene en el primer fallo)
- Create (salida): `sql/referencia.csv`

**Interfaces:**
- Produces: `referencia.csv` con columnas `Indicador,Filtro,Valor` para: Importe cobrado, Importe facturado, Por cobrar, Costo asociado, Margen, Trámites, Atenciones, Atención media, Espera media, Documentos otorgados, Clientes únicos — total y por mes; y una fila por cada una de las 8 preguntas del informe (p. ej. `P2,Efectivo top empleado,<nombre>|<monto>`).

- [ ] **Step 1:** `ejecutar_todo.ps1` termina con código 0 y `referencia.csv` tiene ≥ 60 filas.

### Task 5: Convertir a PBIP, conectar a SQL y modelo

**Files:**
- Create: `powerbi/NOTARIA_LOZANO.pbip` (+ `.SemanticModel/`, `.Report/`) mediante "Guardar como" en Power BI Desktop con computer-use, desde una copia del `.pbix`
- Modify: `powerbi/NOTARIA_LOZANO.SemanticModel/definition/**/*.tmdl`
- Create: `tools/dax.ps1` (consulta DAX al motor local: puerto desde `msmdsrv.port.txt` del workspace activo de Power BI Desktop; ADOMD desde la carpeta bin de Desktop)
- Create: `tools/tests/t05_medidas.ps1`

**Interfaces:**
- Consumes: `DW_NotariaLozano`, `referencia.csv`.
- Produces: tablas del modelo con los mismos nombres del DW; tabla `_Medidas` con carpetas `Finanzas`, `Operaciones`, `Documentos`, `Clientes`, `Visual`. Medidas (nombres exactos): `[Importe cobrado]`, `[Importe facturado]`, `[Por cobrar]`, `[Costo asociado]`, `[Margen]`, `[% Margen]`, `[Ticket medio]`, `[% Efectivo]`, `[Variación mensual cobrado]`, `[Variación mensual documentos]`, `[Trámites registrados]`, `[Tasa de finalización]`, `[Días promedio de duración]`, `[Atenciones registradas]`, `[Atención media minutos]`, `[Espera media minutos]`, `[Proceso medio minutos]`, `[Documentos otorgados]`, `[Clientes únicos]`, `[Clientes recurrentes]`, `[Color KPI]`, `[SVG Tendencia cobrado]`. Se conservan las medidas actuales del reporte con sus nombres.

- [ ] **Step 1:** Pedir acceso a Power BI Desktop (`request_access`), abrir la copia, activar PBIP si hace falta (Opciones › Características en vista previa), guardar como `powerbi/NOTARIA_LOZANO.pbip`, cerrar.
- [ ] **Step 2: Prueba** `t05_medidas.ps1`: para cada fila de `referencia.csv` ejecuta la consulta DAX equivalente y compara (tolerancia 0.01); además `EVALUATE ROW("v", CALCULATE([Variación mensual cobrado], DIM_TIEMPO[Anio_Mes]="2026-06"))` debe ser BLANK.
- [ ] **Step 3:** Editar TMDL: origen `Sql.Database(".\SQLEXPRESS","DW_NotariaLozano")` en cada partición, columnas nuevas, relaciones 1:* desde dimensiones, `DIM_TIEMPO` marcada como tabla de fechas con jerarquía Año›Trimestre›Mes›Día, `Nombre_Mes` ordenado por `Mes`, medidas listadas.
- [ ] **Step 4:** Abrir el `.pbip` en Desktop, Actualizar, sin errores; correr `t05_medidas.ps1` → PASS.

### Task 6: Tema, imágenes e íconos

**Files:**
- Create: `assets/build_assets.py` (Pillow; genera PNG 1920×1080 por página y SVG de íconos)
- Create: `powerbi/NOTARIA_LOZANO.Report/StaticResources/RegisteredResources/fondo_{resumen,finanzas,operaciones,documentos,clientes}.png`, `icono_*.svg`, tema `NotariaLozano2026.json`
- Modify: `powerbi/NOTARIA_LOZANO.Report/definition/report.json` (registrar recursos y tema)

**Interfaces:**
- Produces: fondos con menú lateral (logo actual recortado de `fondo_finanzas.png`), encabezado con título vacío, tarjetas de áreas en coordenadas fijas documentadas en `assets/layout.json` (`{pagina: {zona: [x,y,w,h]}}`) que Task 7 usa para colocar visuales.

- [ ] **Step 1:** `python -I assets/build_assets.py` genera 5 PNG de 1920×1080 y `layout.json`; revisar cada PNG visualmente.

### Task 7: Páginas del reporte

**Files:**
- Modify/Create: `powerbi/NOTARIA_LOZANO.Report/definition/pages/{resumen,finanzas,operaciones,documentos,clientes,tooltip_servicio}/**`, `pages.json`, `bookmarks/**`

**Interfaces:**
- Consumes: medidas de Task 5, `layout.json` de Task 6.
- Produces: páginas según la sección 6.2 del spec, en este orden: resumen, finanzas, operaciones, documentos, clientes; tooltip oculta. Cada página tiene: botones de navegación con estados hover/presionado, botón "Restablecer filtros" (marcador), panel de filtros que se abre/cierra con marcadores, KPIs arriba. Visuales obligatorios por pregunta: P1 cobrado y margen por servicio y trimestre/mes; P2 cobrado en efectivo por empleado; P3 método de pago × tipo de cliente; P4 trámites de escrituras públicas por cargo; P5 documentos por tipo y mes; P6 documentos por empleado y servicio; P7 atención media por servicio y turno; P8 espera media por etapa y mes.

- [ ] **Step 1:** Escribir una página a la vez; tras cada una, abrir en Desktop y capturar pantalla: sin visuales con error ni "(En blanco)" injustificado.
- [ ] **Step 2:** Probar en Desktop: navegación entre las 5 páginas, abrir/cerrar panel de filtros, restablecer filtros, tooltip sobre un servicio.

### Task 8: Verificación final

- [ ] **Step 1:** `sql/ejecutar_todo.ps1` desde cero → código 0.
- [ ] **Step 2:** Abrir `.pbip`, Actualizar, `t05_medidas.ps1` → PASS.
- [ ] **Step 3:** Capturar cada página a `capturas/<pagina>.png` y entregarlas al usuario.
- [ ] **Step 4:** Escribir `LEEME.md` con el orden de ejecución y cómo actualizar el reporte.
