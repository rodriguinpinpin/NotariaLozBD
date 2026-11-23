/* =====================================================================
   Cálculos del dashboard web. Mismas definiciones que las medidas DAX
   (tools/medidas.py) para que web, Power BI y SQL den los mismos números.
   Funciona en el navegador (window.Calc) y en Node (para las pruebas).
   ===================================================================== */
(function (g) {
  "use strict";

  // Columnas de cada hecho (orden exportado por tools/exportar_web.py)
  const COL = {
    tramites: { nro: 0, tiempo: 1, servicio: 2, notario: 3, cliente: 4, personal: 5, estadoPago: 6, pagado: 7, arancel: 8, estado: 9, dias: 10, turno: 11, metodo: 12 },
    pagos: { nro: 0, tiempo: 1, servicio: 2, cliente: 3, personal: 4, metodo: 5, cobrado: 6, costo: 7, pendiente: 8, estadoPago: 9, turno: 10, notario: 11 },
    atenciones: { nro: 0, tiempo: 1, servicio: 2, personal: 3, etapa: 4, turno: 5, espera: 6, proceso: 7, cliente: 8, notario: 9 },
    documentos: { nro: 0, tiempo: 1, servicio: 2, personal: 3, tipodoc: 4, cliente: 5, cantidad: 6, turno: 7, notario: 8 },
  };

  function crear(DATOS) {
    const D = DATOS.dims;
    const mapa = (filas) => new Map(filas.map((f) => [f[0], f]));
    const dim = {
      servicio: mapa(D.servicio), personal: mapa(D.personal), cliente: mapa(D.cliente), metodo: mapa(D.metodo),
      etapa: mapa(D.etapa), turno: mapa(D.turno), tipodoc: mapa(D.tipodoc), notario: mapa(D.notario),
      estadopago: mapa(D.estadopago), tiempo: mapa(D.tiempo),
    };
    const H = DATOS.hechos;
    const diasCalendario = D.tiempo.map((t) => t[0]).sort((a, b) => a - b);
    const meses = [...new Map(D.tiempo.map((t) => [t[1], { anioMes: t[1], etiqueta: t[2] }])).values()].sort((a, b) => a.anioMes.localeCompare(b.anioMes));

    const anioMesDe = (id) => { const s = String(id); return s.slice(0, 4) + "-" + s.slice(4, 6); };

    /** Filtra filas de un hecho. Un filtro sobre una dimensión que el hecho no tiene no lo afecta (igual que en Power BI). */
    function filtrar(hecho, f, rango) {
      const c = COL[hecho];
      return H[hecho].filter((r) => {
        const t = r[c.tiempo];
        if (rango) { if (t < rango[0] || t > rango[1]) return false; }
        else if (f.mes && anioMesDe(t) !== f.mes) return false;
        if (f.servicio != null && r[c.servicio] !== f.servicio) return false;
        if (f.categoria != null && dim.servicio.get(r[c.servicio])[2] !== f.categoria) return false;
        if (f.responsable != null && r[c.personal] !== f.responsable) return false;
        if (f.tipoCliente != null && dim.cliente.get(r[c.cliente])[2] !== f.tipoCliente) return false;
        if (f.distrito != null && dim.cliente.get(r[c.cliente])[3] !== f.distrito) return false;
        if (f.turno != null && r[c.turno] !== f.turno) return false;
        if (f.notario != null && r[c.notario] !== f.notario) return false;
        if (f.metodo != null && c.metodo != null && r[c.metodo] !== f.metodo) return false;
        if (f.etapa != null && c.etapa != null && r[c.etapa] !== f.etapa) return false;
        if (f.tipodoc != null && c.tipodoc != null && r[c.tipodoc] !== f.tipodoc) return false;
        return true;
      });
    }

    const suma = (filas, i) => filas.reduce((s, r) => s + (r[i] || 0), 0);
    const distintos = (filas, i) => new Set(filas.map((r) => r[i])).size;
    const promedio = (vals) => (vals.length ? vals.reduce((a, b) => a + b, 0) / vals.length : null);
    const dividir = (a, b) => (b ? a / b : null);
    const P = COL.pagos, T = COL.tramites, A = COL.atenciones, Dc = COL.documentos;

    // ---- medidas (cada una recibe las filas ya filtradas del hecho que corresponde) ----
    const M = {
      cobrado: (p) => suma(p, P.cobrado),
      costo: (p) => suma(p, P.costo),
      porCobrar: (p) => suma(p, P.pendiente),
      margen: (p) => suma(p, P.cobrado) - suma(p, P.costo),
      pctMargen: (p) => dividir(M.margen(p), M.cobrado(p)),
      registros: (p) => p.length,
      ticket: (p) => dividir(M.cobrado(p), new Set(p.filter((r) => r[P.cobrado] > 0).map((r) => r[P.nro])).size),
      pctEfectivo: (p) => dividir(suma(p.filter((r) => dim.metodo.get(r[P.metodo])[1] === "Efectivo"), P.cobrado), M.cobrado(p)),
      facturado: (t) => suma(t.filter((r) => r[T.estado] !== "Anulado"), T.arancel),
      tramites: (t) => distintos(t, T.nro),
      finalizados: (t) => t.filter((r) => r[T.estado] === "Finalizado").length,
      tasaFinalizacion: (t) => dividir(M.finalizados(t), t.filter((r) => r[T.estado] !== "Anulado").length),
      diasPromedio: (t) => promedio(t.map((r) => r[T.dias]).filter((v) => v != null)),
      clientes: (t) => distintos(t, T.cliente),
      recurrentes: (t) => { const n = new Map(); t.forEach((r) => n.set(r[T.cliente], (n.get(r[T.cliente]) || 0) + 1)); return [...n.values()].filter((v) => v > 1).length; },
      empresas: (t) => new Set(t.filter((r) => dim.cliente.get(r[T.cliente])[2] === "Juridica").map((r) => r[T.cliente])).size,
      atenciones: (a) => a.length,
      atencionMedia: (a) => promedio(a.map((r) => r[A.espera] + r[A.proceso])),
      esperaMedia: (a) => promedio(a.map((r) => r[A.espera])),
      procesoMedio: (a) => promedio(a.map((r) => r[A.proceso])),
      minutosPorTramite: (a) => dividir(a.reduce((s, r) => s + r[A.espera] + r[A.proceso], 0), distintos(a, A.nro)),
      documentos: (d) => suma(d, Dc.cantidad),
      tiposDoc: (d) => new Set(d.filter((r) => r[Dc.cantidad] > 0).map((r) => r[Dc.tipodoc])).size,
      docsPorTramite: (d) => dividir(suma(d, Dc.cantidad), distintos(d, Dc.nro)),
    };

    // ---- variación mensual: último mes del contexto (a la fecha) vs mismos días del mes anterior ----
    function edate(id, n) {
      const y = Math.floor(id / 10000), m = Math.floor(id / 100) % 100, d = id % 100;
      let mm = m + n, yy = y;
      while (mm < 1) { mm += 12; yy -= 1; }
      while (mm > 12) { mm -= 12; yy += 1; }
      const ultimo = new Date(yy, mm, 0).getDate();
      return yy * 10000 + mm * 100 + Math.min(d, ultimo);
    }
    function variacion(hecho, medida, f) {
      const dias = diasCalendario.filter((t) => !f.mes || anioMesDe(t) === f.mes);
      if (!dias.length) return { actual: null, anterior: null, variacion: null };
      const fin = dias[dias.length - 1];
      const ini = Math.max(dias[0], Math.floor(fin / 100) * 100 + 1);
      const filasA = filtrar(hecho, f, [ini, fin]);
      const filasB = filtrar(hecho, f, [edate(ini, -1), edate(fin, -1)]);
      const actual = filasA.length ? M[medida](filasA) : null;
      const anterior = filasB.length ? M[medida](filasB) : null;
      return { actual, anterior, variacion: actual != null && anterior ? (actual - anterior) / anterior : null };
    }

    /** Serie por mes completo/parcial para gráficos y mini gráficos. */
    function porMes(hecho, medida, f) {
      return meses.map((m) => ({ clave: m.anioMes, etiqueta: m.etiqueta, valor: (() => { const fl = filtrar(hecho, { ...f, mes: m.anioMes }); return fl.length ? M[medida](fl) : 0; })() }))
        .filter((m) => !f.mes || m.clave === f.mes);
    }

    /** Agrupa filas por una función de clave y calcula una medida por grupo. */
    function agrupar(filas, clave, medida) {
      const g = new Map();
      filas.forEach((r) => { const k = clave(r); if (!g.has(k)) g.set(k, []); g.get(k).push(r); });
      return [...g.entries()].map(([k, fl]) => ({ clave: k, valor: M[medida](fl) }));
    }

    return { COL, dim, meses, filtrar, M, variacion, porMes, agrupar, anioMesDe, edate };
  }

  g.Calc = { crear, COL };
  if (typeof module !== "undefined") module.exports = { crear, COL };
})(typeof window !== "undefined" ? window : globalThis);
