"""Medidas DAX del modelo (tabla _Medidas). Las define gen_modelo.py.

Definiciones de negocio (spec 7b):
  Importe cobrado   = pagos 'Pagado'          Importe facturado = Monto_Arancel de trámites no anulados
  Por cobrar        = pagos 'Pendiente'       Anulados no suman en ningún indicador
  Variación mensual = mes (a la fecha) vs mismos días del mes anterior; en blanco sin base.
"""

SOLES = r"\S\/\ #,##0.00"
SOLES0 = r"\S\/\ #,##0"
ENTERO = "#,##0"
DEC1 = "#,##0.0"
PCT = "0.0%;-0.0%;0.0%"


def periodo_mensual(medida):
    """DAX que devuelve (actual, anterior) del último mes en contexto, a la fecha de corte del contexto."""
    return f"""
VAR FechaFin = MAX(DIM_TIEMPO[Fecha_Exacta])
VAR FechaIni = MAX(MIN(DIM_TIEMPO[Fecha_Exacta]), DATE(YEAR(FechaFin), MONTH(FechaFin), 1))
VAR Actual = CALCULATE({medida}, FILTER(ALL(DIM_TIEMPO), DIM_TIEMPO[Fecha_Exacta] >= FechaIni && DIM_TIEMPO[Fecha_Exacta] <= FechaFin))
VAR Anterior = CALCULATE({medida}, FILTER(ALL(DIM_TIEMPO), DIM_TIEMPO[Fecha_Exacta] >= EDATE(FechaIni, -1) && DIM_TIEMPO[Fecha_Exacta] <= EDATE(FechaFin, -1)))"""


def sparkline(medida, color):
    """Mini gráfico SVG (área + línea animada) del valor por mes completo en el periodo seleccionado (sin el mes en curso)."""
    c = color.replace("#", "%23")
    return f"""
VAR T = CALCULATETABLE(ADDCOLUMNS(VALUES(DIM_TIEMPO[Orden_Mes]), "@v", {medida} + 0), ALLSELECTED(DIM_TIEMPO), DIM_TIEMPO[Mes_Completo] = TRUE())
VAR N = COUNTROWS(T)
VAR MinV = MINX(T, [@v])
VAR MaxV = MAXX(T, [@v])
VAR Pts = CONCATENATEX(T,
    VAR i = RANKX(T, DIM_TIEMPO[Orden_Mes], , ASC)
    RETURN INT(DIVIDE((i - 1) * 196, N - 1) + 2) & "," & INT(52 - DIVIDE([@v] - MinV, MaxV - MinV) * 44),
    " ", DIM_TIEMPO[Orden_Mes], ASC)
VAR Svg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 200 60' preserveAspectRatio='none'>"
    & "<polygon fill='{c}' fill-opacity='0.14' points='2,58 " & Pts & " 198,58'/>"
    & "<polyline fill='none' stroke='{c}' stroke-width='3' stroke-linecap='round' stroke-linejoin='round' stroke-dasharray='600' points='" & Pts & "'>"
    & "<animate attributeName='stroke-dashoffset' from='600' to='0' dur='1.4s' fill='freeze'/></polyline></svg>"
RETURN IF(N > 1, "data:image/svg+xml;utf8," & Svg)"""


MEDIDAS = [
    # ---------------- Finanzas ----------------
    dict(nombre="Importe cobrado", carpeta="Finanzas", fmt=SOLES, desc="Suma de pagos en estado Pagado (dinero recibido).",
         dax="SUM(FACT_TRAMITES_FINANCIEROS[Monto_Cobrado])"),
    dict(nombre="Importe facturado", carpeta="Finanzas", fmt=SOLES, desc="Importe emitido de trámites no anulados.",
         dax='CALCULATE(SUM(FACT_TRAMITE_GENERAL[Monto_Arancel]), FACT_TRAMITE_GENERAL[Estado_Tramite] <> "Anulado")'),
    dict(nombre="Por cobrar", carpeta="Finanzas", fmt=SOLES, desc="Pagos en estado Pendiente.",
         dax="SUM(FACT_TRAMITES_FINANCIEROS[Monto_Pendiente])"),
    dict(nombre="Costo asociado", carpeta="Finanzas", fmt=SOLES, desc="Costo (insumos, tasas) del importe cobrado.",
         dax="SUM(FACT_TRAMITES_FINANCIEROS[Costo_Asociado])"),
    dict(nombre="Margen", carpeta="Finanzas", fmt=SOLES, desc="Importe cobrado menos costo asociado. No es utilidad neta.",
         dax="[Importe cobrado] - [Costo asociado]"),
    dict(nombre="% Margen", carpeta="Finanzas", fmt=PCT, dax="DIVIDE([Margen], [Importe cobrado])"),
    dict(nombre="Registros financieros", carpeta="Finanzas", fmt=ENTERO, desc="Filas del hecho financiero (un pago por fila).",
         dax="COUNTROWS(FACT_TRAMITES_FINANCIEROS)"),
    dict(nombre="Registros con monto", carpeta="Finanzas", fmt=ENTERO,
         dax="CALCULATE(COUNTROWS(FACT_TRAMITES_FINANCIEROS), FACT_TRAMITES_FINANCIEROS[Monto_Cobrado] > 0)"),
    dict(nombre="Importe medio por registro", carpeta="Finanzas", fmt=SOLES, dax="DIVIDE([Importe cobrado], [Registros con monto])"),
    dict(nombre="Ticket medio", carpeta="Finanzas", fmt=SOLES, desc="Importe cobrado por trámite con pago.",
         dax="DIVIDE([Importe cobrado], CALCULATE(DISTINCTCOUNT(FACT_TRAMITES_FINANCIEROS[Nro_Tramite]), FACT_TRAMITES_FINANCIEROS[Monto_Cobrado] > 0))"),
    dict(nombre="% Efectivo", carpeta="Finanzas", fmt=PCT,
         dax='DIVIDE(CALCULATE([Importe cobrado], DIM_METODO_PAGO[Tipo_Pago] = "Efectivo"), [Importe cobrado])'),
    dict(nombre="Cobrado en efectivo", carpeta="Finanzas", fmt=SOLES, desc="P2: importe cobrado con método Efectivo.",
         dax='CALCULATE([Importe cobrado], DIM_METODO_PAGO[Tipo_Pago] = "Efectivo")'),
    dict(nombre="% Digital", carpeta="Finanzas", fmt=PCT,
         dax='DIVIDE(CALCULATE([Importe cobrado], DIM_METODO_PAGO[Canal] = "Digital"), [Importe cobrado])'),
    dict(nombre="% Cobranza", carpeta="Finanzas", fmt=PCT, desc="Cobrado sobre cobrado + por cobrar.",
         dax="DIVIDE([Importe cobrado], [Importe cobrado] + [Por cobrar])"),
    dict(nombre="Cobrado mes actual", carpeta="Finanzas\\Variación", fmt=SOLES,
         dax=periodo_mensual("[Importe cobrado]") + "\nRETURN Actual"),
    dict(nombre="Cobrado mes anterior", carpeta="Finanzas\\Variación", fmt=SOLES,
         dax=periodo_mensual("[Importe cobrado]") + "\nRETURN Anterior"),
    dict(nombre="Variacion mensual cobros", carpeta="Finanzas\\Variación", fmt=PCT,
         desc="Último mes del contexto (a la fecha) frente a los mismos días del mes anterior.",
         dax=periodo_mensual("[Importe cobrado]") + "\nRETURN DIVIDE(Actual - Anterior, Anterior)"),

    # ---------------- Trámites ----------------
    dict(nombre="Tramites registrados", carpeta="Trámites", fmt=ENTERO, dax="DISTINCTCOUNT(FACT_TRAMITE_GENERAL[Nro_Tramite])"),
    dict(nombre="Cantidad de tramites", carpeta="Trámites", fmt=ENTERO, dax="SUM(FACT_TRAMITE_GENERAL[Cantidad_Tramites])"),
    dict(nombre="Pagos registrados", carpeta="Trámites", fmt=ENTERO,
         dax="CALCULATE(COUNTROWS(FACT_TRAMITE_GENERAL), FACT_TRAMITE_GENERAL[Monto_Pagado] > 0)"),
    dict(nombre="Importe pagado tramites", carpeta="Trámites", fmt=SOLES, dax="SUM(FACT_TRAMITE_GENERAL[Monto_Pagado])"),
    dict(nombre="Tramites escrituras publicas", carpeta="Trámites", fmt=ENTERO, desc="P4: trámites de la categoría Escrituras públicas.",
         dax='CALCULATE([Tramites registrados], DIM_SERVICIO[Categoria] = "Escrituras públicas")'),
    dict(nombre="Tramites finalizados", carpeta="Trámites", fmt=ENTERO,
         dax='CALCULATE([Tramites registrados], FACT_TRAMITE_GENERAL[Estado_Tramite] = "Finalizado")'),
    dict(nombre="Tramites en proceso", carpeta="Trámites", fmt=ENTERO,
         dax='CALCULATE([Tramites registrados], FACT_TRAMITE_GENERAL[Estado_Tramite] IN {"En Proceso", "Observado"})'),
    dict(nombre="Tasa de finalizacion", carpeta="Trámites", fmt=PCT, desc="Finalizados sobre trámites no anulados.",
         dax='DIVIDE([Tramites finalizados], CALCULATE([Tramites registrados], FACT_TRAMITE_GENERAL[Estado_Tramite] <> "Anulado"))'),
    dict(nombre="Dias promedio de duracion", carpeta="Trámites", fmt=DEC1, desc="Días entre inicio y fin de trámites finalizados.",
         dax="AVERAGE(FACT_TRAMITE_GENERAL[Dias_Duracion])"),
    dict(nombre="Tramites mes actual", carpeta="Trámites", fmt=ENTERO,
         dax=periodo_mensual("[Tramites registrados]") + "\nRETURN Actual"),
    dict(nombre="Variacion mensual tramites", carpeta="Trámites", fmt=PCT,
         dax=periodo_mensual("[Tramites registrados]") + "\nRETURN DIVIDE(Actual - Anterior, Anterior)"),

    # ---------------- Operaciones ----------------
    dict(nombre="Atenciones registradas", carpeta="Operaciones", fmt=ENTERO, desc="Registros de atención (trámite x etapa).",
         dax="COUNTROWS(FACT_TIEMPOS_ATENCION)"),
    dict(nombre="Atencion media minutos", carpeta="Operaciones", fmt=DEC1, dax="AVERAGE(FACT_TIEMPOS_ATENCION[Minutos_Totales])"),
    dict(nombre="Espera media minutos", carpeta="Operaciones", fmt=DEC1, dax="AVERAGE(FACT_TIEMPOS_ATENCION[Minutos_Espera])"),
    dict(nombre="Proceso medio minutos", carpeta="Operaciones", fmt=DEC1, dax="AVERAGE(FACT_TIEMPOS_ATENCION[Minutos_Proceso])"),
    dict(nombre="Atencion minima minutos", carpeta="Operaciones", fmt=ENTERO, dax="MIN(FACT_TIEMPOS_ATENCION[Minutos_Totales])"),
    dict(nombre="Atencion maxima minutos", carpeta="Operaciones", fmt=ENTERO, dax="MAX(FACT_TIEMPOS_ATENCION[Minutos_Totales])"),
    dict(nombre="Espera sobre total declarado", carpeta="Operaciones", fmt=PCT,
         dax="DIVIDE(SUM(FACT_TIEMPOS_ATENCION[Minutos_Espera]), SUM(FACT_TIEMPOS_ATENCION[Minutos_Totales]))"),
    dict(nombre="Minutos por tramite", carpeta="Operaciones", fmt=DEC1, desc="Tiempo total de las 4 etapas por trámite.",
         dax="DIVIDE(SUM(FACT_TIEMPOS_ATENCION[Minutos_Totales]), DISTINCTCOUNT(FACT_TIEMPOS_ATENCION[Nro_Tramite]))"),

    # ---------------- Documentos ----------------
    dict(nombre="Documentos otorgados", carpeta="Documentos", fmt=ENTERO, dax="SUM(FACT_DOCUMENTOS_OTORGADOS[Cantidad_Documentos])"),
    dict(nombre="Tipos documentales atendidos", carpeta="Documentos", fmt=ENTERO,
         dax="CALCULATE(DISTINCTCOUNT(FACT_DOCUMENTOS_OTORGADOS[ID_TipoDocumento]), FACT_DOCUMENTOS_OTORGADOS[Cantidad_Documentos] > 0)"),
    dict(nombre="Documentos por tramite", carpeta="Documentos", fmt=DEC1,
         dax="DIVIDE([Documentos otorgados], DISTINCTCOUNT(FACT_DOCUMENTOS_OTORGADOS[Nro_Tramite]))"),
    dict(nombre="Documentos mes anterior", carpeta="Documentos", fmt=ENTERO,
         dax=periodo_mensual("[Documentos otorgados]") + "\nRETURN Anterior"),
    dict(nombre="Variacion mensual documentos", carpeta="Documentos", fmt=PCT,
         dax=periodo_mensual("[Documentos otorgados]") + "\nRETURN DIVIDE(Actual - Anterior, Anterior)"),

    # ---------------- Clientes ----------------
    dict(nombre="Clientes unicos", carpeta="Clientes", fmt=ENTERO, dax="DISTINCTCOUNT(FACT_TRAMITE_GENERAL[ID_Cliente])"),
    dict(nombre="Clientes recurrentes", carpeta="Clientes", fmt=ENTERO, desc="Clientes con más de un trámite en el contexto.",
         dax="COUNTROWS(FILTER(VALUES(FACT_TRAMITE_GENERAL[ID_Cliente]), CALCULATE([Tramites registrados]) > 1))"),
    dict(nombre="% Recurrencia", carpeta="Clientes", fmt=PCT, dax="DIVIDE([Clientes recurrentes], [Clientes unicos])"),
    dict(nombre="Tramites por cliente", carpeta="Clientes", fmt=DEC1, dax="DIVIDE([Tramites registrados], [Clientes unicos])"),
    dict(nombre="Clientes juridicos", carpeta="Clientes", fmt=ENTERO,
         dax='CALCULATE([Clientes unicos], DIM_CLIENTE[Tipo_Cliente] = "Juridica")'),
    dict(nombre="Importe por cliente", carpeta="Clientes", fmt=SOLES, dax="DIVIDE([Importe cobrado], [Clientes unicos])"),

    # ---------------- Visual ----------------
    dict(nombre="Color variacion cobros", carpeta="Visual", dax='IF([Variacion mensual cobros] < 0, "#FF8A9C", "#6EE7C4")'),
    dict(nombre="Color variacion documentos", carpeta="Visual", dax='IF([Variacion mensual documentos] < 0, "#FF8A9C", "#6EE7C4")'),
    dict(nombre="Texto variacion cobros", carpeta="Visual",
         dax='VAR v = [Variacion mensual cobros]\nRETURN IF(ISBLANK(v), "Sin mes anterior", IF(v >= 0, "▲ ", "▼ ") & FORMAT(ABS(v), "0.0%") & " vs mes anterior")'),
    dict(nombre="Texto variacion documentos", carpeta="Visual",
         dax='VAR v = [Variacion mensual documentos]\nRETURN IF(ISBLANK(v), "Sin mes anterior", IF(v >= 0, "▲ ", "▼ ") & FORMAT(ABS(v), "0.0%") & " vs mes anterior")'),
    dict(nombre="Texto periodo", carpeta="Visual",
         dax='"Periodo: " & FORMAT(MIN(DIM_TIEMPO[Fecha_Exacta]), "dd mmm yyyy") & " – " & FORMAT(MAX(DIM_TIEMPO[Fecha_Exacta]), "dd mmm yyyy")'),
    dict(nombre="SVG tendencia cobrado", carpeta="Visual", cat="ImageUrl", dax=sparkline("[Importe cobrado]", "#0876AA")),
    dict(nombre="SVG tendencia tramites", carpeta="Visual", cat="ImageUrl", dax=sparkline("[Tramites registrados]", "#BE263E")),
    dict(nombre="SVG tendencia atencion", carpeta="Visual", cat="ImageUrl", dax=sparkline("[Atencion media minutos]", "#168D9C")),
    dict(nombre="SVG tendencia documentos", carpeta="Visual", cat="ImageUrl", dax=sparkline("[Documentos otorgados]", "#173D64")),
]
