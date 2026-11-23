// Prueba: los cálculos de la web (web/calculos.js) coinciden con sql/referencia.csv (mismas definiciones que DAX).
// Uso: node tools/tests/t07_web.js
const fs = require("fs");
const path = require("path");
const vm = require("vm");

const raiz = path.resolve(__dirname, "..", "..");
const ctx = { window: {} };
vm.createContext(ctx);
vm.runInContext(fs.readFileSync(path.join(raiz, "web", "datos.js"), "utf8"), ctx);
const { crear } = require(path.join(raiz, "web", "calculos.js"));
const C = crear(ctx.window.DATOS);
const sinFiltro = {};

const mapa = {
  "Importe cobrado": ["pagos", "cobrado"], "Importe facturado": ["tramites", "facturado"], "Por cobrar": ["pagos", "porCobrar"],
  "Costo asociado": ["pagos", "costo"], "Margen": ["pagos", "margen"], "Tramites registrados": ["tramites", "tramites"],
  "Atenciones registradas": ["atenciones", "atenciones"], "Atencion media minutos": ["atenciones", "atencionMedia"],
  "Espera media minutos": ["atenciones", "esperaMedia"], "Documentos otorgados": ["documentos", "documentos"],
  "Clientes unicos": ["tramites", "clientes"],
};
const D = C.dim;
const top = (filas, clave, medida) => C.agrupar(filas, clave, medida).sort((a, b) => b.valor - a.valor)[0];
const COL = C.COL;
const preguntas = {
  "Servicio con mayor margen": () => { const t = top(C.filtrar("pagos", sinFiltro), (r) => D.servicio.get(r[COL.pagos.servicio])[1], "margen"); return [t.clave, t.valor]; },
  "Trimestre con mas tramites": () => { const t = top(C.filtrar("tramites", sinFiltro), (r) => D.tiempo.get(r[COL.tramites.tiempo])[3], "tramites"); return [t.clave, t.valor]; },
  "Empleado con mas efectivo": () => { const t = top(C.filtrar("pagos", { metodo: 1 }), (r) => D.personal.get(r[COL.pagos.personal])[1], "cobrado"); return [t.clave, t.valor]; },
  "Metodo preferido Juridica": () => { const t = top(C.filtrar("pagos", { tipoCliente: "Juridica" }), (r) => D.metodo.get(r[COL.pagos.metodo])[1], "registros"); return [t.clave, t.valor]; },
  "Metodo preferido Natural": () => { const t = top(C.filtrar("pagos", { tipoCliente: "Natural" }), (r) => D.metodo.get(r[COL.pagos.metodo])[1], "registros"); return [t.clave, t.valor]; },
  "Cargo con mas escrituras publicas": () => { const t = top(C.filtrar("tramites", { categoria: "Escrituras públicas" }), (r) => D.personal.get(r[COL.tramites.personal])[2], "tramites"); return [t.clave, t.valor]; },
  "Tipo documental con mas documentos": () => { const t = top(C.filtrar("documentos", sinFiltro), (r) => D.tipodoc.get(r[COL.documentos.tipodoc])[1], "documentos"); return [t.clave, t.valor]; },
  "Empleado con mas documentos": () => { const t = top(C.filtrar("documentos", sinFiltro), (r) => D.personal.get(r[COL.documentos.personal])[1], "documentos"); return [t.clave, t.valor]; },
  "Servicio con mayor atencion media": () => { const t = top(C.filtrar("atenciones", sinFiltro), (r) => D.servicio.get(r[COL.atenciones.servicio])[1], "atencionMedia"); return [t.clave, t.valor]; },
  "Turno con mayor atencion media": () => { const t = top(C.filtrar("atenciones", sinFiltro), (r) => D.turno.get(r[COL.atenciones.turno])[1], "atencionMedia"); return [t.clave, t.valor]; },
  "Etapa con mayor espera media": () => { const t = top(C.filtrar("atenciones", sinFiltro), (r) => D.etapa.get(r[COL.atenciones.etapa])[1], "esperaMedia"); return [t.clave, t.valor]; },
};

const ref = fs.readFileSync(path.join(raiz, "sql", "referencia.csv"), "utf8").replace(/^﻿/, "").trim().split(/\r?\n/).slice(1).map((l) => l.split(";"));
let ok = 0; const fallos = [];
for (const [ind, filtro, valor] of ref) {
  if (mapa[ind]) {
    const [hecho, medida] = mapa[ind];
    const f = filtro === "Total" ? {} : { mes: filtro.slice(4) };
    const filas = C.filtrar(hecho, f);
    const v = filas.length ? C.M[medida](filas) : 0;
    if (Math.abs((v || 0) - Number(valor)) > 0.01) fallos.push(`${ind} [${filtro}]: web=${v} sql=${valor}`); else ok++;
  } else if (preguntas[filtro]) {
    const [n, v] = preguntas[filtro]();
    const [en, ev] = valor.split("|");
    if (n !== en || Math.abs(v - Number(ev)) > 0.01) fallos.push(`${ind} ${filtro}: web=${n}|${v} sql=${valor}`); else ok++;
  } else fallos.push(`Sin mapeo: ${ind} / ${filtro}`);
}
// Variación: junio sin base (en blanco); noviembre al 22 vs octubre 1-22 = -9.89 % (mismo valor que DAX)
const vJun = C.variacion("pagos", "cobrado", { mes: "2026-06" }).variacion;
if (vJun !== null) fallos.push(`Variación de junio debería ser nula y es ${vJun}`); else ok++;
const vNov = C.variacion("pagos", "cobrado", {}).variacion;
if (Math.abs(vNov - -0.0989188517459923) > 1e-9) fallos.push(`Variación de noviembre: ${vNov}`); else ok++;

if (fallos.length) { fallos.forEach((f) => console.log("FALLO " + f)); console.log(`${ok} OK, ${fallos.length} fallos`); process.exit(1); }
console.log(`t07_web: PASS (${ok} comprobaciones)`);
