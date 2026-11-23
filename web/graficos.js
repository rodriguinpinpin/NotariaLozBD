/* =====================================================================
   Gráficos SVG animados sin librerías. Las animaciones son clases CSS
   (estilos.css): .crece-y / .crece-x (barras), .dibuja (líneas y donas),
   .aparece (áreas y textos), .salta (puntos). --i escalona la entrada.
   ===================================================================== */
(function (g) {
  "use strict";
  const NS = "http://www.w3.org/2000/svg";
  const s = (tag, attrs = {}, padre) => {
    const e = document.createElementNS(NS, tag);
    for (const [k, v] of Object.entries(attrs)) if (v != null) e.setAttribute(k, v);
    if (padre) padre.appendChild(e);
    return e;
  };
  const corto = (v) => {
    const a = Math.abs(v);
    if (a >= 1e6) return (v / 1e6).toFixed(1).replace(/\.0$/, "") + " M";
    if (a >= 1e3) return (v / 1e3).toFixed(a >= 1e4 ? 0 : 1).replace(/\.0$/, "") + "k";
    return Math.round(v * 10) / 10 + "";
  };
  /** Máximo del eje = 4 pasos "redondos" (1, 2, 2.5, 5 × 10^k), así las etiquetas quedan 10k, 20k, 30k… */
  function maximoBonito(v) {
    if (v <= 0) return 4;
    const paso = v / 4, e = Math.pow(10, Math.floor(Math.log10(paso))), m = paso / e;
    return (m <= 1 ? 1 : m <= 2 ? 2 : m <= 2.5 ? 2.5 : m <= 5 ? 5 : 10) * e * 4;
  }
  function lienzo(el) {
    el.innerHTML = "";
    const w = Math.max(el.clientWidth, 200), h = Math.max(el.clientHeight, 120);
    const svg = s("svg", { viewBox: `0 0 ${w} ${h}`, role: "img" }, el);
    const defs = s("defs", {}, svg);
    return { svg, defs, w, h };
  }
  let nGrad = 0;
  function degradado(defs, color, vertical = true, a1 = 1, a2 = 0.55) {
    const id = "gr" + ++nGrad;
    const gr = s("linearGradient", { id, x1: 0, y1: 0, x2: vertical ? 0 : 1, y2: vertical ? 1 : 0 }, defs);
    s("stop", { offset: "0%", "stop-color": color, "stop-opacity": a1 }, gr);
    s("stop", { offset: "100%", "stop-color": color, "stop-opacity": a2 }, gr);
    return `url(#${id})`;
  }

  // ---------------- tooltip de vidrio ----------------
  const tip = document.createElement("div");
  tip.className = "tooltip";
  tip.setAttribute("role", "status");
  document.addEventListener("DOMContentLoaded", () => document.body.appendChild(tip));
  const tooltip = {
    mostrar(html, ev) {
      tip.innerHTML = html;
      tip.classList.add("visible");
      tooltip.mover(ev);
    },
    mover(ev) {
      const r = tip.getBoundingClientRect();
      let x = ev.clientX + 16, y = ev.clientY - r.height - 12;
      if (x + r.width > innerWidth - 8) x = ev.clientX - r.width - 16;
      if (y < 8) y = ev.clientY + 18;
      tip.style.left = x + "px";
      tip.style.top = y + "px";
    },
    ocultar() { tip.classList.remove("visible"); },
  };
  function conTooltip(nodo, html, alClic) {
    nodo.addEventListener("pointerenter", (ev) => tooltip.mostrar(typeof html === "function" ? html() : html, ev));
    nodo.addEventListener("pointermove", (ev) => tooltip.mover(ev));
    nodo.addEventListener("pointerleave", () => tooltip.ocultar());
    if (alClic) {
      nodo.addEventListener("click", alClic);
      nodo.setAttribute("tabindex", "0");
      nodo.addEventListener("keydown", (ev) => { if (ev.key === "Enter" || ev.key === " ") { ev.preventDefault(); alClic(); } });
    }
  }
  const filaTip = (k, v) => `<div class="fila"><span>${k}</span><span>${v}</span></div>`;

  // ---------------- barras horizontales ----------------
  function barrasH(el, items, o = {}) {
    const { svg, defs, w, h } = lienzo(el);
    const izq = o.izq || Math.min(190, w * 0.38), der = 64, arriba = 6;
    const alto = Math.min(30, (h - arriba) / Math.max(items.length, 1));
    const max = Math.max(...items.map((i) => i.valor), 0) || 1;
    const relleno = degradado(defs, o.color || "#0876AA", false, 0.55, 1);
    const grupo = s("g", {}, svg);
    if (o.foco != null) svg.classList.add("atenuado");
    items.forEach((it, i) => {
      const y = arriba + i * alto, bh = Math.max(6, alto * 0.58), bw = Math.max(2, ((w - izq - der) * it.valor) / max);
      s("text", { x: izq - 10, y: y + alto / 2 + 4, "text-anchor": "end", class: "cat" }, grupo).textContent = recortar(it.etiqueta, 26);
      const r = s("rect", { x: izq, y: y + (alto - bh) / 2, width: bw, height: bh, rx: bh / 2.4, fill: it.color ? degradado(defs, it.color, false, 0.55, 1) : relleno,
        class: "barra crece-x" + (o.foco != null && it.clave === o.foco ? " foco" : ""), style: `--i:${i}` }, grupo);
      const t = s("text", { x: izq + bw + 8, y: y + alto / 2 + 4, class: "val aparece", style: `--i:${i}` }, grupo);
      t.textContent = o.fmt(it.valor);
      conTooltip(r, () => `<b>${it.etiqueta}</b>${filaTip(o.nombre || "Valor", o.fmt(it.valor))}${(it.extra || []).map(([k, v]) => filaTip(k, v)).join("")}${o.onClick ? '<div class="pista">Clic para filtrar</div>' : ""}`,
        o.onClick ? () => o.onClick(it) : null);
    });
  }
  const recortar = (t, n) => (t.length > n ? t.slice(0, n - 1) + "…" : t);

  // ---------------- columnas (agrupadas o apiladas) + línea opcional ----------------
  function columnas(el, cats, series, o = {}) {
    const { svg, defs, w, h } = lienzo(el);
    const izq = 44, der = o.linea ? 44 : 10, arriba = 18, abajo = 28;
    const ah = h - arriba - abajo, aw = w - izq - der;
    const totales = cats.map((_, ci) => (o.apiladas ? series.reduce((a, se) => a + (se.valores[ci] || 0), 0) : Math.max(...series.map((se) => se.valores[ci] || 0))));
    const max = maximoBonito(Math.max(...totales, 0));
    const eje = s("g", { class: "eje" }, svg);
    for (let k = 0; k <= 4; k++) {
      const y = arriba + ah - (ah * k) / 4;
      s("line", { x1: izq, x2: w - der, y1: y, y2: y }, eje);
      s("text", { x: izq - 8, y: y + 4, "text-anchor": "end" }, eje).textContent = (o.prefijo || "") + corto((max * k) / 4);
    }
    const banda = aw / cats.length, ancho = Math.min(banda * 0.62, o.apiladas ? 46 : 26 * series.length);
    const sub = o.apiladas ? ancho : ancho / series.length;
    const rellenos = series.map((se) => degradado(defs, se.color, true, 1, 0.62));
    let n = 0;
    cats.forEach((c, ci) => {
      const x0 = izq + banda * ci + (banda - ancho) / 2;
      let acum = 0;
      series.forEach((se, si) => {
        const v = se.valores[ci] || 0, bh = (ah * v) / max;
        const x = o.apiladas ? x0 : x0 + si * sub;
        const y = arriba + ah - bh - (o.apiladas ? (ah * acum) / max : 0);
        const r = s("rect", { x: x + (o.apiladas ? 0 : 1), y, width: Math.max(1, sub - (o.apiladas ? 0 : 2)), height: Math.max(0, bh), rx: o.apiladas ? 2 : 5,
          fill: rellenos[si], class: "barra crece-y" + (c.parcial ? " parcial" : ""), style: `--i:${n++};${c.parcial ? "opacity:.75" : ""}` }, svg);
        if (!o.apiladas && !o.sinValores && bh > 14) s("text", { x: x + sub / 2, y: y - 5, "text-anchor": "middle", class: "val aparece", style: `--i:${n}` }, svg).textContent = corto(v);
        if (o.apiladas && bh > 16) s("text", { x: x + sub / 2, y: y + bh / 2 + 4, "text-anchor": "middle", class: "val aparece", style: `--i:${n};fill:#fff` }, svg).textContent = corto(v);
        conTooltip(r, () => `<b>${c.etiqueta}</b>${filaTip(se.nombre, o.fmt(v))}${o.apiladas ? filaTip("Total", o.fmt(totales[ci])) : ""}${c.parcial ? '<div class="pista">Mes en curso (al 22)</div>' : o.onClick ? '<div class="pista">Clic para filtrar</div>' : ""}`,
          o.onClick ? () => o.onClick(c) : null);
        acum += v;
      });
      s("text", { x: izq + banda * ci + banda / 2, y: h - 8, "text-anchor": "middle", class: "cat" }, svg).textContent = c.etiqueta;
    });
    if (o.linea) dibujarLinea(svg, defs, cats, o.linea, { izq, der, arriba, ah, aw, banda, w, ejeDerecho: true });
  }

  function dibujarLinea(svg, defs, cats, l, g2) {
    const max = maximoBonito(Math.max(...l.valores, 0));
    const pts = l.valores.map((v, i) => [g2.izq + g2.banda * i + g2.banda / 2, g2.arriba + g2.ah - (g2.ah * v) / max]);
    if (g2.ejeDerecho) {
      for (let k = 0; k <= 4; k++) s("text", { x: g2.w - g2.der + 8, y: g2.arriba + g2.ah - (g2.ah * k) / 4 + 4, class: "eje", fill: "#6f87a1", "font-size": 11 }, svg).textContent = corto((max * k) / 4);
    }
    const d = curva(pts);
    s("path", { d, stroke: l.color, class: "linea dibuja", pathLength: 1, style: "--i:2" }, svg);
    pts.forEach(([x, y], i) => {
      const c = s("circle", { cx: x, cy: y, r: 5, fill: l.color, class: "punto salta", style: `--i:${i}` }, svg);
      conTooltip(c, () => `<b>${cats[i].etiqueta}</b>${filaTip(l.nombre, l.fmt(l.valores[i]))}`);
    });
  }
  function curva(pts) { // curva suave (Catmull-Rom → Bézier)
    if (pts.length < 2) return "";
    let d = `M${pts[0][0]},${pts[0][1]}`;
    for (let i = 0; i < pts.length - 1; i++) {
      const p0 = pts[i - 1] || pts[i], p1 = pts[i], p2 = pts[i + 1], p3 = pts[i + 2] || p2;
      const c1 = [p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6], c2 = [p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6];
      d += ` C${c1[0]},${c1[1]} ${c2[0]},${c2[1]} ${p2[0]},${p2[1]}`;
    }
    return d;
  }

  // ---------------- líneas (varias series) con área ----------------
  function lineas(el, cats, series, o = {}) {
    const { svg, defs, w, h } = lienzo(el);
    const izq = 40, der = 12, arriba = 14, abajo = 28, ah = h - arriba - abajo, aw = w - izq - der;
    const max = maximoBonito(Math.max(...series.flatMap((se) => se.valores), 0));
    const eje = s("g", { class: "eje" }, svg);
    for (let k = 0; k <= 4; k++) {
      const y = arriba + ah - (ah * k) / 4;
      s("line", { x1: izq, x2: w - der, y1: y, y2: y }, eje);
      s("text", { x: izq - 8, y: y + 4, "text-anchor": "end" }, eje).textContent = corto((max * k) / 4);
    }
    const paso = cats.length > 1 ? aw / (cats.length - 1) : 0;
    cats.forEach((c, i) => s("text", { x: izq + paso * i, y: h - 8, "text-anchor": "middle", class: "cat" }, svg).textContent = c.etiqueta);
    series.forEach((se, si) => {
      const pts = se.valores.map((v, i) => [izq + paso * i, arriba + ah - (ah * v) / max]);
      if (o.area) {
        const area = curva(pts) + ` L${pts[pts.length - 1][0]},${arriba + ah} L${pts[0][0]},${arriba + ah} Z`;
        s("path", { d: area, fill: degradado(defs, se.color, true, 0.32, 0), class: "aparece", style: `--i:${si}` }, svg);
      }
      s("path", { d: curva(pts), stroke: se.color, class: "linea dibuja", pathLength: 1, style: `--i:${si}` }, svg);
      pts.forEach(([x, y], i) => {
        const c = s("circle", { cx: x, cy: y, r: 4.5, fill: se.color, class: "punto salta", style: `--i:${i + si}` }, svg);
        conTooltip(c, () => `<b>${cats[i].etiqueta}</b>${series.map((x2) => filaTip(x2.nombre, o.fmt(x2.valores[i]))).join("")}`);
      });
    });
  }

  // ---------------- dona ----------------
  function dona(el, items, o = {}) {
    const { svg, w, h } = lienzo(el);
    const r = Math.min(h, w * 0.55) / 2 - 14, cx = Math.min(w * 0.36, r + 30), cy = h / 2, grosor = r * 0.3;
    const total = items.reduce((a, i) => a + i.valor, 0) || 1;
    s("circle", { cx, cy, r, fill: "none", stroke: "rgba(255,255,255,0.06)", "stroke-width": grosor }, svg);
    let ini = 0;
    items.forEach((it, i) => {
      const frac = it.valor / total, hueco = items.length > 1 ? 0.006 : 0;
      const c = s("circle", { cx, cy, r, stroke: it.color, "stroke-width": grosor, class: "sector", pathLength: 1,
        style: `--i:${i};stroke-dasharray:${Math.max(0, frac - hueco)} ${1 - Math.max(0, frac - hueco)};transform:rotate(${-90 + ini * 360}deg);transform-origin:${cx}px ${cy}px;filter:drop-shadow(0 0 10px ${it.color}55)` }, svg);
      c.style.strokeDashoffset = 0;
      c.animate([{ strokeDashoffset: frac }, { strokeDashoffset: 0 }], { duration: matchMedia("(prefers-reduced-motion: reduce)").matches || document.documentElement.classList.contains("captura") ? 1 : 900, delay: 150 + i * 120, easing: "cubic-bezier(0.23, 1, 0.32, 1)", fill: "backwards" });
      conTooltip(c, () => `<b>${it.etiqueta}</b>${filaTip(o.nombre || "Valor", o.fmt(it.valor))}${filaTip("Participación", (frac * 100).toFixed(1) + " %")}${o.onClick ? '<div class="pista">Clic para filtrar</div>' : ""}`,
        o.onClick ? () => o.onClick(it) : null);
      ini += frac;
    });
    s("text", { x: cx, y: cy + 6, "text-anchor": "middle", class: "centro-dona aparece" }, svg).textContent = o.centro != null ? o.centro : "";
    s("text", { x: cx, y: cy + 26, "text-anchor": "middle", class: "centro-sub aparece" }, svg).textContent = o.centroSub || "";
    const lx = cx + r + grosor / 2 + 26;
    items.forEach((it, i) => {
      const y = cy - (items.length * 26) / 2 + i * 26 + 14;
      s("rect", { x: lx, y: y - 9, width: 10, height: 10, rx: 3, fill: it.color, class: "aparece", style: `--i:${i}` }, svg);
      s("text", { x: lx + 18, y, class: "cat aparece", style: `--i:${i}` }, svg).textContent = `${it.etiqueta} · ${((it.valor / total) * 100).toFixed(1)} %`;
    });
  }

  // ---------------- barras 100 % apiladas (horizontales) ----------------
  function barras100(el, cats, series, o = {}) {
    const { svg, h, w } = lienzo(el);
    const izq = 86, der = 8, alto = Math.min(46, (h - 10) / cats.length);
    let n = 0;
    cats.forEach((c, ci) => {
      const tot = series.reduce((a, se) => a + (se.valores[ci] || 0), 0) || 1;
      const y = 6 + ci * (alto + 14);
      s("text", { x: izq - 10, y: y + alto / 2 + 4, "text-anchor": "end", class: "cat" }, svg).textContent = c.etiqueta;
      let x = izq;
      series.forEach((se) => {
        const frac = (se.valores[ci] || 0) / tot, bw = (w - izq - der) * frac;
        if (bw <= 0) return;
        const r = s("rect", { x, y, width: Math.max(0, bw - 2), height: alto, rx: 6, fill: se.color, class: "barra crece-x", style: `--i:${n++}` }, svg);
        if (bw > 40) s("text", { x: x + bw / 2, y: y + alto / 2 + 4, "text-anchor": "middle", class: "val aparece", style: `--i:${n};fill:#fff` }, svg).textContent = (frac * 100).toFixed(1) + "%";
        conTooltip(r, () => `<b>${c.etiqueta} · ${se.nombre}</b>${filaTip("Registros", se.valores[ci])}${filaTip("Participación", (frac * 100).toFixed(1) + " %")}`);
        x += bw;
      });
    });
  }

  // ---------------- mini gráfico (sparkline) ----------------
  function spark(svg, valores, color) {
    svg.innerHTML = "";
    const w = 96, h = 30;
    svg.setAttribute("viewBox", `0 0 ${w} ${h}`);
    if (valores.length < 2) return;
    const min = Math.min(...valores), max = Math.max(...valores), r = max - min || 1;
    const pts = valores.map((v, i) => [2 + (i * (w - 4)) / (valores.length - 1), h - 3 - ((v - min) / r) * (h - 8)]);
    const defs = s("defs", {}, svg);
    s("path", { d: curva(pts) + ` L${w - 2},${h} L2,${h} Z`, fill: degradado(defs, color, true, 0.35, 0), class: "aparece" }, svg);
    s("path", { d: curva(pts), stroke: color, "stroke-width": 2.2, fill: "none", "stroke-linecap": "round", class: "dibuja", pathLength: 1 }, svg);
    const [ux, uy] = pts[pts.length - 1];
    s("circle", { cx: ux, cy: uy, r: 3, fill: color, class: "salta" }, svg);
  }

  // ---------------- tabla ----------------
  function tabla(el, cols, filas, o = {}) {
    el.innerHTML = "";
    const cont = document.createElement("div");
    cont.className = "contenedor-tabla";
    const t = document.createElement("table");
    t.className = "tabla";
    t.innerHTML = `<thead><tr>${cols.map((c) => `<th class="${c.num ? "num" : ""}">${c.titulo}</th>`).join("")}</tr></thead>`;
    const tb = document.createElement("tbody");
    const maxBarra = Math.max(...filas.map((f) => f[o.barra ?? -1] || 0), 1);
    filas.forEach((f, i) => {
      const tr = document.createElement("tr");
      tr.className = "entra";
      tr.style.setProperty("--i", Math.min(i, 14));
      tr.innerHTML = cols.map((c, ci) => `<td class="${c.num ? "num" : ""}">${c.fmt ? c.fmt(f[ci]) : f[ci]}${o.barra === ci ? `<div class="barrita" style="--i:${i};transform:scaleX(${(f[ci] || 0) / maxBarra})"></div>` : ""}</td>`).join("");
      tb.appendChild(tr);
    });
    t.appendChild(tb);
    cont.appendChild(t);
    el.appendChild(cont);
  }

  g.Graf = { barrasH, columnas, lineas, dona, barras100, spark, tabla, tooltip, corto };
})(window);
