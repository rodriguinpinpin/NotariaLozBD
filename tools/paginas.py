"""Especificación compartida del reporte: lienzo, zonas, KPIs y gráficos por página.
La usan build_assets.py (fondos PNG) y build_report.py (visuales PBIR), así las coordenadas coinciden.

Campos: "TABLA.Columna" = columna; "[Medida]" = medida de la tabla _Medidas.
"""

ANCHO, ALTO = 1920, 1080
SIDEBAR = 264
X0, X1 = 288, 1896                     # área de contenido
GAP = 16
HEADER = (X0, 20, X1 - X0, 112)
FILTROS = (X0, 148, X1 - X0, 64)
KPI_Y, KPI_H = 228, 120
FILA1 = (364, 336)                     # (y, alto)
FILA2 = (716, 344)

AZUL, MARINO, ROJO, TURQUESA, GRIS, ARENA = "#0876AA", "#173D64", "#BE263E", "#168D9C", "#8196B0", "#D5A76F"
ACENTOS = [AZUL, ROJO, TURQUESA, GRIS, MARINO, ARENA]

NAV = [  # (página, etiqueta, icono)
    ("resumen", "Resumen ejecutivo", "building"),
    ("finanzas", "Finanzas e ingresos", "coins"),
    ("operaciones", "Operaciones y tiempos", "clock"),
    ("documentos", "Producción documental", "doc"),
    ("clientes", "Clientes", "users"),
]
NAV_Y0, NAV_H, NAV_GAP = 232, 52, 8
RESET = (20, 560, 224, 44)


def nav_rect(i):
    return (16, NAV_Y0 + i * (NAV_H + NAV_GAP), SIDEBAR - 32, NAV_H)


def kpi_rects(n=6):
    w = (X1 - X0 - (n - 1) * GAP) / n
    return [(round(X0 + i * (w + GAP)), KPI_Y, round(w), KPI_H) for i in range(n)]


def fila_rects(fila, spans):
    """spans: lista de anchos en columnas (1 o 2) que suman 3."""
    y, h = fila
    col = (X1 - X0 - 2 * GAP) / 3
    rects, x = [], X0
    for s in spans:
        w = col * s + GAP * (s - 1)
        rects.append((round(x), y, round(w), h))
        x += w + GAP
    return rects


def slicer_rects(n=6):
    pad = 10
    x0, y0, w0, h0 = FILTROS
    w = (w0 - 2 * pad - (n - 1) * 12) / n
    return [(round(x0 + pad + i * (w + 12)), y0 + 4, round(w), h0 - 8) for i in range(n)]


def K(etiqueta, icono, medida, texto=None, color=None, sparkline=None, sufijo=None):
    return dict(etiqueta=etiqueta, icono=icono, medida=medida, texto=texto, color=color, sparkline=sparkline, sufijo=sufijo)


def G(tipo, titulo, **kw):
    return dict(tipo=tipo, titulo=titulo, **kw)


SLICERS_BASE = [("Mes", "DIM_TIEMPO.Nombre_Mes"), ("Servicio", "DIM_SERVICIO.Nombre_Tramite"),
                ("Categoría", "DIM_SERVICIO.Categoria"), ("Responsable", "DIM_PERSONAL.Nombre_Completo")]

PAGINAS = [
    dict(
        nombre="resumen", titulo="Resumen ejecutivo", icono="building",
        subtitulo="Ingresos, demanda, tiempos y producción documental · junio a noviembre de 2026",
        slicers=SLICERS_BASE + [("Tipo de cliente", "DIM_CLIENTE.Tipo_Cliente"), ("Turno", "DIM_TURNO.Nombre_Turno")],
        kpis=[K("Importe cobrado", "coins", "[Importe cobrado]", sparkline="[SVG tendencia cobrado]"),
              K("Trámites registrados", "doc", "[Tramites registrados]", sparkline="[SVG tendencia tramites]"),
              K("Clientes atendidos", "users", "[Clientes unicos]"),
              K("Atención media (min)", "clock", "[Atencion media minutos]", sparkline="[SVG tendencia atencion]"),
              K("Documentos otorgados", "layers", "[Documentos otorgados]", sparkline="[SVG tendencia documentos]"),
              K("Margen sobre cobrado", "percent", "[% Margen]")],
        filas=[[2, 1], [1, 1, 1]],
        graficos=[
            G("lineClusteredColumnComboChart", "Ingresos cobrados y trámites por mes",
              cat=["DIM_TIEMPO.Mes_Etiqueta"], y=["[Importe cobrado]"], y2=["[Tramites registrados]"]),
            G("clusteredBarChart", "Servicios con mayor margen", cat=["DIM_SERVICIO.Nombre_Tramite"], y=["[Margen]"],
              orden="[Margen]", tooltip_pagina=True),
            G("clusteredColumnChart", "Demanda por día y turno", cat=["DIM_TIEMPO.Nombre_Dia"], series="DIM_TURNO.Nombre_Turno",
              y=["[Tramites registrados]"]),
            G("donutChart", "Estado de los trámites", cat=["FACT_TRAMITE_GENERAL.Estado_Tramite"], y=["[Tramites registrados]"]),
            G("clusteredBarChart", "Cobrado por método de pago", cat=["DIM_METODO_PAGO.Tipo_Pago"], y=["[Importe cobrado]"],
              orden="[Importe cobrado]"),
        ]),
    dict(
        nombre="finanzas", titulo="Gestión financiera e ingresos", icono="coins",
        subtitulo="Cobrado = pagos confirmados · Facturado = trámites no anulados · Por cobrar = pagos pendientes",
        slicers=SLICERS_BASE + [("Método de pago", "DIM_METODO_PAGO.Tipo_Pago"), ("Tipo de cliente", "DIM_CLIENTE.Tipo_Cliente")],
        kpis=[K("Importe cobrado", "coins", "[Importe cobrado]"),
              K("Importe facturado", "receipt", "[Importe facturado]"),
              K("Por cobrar", "hourglass", "[Por cobrar]"),
              K("Margen sobre cobrado", "percent", "[% Margen]"),
              K("Ticket medio por trámite", "tag", "[Ticket medio]"),
              K("Variación mensual", "trend", "[Variacion mensual cobros]",
                texto="[Texto variacion cobros]", color="[Color variacion cobros]")],
        filas=[[1, 1, 1], [1, 1, 1]],
        graficos=[
            G("clusteredBarChart", "P1 · Cobrado y margen por servicio", cat=["DIM_SERVICIO.Nombre_Tramite"],
              y=["[Importe cobrado]", "[Margen]"], orden="[Importe cobrado]", leyenda=True, tooltip_pagina=True),
            G("clusteredColumnChart", "P1 · Demanda de trámites por trimestre", cat=["DIM_TIEMPO.Trimestre_Texto"],
              y=["[Tramites registrados]"]),
            G("clusteredBarChart", "P2 · Efectivo cobrado por empleado", cat=["DIM_PERSONAL.Nombre_Completo"],
              y=["[Cobrado en efectivo]"], orden="[Cobrado en efectivo]"),
            G("hundredPercentStackedBarChart", "P3 · Medios de pago: empresas vs personas", cat=["DIM_CLIENTE.Tipo_Cliente"],
              series="DIM_METODO_PAGO.Tipo_Pago", y=["[Registros financieros]"], leyenda=True),
            G("clusteredColumnChart", "Ingresos y costos por mes", cat=["DIM_TIEMPO.Mes_Etiqueta"],
              y=["[Importe cobrado]", "[Costo asociado]"], leyenda=True),
            G("tableEx", "Detalle financiero por servicio",
              columnas=["DIM_SERVICIO.Nombre_Tramite", "[Registros financieros]", "[Importe cobrado]", "[Margen]", "[% Margen]"],
              orden="[Importe cobrado]"),
        ]),
    dict(
        nombre="operaciones", titulo="Eficiencia operacional y tiempos de atención", icono="clock",
        subtitulo="Minutos por etapa (recepción, revisión y redacción, firma y entrega) según servicio, turno y personal",
        slicers=SLICERS_BASE + [("Turno", "DIM_TURNO.Nombre_Turno"), ("Etapa", "DIM_ETAPA_TRAMITE.Nombre_Etapa")],
        kpis=[K("Atenciones registradas", "chart", "[Atenciones registradas]"),
              K("Atención media (min)", "clock", "[Atencion media minutos]"),
              K("Espera media (min)", "hourglass", "[Espera media minutos]"),
              K("Proceso medio (min)", "gear", "[Proceso medio minutos]"),
              K("Minutos por trámite", "clock", "[Minutos por tramite]"),
              K("Días promedio de duración", "calendar", "[Dias promedio de duracion]")],
        filas=[[1, 1, 1], [1, 1, 1]],
        graficos=[
            G("clusteredBarChart", "P7 · Atención media por servicio y turno", cat=["DIM_SERVICIO.Nombre_Tramite"],
              series="DIM_TURNO.Nombre_Turno", y=["[Atencion media minutos]"], leyenda=True, tooltip_pagina=True),
            G("lineChart", "P8 · Espera media por etapa y mes", cat=["DIM_TIEMPO.Mes_Etiqueta"], series="DIM_ETAPA_TRAMITE.Nombre_Etapa",
              y=["[Espera media minutos]"], leyenda=True),
            G("barChart", "Espera vs proceso por etapa", cat=["DIM_ETAPA_TRAMITE.Nombre_Etapa"],
              y=["[Espera media minutos]", "[Proceso medio minutos]"], leyenda=True),
            G("clusteredBarChart", "Carga de atención por personal", cat=["DIM_PERSONAL.Nombre_Completo"],
              y=["[Atenciones registradas]"], orden="[Atenciones registradas]"),
            G("clusteredColumnChart", "Espera media por día y turno", cat=["DIM_TIEMPO.Nombre_Dia"], series="DIM_TURNO.Nombre_Turno",
              y=["[Espera media minutos]"], leyenda=True),
            G("tableEx", "Detalle por etapa",
              columnas=["DIM_ETAPA_TRAMITE.Nombre_Etapa", "[Atenciones registradas]", "[Espera media minutos]",
                        "[Proceso medio minutos]"]),
        ]),
    dict(
        nombre="documentos", titulo="Producción documental y trámites", icono="doc",
        subtitulo="Documentos otorgados por tipo, empleado y servicio · escrituras públicas por cargo",
        slicers=SLICERS_BASE + [("Turno", "DIM_TURNO.Nombre_Turno"), ("Notario", "DIM_NOTARIO.Nombre_Completo")],
        kpis=[K("Documentos otorgados", "doc", "[Documentos otorgados]"),
              K("Tipos documentales", "layers", "[Tipos documentales atendidos]"),
              K("Trámites registrados", "receipt", "[Tramites registrados]"),
              K("Tasa de finalización", "check", "[Tasa de finalizacion]"),
              K("Documentos por trámite", "layers", "[Documentos por tramite]"),
              K("Variación mensual", "trend", "[Variacion mensual documentos]",
                texto="[Texto variacion documentos]", color="[Color variacion documentos]")],
        filas=[[2, 1], [1, 1, 1]],
        graficos=[
            G("columnChart", "P5 · Documentos otorgados por tipo y mes", cat=["DIM_TIEMPO.Mes_Etiqueta"],
              series="DIM_TIPO_DOCUMENTO.Nombre_TipoDocumento", y=["[Documentos otorgados]"], leyenda=True),
            G("clusteredBarChart", "P4 · Escrituras públicas por cargo", cat=["DIM_PERSONAL.Cargo"],
              y=["[Tramites escrituras publicas]"], orden="[Tramites escrituras publicas]"),
            G("pivotTable", "P6 · Documentos por empleado y servicio",
              filas_m=["DIM_PERSONAL.Nombre_Completo", "DIM_SERVICIO.Nombre_Tramite"], valores=["[Documentos otorgados]"]),
            G("clusteredBarChart", "Trámites por servicio", cat=["DIM_SERVICIO.Nombre_Tramite"], y=["[Tramites registrados]"],
              orden="[Tramites registrados]", tooltip_pagina=True),
            G("barChart", "Trámites por notario y estado", cat=["DIM_NOTARIO.Nombre_Completo"],
              series="FACT_TRAMITE_GENERAL.Estado_Tramite", y=["[Tramites registrados]"], leyenda=True),
        ]),
    dict(
        nombre="clientes", titulo="Clientes", icono="users",
        subtitulo="Personas naturales y jurídicas, recurrencia, distritos y valor por cliente",
        slicers=SLICERS_BASE + [("Tipo de cliente", "DIM_CLIENTE.Tipo_Cliente"), ("Distrito", "DIM_CLIENTE.Distrito")],
        kpis=[K("Clientes atendidos", "users", "[Clientes unicos]"),
              K("Clientes recurrentes", "repeat", "[Clientes recurrentes]"),
              K("Tasa de recurrencia", "percent", "[% Recurrencia]"),
              K("Trámites por cliente", "doc", "[Tramites por cliente]"),
              K("Importe por cliente", "coins", "[Importe por cliente]"),
              K("Empresas atendidas", "building", "[Clientes juridicos]")],
        filas=[[1, 1, 1], [2, 1]],
        graficos=[
            G("donutChart", "Clientes: personas naturales vs jurídicas", cat=["DIM_CLIENTE.Tipo_Cliente"], y=["[Clientes unicos]"]),
            G("clusteredBarChart", "Clientes por distrito", cat=["DIM_CLIENTE.Distrito"], y=["[Clientes unicos]"],
              orden="[Clientes unicos]"),
            G("tableEx", "Clientes por importe cobrado",
              columnas=["DIM_CLIENTE.Razon_Social_Nombre", "DIM_CLIENTE.Tipo_Cliente", "[Tramites registrados]", "[Importe cobrado]"],
              orden="[Importe cobrado]"),
            G("clusteredColumnChart", "Clientes atendidos por mes y segmento", cat=["DIM_TIEMPO.Mes_Etiqueta"],
              series="DIM_CLIENTE.Segmento", y=["[Clientes unicos]"], leyenda=True),
            G("clusteredColumnChart", "Ticket medio por tipo de cliente", cat=["DIM_CLIENTE.Tipo_Cliente"], y=["[Ticket medio]"]),
        ]),
]

TOOLTIP = dict(nombre="tooltip_servicio", titulo="Detalle del servicio", ancho=320, alto=240,
               kpis=[("Importe cobrado", "[Importe cobrado]"), ("Trámites", "[Tramites registrados]"),
                     ("Atención (min)", "[Atencion media minutos]"), ("Margen", "[% Margen]")])
