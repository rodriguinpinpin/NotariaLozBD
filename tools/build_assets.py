"""Genera los fondos PNG (1920x1080) de cada página y layout.json.
Dibuja a escala 2x y reduce con LANCZOS para bordes suaves.
Uso:  python -I tools/build_assets.py
"""
import json
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))
import paginas as P  # noqa: E402

S = 2
RES = os.path.join(RAIZ, "powerbi", "NOTARIA_LOZANO.Report", "StaticResources", "RegisteredResources")
LOGO_ORIGEN = os.path.join(RAIZ, "assets", "logo_origen.png")
FUENTES = r"C:\Windows\Fonts"
FONDO = "#EEF2F7"


def f(nombre, tam):
    archivo = {"regular": "segoeui.ttf", "semibold": "seguisb.ttf", "bold": "segoeuib.ttf", "light": "segoeuil.ttf"}[nombre]
    return ImageFont.truetype(os.path.join(FUENTES, archivo), int(tam * S))


def rgb(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mezcla(color, fondo, t):
    """Color opaco equivalente a `color` con opacidad t sobre `fondo`."""
    a, b = rgb(color), rgb(fondo)
    return tuple(int(b[k] + (a[k] - b[k]) * t) for k in range(3)) + (255,)


def R(rect):
    x, y, w, h = rect
    return [x * S, y * S, (x + w) * S, (y + h) * S]


FONDO_OSCURO = "#050F1E"


def sombra(base, rect, radio, alpha=110, blur=16, dy=10):
    capa = Image.new("RGBA", base.size, (0, 0, 0, 0))
    x0, y0, x1, y1 = R(rect)
    ImageDraw.Draw(capa, "RGBA").rounded_rectangle([x0, y0 + dy * S, x1, y1 + dy * S], radio * S, fill=(0, 4, 12, alpha))
    base.alpha_composite(capa.filter(ImageFilter.GaussianBlur(blur * S)))


def vidrio(base, rect, radio=18, relleno=16, borde=34):
    """Panel de vidrio: sombra oscura, relleno blanco translúcido, brillo superior y borde claro."""
    sombra(base, rect, radio)
    x0, y0, x1, y1 = R(rect)
    capa = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(capa)
    d.rounded_rectangle([x0, y0, x1, y1], radio * S, fill=(255, 255, 255, relleno))
    # brillo: degradado blanco en el tercio superior
    alto = max(2, (y1 - y0) // 3)
    brillo = degradado((x1 - x0, alto), "#FFFFFF", "#FFFFFF", horizontal=False)
    alfa = Image.linear_gradient("L").resize((x1 - x0, alto)).point(lambda v: int((255 - v) * 0.07))
    brillo.putalpha(alfa)
    mascara = Image.new("L", (x1 - x0, y1 - y0), 0)
    ImageDraw.Draw(mascara).rounded_rectangle([0, 0, x1 - x0 - 1, y1 - y0 - 1], radio * S, fill=255)
    capa_b = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
    capa_b.paste(brillo, (0, 0))
    capa_b.putalpha(ImageChops_multiply(capa_b.getchannel("A"), mascara))
    capa.alpha_composite(capa_b, (x0, y0))
    d.rounded_rectangle([x0, y0, x1, y1], radio * S, outline=(255, 255, 255, borde), width=max(1, S))
    base.alpha_composite(capa)


def ImageChops_multiply(a, b):
    from PIL import ImageChops
    return ImageChops.multiply(a, b)


def fondo_manchas():
    """Fondo oscuro con manchas difusas de color (azul, marino, rojo, turquesa), como la versión web."""
    w, h = P.ANCHO // 4, P.ALTO // 4
    img = Image.new("RGBA", (w, h), rgb(FONDO_OSCURO))
    capa = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(capa)
    for cx, cy, r, col, a in ((40, 20, 150, P.AZUL, 150), (300, 150, 120, P.MARINO, 190), (480, 280, 130, P.ROJO, 105),
                              (380, -10, 80, P.TURQUESA, 70), (60, 260, 90, P.MARINO, 160)):
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=rgb(col, a))
    img.alpha_composite(capa.filter(ImageFilter.GaussianBlur(55)))
    return img.resize((P.ANCHO * S, P.ALTO * S), Image.BICUBIC)


def tarjeta(base, rect, radio=16, color=None):
    vidrio(base, rect, radio)


def degradado(tam, c1, c2, horizontal=True):
    w, h = tam
    a, b = rgb(c1), rgb(c2)
    g = Image.new("RGBA", (w, h))
    px = ImageDraw.Draw(g, "RGBA")
    n = w if horizontal else h
    for i in range(n):
        t = i / max(n - 1, 1)
        col = tuple(int(a[k] + (b[k] - a[k]) * t) for k in range(4))
        px.line([(i, 0), (i, h)] if horizontal else [(0, i), (w, i)], fill=col)
    return g


# ---------------------------------------------------------------- iconos (trazo)
def icono(d, nombre, cx, cy, r, color, w=2.2):
    cx, cy, r, w = cx * S, cy * S, r * S, max(1, int(w * S))
    c = rgb(color) if isinstance(color, str) else color
    L = lambda pts: d.line(pts, fill=c, width=w, joint="curve")  # noqa: E731
    E = lambda x0, y0, x1, y1: d.ellipse([x0, y0, x1, y1], outline=c, width=w)  # noqa: E731
    if nombre == "coins":
        E(cx - r * .55, cy - r * .55, cx + r * .55, cy + r * .55)
        d.text((cx, cy + r * .02), "S/", font=ImageFont.truetype(os.path.join(FUENTES, "seguisb.ttf"), int(r * .55)), fill=c, anchor="mm")
        d.arc([cx - r * .75, cy - r * .75, cx + r * .75, cy + r * .75], 200, 340, fill=c, width=w)
    elif nombre in ("doc", "receipt"):
        x0, y0, x1, y1 = cx - r * .42, cy - r * .55, cx + r * .42, cy + r * .55
        L([(x0, y0), (x1 - r * .25, y0), (x1, y0 + r * .25), (x1, y1), (x0, y1), (x0, y0)])
        L([(x1 - r * .25, y0), (x1 - r * .25, y0 + r * .25), (x1, y0 + r * .25)])
        for k in range(3):
            yy = cy - r * .12 + k * r * .2
            L([(x0 + r * .18, yy), (x1 - r * .18 - (r * .2 if k == 2 else 0), yy)])
        if nombre == "receipt":
            d.text((cx, cy - r * .32), "$", font=ImageFont.truetype(os.path.join(FUENTES, "seguisb.ttf"), int(r * .3)), fill=c, anchor="mm")
    elif nombre == "users":
        E(cx - r * .55, cy - r * .5, cx - r * .05, cy)
        d.arc([cx - r * .8, cy + r * .05, cx + r * .2, cy + r * 1.05], 180, 360, fill=c, width=w)
        E(cx + r * .05, cy - r * .62, cx + r * .5, cy - r * .17)
        d.arc([cx - r * .1, cy - r * .1, cx + r * .75, cy + r * .75], 200, 360, fill=c, width=w)
    elif nombre == "clock":
        E(cx - r * .6, cy - r * .6, cx + r * .6, cy + r * .6)
        L([(cx, cy - r * .35), (cx, cy), (cx + r * .28, cy + r * .15)])
    elif nombre == "hourglass":
        x0, x1, y0, y1 = cx - r * .4, cx + r * .4, cy - r * .58, cy + r * .58
        L([(x0 - r * .08, y0), (x1 + r * .08, y0)]); L([(x0 - r * .08, y1), (x1 + r * .08, y1)])
        L([(x0, y0), (x1, y0), (cx + r * .06, cy), (x1, y1), (x0, y1), (cx - r * .06, cy), (x0, y0)])
    elif nombre == "layers":
        for k, dy in enumerate((-r * .32, 0, r * .32)):
            pts = [(cx, cy - r * .3 + dy), (cx + r * .6, cy + dy), (cx, cy + r * .3 + dy), (cx - r * .6, cy + dy)]
            if k == 0:
                L(pts + [pts[0]])
            else:
                L([pts[3], pts[2], pts[1]])
    elif nombre == "percent":
        E(cx - r * .5, cy - r * .5, cx - r * .12, cy - r * .12)
        E(cx + r * .12, cy + r * .12, cx + r * .5, cy + r * .5)
        L([(cx + r * .45, cy - r * .5), (cx - r * .45, cy + r * .5)])
    elif nombre == "tag":
        pts = [(cx - r * .55, cy - r * .2), (cx - r * .1, cy - r * .58), (cx + r * .55, cy - r * .58), (cx + r * .55, cy + r * .1),
               (cx + r * .05, cy + r * .58), (cx - r * .55, cy - r * .2)]
        L(pts)
        E(cx + r * .2, cy - r * .35, cx + r * .36, cy - r * .19)
    elif nombre == "trend":
        L([(cx - r * .6, cy + r * .4), (cx - r * .2, cy), (cx + r * .05, cy + r * .2), (cx + r * .55, cy - r * .35)])
        L([(cx + r * .25, cy - r * .38), (cx + r * .58, cy - r * .38), (cx + r * .58, cy - r * .05)])
    elif nombre == "chart":
        for k, hh in enumerate((.45, .8, .6)):
            x = cx - r * .45 + k * r * .45
            L([(x, cy + r * .5), (x, cy + r * .5 - r * hh)])
        L([(cx - r * .65, cy + r * .55), (cx + r * .65, cy + r * .55)])
    elif nombre == "gear":
        E(cx - r * .35, cy - r * .35, cx + r * .35, cy + r * .35)
        E(cx - r * .12, cy - r * .12, cx + r * .12, cy + r * .12)
        for k in range(8):
            a = k * math.pi / 4
            L([(cx + math.cos(a) * r * .36, cy + math.sin(a) * r * .36), (cx + math.cos(a) * r * .55, cy + math.sin(a) * r * .55)])
    elif nombre == "calendar":
        x0, y0, x1, y1 = cx - r * .55, cy - r * .45, cx + r * .55, cy + r * .55
        d.rounded_rectangle([x0, y0, x1, y1], int(r * .1), outline=c, width=w)
        L([(x0, y0 + r * .28), (x1, y0 + r * .28)])
        L([(cx - r * .28, y0 - r * .15), (cx - r * .28, y0 + r * .1)]); L([(cx + r * .28, y0 - r * .15), (cx + r * .28, y0 + r * .1)])
        for i in range(3):
            for j in range(2):
                px, py = cx - r * .3 + i * r * .3, cy + r * .02 + j * r * .25
                d.ellipse([px - w, py - w, px + w, py + w], fill=c)
    elif nombre == "check":
        E(cx - r * .6, cy - r * .6, cx + r * .6, cy + r * .6)
        L([(cx - r * .28, cy), (cx - r * .06, cy + r * .24), (cx + r * .3, cy - r * .2)])
    elif nombre == "repeat":
        d.arc([cx - r * .55, cy - r * .55, cx + r * .55, cy + r * .55], 30, 300, fill=c, width=w)
        ax, ay = cx + math.cos(math.radians(300)) * r * .55, cy + math.sin(math.radians(300)) * r * .55
        L([(ax - r * .25, ay - r * .05), (ax, ay), (ax - r * .02, ay + r * .25)])
    elif nombre == "building":
        L([(cx - r * .62, cy - r * .22), (cx, cy - r * .6), (cx + r * .62, cy - r * .22), (cx - r * .62, cy - r * .22)])
        for k in range(4):
            x = cx - r * .42 + k * r * .28
            L([(x, cy - r * .1), (x, cy + r * .4)])
        L([(cx - r * .62, cy + r * .5), (cx + r * .62, cy + r * .5)])


# ---------------------------------------------------------------- piezas comunes
def logo():
    if not os.path.exists(LOGO_ORIGEN):
        sys.exit(f"Falta {LOGO_ORIGEN}")
    return Image.open(LOGO_ORIGEN).convert("RGBA")


def barra_lateral(base, d, activa):
    vidrio(base, (10, 10, P.SIDEBAR - 20, P.ALTO - 20), 18)
    # tarjeta del logo
    caja = (20, 22, P.SIDEBAR - 40, 140)
    d.rounded_rectangle(R(caja), 14 * S, fill=rgb("#FFFFFF"))
    lg = logo()
    lw, lh = lg.size
    esc = min((caja[2] - 24) * S / lw, (caja[3] - 20) * S / lh)
    lg = lg.resize((int(lw * esc), int(lh * esc)), Image.LANCZOS)
    base.alpha_composite(lg, (int((caja[0] + caja[2] / 2) * S - lg.size[0] / 2), int((caja[1] + caja[3] / 2) * S - lg.size[1] / 2)))
    d.line([20 * S, 186 * S, 56 * S, 186 * S], fill=rgb(P.ROJO), width=3 * S)
    d.text((20 * S, 198 * S), "PANEL DE GESTIÓN", font=f("semibold", 12), fill=rgb("#8FB2CC"))
    for i, (pag, etiqueta, ico) in enumerate(P.NAV):
        r = P.nav_rect(i)
        x, y, w, h = r
        if pag == activa:   # píldora azul translúcida con borde luminoso y marca roja, como en la web
            capa = Image.new("RGBA", base.size, (0, 0, 0, 0))
            dc = ImageDraw.Draw(capa)
            dc.rounded_rectangle(R(r), 12 * S, fill=rgb(P.AZUL, 120), outline=(63, 167, 220, 140), width=S)
            base.alpha_composite(capa.filter(ImageFilter.GaussianBlur(0.6 * S)))
            d.rounded_rectangle(R((x, y + 12, 3, h - 24)), 2 * S, fill=rgb("#E2546B"))
            col_t, col_i = rgb("#FFFFFF"), rgb("#FFFFFF")
        else:
            col_t, col_i = rgb("#B8D0E2"), rgb("#7FA6C4")
        icono(d, ico, x + 26, y + h / 2, 15, col_i, w=1.8)
        d.text(((x + 50) * S, (y + h / 2) * S), etiqueta, font=f("semibold" if pag == activa else "regular", 14), fill=col_t, anchor="lm")
    # ayuda
    d.line([20 * S, 628 * S, (P.SIDEBAR - 20) * S, 628 * S], fill=rgb("#26445E"), width=S)
    d.text((20 * S, 646 * S), "EXPLORA LOS DATOS", font=f("semibold", 12), fill=rgb("#8FB2CC"))
    for k, t in enumerate(["Haz clic en una barra o sector", "para filtrar toda la página.", "",
                           "Pasa el cursor sobre un servicio", "para ver su ficha de detalle."]):
        d.text((20 * S, (672 + k * 20) * S), t, font=f("regular", 13), fill=rgb("#C9DCEA"))
    d.ellipse([20 * S, 784 * S, 28 * S, 792 * S], fill=rgb(P.ROJO))
    d.text((36 * S, 788 * S), "Datos interactivos", font=f("regular", 13), fill=rgb("#C9DCEA"), anchor="lm")
    d.line([20 * S, 988 * S, (P.SIDEBAR - 20) * S, 988 * S], fill=rgb("#26445E"), width=S)
    d.text((20 * S, 1002 * S), "NOTARÍA LOZANO", font=f("bold", 15), fill=rgb("#FFFFFF"))
    d.text((20 * S, 1028 * S), "Datos al 22/11/2026 · DW_NotariaLozano", font=f("regular", 11), fill=rgb("#8FB2CC"))


def encabezado(base, d, pag):
    x, y, w, h = P.HEADER
    vidrio(base, P.HEADER, 18)
    g = degradado((w * S, h * S), "#0876AA", "#0876AA")
    g.putalpha(Image.linear_gradient("L").rotate(90).resize(g.size).point(lambda v: int(v * 0.22)))
    capa = Image.new("RGBA", g.size, (0, 0, 0, 0))
    deco = ImageDraw.Draw(capa)
    for k, rr in enumerate((170, 128, 88)):
        cx, cy = (w - 230) * S, (h + 70) * S
        deco.ellipse([cx - rr * S, cy - rr * S, cx + rr * S, cy + rr * S], outline=(255, 255, 255, 22 + k * 6), width=(12 - k * 3) * S)
    deco.arc([(w - 420) * S, (-90) * S, (w - 240) * S, 90 * S], 15, 105, fill=rgb(P.ROJO, 200), width=6 * S)
    g.alpha_composite(capa)
    mascara = Image.new("L", g.size, 0)
    ImageDraw.Draw(mascara).rounded_rectangle([0, 0, w * S, h * S], 18 * S, fill=255)
    from PIL import ImageChops
    g.putalpha(ImageChops.multiply(g.getchannel("A"), mascara))
    base.alpha_composite(g, (x * S, y * S))
    d.line([(x + 28) * S, (y + 25) * S, (x + 48) * S, (y + 25) * S], fill=rgb(P.ROJO), width=3 * S)
    d.text(((x + 58) * S, (y + 25) * S), "NOTARÍA LOZANO  /  INTELIGENCIA DE GESTIÓN", font=f("semibold", 12), fill=rgb("#9EC3DD"), anchor="lm")
    d.text(((x + 28) * S, (y + 40) * S), pag["titulo"], font=f("semibold", 30), fill=rgb("#FFFFFF"))
    d.text(((x + 28) * S, (y + 84) * S), pag["subtitulo"], font=f("regular", 14), fill=rgb("#C9DDEB"))
    cx, cy = x + w - 62, y + h / 2
    capa = Image.new("RGBA", base.size, (0, 0, 0, 0))
    ImageDraw.Draw(capa).ellipse([(cx - 36) * S, (cy - 36) * S, (cx + 36) * S, (cy + 36) * S], fill=(255, 255, 255, 34),
                                 outline=(255, 255, 255, 110), width=S)
    base.alpha_composite(capa)
    icono(d, pag["icono"], cx, cy, 30, "#FFFFFF", w=2.6)


def kpi_zonas(pag):
    zonas = []
    for k, r in zip(pag["kpis"], P.kpi_rects(len(pag["kpis"]))):
        x, y, w, h = r
        z = dict(tarjeta=r, icono=(x + 40, y + h / 2), etiqueta=(x + 76, y + 16))
        if k["sparkline"] or k["texto"]:
            z["valor"] = (x + 70, y + 28, w - 78, 52)
            z["extra"] = (x + 70, y + 74, w - 78, 40)
        else:
            z["valor"] = (x + 70, y + 36, w - 78, 66)
        zonas.append(z)
    return zonas


def grafico_zonas(pag):
    rects = []
    for fila, spans in zip((P.FILA1, P.FILA2), pag["filas"]):
        rects += P.fila_rects(fila, spans)
    return [dict(tarjeta=r, visual=(r[0] + 22, r[1] + 10, r[2] - 32, r[3] - 20)) for r in rects]


def pagina(pag):
    base = fondo_manchas()
    d = ImageDraw.Draw(base, "RGBA")
    barra_lateral(base, d, pag["nombre"])
    encabezado(base, d, pag)
    d = ImageDraw.Draw(base, "RGBA")
    tarjeta(base, P.FILTROS, 12)
    for i, (k, z) in enumerate(zip(pag["kpis"], kpi_zonas(pag))):
        col = P.ACENTOS[i % len(P.ACENTOS)]
        tarjeta(base, z["tarjeta"])
        x, y, w, h = z["tarjeta"]
        d.rounded_rectangle(R((x, y + 18, 5, h - 36)), 3 * S, fill=rgb(col))
        cx, cy = z["icono"]
        capa = Image.new("RGBA", base.size, (0, 0, 0, 0))   # halo de color detrás del icono
        ImageDraw.Draw(capa).ellipse([(cx - 34) * S, (cy - 34) * S, (cx + 34) * S, (cy + 34) * S], fill=rgb(col, 90))
        base.alpha_composite(capa.filter(ImageFilter.GaussianBlur(14 * S)))
        d.rounded_rectangle([(cx - 24) * S, (cy - 24) * S, (cx + 24) * S, (cy + 24) * S], 12 * S, fill=mezcla(col, "#0B1D33", 0.42),
                            outline=mezcla(col, "#0B1D33", 0.75), width=S)
        icono(d, k["icono"], cx, cy, 22, "#FFFFFF")
        d.text((z["etiqueta"][0] * S, z["etiqueta"][1] * S), k["etiqueta"], font=f("semibold", 13), fill=rgb("#A9BDD2"))
    for i, z in enumerate(grafico_zonas(pag)):
        tarjeta(base, z["tarjeta"])
        x, y, w, h = z["tarjeta"]
        d.rounded_rectangle(R((x + 12, y + 17, 4, 18)), 2 * S, fill=rgb(P.ACENTOS[i % len(P.ACENTOS)]))
    return base.resize((P.ANCHO, P.ALTO), Image.LANCZOS).convert("RGB")


def tooltip_fondo():
    t = P.TOOLTIP
    base = Image.new("RGBA", (t["ancho"] * S, t["alto"] * S), rgb("#0B1D33"))
    d = ImageDraw.Draw(base, "RGBA")
    g = degradado((t["ancho"] * S, 44 * S), "#0A2846", "#0B73A6")
    base.alpha_composite(g, (0, 0))
    d.text((14 * S, 22 * S), t["titulo"].upper(), font=f("semibold", 12), fill=rgb("#FFFFFF"), anchor="lm")
    for i in range(4):
        x, y = 12 + (i % 2) * 152, 56 + (i // 2) * 88
        d.rounded_rectangle(R((x, y, 144, 78)), 10 * S, fill=mezcla("#FFFFFF", "#0B1D33", 0.07), outline=mezcla("#FFFFFF", "#0B1D33", 0.16), width=S)
        d.rounded_rectangle(R((x, y + 14, 4, 50)), 2 * S, fill=rgb(P.ACENTOS[i]))
    return base.resize((t["ancho"], t["alto"]), Image.LANCZOS).convert("RGB")


def main():
    os.makedirs(RES, exist_ok=True)
    layout = {}
    for pag in P.PAGINAS:
        pagina(pag).save(os.path.join(RES, f"fondo_{pag['nombre']}.png"), optimize=True)
        layout[pag["nombre"]] = dict(kpis=kpi_zonas(pag), graficos=grafico_zonas(pag), slicers=P.slicer_rects(len(pag["slicers"])),
                                     nav=[P.nav_rect(i) for i in range(len(P.NAV))], reset=P.RESET,
                                     periodo=(P.X1 - 520, P.HEADER[1] + 78, 400, 26))
    tooltip_fondo().save(os.path.join(RES, "fondo_tooltip.png"), optimize=True)
    with open(os.path.join(RAIZ, "assets", "layout.json"), "w", encoding="utf-8") as fh:
        json.dump(layout, fh, ensure_ascii=False, indent=1)
    print("Fondos generados:", ", ".join(f"fondo_{p['nombre']}.png" for p in P.PAGINAS), "+ fondo_tooltip.png")


if __name__ == "__main__":
    main()
