"""Dibuja los 4 diagramas de modelo estrella a partir de la estructura real de DW_NotariaLozano.
Salida: assets/estrella_<hecho>.png (1500x1100, mismo formato que las figuras 24-27 del informe).
Uso:  python -I tools/diagramas_estrella.py
"""
import math
import os
import subprocess

from PIL import Image, ImageDraw, ImageFont

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SALIDA = os.path.join(RAIZ, "assets")
F = r"C:\Windows\Fonts"
S = 2                                   # se dibuja a 2x y se reduce
ANCHO, ALTO = 1500, 1100

HECHOS = {
    "FACT_TRAMITES_FINANCIEROS": ("TRÁMITES FINANCIEROS", [
        "P1 · ¿Cuál es el trámite notarial más rentable y en qué trimestre presenta mayor demanda?",
        "P2 · ¿Qué empleado procesa el mayor volumen de dinero en efectivo?",
        "P3 · ¿Qué medios de pago prefieren las empresas frente a los clientes particulares?"]),
    "FACT_TIEMPOS_ATENCION": ("TIEMPOS DE ATENCIÓN", [
        "P7 · ¿Qué servicios tienen el mayor tiempo promedio de atención y cómo varía según el turno?",
        "P8 · ¿En qué etapas del trámite se registra la mayor espera promedio y cómo varía entre meses?"]),
    "FACT_DOCUMENTOS_OTORGADOS": ("DOCUMENTOS OTORGADOS", [
        "P5 · ¿Qué tipos de documentos se otorgan más y cómo varía su producción por mes?",
        "P6 · ¿Qué empleado registra más documentos otorgados y a qué servicios corresponden?"]),
    "FACT_TRAMITE_GENERAL": ("TRÁMITE GENERAL", [
        "P4 · ¿Qué cargo atiende la mayor cantidad de trámites de Escrituras Públicas?",
        "P1 · Demanda de trámites por servicio y trimestre (complementa al hecho financiero)."]),
}
DIM_DE = {"ID_Cliente": "DIM_CLIENTE", "ID_Servicio": "DIM_SERVICIO", "ID_Tiempo": "DIM_TIEMPO", "ID_Personal": "DIM_PERSONAL",
          "ID_Metodo": "DIM_METODO_PAGO", "ID_Estado_Pago": "DIM_ESTADO_PAGO", "ID_Etapa": "DIM_ETAPA_TRAMITE",
          "ID_Turno": "DIM_TURNO", "ID_TipoDocumento": "DIM_TIPO_DOCUMENTO", "ID_Notario": "DIM_NOTARIO"}
PRIORIDAD = {"DIM_TIEMPO": ["Fecha_Exacta", "Anio", "Trimestre_Texto", "Nombre_Mes", "Mes_Etiqueta"]}
MAX_ATRIB = 4

MARINO, AZUL_CLARO, BORDE, FILA, TEXTO, GRIS, LINEA = "#173D64", "#DCE8F5", "#8EA9C6", "#F1F5F9", "#1F2A37", "#6B7C8F", "#5B6F82"


def fuente(tipo, tam):
    return ImageFont.truetype(os.path.join(F, {"r": "segoeui.ttf", "b": "segoeuib.ttf", "s": "seguisb.ttf"}[tipo]), int(tam * S))


def columnas():
    q = ("SET NOCOUNT ON; SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, ISNULL(CHARACTER_MAXIMUM_LENGTH, -1), ISNULL(CAST(NUMERIC_PRECISION AS INT), -1), "
         "ISNULL(CAST(NUMERIC_SCALE AS INT), -1) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME LIKE 'DIM[_]%' OR TABLE_NAME LIKE 'FACT[_]%' "
         "ORDER BY TABLE_NAME, ORDINAL_POSITION")
    out = subprocess.run(["sqlcmd", "-S", r".\SQLEXPRESS", "-E", "-C", "-b", "-d", "DW_NotariaLozano", "-W", "-h", "-1", "-s", "|", "-Q", q],
                         capture_output=True, text=True, check=True).stdout
    t = {}
    for linea in out.splitlines():
        p = linea.strip().split("|")
        if len(p) == 6:
            tipo = p[2].upper()
            if p[2] in ("varchar", "nvarchar", "char"):
                tipo += f"({p[3]})"
            elif p[2] == "decimal":
                tipo += f"({p[4]},{p[5]})"
            t.setdefault(p[0], []).append((p[1], tipo))
    return t


def caja(d, x, y, w, titulo, filas, hecho=False):
    """filas: lista de (prefijo, nombre, tipo). Devuelve {nombre: y_centro} y la altura."""
    hh, rh = 44, 28
    h = hh + rh * len(filas)
    X = lambda v: int(v * S)  # noqa: E731
    d.rectangle([X(x), X(y), X(x + w), X(y + h)], fill="#FFFFFF", outline=BORDE, width=S)
    d.rectangle([X(x), X(y), X(x + w), X(y + hh)], fill=MARINO if hecho else AZUL_CLARO, outline=BORDE, width=S)
    d.text((X(x + 14), X(y + hh / 2)), titulo, font=fuente("b", 16), fill="#FFFFFF" if hecho else MARINO, anchor="lm")
    centros = {}
    for k, (pre, nom, tipo) in enumerate(filas):
        ry = y + hh + k * rh
        if k % 2 == 0:
            d.rectangle([X(x + 1), X(ry), X(x + w - 1), X(ry + rh)], fill=FILA)
        cx = x + 14
        if pre:
            d.text((X(cx), X(ry + rh / 2)), pre, font=fuente("b", 13), fill=TEXTO, anchor="lm")
            cx += d.textlength(pre + " ", font=fuente("b", 13)) / S
        col = GRIS if pre == "…" else TEXTO
        d.text((X(cx), X(ry + rh / 2)), nom, font=fuente("r", 13), fill=col, anchor="lm")
        if tipo:
            cx += d.textlength(nom + " ", font=fuente("r", 13)) / S
            d.text((X(cx), X(ry + rh / 2)), tipo, font=fuente("r", 12), fill=GRIS, anchor="lm")
        centros[nom] = ry + rh / 2
    d.rectangle([X(x), X(y), X(x + w), X(y + h)], outline=BORDE, width=S)   # borde al final para que no lo tape una fila
    return centros, h


def filas_dimension(dim, cols):
    pk = cols[0]
    resto = cols[1:]
    orden = PRIORIDAD.get(dim)
    if orden:
        resto = sorted(resto, key=lambda c: orden.index(c[0]) if c[0] in orden else 99)
    vis, ocultas = resto[:MAX_ATRIB], len(resto) - MAX_ATRIB
    filas = [("PK", pk[0], pk[1])] + [("—", c[0], c[1]) for c in vis]
    if ocultas > 0:
        filas.append(("…", f"+{ocultas} columna{'s' if ocultas > 1 else ''} más", ""))
    return filas


def diagrama(hecho, cols):
    titulo, preguntas = HECHOS[hecho]
    img = Image.new("RGB", (ANCHO * S, ALTO * S), "#FFFFFF")
    d = ImageDraw.Draw(img)
    d.text((50 * S, 32 * S), f"NOTARÍA LOZANO · {titulo}", font=fuente("b", 28), fill=MARINO)
    for k, p in enumerate(preguntas):
        d.text((50 * S, (84 + k * 24) * S), p, font=fuente("r", 16), fill=TEXTO)
    d.text((50 * S, (ALTO - 34) * S), "Fuente: DW_NotariaLozano (INFORMATION_SCHEMA). PK: clave primaria · FK: clave foránea · DD: dimensión degenerada.",
           font=fuente("r", 12), fill=GRIS)

    fcols = cols[hecho]
    fks = [c for c in fcols if c[0] in DIM_DE]
    filas_f = [("FK" if c[0] in DIM_DE else ("DD" if c[0] == "Nro_Tramite" else "—"), c[0], c[1]) for c in fcols]
    dims = [DIM_DE[c[0]] for c in fks]
    izq, der = dims[: math.ceil(len(dims) / 2)], dims[math.ceil(len(dims) / 2):]

    top = 84 + len(preguntas) * 24 + 40
    alto_f = 44 + 28 * len(filas_f)
    fx, fw = 555, 390
    fy = top + (ALTO - 60 - top - alto_f) / 2
    centros_f, _ = caja(d, fx, fy, fw, hecho, filas_f, hecho=True)

    def columna(lista, x, lado):
        alturas = [44 + 28 * len(filas_dimension(dm, cols[dm])) for dm in lista]
        hueco = (ALTO - 60 - top - sum(alturas)) / max(len(lista) - 1, 1)
        y = top
        for k, (dm, h) in enumerate(zip(lista, alturas)):
            centros, _ = caja(d, x, y, 400, dm, filas_dimension(dm, cols[dm]))
            pk = cols[dm][0][0]
            y_dim, y_fact = centros[pk], centros_f[pk]
            # cada conector baja por su propia vertical para que no se superpongan
            if lado == "izq":
                x_dim, x_fact, x_mid = x + 400, fx, x + 400 + 22 + k * 22
            else:
                x_dim, x_fact, x_mid = x, fx + fw, x - 22 - k * 22
            pts = [(x_fact, y_fact), (x_mid, y_fact), (x_mid, y_dim), (x_dim, y_dim)]
            d.line([(px * S, py * S) for px, py in pts], fill=LINEA, width=int(1.6 * S))
            # lado "1" (barra) junto a la dimensión, lado "N" (pata de gallo) junto al hecho
            sx = 1 if lado == "izq" else -1
            d.line([((x_dim + sx * 8) * S, (y_dim - 7) * S), ((x_dim + sx * 8) * S, (y_dim + 7) * S)], fill=LINEA, width=int(1.6 * S))
            for dy in (-7, 0, 7):
                d.line([((x_fact - sx * 12) * S, y_fact * S), (x_fact * S, (y_fact + dy) * S)], fill=LINEA, width=int(1.4 * S))
            d.text(((x_mid + 6 * (1 if lado == "izq" else -1)) * S, ((y_fact + y_dim) / 2) * S), "1 : N", font=fuente("r", 12),
                   fill=TEXTO, anchor="lm" if lado == "izq" else "rm")
            y += h + hueco

    columna(izq, 40, "izq")
    columna(der, ANCHO - 440, "der")
    return img.resize((ANCHO, ALTO), Image.LANCZOS)


def main():
    cols = columnas()
    os.makedirs(SALIDA, exist_ok=True)
    for hecho in HECHOS:
        ruta = os.path.join(SALIDA, f"estrella_{hecho.replace('FACT_', '').lower()}.png")
        diagrama(hecho, cols).save(ruta, optimize=True)
        print(ruta)


if __name__ == "__main__":
    main()
