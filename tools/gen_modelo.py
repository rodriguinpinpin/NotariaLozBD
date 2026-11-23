"""Genera el modelo semántico (TMDL) de NOTARIA_LOZANO.pbip a partir de DW_NotariaLozano.

- Lee columnas desde INFORMATION_SCHEMA (sqlcmd) y escribe una tabla .tmdl por tabla del DW.
- Relaciones 1:* correctas desde cada dimensión hacia los hechos.
- DIM_TIEMPO marcada como tabla de fechas con jerarquía Año > Trimestre > Mes > Día.
- Tabla _Medidas con todas las medidas (ver tools/medidas.py).
Uso:  python -I tools/gen_modelo.py   (con Power BI Desktop CERRADO)
"""
import os
import shutil
import subprocess
import sys
import uuid

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))
from medidas import MEDIDAS  # noqa: E402

MODELO = os.path.join(RAIZ, "powerbi", "NOTARIA_LOZANO.SemanticModel")
DEF = os.path.join(MODELO, "definition")
SERVIDOR = r"localhost\SQLEXPRESS"
BASE = "DW_NotariaLozano"

TIPOS = {"int": ("int64", "0"), "bigint": ("int64", "0"), "tinyint": ("int64", "0"),
         "varchar": ("string", None), "nvarchar": ("string", None), "char": ("string", None),
         "date": ("dateTime", "dd/mm/yyyy"), "datetime2": ("dateTime", "dd/mm/yyyy hh:nn"),
         "decimal": ("decimal", "#,##0.00"), "bit": ("boolean", None)}

ORDEN_POR = {("DIM_TIEMPO", "Nombre_Mes"): "Mes", ("DIM_TIEMPO", "Mes_Corto"): "Mes",
             ("DIM_TIEMPO", "Nombre_Dia"): "Dia_Semana", ("DIM_TIEMPO", "Anio_Mes"): "Orden_Mes", ("DIM_TIEMPO", "Mes_Etiqueta"): "Orden_Mes",
             ("DIM_TIEMPO", "Trimestre_Texto"): "Trimestre", ("DIM_ETAPA_TRAMITE", "Nombre_Etapa"): "Orden"}

# (hecho, columna, dimensión, columna)
RELACIONES = [
    (f, c, d, c) for f, cols in {
        "FACT_TRAMITES_FINANCIEROS": ["ID_Cliente", "ID_Servicio", "ID_Tiempo", "ID_Personal", "ID_Metodo", "ID_Estado_Pago", "ID_Turno", "ID_Notario"],
        "FACT_TIEMPOS_ATENCION": ["ID_Servicio", "ID_Personal", "ID_Tiempo", "ID_Etapa", "ID_Turno", "ID_Cliente", "ID_Notario"],
        "FACT_DOCUMENTOS_OTORGADOS": ["ID_Servicio", "ID_Personal", "ID_Tiempo", "ID_TipoDocumento", "ID_Cliente", "ID_Turno", "ID_Notario"],
        "FACT_TRAMITE_GENERAL": ["ID_Tiempo", "ID_Servicio", "ID_Notario", "ID_Cliente", "ID_Personal", "ID_Estado_Pago", "ID_Turno", "ID_Metodo"],
    }.items() for c in cols for d in [{
        "ID_Cliente": "DIM_CLIENTE", "ID_Servicio": "DIM_SERVICIO", "ID_Tiempo": "DIM_TIEMPO", "ID_Personal": "DIM_PERSONAL",
        "ID_Metodo": "DIM_METODO_PAGO", "ID_Estado_Pago": "DIM_ESTADO_PAGO", "ID_Etapa": "DIM_ETAPA_TRAMITE",
        "ID_Turno": "DIM_TURNO", "ID_TipoDocumento": "DIM_TIPO_DOCUMENTO", "ID_Notario": "DIM_NOTARIO"}[c]]
]


def columnas_dw():
    q = ("SET NOCOUNT ON; SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS "
         "WHERE TABLE_SCHEMA='dbo' AND (TABLE_NAME LIKE 'DIM[_]%' OR TABLE_NAME LIKE 'FACT[_]%') "
         "ORDER BY TABLE_NAME, ORDINAL_POSITION")
    out = subprocess.run(["sqlcmd", "-S", r".\SQLEXPRESS", "-E", "-C", "-b", "-d", BASE, "-W", "-h", "-1",
                          "-s", "|", "-Q", q], capture_output=True, text=True, check=True).stdout
    tablas = {}
    for linea in out.splitlines():
        partes = linea.strip().split("|")
        if len(partes) == 3:
            tablas.setdefault(partes[0], []).append((partes[1], partes[2]))
    return tablas


def q(nombre):
    return f"'{nombre}'" if any(ch in nombre for ch in " -%.()") or not nombre.isascii() else nombre


def tabla_tmdl(tabla, cols):
    es_hecho = tabla.startswith("FACT_")
    L = [f"table {tabla}"]
    if tabla == "DIM_TIEMPO":
        L.append("\tdataCategory: Time")
    L.append("")
    for col, sqltipo in cols:
        tipo, fmt = TIPOS[sqltipo]
        L.append(f"\tcolumn {col}")
        L.append(f"\t\tdataType: {tipo}")
        if tabla == "DIM_TIEMPO" and col == "Fecha_Exacta":
            L.append("\t\tisKey")
            fmt = "dd/mm/yyyy"
        if fmt:
            L.append(f"\t\tformatString: {fmt}")
        if es_hecho and (col.startswith("ID_") or col == "Nro_Tramite"):
            L.append("\t\tisHidden")
        L.append("\t\tsummarizeBy: none" if (col.startswith("ID_") or tipo != "decimal") else "\t\tsummarizeBy: sum")
        L.append(f"\t\tsourceColumn: {col}")
        if (tabla, col) in ORDEN_POR:
            L.append(f"\t\tsortByColumn: {ORDEN_POR[(tabla, col)]}")
        if tipo == "dateTime":
            L.append("")
            L.append("\t\tannotation UnderlyingDateTimeDataType = Date")
        L.append("")
    if tabla == "DIM_TIEMPO":
        L += ["\thierarchy 'Jerarquía de fechas'", "",
              "\t\tlevel Año", "\t\t\tcolumn: Anio", "",
              "\t\tlevel Trimestre", "\t\t\tcolumn: Trimestre_Texto", "",
              "\t\tlevel Mes", "\t\t\tcolumn: Nombre_Mes", "",
              "\t\tlevel Día", "\t\t\tcolumn: Dia", ""]
    L += [f"\tpartition {tabla} = m", "\t\tmode: import", "\t\tsource =", "\t\t\t\tlet",
          f'\t\t\t\t    Origen = Sql.Database("{SERVIDOR}", "{BASE}"),',
          f'\t\t\t\t    Datos = Origen{{[Schema = "dbo", Item = "{tabla}"]}}[Data]',
          "\t\t\t\tin", "\t\t\t\t    Datos", "", "\tannotation PBI_ResultType = Table", ""]
    return "\n".join(L)


def medidas_tmdl():
    L = ["table _Medidas", ""]
    for m in MEDIDAS:
        if m.get("desc"):
            L.append(f"\t/// {m['desc']}")
        lineas = m["dax"].strip("\n").split("\n")
        if len(lineas) == 1:
            L.append(f"\tmeasure {q(m['nombre'])} = {lineas[0].strip()}")
        else:
            L.append(f"\tmeasure {q(m['nombre'])} =")
            L += [f"\t\t\t{x.rstrip()}" for x in lineas]
        if m.get("fmt"):
            L.append(f"\t\tformatString: {m['fmt']}")
        if m.get("cat"):
            L.append(f"\t\tdataCategory: {m['cat']}")
        L.append(f"\t\tdisplayFolder: {m['carpeta']}")
        L.append("")
    L += ["\tcolumn Dummy", "\t\tdataType: string", "\t\tisHidden", "\t\tsummarizeBy: none", "\t\tsourceColumn: Dummy", "",
          "\tpartition _Medidas = m", "\t\tmode: import", "\t\tsource = #table(type table [Dummy = text], {})", "",
          "\tannotation PBI_ResultType = Table", ""]
    return "\n".join(L)


def main():
    tablas = columnas_dw()
    if len(tablas) != 14:
        sys.exit(f"Se esperaban 14 tablas en {BASE}, hay {len(tablas)}")

    # Limpiar definición anterior (tablas con relaciones erróneas, tablas de fecha automáticas, cultura)
    tdir = os.path.join(DEF, "tables")
    shutil.rmtree(tdir, ignore_errors=True)
    os.makedirs(tdir)
    shutil.rmtree(os.path.join(DEF, "cultures"), ignore_errors=True)
    # cache.abf guarda los datos importados; solo se borra con --limpiar-cache (cambio de columnas/tablas)
    if "--limpiar-cache" in sys.argv:
        p = os.path.join(MODELO, ".pbi", "cache.abf")
        if os.path.exists(p):
            os.remove(p)

    for t, cols in tablas.items():
        with open(os.path.join(tdir, f"{t}.tmdl"), "w", encoding="utf-8", newline="\n") as fh:
            fh.write(tabla_tmdl(t, cols))
    with open(os.path.join(tdir, "_Medidas.tmdl"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(medidas_tmdl())

    rel = []
    for f, c, d, dc in RELACIONES:
        rel += [f"relationship {uuid.uuid5(uuid.NAMESPACE_URL, f + c)}", f"\tfromColumn: {f}.{c}", f"\ttoColumn: {d}.{dc}", ""]
    with open(os.path.join(DEF, "relationships.tmdl"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(rel))

    orden = sorted(tablas) + ["_Medidas"]
    modelo = ["model Model", "\tculture: es-ES", "\tdefaultPowerBIDataSourceVersion: powerBI_V3",
              "\tsourceQueryCulture: en-US", "\tdataAccessOptions", "\t\tlegacyRedirects", "\t\treturnErrorValuesAsNull", "",
              "annotation __PBI_TimeIntelligenceEnabled = 0", "",
              "annotation PBI_QueryOrder = [" + ",".join(f'"{t}"' for t in orden) + "]", "",
              'annotation PBI_ProTooling = ["DaxQueryView_Desktop","DevMode"]', ""]
    modelo += [f"ref table {q(t)}" for t in orden] + [""]
    with open(os.path.join(DEF, "model.tmdl"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(modelo))
    print(f"Modelo generado: {len(tablas)} tablas, {len(RELACIONES)} relaciones, {len(MEDIDAS)} medidas")


if __name__ == "__main__":
    main()
