/* =====================================================================
   Dashboard web animado · Notaría Lozano
   Páginas, filtros, filtrado cruzado por clic y transiciones.
   ===================================================================== */
(function () {
  "use strict";
  const C = Calc.crear(window.DATOS);
  const G = Graf;
  const D = C.dim, COL = C.COL;
  const captura = new URLSearchParams(location.search).has("captura");   // ?captura: estado final sin animación (fotos)
  if (captura) document.documentElement.classList.add("captura");
  const reducido = captura || matchMedia("(prefers-reduced-motion: reduce)").matches;

  // ---------------- formatos (es-PE) ----------------
  const nf0 = new Intl.NumberFormat("es-PE", { maximumFractionDigits: 0 });
  const nf1 = new Intl.NumberFormat("es-PE", { minimumFractionDigits: 1, maximumFractionDigits: 1 });
  const nf2 = new Intl.NumberFormat("es-PE", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  const F = {
    soles: (v) => (v == null ? "—" : "S/ " + nf2.format(v)),
    soles0: (v) => (v == null ? "—" : "S/ " + nf0.format(v)),
    ent: (v) => (v == null ? "—" : nf0.format(v)),
    dec1: (v) => (v == null ? "—" : nf1.format(v)),
    min: (v) => (v == null ? "—" : nf1.format(v) + " min"),
    pct: (v) => (v == null ? "—" : nf1.format(v * 100) + " %"),
  };
  const COLORES = ["#0876AA", "#BE263E", "#168D9C", "#8196B0", "#D5A76F", "#3FA7DC", "#E2546B", "#7CC4C9"];
  const corto = (t) => t.split(" ")[0];

  // ---------------- estado de filtros ----------------
  const filtros = {};
  const ETIQUETAS_FILTRO = {
    mes: "Mes", servicio: "Servicio", categoria: "Categoría", responsable: "Responsable", tipoCliente: "Tipo de cliente",
    turno: "Turno", metodo: "Método de pago", etapa: "Etapa", notario: "Notario", distrito: "Distrito", tipodoc: "Tipo documental",
  };
  const nombreFiltro = (k, v) => ({
    mes: () => C.meses.find((m) => m.anioMes === v).etiqueta, servicio: () => D.servicio.get(v)[1], responsable: () => D.personal.get(v)[1],
    turno: () => D.turno.get(v)[1], metodo: () => D.metodo.get(v)[1], etapa: () => D.etapa.get(v)[1], notario: () => D.notario.get(v)[1],
    tipodoc: () => D.tipodoc.get(v)[1],
  }[k] || (() => (v === "Juridica" ? "Jurídica" : v)))();
  const sin = (...claves) => { const f = { ...filtros }; claves.forEach((k) => delete f[k]); return f; };
  const filas = (hecho, f = filtros) => C.filtrar(hecho, f);
  function poner(k, v) {
    if (v == null || filtros[k] === v) delete filtros[k]; else filtros[k] = v;   // clic de nuevo = quitar
    sincronizarSelects();
    renderizar(false);
  }

  // ---------------- iconos (trazos estilo lucide) ----------------
  const I = {
    resumen: '<path d="M3 21h18M5 21V10l7-5 7 5v11M9 21v-6h6v6"/>',
    finanzas: '<circle cx="12" cy="12" r="9"/><path d="M15 9.5c-.5-1-1.6-1.5-3-1.5-1.7 0-3 .9-3 2.2 0 3 6 1.6 6 4.6 0 1.3-1.3 2.2-3 2.2-1.4 0-2.6-.6-3.1-1.6M12 6.5V8m0 8v1.5"/>',
    operaciones: '<circle cx="12" cy="13" r="8"/><path d="M12 9v4l2.5 2.5M9 2h6"/>',
    documentos: '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5M9 13h6M9 17h4"/>',
    clientes: '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0M16 4.5a3.5 3.5 0 0 1 0 7M18 13.5a6 6 0 0 1 3.5 6.5"/>',
    monedas: '<circle cx="9" cy="9" r="6"/><path d="M18.1 10.4A6 6 0 1 1 10.4 18.1M8 7h1.5v4"/>',
    archivo: '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14 3v5h5"/>',
    reloj: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    capas: '<path d="m12 2 9 5-9 5-9-5z"/><path d="m3 12 9 5 9-5M3 17l9 5 9-5"/>',
    porcentaje: '<path d="M19 5 5 19"/><circle cx="6.5" cy="6.5" r="2.5"/><circle cx="17.5" cy="17.5" r="2.5"/>',
    recibo: '<path d="M5 3v18l2.5-1.5L10 21l2-1.5 2 1.5 2.5-1.5L19 21V3l-2.5 1.5L14 3l-2 1.5L10 3 7.5 4.5z"/><path d="M9 9h6M9 13h6"/>',
    reloj2: '<path d="M6 2h12M6 22h12M7 2c0 6 10 6 10 10S7 16 7 22M17 2c0 6-10 6-10 10"/>',
    etiqueta: '<path d="M20.6 13.4 13.4 20.6a2 2 0 0 1-2.8 0L3 13V3h10l7.6 7.6a2 2 0 0 1 0 2.8z"/><circle cx="7.5" cy="7.5" r="1.5"/>',
    efectivo: '<rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="2.5"/><path d="M6 12h.01M18 12h.01"/>',
    grafico: '<path d="M3 3v18h18M7 16v-4M12 16V8M17 16v-7"/>',
    engranaje: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-2.8 1.2V21a2 2 0 1 1-4 0v-.1A1.7 1.7 0 0 0 7 19.4l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1A1.7 1.7 0 0 0 3 13.9H3a2 2 0 1 1 0-4h.1A1.7 1.7 0 0 0 4.6 7l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1A1.7 1.7 0 0 0 10 3.1V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 2.9 1.2l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0 1.2 2.9H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>',
    calendario: '<rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/>',
    check: '<circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/>',
    repetir: '<path d="M17 2l4 4-4 4"/><path d="M3 11V9a3 3 0 0 1 3-3h15M7 22l-4-4 4-4"/><path d="M21 13v2a3 3 0 0 1-3 3H3"/>',
    edificio: '<path d="M3 21h18M6 21V5a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v16M10 7h4M10 11h4M10 15h4"/>',
    reiniciar: '<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/>',
  };
  const svgIcono = (n) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${I[n]}</svg>`;

  // ---------------- KPIs ----------------
  const valoresPrevios = new Map();
  function contar(el, clave, destino, fmt) {
    const desde = valoresPrevios.get(clave) ?? 0;
    valoresPrevios.set(clave, destino ?? 0);
    if (destino == null) { el.textContent = fmt(null); return; }
    if (reducido) { el.textContent = fmt(destino); return; }
    const t0 = performance.now(), dur = 900;
    const paso = (t) => {
      const p = Math.min(1, (t - t0) / dur), e = 1 - Math.pow(1 - p, 4);     // ease-out
      el.textContent = fmt(desde + (destino - desde) * e);
      if (p < 1) requestAnimationFrame(paso);
    };
    requestAnimationFrame(paso);
  }
  /** kpi: {etiqueta, icono, color, hecho, medida, fmt, valor?(f), sinDelta?} */
  function tarjetaKpi(k, i) {
    const el = document.createElement("article");
    el.className = "vidrio kpi entra";
    el.style.setProperty("--i", i);
    el.style.setProperty("--c", k.color);
    el.innerHTML = `<div class="cab"><span class="icono">${svgIcono(k.icono)}</span><span class="etiqueta">${k.etiqueta}</span></div>
      <div class="valor">—</div><div class="pie-kpi"><span class="delta neutro">—</span><svg class="spark" aria-hidden="true"></svg></div>`;
    return el;
  }
  function llenarKpi(el, k, pagina) {
    const valor = k.valor ? k.valor(filtros) : (() => { const fl = filas(k.hecho); return fl.length ? C.M[k.medida](fl) : null; })();
    contar(el.querySelector(".valor"), pagina + k.etiqueta, valor, k.fmt);
    const delta = el.querySelector(".delta");
    if (!k.sinDelta && k.hecho) {
      const v = C.variacion(k.hecho, k.medida, filtros);
      if (v.variacion == null) { delta.className = "delta neutro"; delta.textContent = "sin mes anterior"; }
      else {
        const sube = v.variacion >= 0, buenoSiBaja = k.bajarEsBueno;
        delta.className = "delta " + ((sube !== !!buenoSiBaja) ? "sube" : "baja");
        delta.textContent = (sube ? "▲ " : "▼ ") + nf1.format(Math.abs(v.variacion) * 100) + " %";
        delta.title = "Último mes (a la fecha) vs mismos días del mes anterior";
      }
    } else { delta.className = "delta neutro"; delta.textContent = k.nota || "periodo"; }
    if (k.hecho && !k.valor) {
      const serie = C.porMes(k.hecho, k.medida, sin("mes")).filter((m) => !/\(al/.test(m.etiqueta)).map((m) => m.valor);
      G.spark(el.querySelector(".spark"), serie, k.color);
    }
  }

  // ---------------- tarjetas de gráfico ----------------
  function tarjeta(t, i) {
    const el = document.createElement("article");
    el.className = `vidrio tarjeta ${t.ancho || "c4"} entra`;
    el.style.setProperty("--i", i + 6);
    el.innerHTML = `<div class="tit"><h3>${t.p ? `<span class="p">${t.p}</span>` : ""}${t.titulo}</h3></div>
      ${t.sub ? `<p class="sub">${t.sub}</p>` : ""}<div class="leyenda"></div><div class="grafico ${t.alto ? "alto" : ""}"></div>`;
    return el;
  }
  const leyenda = (el, series) => { el.querySelector(".leyenda").innerHTML = series.map((s) => `<span><i style="background:${s.color}"></i>${s.nombre}</span>`).join(""); };

  // ---------------- ayudantes de agrupación ----------------
  const grupo = (hecho, f, clave, medida, nombre) =>
    C.agrupar(filas(hecho, f), (r) => r[COL[hecho][clave]], medida).map((x) => ({ clave: x.clave, valor: x.valor, etiqueta: nombre(x.clave) }));
  const ordenar = (a) => a.sort((x, y) => y.valor - x.valor);
  const mesesCat = () => C.meses.filter((m) => !filtros.mes || m.anioMes === filtros.mes).map((m) => ({ clave: m.anioMes, etiqueta: m.etiqueta, parcial: /\(al/.test(m.etiqueta) }));
  const porMesSerie = (hecho, medida, f, extra = {}) => mesesCat().map((m) => { const fl = filas(hecho, { ...f, ...extra, mes: m.clave }); return fl.length ? C.M[medida](fl) : 0; });
  const DIAS = [[1, "Lun"], [2, "Mar"], [3, "Mié"], [4, "Jue"], [5, "Vie"], [6, "Sáb"]];
  const porDia = (hecho, medida, f) => DIAS.map(([d]) => { const fl = filas(hecho, f).filter((r) => D.tiempo.get(r[COL[hecho].tiempo])[5] === d); return fl.length ? C.M[medida](fl) : 0; });

  // ---------------- páginas ----------------
  const PAGINAS = {
    resumen: {
      titulo: "Resumen ejecutivo", icono: "resumen",
      sub: "Ingresos, demanda, tiempos y producción documental de la notaría",
      kpis: [
        { etiqueta: "Importe cobrado", icono: "monedas", color: "#0876AA", hecho: "pagos", medida: "cobrado", fmt: F.soles0 },
        { etiqueta: "Trámites registrados", icono: "archivo", color: "#BE263E", hecho: "tramites", medida: "tramites", fmt: F.ent },
        { etiqueta: "Clientes atendidos", icono: "clientes", color: "#168D9C", hecho: "tramites", medida: "clientes", fmt: F.ent },
        { etiqueta: "Atención media por etapa", icono: "reloj", color: "#8196B0", hecho: "atenciones", medida: "atencionMedia", fmt: F.min, bajarEsBueno: true },
        { etiqueta: "Documentos otorgados", icono: "capas", color: "#D5A76F", hecho: "documentos", medida: "documentos", fmt: F.ent },
        { etiqueta: "Margen sobre cobrado", icono: "porcentaje", color: "#3FA7DC", hecho: "pagos", medida: "pctMargen", fmt: F.pct },
      ],
      tarjetas: [
        { ancho: "c8", titulo: "Ingresos cobrados y trámites por mes", sub: "Clic en un mes para filtrar · noviembre llega al día 22", alto: true, dibujar: (el) => {
          const cats = mesesCat();
          const s1 = { nombre: "Cobrado", color: "#0876AA", valores: porMesSerie("pagos", "cobrado", sin("mes")) };
          const l = { nombre: "Trámites", color: "#E2546B", valores: porMesSerie("tramites", "tramites", sin("mes")), fmt: F.ent };
          leyenda(el, [s1, l]);
          G.columnas(el.querySelector(".grafico"), cats, [s1], { fmt: F.soles, prefijo: "S/ ", linea: l, onClick: (c) => poner("mes", c.clave) });
        } },
        { ancho: "c4", titulo: "Servicios con mayor margen", sub: "Clic en un servicio para filtrar", alto: true, dibujar: (el) => {
          G.barrasH(el.querySelector(".grafico"), ordenar(grupo("pagos", sin("servicio"), "servicio", "margen", (k) => D.servicio.get(k)[1])),
            { fmt: F.soles0, nombre: "Margen", color: "#0876AA", foco: filtros.servicio, onClick: (it) => poner("servicio", it.clave) });
        } },
        { ancho: "c4", titulo: "Demanda por día y turno", sub: "Trámites iniciados", dibujar: (el) => {
          const series = [{ nombre: "Mañana", color: "#0876AA", valores: porDia("tramites", "tramites", sin("turno", "mes"), { turno: 1 }) }];
          series[0].valores = DIAS.map(([d]) => filas("tramites", { ...filtros, turno: 1 }).filter((r) => D.tiempo.get(r[1])[5] === d).length);
          series.push({ nombre: "Tarde", color: "#BE263E", valores: DIAS.map(([d]) => filas("tramites", { ...filtros, turno: 2 }).filter((r) => D.tiempo.get(r[1])[5] === d).length) });
          leyenda(el, series);
          G.columnas(el.querySelector(".grafico"), DIAS.map(([, e]) => ({ etiqueta: e })), series, { fmt: F.ent });
        } },
        { ancho: "c4", titulo: "Estado de los trámites", dibujar: (el) => {
          const est = ["Finalizado", "En Proceso", "Observado", "Anulado"], col = ["#168D9C", "#0876AA", "#D5A76F", "#BE263E"];
          const t = filas("tramites");
          const items = est.map((e, i) => ({ etiqueta: e, valor: t.filter((r) => r[COL.tramites.estado] === e).length, color: col[i] })).filter((x) => x.valor);
          G.dona(el.querySelector(".grafico"), items, { fmt: F.ent, nombre: "Trámites", centro: F.ent(t.length), centroSub: "trámites" });
        } },
        { ancho: "c4", titulo: "Cobrado por método de pago", sub: "Clic para filtrar por método", dibujar: (el) => {
          G.barrasH(el.querySelector(".grafico"), ordenar(grupo("pagos", sin("metodo"), "metodo", "cobrado", (k) => D.metodo.get(k)[1])),
            { fmt: F.soles0, nombre: "Cobrado", color: "#168D9C", izq: 110, foco: filtros.metodo, onClick: (it) => poner("metodo", it.clave) });
        } },
      ],
    },
    finanzas: {
      titulo: "Gestión financiera e ingresos", icono: "finanzas",
      sub: "Cobrado = pagos confirmados · Facturado = trámites no anulados · Por cobrar = pagos pendientes",
      kpis: [
        { etiqueta: "Importe cobrado", icono: "monedas", color: "#0876AA", hecho: "pagos", medida: "cobrado", fmt: F.soles0 },
        { etiqueta: "Importe facturado", icono: "recibo", color: "#BE263E", hecho: "tramites", medida: "facturado", fmt: F.soles0 },
        { etiqueta: "Por cobrar", icono: "reloj2", color: "#168D9C", hecho: "pagos", medida: "porCobrar", fmt: F.soles0, sinDelta: true, nota: "saldo pendiente" },
        { etiqueta: "Margen sobre cobrado", icono: "porcentaje", color: "#8196B0", hecho: "pagos", medida: "pctMargen", fmt: F.pct },
        { etiqueta: "Ticket medio por trámite", icono: "etiqueta", color: "#D5A76F", hecho: "pagos", medida: "ticket", fmt: F.soles },
        { etiqueta: "Cobrado en efectivo", icono: "efectivo", color: "#3FA7DC", hecho: "pagos", medida: "pctEfectivo", fmt: F.pct },
      ],
      tarjetas: [
        { ancho: "c4", p: "P1", titulo: "Margen por servicio", sub: "Cobrado menos costo asociado · clic para filtrar", alto: true, dibujar: (el) => {
          const items = ordenar(grupo("pagos", sin("servicio"), "servicio", "margen", (k) => D.servicio.get(k)[1]));
          items.forEach((it) => { const fl = filas("pagos", { ...sin("servicio"), servicio: it.clave }); it.extra = [["Cobrado", F.soles(C.M.cobrado(fl))], ["% margen", F.pct(C.M.pctMargen(fl))]]; });
          G.barrasH(el.querySelector(".grafico"), items, { fmt: F.soles0, nombre: "Margen", color: "#0876AA", foco: filtros.servicio, onClick: (it) => poner("servicio", it.clave) });
        } },
        { ancho: "c4", p: "P1", titulo: "Demanda de trámites por trimestre", sub: "T2 solo incluye junio", alto: true, dibujar: (el) => {
          const tri = ["T2 2026", "T3 2026", "T4 2026"];
          const t = filas("tramites");
          G.columnas(el.querySelector(".grafico"), tri.map((x) => ({ etiqueta: x })), [{ nombre: "Trámites", color: "#BE263E", valores: tri.map((x) => t.filter((r) => D.tiempo.get(r[1])[3] === x).length) }], { fmt: F.ent });
        } },
        { ancho: "c4", p: "P2", titulo: "Efectivo cobrado por empleado", sub: "Solo pagos en efectivo", alto: true, dibujar: (el) => {
          const items = ordenar(grupo("pagos", { ...sin("responsable"), metodo: 1 }, "personal", "cobrado", (k) => D.personal.get(k)[1])).filter((x) => x.valor > 0);
          G.barrasH(el.querySelector(".grafico"), items, { fmt: F.soles0, nombre: "Efectivo", color: "#168D9C", foco: filtros.responsable, onClick: (it) => poner("responsable", it.clave) });
        } },
        { ancho: "c4", p: "P3", titulo: "Medios de pago: empresas vs personas", sub: "Proporción de pagos registrados", dibujar: (el) => {
          const metodos = [...D.metodo.values()];
          const series = metodos.map((m, i) => ({ nombre: m[1], color: COLORES[i], valores: ["Juridica", "Natural"].map((tc) => filas("pagos", { ...sin("tipoCliente", "metodo"), tipoCliente: tc }).filter((r) => r[COL.pagos.metodo] === m[0]).length) }));
          leyenda(el, series);
          G.barras100(el.querySelector(".grafico"), [{ etiqueta: "Jurídica" }, { etiqueta: "Natural" }], series);
        } },
        { ancho: "c4", titulo: "Ingresos y costos por mes", sub: "Clic en un mes para filtrar", dibujar: (el) => {
          const series = [{ nombre: "Cobrado", color: "#0876AA", valores: porMesSerie("pagos", "cobrado", sin("mes")) }, { nombre: "Costo", color: "#BE263E", valores: porMesSerie("pagos", "costo", sin("mes")) }];
          leyenda(el, series);
          G.columnas(el.querySelector(".grafico"), mesesCat(), series, { fmt: F.soles, prefijo: "S/ ", sinValores: true, onClick: (c) => poner("mes", c.clave) });
        } },
        { ancho: "c4", titulo: "Detalle financiero por servicio", dibujar: (el) => {
          el.querySelector(".grafico").classList.add("sin-svg");
          const filasT = ordenar(grupo("pagos", filtros, "servicio", "cobrado", (k) => D.servicio.get(k)[1])).map((x) => {
            const fl = filas("pagos", { ...filtros, servicio: x.clave });
            return [x.etiqueta, fl.length, C.M.cobrado(fl), C.M.margen(fl), C.M.pctMargen(fl)];
          });
          G.tabla(el.querySelector(".grafico"), [{ titulo: "Servicio" }, { titulo: "Pagos", num: 1 }, { titulo: "Cobrado", num: 1, fmt: F.soles0 }, { titulo: "Margen", num: 1, fmt: F.soles0 }, { titulo: "%", num: 1, fmt: F.pct }], filasT, { barra: 2 });
        } },
      ],
    },
    operaciones: {
      titulo: "Eficiencia operacional y tiempos de atención", icono: "operaciones",
      sub: "Minutos por etapa: recepción, revisión y redacción, firma y entrega",
      kpis: [
        { etiqueta: "Atenciones registradas", icono: "grafico", color: "#0876AA", hecho: "atenciones", medida: "atenciones", fmt: F.ent },
        { etiqueta: "Atención media por etapa", icono: "reloj", color: "#BE263E", hecho: "atenciones", medida: "atencionMedia", fmt: F.min, bajarEsBueno: true },
        { etiqueta: "Espera media", icono: "reloj2", color: "#168D9C", hecho: "atenciones", medida: "esperaMedia", fmt: F.min, bajarEsBueno: true },
        { etiqueta: "Proceso medio", icono: "engranaje", color: "#8196B0", hecho: "atenciones", medida: "procesoMedio", fmt: F.min, bajarEsBueno: true },
        { etiqueta: "Minutos por trámite", icono: "reloj", color: "#D5A76F", hecho: "atenciones", medida: "minutosPorTramite", fmt: F.min, bajarEsBueno: true },
        { etiqueta: "Días promedio de duración", icono: "calendario", color: "#3FA7DC", hecho: "tramites", medida: "diasPromedio", fmt: (v) => (v == null ? "—" : nf1.format(v) + " días"), bajarEsBueno: true },
      ],
      tarjetas: [
        { ancho: "c6", p: "P7", titulo: "Atención media por servicio y turno", sub: "Minutos por etapa", alto: true, dibujar: (el) => {
          const servs = [...D.servicio.values()];
          const series = [[1, "Mañana", "#0876AA"], [2, "Tarde", "#BE263E"]].map(([t, n, c]) => ({ nombre: n, color: c, valores: servs.map((s) => { const fl = filas("atenciones", { ...sin("turno", "servicio"), turno: t, servicio: s[0] }); return fl.length ? C.M.atencionMedia(fl) : 0; }) }));
          leyenda(el, series);
          G.columnas(el.querySelector(".grafico"), servs.map((s) => ({ etiqueta: corto(s[1]), clave: s[0] })), series, { fmt: F.min, onClick: (c) => poner("servicio", c.clave) });
        } },
        { ancho: "c6", p: "P8", titulo: "Espera media por etapa y mes", sub: "Minutos de espera antes de cada etapa", alto: true, dibujar: (el) => {
          const etapas = [...D.etapa.values()];
          const series = etapas.map((e, i) => ({ nombre: e[1], color: ["#3FA7DC", "#E2546B", "#168D9C", "#D5A76F"][i], valores: porMesSerie("atenciones", "esperaMedia", { ...sin("mes", "etapa"), etapa: e[0] }) }));
          leyenda(el, series);
          G.lineas(el.querySelector(".grafico"), mesesCat(), series, { fmt: F.min, area: false });
        } },
        { ancho: "c4", titulo: "Espera vs proceso por etapa", sub: "Minutos promedio", dibujar: (el) => {
          const etapas = [...D.etapa.values()];
          const v = (m) => etapas.map((e) => { const fl = filas("atenciones", { ...filtros, etapa: e[0] }); return fl.length ? C.M[m](fl) : 0; });
          const series = [{ nombre: "Espera", color: "#3FA7DC", valores: v("esperaMedia") }, { nombre: "Proceso", color: "#BE263E", valores: v("procesoMedio") }];
          leyenda(el, series);
          G.columnas(el.querySelector(".grafico"), etapas.map((e) => ({ etiqueta: corto(e[1]), clave: e[0] })), series, { fmt: F.min, apiladas: true, onClick: (c) => poner("etapa", c.clave) });
        } },
        { ancho: "c4", titulo: "Carga de atención por personal", sub: "Clic en una persona para filtrar", dibujar: (el) => {
          G.barrasH(el.querySelector(".grafico"), ordenar(grupo("atenciones", sin("responsable"), "personal", "atenciones", (k) => D.personal.get(k)[1])),
            { fmt: F.ent, nombre: "Atenciones", color: "#168D9C", foco: filtros.responsable, onClick: (it) => poner("responsable", it.clave) });
        } },
        { ancho: "c4", titulo: "Espera media por día y turno", sub: "La tarde concentra más espera", dibujar: (el) => {
          const series = [[1, "Mañana", "#0876AA"], [2, "Tarde", "#BE263E"]].map(([t, n, c]) => ({ nombre: n, color: c, valores: DIAS.map(([d]) => { const fl = filas("atenciones", { ...sin("turno"), turno: t }).filter((r) => D.tiempo.get(r[1])[5] === d); return fl.length ? C.M.esperaMedia(fl) : 0; }) }));
          leyenda(el, series);
          G.columnas(el.querySelector(".grafico"), DIAS.map(([, e]) => ({ etiqueta: e })), series, { fmt: F.min });
        } },
      ],
    },
    documentos: {
      titulo: "Producción documental y trámites", icono: "documentos",
      sub: "Documentos otorgados por tipo, empleado y servicio · escrituras públicas por cargo",
      kpis: [
        { etiqueta: "Documentos otorgados", icono: "archivo", color: "#0876AA", hecho: "documentos", medida: "documentos", fmt: F.ent },
        { etiqueta: "Tipos documentales", icono: "capas", color: "#BE263E", hecho: "documentos", medida: "tiposDoc", fmt: F.ent, sinDelta: true, nota: "en el periodo" },
        { etiqueta: "Trámites registrados", icono: "recibo", color: "#168D9C", hecho: "tramites", medida: "tramites", fmt: F.ent },
        { etiqueta: "Tasa de finalización", icono: "check", color: "#8196B0", hecho: "tramites", medida: "tasaFinalizacion", fmt: F.pct },
        { etiqueta: "Documentos por trámite", icono: "capas", color: "#D5A76F", hecho: "documentos", medida: "docsPorTramite", fmt: F.dec1 },
        { etiqueta: "Trámites finalizados", icono: "check", color: "#3FA7DC", hecho: "tramites", medida: "finalizados", fmt: F.ent },
      ],
      tarjetas: [
        { ancho: "c8", p: "P5", titulo: "Documentos otorgados por tipo y mes", sub: "Clic en un mes para filtrar", alto: true, dibujar: (el) => {
          const tipos = [...D.tipodoc.values()];
          const series = tipos.map((t, i) => ({ nombre: t[1], color: ["#0876AA", "#BE263E", "#168D9C", "#8196B0", "#D5A76F"][i], valores: porMesSerie("documentos", "documentos", { ...sin("mes", "tipodoc"), tipodoc: t[0] }) }));
          leyenda(el, series);
          G.columnas(el.querySelector(".grafico"), mesesCat(), series, { fmt: F.ent, apiladas: true, onClick: (c) => poner("mes", c.clave) });
        } },
        { ancho: "c4", p: "P4", titulo: "Escrituras públicas por cargo", sub: "Trámites de la categoría Escrituras públicas", alto: true, dibujar: (el) => {
          const fl = filas("tramites", { ...filtros, categoria: "Escrituras públicas" });
          const items = ordenar(C.agrupar(fl, (r) => D.personal.get(r[COL.tramites.personal])[2], "tramites").map((x) => ({ ...x, etiqueta: x.clave })));
          G.barrasH(el.querySelector(".grafico"), items, { fmt: F.ent, nombre: "Escrituras", color: "#BE263E", izq: 130 });
        } },
        { ancho: "c4", p: "P6", titulo: "Documentos por empleado", sub: "En el detalle, su servicio principal", dibujar: (el) => {
          const items = ordenar(grupo("documentos", sin("responsable"), "personal", "documentos", (k) => D.personal.get(k)[1]));
          items.forEach((it) => {
            const top = ordenar(C.agrupar(filas("documentos", { ...sin("responsable"), responsable: it.clave }), (r) => D.servicio.get(r[COL.documentos.servicio])[1], "documentos"))[0];
            it.extra = top ? [["Servicio principal", top.clave], ["Documentos en él", F.ent(top.valor)]] : [];
          });
          G.barrasH(el.querySelector(".grafico"), items, { fmt: F.ent, nombre: "Documentos", color: "#0876AA", foco: filtros.responsable, onClick: (it) => poner("responsable", it.clave) });
        } },
        { ancho: "c4", titulo: "Trámites por servicio", sub: "Clic para filtrar", dibujar: (el) => {
          G.barrasH(el.querySelector(".grafico"), ordenar(grupo("tramites", sin("servicio"), "servicio", "tramites", (k) => D.servicio.get(k)[1])),
            { fmt: F.ent, nombre: "Trámites", color: "#168D9C", foco: filtros.servicio, onClick: (it) => poner("servicio", it.clave) });
        } },
        { ancho: "c4", titulo: "Trámites por notario", sub: "Titular y suplente · clic para filtrar", dibujar: (el) => {
          const t = filas("tramites", sin("notario"));
          const items = [...D.notario.values()].map((n, i) => ({ clave: n[0], etiqueta: `${n[2]}`, valor: t.filter((r) => r[COL.tramites.notario] === n[0]).length, color: ["#0876AA", "#BE263E"][i] }));
          G.dona(el.querySelector(".grafico"), items, { fmt: F.ent, nombre: "Trámites", centro: F.ent(t.length), centroSub: "trámites", onClick: (it) => poner("notario", it.clave) });
        } },
      ],
    },
    clientes: {
      titulo: "Clientes", icono: "clientes",
      sub: "Personas naturales y jurídicas, recurrencia, distritos y valor por cliente",
      kpis: [
        { etiqueta: "Clientes atendidos", icono: "clientes", color: "#0876AA", hecho: "tramites", medida: "clientes", fmt: F.ent },
        { etiqueta: "Clientes recurrentes", icono: "repetir", color: "#BE263E", hecho: "tramites", medida: "recurrentes", fmt: F.ent, sinDelta: true, nota: "más de 1 trámite" },
        { etiqueta: "Tasa de recurrencia", icono: "porcentaje", color: "#168D9C", fmt: F.pct, sinDelta: true, nota: "del periodo", valor: (f) => { const t = C.filtrar("tramites", f); return t.length ? C.M.recurrentes(t) / C.M.clientes(t) : null; } },
        { etiqueta: "Trámites por cliente", icono: "archivo", color: "#8196B0", fmt: F.dec1, sinDelta: true, nota: "promedio", valor: (f) => { const t = C.filtrar("tramites", f); return t.length ? C.M.tramites(t) / C.M.clientes(t) : null; } },
        { etiqueta: "Importe por cliente", icono: "monedas", color: "#D5A76F", fmt: F.soles0, sinDelta: true, nota: "promedio", valor: (f) => { const t = C.filtrar("tramites", f); return t.length ? C.M.cobrado(C.filtrar("pagos", f)) / C.M.clientes(t) : null; } },
        { etiqueta: "Empresas atendidas", icono: "edificio", color: "#3FA7DC", hecho: "tramites", medida: "empresas", fmt: F.ent },
      ],
      tarjetas: [
        { ancho: "c4", titulo: "Naturales vs jurídicas", sub: "Clientes atendidos · clic para filtrar", dibujar: (el) => {
          const t = filas("tramites", sin("tipoCliente"));
          const items = [["Natural", "#BE263E"], ["Juridica", "#0876AA"]].map(([k, c]) => ({ clave: k, etiqueta: k === "Juridica" ? "Jurídica" : k, color: c, valor: new Set(t.filter((r) => D.cliente.get(r[COL.tramites.cliente])[2] === k).map((r) => r[COL.tramites.cliente])).size }));
          G.dona(el.querySelector(".grafico"), items, { fmt: F.ent, nombre: "Clientes", centro: F.ent(C.M.clientes(t)), centroSub: "clientes", onClick: (it) => poner("tipoCliente", it.clave) });
        } },
        { ancho: "c4", titulo: "Clientes por distrito", sub: "Clic para filtrar", dibujar: (el) => {
          const t = filas("tramites", sin("distrito"));
          const items = ordenar(C.agrupar(t, (r) => D.cliente.get(r[COL.tramites.cliente])[3], "clientes").map((x) => ({ ...x, etiqueta: x.clave })));
          G.barrasH(el.querySelector(".grafico"), items, { fmt: F.ent, nombre: "Clientes", color: "#168D9C", izq: 120, foco: filtros.distrito, onClick: (it) => poner("distrito", it.clave) });
        } },
        { ancho: "c4", titulo: "Clientes por importe cobrado", dibujar: (el) => {
          const p = filas("pagos"), t = filas("tramites");
          const filasT = ordenar(C.agrupar(p, (r) => r[COL.pagos.cliente], "cobrado")).slice(0, 40).map((x) => {
            const c = D.cliente.get(x.clave);
            return [c[1], c[2] === "Juridica" ? "Jurídica" : "Natural", t.filter((r) => r[COL.tramites.cliente] === x.clave).length, x.valor];
          });
          G.tabla(el.querySelector(".grafico"), [{ titulo: "Cliente" }, { titulo: "Tipo" }, { titulo: "Trám.", num: 1 }, { titulo: "Cobrado", num: 1, fmt: F.soles0 }], filasT, { barra: 3 });
        } },
        { ancho: "c8", titulo: "Clientes atendidos por mes y segmento", sub: "Recurrente = más de un trámite en el periodo", dibujar: (el) => {
          const series = [["Nuevo", "#3FA7DC"], ["Recurrente", "#BE263E"]].map(([s, c]) => ({ nombre: s, color: c, valores: mesesCat().map((m) => new Set(filas("tramites", { ...sin("mes"), mes: m.clave }).filter((r) => D.cliente.get(r[COL.tramites.cliente])[4] === s).map((r) => r[COL.tramites.cliente])).size) }));
          leyenda(el, series);
          G.columnas(el.querySelector(".grafico"), mesesCat(), series, { fmt: F.ent, onClick: (c) => poner("mes", c.clave) });
        } },
        { ancho: "c4", titulo: "Ticket medio por tipo de cliente", sub: "Importe cobrado por trámite", dibujar: (el) => {
          const vals = ["Juridica", "Natural"].map((k) => C.M.ticket(filas("pagos", { ...sin("tipoCliente"), tipoCliente: k })) || 0);
          G.columnas(el.querySelector(".grafico"), [{ etiqueta: "Jurídica", clave: "Juridica" }, { etiqueta: "Natural", clave: "Natural" }],
            [{ nombre: "Ticket medio", color: "#D5A76F", valores: vals }], { fmt: F.soles, prefijo: "S/ ", onClick: (c) => poner("tipoCliente", c.clave) });
        } },
      ],
    },
  };
  const ORDEN = ["resumen", "finanzas", "operaciones", "documentos", "clientes"];
  const NOMBRES_NAV = { resumen: "Resumen ejecutivo", finanzas: "Finanzas e ingresos", operaciones: "Operaciones y tiempos", documentos: "Producción documental", clientes: "Clientes" };

  // ---------------- estructura de la página ----------------
  let actual = ORDEN.includes(location.hash.slice(1)) ? location.hash.slice(1) : "resumen";
  const $ = (q) => document.querySelector(q);

  function montarNav() {
    const nav = $(".nav");
    nav.innerHTML = '<div class="nav-indicador" aria-hidden="true"></div>' + ORDEN.map((p) => `<button data-p="${p}">${svgIcono(PAGINAS[p].icono)}<span>${NOMBRES_NAV[p]}</span></button>`).join("");
    nav.querySelectorAll("button").forEach((b) => b.addEventListener("click", () => ir(b.dataset.p)));
  }
  function marcarNav() {
    const i = ORDEN.indexOf(actual);
    document.querySelectorAll(".nav button").forEach((b, k) => { b.classList.toggle("activo", k === i); b.setAttribute("aria-current", k === i ? "page" : "false"); });
    $(".nav-indicador").style.transform = `translateY(${i * 50}px)`;
  }

  const SELECTS = [
    ["mes", "Mes", () => C.meses.map((m) => [m.anioMes, m.etiqueta])],
    ["servicio", "Servicio", () => [...D.servicio.values()].map((s) => [s[0], s[1]])],
    ["categoria", "Categoría", () => [...new Set([...D.servicio.values()].map((s) => s[2]))].map((c) => [c, c])],
    ["responsable", "Responsable", () => [...D.personal.values()].map((p) => [p[0], p[1]])],
    ["tipoCliente", "Tipo de cliente", () => [["Natural", "Natural"], ["Juridica", "Jurídica"]]],
    ["turno", "Turno", () => [...D.turno.values()].map((t) => [t[0], t[1]])],
  ];
  function montarFiltros() {
    const cont = $(".filtros");
    cont.innerHTML = SELECTS.map(([k, n, ops]) => `<div class="filtro"><label for="f-${k}">${n}</label><select id="f-${k}" data-k="${k}"><option value="">Todos</option>${ops().map(([v, t]) => `<option value="${v}">${t}</option>`).join("")}</select></div>`).join("")
      + `<button class="boton" type="button" id="reiniciar">${svgIcono("reiniciar")}Restablecer</button>`;
    cont.querySelectorAll("select").forEach((s) => s.addEventListener("change", () => {
      const k = s.dataset.k, v = s.value;
      if (v === "") delete filtros[k]; else filtros[k] = /^\d+$/.test(v) && k !== "mes" ? Number(v) : v;
      sincronizarSelects();
      renderizar(false);
    }));
    $("#reiniciar").addEventListener("click", () => { Object.keys(filtros).forEach((k) => delete filtros[k]); sincronizarSelects(); renderizar(false); });
  }
  function sincronizarSelects() {
    document.querySelectorAll(".filtros select").forEach((s) => { const v = filtros[s.dataset.k]; s.value = v == null ? "" : String(v); s.classList.toggle("con-valor", v != null); });
    const activos = $(".activos");
    const extra = Object.keys(filtros).filter((k) => !SELECTS.some(([s]) => s === k));
    activos.innerHTML = extra.map((k) => `<button class="activo-chip" data-k="${k}" title="Quitar filtro">${ETIQUETAS_FILTRO[k]}: <b>${nombreFiltro(k, filtros[k])}</b> ✕</button>`).join("");
    activos.querySelectorAll(".activo-chip").forEach((b) => b.addEventListener("click", () => { delete filtros[b.dataset.k]; sincronizarSelects(); renderizar(false); }));
  }

  // ---------------- render ----------------
  let pendiente = null;
  function ir(p) {
    if (p === actual) return;
    actual = p;
    history.replaceState(null, "", "#" + p);
    marcarNav();
    const vista = $(".rejilla");
    if (reducido || !vista.children.length) { renderizar(true); return; }
    [...vista.children].forEach((c) => c.classList.add("sale"));
    clearTimeout(pendiente);
    pendiente = setTimeout(() => renderizar(true), 170);
  }
  function renderizar(nuevaPagina) {
    G.tooltip.ocultar();
    const pg = PAGINAS[actual];
    $(".cabecera h1").textContent = pg.titulo;
    $(".cabecera p").textContent = pg.sub;
    const rej = $(".rejilla");
    if (nuevaPagina || !rej.children.length || rej.dataset.p !== actual) {
      rej.innerHTML = "";
      rej.dataset.p = actual;
      pg.kpis.forEach((k, i) => rej.appendChild(tarjetaKpi(k, i)));
      pg.tarjetas.forEach((t, i) => rej.appendChild(tarjeta(t, i)));
      $(".vista").scrollTop = 0;
    }
    const kpiEls = rej.querySelectorAll(".kpi"), tarEls = rej.querySelectorAll(".tarjeta");
    pg.kpis.forEach((k, i) => llenarKpi(kpiEls[i], k, actual));
    requestAnimationFrame(() => pg.tarjetas.forEach((t, i) => t.dibujar(tarEls[i])));
    const n = filas("tramites").length;
    $("#periodo").textContent = filtros.mes ? `${nombreFiltro("mes", filtros.mes)} 2026 · ${nf0.format(n)} trámites` : `01 jun – 22 nov 2026 · ${nf0.format(n)} trámites`;
  }
  let tRes = null;
  addEventListener("resize", () => { clearTimeout(tRes); tRes = setTimeout(() => renderizar(false), 200); });
  addEventListener("hashchange", () => { const p = location.hash.slice(1); if (ORDEN.includes(p)) ir(p); });

  document.addEventListener("DOMContentLoaded", () => {
    montarNav();
    montarFiltros();
    marcarNav();
    sincronizarSelects();
    renderizar(true);
  });
})();
