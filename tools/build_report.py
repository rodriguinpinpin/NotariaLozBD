"""Genera las páginas del reporte (formato PBIR) a partir de tools/paginas.py.
Reemplaza definition/pages/* y actualiza report.json (tema y recursos).
Uso:  python -I tools/build_report.py   (con Power BI Desktop CERRADO)
"""
import hashlib
import json
import os
import shutil
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))
import paginas as P  # noqa: E402
from build_assets import grafico_zonas, kpi_zonas  # noqa: E402
from medidas import MEDIDAS  # noqa: E402

REPORTE = os.path.join(RAIZ, "powerbi", "NOTARIA_LOZANO.Report")
DEF = os.path.join(REPORTE, "definition")
ESQ_VISUAL = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.4.0/schema.json"
ESQ_PAGINA = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/page/2.0.0/schema.json"
ESQ_PAGINAS = "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/pagesMetadata/1.1.0/schema.json"
TEMA = "NotariaLozano2026"
MEDIDAS_EXISTENTES = {m["nombre"] for m in MEDIDAS}
FORMATOS = {m["nombre"]: m.get("fmt") for m in MEDIDAS}
# Nombres visibles en leyendas, encabezados de tabla y matrices
ETIQUETAS = {
    "DIM_SERVICIO.Nombre_Tramite": "Servicio", "DIM_ETAPA_TRAMITE.Nombre_Etapa": "Etapa", "DIM_PERSONAL.Nombre_Completo": "Empleado",
    "DIM_NOTARIO.Nombre_Completo": "Notario", "DIM_CLIENTE.Razon_Social_Nombre": "Cliente", "DIM_CLIENTE.Tipo_Cliente": "Tipo",
    "DIM_TIPO_DOCUMENTO.Nombre_TipoDocumento": "Tipo documental", "DIM_METODO_PAGO.Tipo_Pago": "Método",
    "FACT_TRAMITE_GENERAL.Estado_Tramite": "Estado", "DIM_TURNO.Nombre_Turno": "Turno", "DIM_PERSONAL.Cargo": "Cargo",
    "DIM_CLIENTE.Distrito": "Distrito", "DIM_CLIENTE.Segmento": "Segmento", "DIM_TIEMPO.Mes_Corto": "Mes", "DIM_TIEMPO.Mes_Etiqueta": "Mes",
    "DIM_TIEMPO.Trimestre_Texto": "Trimestre", "DIM_TIEMPO.Nombre_Dia": "Día",
    "[Importe cobrado]": "Cobrado", "[Costo asociado]": "Costo", "[Margen]": "Margen", "[% Margen]": "% Margen",
    "[Registros financieros]": "Registros", "[Tramites registrados]": "Trámites", "[Atenciones registradas]": "Atenciones",
    "[Atencion media minutos]": "Atención media (min)", "[Espera media minutos]": "Espera (min)",
    "[Proceso medio minutos]": "Proceso (min)", "[Documentos otorgados]": "Documentos", "[Clientes unicos]": "Clientes",
    "[Ticket medio]": "Ticket medio", "[Cobrado en efectivo]": "Efectivo", "[Tramites escrituras publicas]": "Escrituras",
}


# ---------------------------------------------------------------- utilidades PBIR
def lit(v):
    if isinstance(v, bool):
        s = "true" if v else "false"
    elif isinstance(v, (int, float)):
        s = f"{v}D"
    else:
        s = "'" + str(v).replace("'", "''") + "'"
    return {"expr": {"Literal": {"Value": s}}}


def color(c):
    return {"solid": {"color": lit(c)}}


def color_medida(m):
    return {"solid": {"color": {"expr": campo(m)}}}


def props(**kw):
    return {"properties": {k: (v if isinstance(v, dict) else lit(v)) for k, v in kw.items()}}


def campo(ref):
    if ref.startswith("["):
        nombre = ref[1:-1]
        if nombre not in MEDIDAS_EXISTENTES:
            sys.exit(f"Medida inexistente en el modelo: {ref}")
        return {"Measure": {"Expression": {"SourceRef": {"Entity": "_Medidas"}}, "Property": nombre}}
    tabla, col = ref.split(".", 1)
    return {"Column": {"Expression": {"SourceRef": {"Entity": tabla}}, "Property": col}}


def proy(ref, nombre=None, activa=False):
    nombre = nombre or ETIQUETAS.get(ref)
    f = campo(ref)
    clave = "Measure" if "Measure" in f else "Column"
    ent, prop = f[clave]["Expression"]["SourceRef"]["Entity"], f[clave]["Property"]
    p = {"field": f, "queryRef": f"{ent}.{prop}", "nativeQueryRef": nombre or prop}
    if nombre:
        p["displayName"] = nombre
    if activa:
        p["active"] = True
    return p


def ident(*partes):
    return hashlib.md5("|".join(partes).encode()).hexdigest()[:20]


class Pagina:
    def __init__(self, nombre):
        self.nombre, self.visuales, self.z = nombre, [], 0

    def agregar(self, clave, rect, visual, how=None):
        self.z += 1
        x, y, w, h = rect
        v = {"$schema": ESQ_VISUAL, "name": ident(self.nombre, clave),
             "position": {"x": x, "y": y, "z": self.z * 100, "width": w, "height": h, "tabOrder": self.z * 100},
             "visual": visual}
        if how:
            v["howCreated"] = how
        self.visuales.append(v)


def contenedor(titulo=None, fondo=False, tooltip=None):
    vco = {"visualHeader": [props(show=False)] if titulo is None else [props(show=True)],
           "background": [props(show=fondo)], "border": [props(show=False)], "dropShadow": [props(show=False)],
           "subTitle": [props(show=False)]}
    if titulo is None:
        vco["title"] = [props(show=False)]
    else:
        vco["title"] = [props(show=True, text=titulo, fontColor=color("#EAF2FA"), fontSize=13,
                              fontFamily="Segoe UI Semibold", alignment="left")]
    if tooltip:
        vco["visualTooltip"] = [props(show=True, type="Canvas", section=tooltip)]
    return vco


# ---------------------------------------------------------------- visuales
def slicer(etiqueta, ref):
    return {"visualType": "slicer",
            "query": {"queryState": {"Values": {"projections": [proy(ref, etiqueta, activa=True)]}}},
            "objects": {"data": [props(mode="Dropdown")],
                        "selection": [props(singleSelect=False, selectAllCheckboxEnabled=True)],
                        "header": [props(show=True, text=etiqueta, fontColor=color("#8FA6BE"), fontSize=10, fontFamily="Segoe UI Semibold")],
                        "items": [props(fontColor=color("#EAF2FA"), fontSize=11, background=color("#13263D"))]},
            "visualContainerObjects": {**contenedor(), "background": [props(show=True, color=color("#13263D"), transparency=15)],
                                       "border": [props(show=True, color=color("#2A4360"), radius=10)]},
            "drillFilterOtherVisuals": True}


def tarjeta(ref, nombre, tam=22, col="#FFFFFF", col_medida=None, etiqueta=False, unidades=1, decimales=None):
    extra = {} if decimales is None else {"labelPrecision": decimales}
    etq = {"labels": [props(color=color_medida(col_medida) if col_medida else color(col), fontSize=tam,
                            fontFamily="Segoe UI Semibold", labelDisplayUnits=unidades, **extra)],
           "categoryLabels": [props(show=etiqueta, color=color("#A9BDD2"), fontSize=9)]}
    return {"visualType": "card", "query": {"queryState": {"Values": {"projections": [proy(ref, nombre)]}}},
            "objects": etq, "visualContainerObjects": contenedor(), "drillFilterOtherVisuals": True}


def imagen_medida(ref):
    return {"visualType": "image",
            "objects": {"general": [props(imageScaling="Fit")],
                        "image": [{"properties": {"sourceType": lit("imageUrl"), "sourceUrl": {"expr": campo(ref)}}}]},
            "visualContainerObjects": contenedor(), "drillFilterOtherVisuals": True}


def grafico(g, tooltip=None):
    t = g["tipo"]
    qs, objetos = {}, {}
    if t == "tableEx":
        qs["Values"] = {"projections": [proy(c) for c in g["columnas"]]}
        objetos = {"columnHeaders": [props(fontColor=color("#FFFFFF"), backColor=color("#173D64"), fontSize=10,
                                           fontFamily="Segoe UI Semibold", wordWrap=True)],
                   "values": [props(fontColor=color("#D6E3F0"), backColorPrimary=color("#0E2034"),
                                    backColorSecondary=color("#132840"), fontSize=10)],
                   "total": [props(totals=True, fontColor=color("#FFFFFF"), backColor=color("#173D64"))],
                   "grid": [props(gridHorizontal=False, rowPadding=4)]}
    elif t == "pivotTable":
        qs["Rows"] = {"projections": [proy(c, activa=True) for c in g["filas_m"]]}
        qs["Values"] = {"projections": [proy(c) for c in g["valores"]]}
        objetos = {"columnHeaders": [props(fontColor=color("#FFFFFF"), backColor=color("#173D64"), fontSize=10)],
                   "rowHeaders": [props(fontColor=color("#D6E3F0"), backColor=color("#0E2034"), fontSize=10, stepped=True)],
                   "values": [props(fontSize=10, fontColor=color("#D6E3F0"), backColorPrimary=color("#0E2034"), backColorSecondary=color("#132840"))],
                   "subTotals": [props(rowSubtotals=True)]}
    else:
        qs["Category"] = {"projections": [proy(c, activa=True) for c in g["cat"]]}
        qs["Y"] = {"projections": [proy(m) for m in g["y"]]}
        if g.get("y2"):
            qs["Y2"] = {"projections": [proy(m) for m in g["y2"]]}
        if g.get("series"):
            qs["Series"] = {"projections": [proy(g["series"])]}
        objetos["legend"] = [props(show=bool(g.get("leyenda") or t == "donutChart" or g.get("y2")),
                                   position="Right" if t == "donutChart" else "Top", fontSize=10)]
        if t == "donutChart":
            objetos["labels"] = [props(show=True, labelStyle="Percent of total", fontSize=10)]
            objetos["slices"] = [props(innerRadiusRatio=62)]
        elif t != "lineChart":
            objetos["labels"] = [props(show=True, fontSize=9, labelDisplayUnits=0)]
        objetos["categoryAxis"] = [props(show=True, showAxisTitle=False, fontSize=10)]
        objetos["valueAxis"] = [props(show=t not in ("clusteredBarChart", "barChart", "hundredPercentStackedBarChart"),
                                      showAxisTitle=False, fontSize=9, labelDisplayUnits=0)]
        if t in ("lineChart", "lineClusteredColumnComboChart"):
            objetos["lineStyles"] = [props(strokeWidth=3, showMarker=True, markerSize=5)]
    visual = {"visualType": t, "query": {"queryState": qs}, "objects": objetos,
              "visualContainerObjects": contenedor(g["titulo"], tooltip=tooltip if g.get("tooltip_pagina") else None),
              "drillFilterOtherVisuals": True}
    if g.get("orden"):
        visual["query"]["sortDefinition"] = {"sort": [{"field": campo(g["orden"]), "direction": "Descending"}], "isDefaultSort": True}
    return visual


def boton_nav(destino, etiqueta):
    return {"visualType": "actionButton",
            "objects": {"icon": [props(show=False)], "text": [props(show=False)],
                        "outline": [{**props(show=False), "selector": {"id": "default"}}],
                        "fill": [{**props(show=True, fillColor=color("#FFFFFF"), transparency=100), "selector": {"id": "default"}},
                                 {**props(show=True, fillColor=color("#FFFFFF"), transparency=86), "selector": {"id": "hover"}},
                                 {**props(show=True, fillColor=color("#FFFFFF"), transparency=78), "selector": {"id": "selected"}}]},
            "visualContainerObjects": {"visualLink": [props(show=True, type="PageNavigation", navigationSection=destino,
                                                            tooltipPlaceholderText=f"Ir a {etiqueta}")],
                                       "visualHeader": [props(show=False)], "background": [props(show=False)],
                                       "border": [props(show=True, radius=10, color=color("#FFFFFF"), width=0)]},
            "drillFilterOtherVisuals": True}


def boton_reset():
    est = lambda c: {"properties": {"show": lit(True), "fillColor": color(c), "transparency": lit(0)}}  # noqa: E731
    return {"visualType": "actionButton",
            "objects": {"icon": [{**props(shapeType="clearAllSlicers"), "selector": {"id": "default"}}, props(show=False)],
                        "text": [props(show=True),
                                 {**props(text="↺  Restablecer filtros", horizontalAlignment="center", fontColor=color("#FFFFFF"),
                                          fontSize=12, fontFamily="Segoe UI Semibold"), "selector": {"id": "default"}}],
                        "fill": [{**est("#BE263E"), "selector": {"id": "default"}}, {**est("#9E1C31"), "selector": {"id": "hover"}},
                                 {**est("#7E1627"), "selector": {"id": "selected"}}],
                        "outline": [{**props(show=False), "selector": {"id": "default"}}]},
            "visualContainerObjects": {"visualLink": [props(show=True, type="ClearAllSlicers",
                                                            tooltipPlaceholderText="Borrar todas las segmentaciones de esta página")],
                                       "visualHeader": [props(show=False)], "background": [props(show=False)],
                                       "border": [props(show=True, radius=10, color=color("#BE263E"))]},
            "drillFilterOtherVisuals": True}


# ---------------------------------------------------------------- páginas
def fondo_pagina(imagen, color_fondo="#050F1E"):
    return {"background": [{"properties": {
        "color": color(color_fondo), "transparency": lit(0),
        "image": {"image": {"name": lit(imagen),
                            "url": {"expr": {"ResourcePackageItem": {"PackageName": "RegisteredResources", "PackageType": 1, "ItemName": imagen}}},
                            "scaling": lit("Fit")}}}}]}


def construir_pagina(spec):
    pg = Pagina(spec["nombre"])
    for i, ((etq, ref), r) in enumerate(zip(spec["slicers"], P.slicer_rects(len(spec["slicers"])))):
        pg.agregar(f"slicer{i}", r, slicer(etq, ref))
    for i, (k, z) in enumerate(zip(spec["kpis"], kpi_zonas(spec))):
        es_soles = "S" in (FORMATOS.get(k["medida"][1:-1]) or "")
        pg.agregar(f"kpi{i}", z["valor"], tarjeta(k["medida"], k["etiqueta"], tam=21, decimales=0 if es_soles else None,
                                                  col_medida=k["color"]))
        if k["texto"]:
            pg.agregar(f"kpitexto{i}", z["extra"], tarjeta(k["texto"], k["etiqueta"], tam=10, col_medida=k["color"]))
        if k["sparkline"]:
            pg.agregar(f"kpispark{i}", z["extra"], imagen_medida(k["sparkline"]))
    for i, (g, z) in enumerate(zip(spec["graficos"], grafico_zonas(spec))):
        pg.agregar(f"graf{i}", z["visual"], grafico(g, tooltip=P.TOOLTIP["nombre"]))
    for i, (destino, etiqueta, _) in enumerate(P.NAV):
        pg.agregar(f"nav{i}", P.nav_rect(i), boton_nav(destino, etiqueta), how="InsertVisualButton")
    pg.agregar("reset", P.RESET, boton_reset(), how="InsertVisualButton")
    x, y, w, h = P.HEADER
    pg.agregar("periodo", (x + w - 560, y + 74, 440, 30), tarjeta("[Texto periodo]", "Periodo", tam=11, col="#D6E6F2"))
    pagina = {"$schema": ESQ_PAGINA, "name": spec["nombre"], "displayName": spec["titulo"], "displayOption": "FitToPage",
              "width": P.ANCHO, "height": P.ALTO, "objects": fondo_pagina(f"fondo_{spec['nombre']}.png")}
    return pagina, pg


def construir_tooltip():
    t = P.TOOLTIP
    pg = Pagina(t["nombre"])
    for i, (etq, ref) in enumerate(t["kpis"]):
        x, y = 12 + (i % 2) * 152, 56 + (i // 2) * 88
        es_soles = "S" in (FORMATOS.get(ref[1:-1]) or "")
        pg.agregar(f"tt{i}", (x + 8, y + 4, 132, 70), tarjeta(ref, etq, tam=15, etiqueta=True, decimales=0 if es_soles else None))
    pagina = {"$schema": ESQ_PAGINA, "name": t["nombre"], "displayName": t["titulo"], "displayOption": "FitToPage",
              "width": t["ancho"], "height": t["alto"], "objects": fondo_pagina("fondo_tooltip.png", "#0B1D33"), "type": "Tooltip",
              "pageBinding": {"name": ident("binding", t["nombre"]), "type": "Tooltip", "parameters": []},
              "visibility": "HiddenInViewMode"}
    return pagina, pg


def escribir(pagina, pg):
    carpeta = os.path.join(DEF, "pages", pagina["name"])
    os.makedirs(os.path.join(carpeta, "visuals"), exist_ok=True)
    with open(os.path.join(carpeta, "page.json"), "w", encoding="utf-8") as fh:
        json.dump(pagina, fh, ensure_ascii=False, indent=2)
    for v in pg.visuales:
        d = os.path.join(carpeta, "visuals", v["name"])
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "visual.json"), "w", encoding="utf-8") as fh:
            json.dump(v, fh, ensure_ascii=False, indent=2)


def actualizar_report_json():
    ruta = os.path.join(DEF, "report.json")
    with open(ruta, encoding="utf-8") as fh:
        rep = json.load(fh)
    rep["themeCollection"]["customTheme"]["name"] = TEMA
    items = [{"name": f"fondo_{p['nombre']}.png", "path": f"fondo_{p['nombre']}.png", "type": "Image"} for p in P.PAGINAS]
    items += [{"name": "fondo_tooltip.png", "path": "fondo_tooltip.png", "type": "Image"},
              {"name": TEMA, "path": TEMA + ".json", "type": "CustomTheme"}]
    for paquete in rep["resourcePackages"]:
        if paquete["name"] == "RegisteredResources":
            paquete["items"] = items
    with open(ruta, "w", encoding="utf-8") as fh:
        json.dump(rep, fh, ensure_ascii=False, indent=2)
    # quitar recursos que ya no se usan
    res = os.path.join(REPORTE, "StaticResources", "RegisteredResources")
    usados = {i["path"] for i in items} | {TEMA + ".json"}
    for f in os.listdir(res):
        if f not in usados:
            os.remove(os.path.join(res, f))


def main():
    pages = os.path.join(DEF, "pages")
    shutil.rmtree(pages, ignore_errors=True)
    os.makedirs(pages)
    orden = []
    for spec in P.PAGINAS:
        escribir(*construir_pagina(spec))
        orden.append(spec["nombre"])
    escribir(*construir_tooltip())
    orden.append(P.TOOLTIP["nombre"])
    with open(os.path.join(pages, "pages.json"), "w", encoding="utf-8") as fh:
        json.dump({"$schema": ESQ_PAGINAS, "pageOrder": orden, "activePageName": "resumen"}, fh, indent=2)
    actualizar_report_json()
    total = sum(len(os.listdir(os.path.join(pages, p, "visuals"))) for p in orden)
    print(f"Reporte generado: {len(orden)} páginas, {total} visuales")


if __name__ == "__main__":
    main()
