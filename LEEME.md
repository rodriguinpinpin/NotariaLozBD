# Notaría Lozano: base de datos ampliada y dashboard de Power BI

Datos ficticios del **1 de junio al 22 de noviembre de 2026**: 767 trámites, 200 clientes, 10 empleados, 2 notarios y 8 servicios.

## Estructura

| Carpeta / archivo | Qué contiene |
|---|---|
| `sql/01_crear_oltp.sql` | Base transaccional `NotariaPeru` (22 tablas, re-ejecutable) |
| `sql/02_datos_oltp.sql` | Generador **determinista** de datos (mismo resultado en cada ejecución) |
| `sql/03_crear_dw.sql` | Data warehouse `DW_NotariaLozano` (modelo estrella + `ETL_Auditoria`) |
| `sql/04_etl_dw.sql` | ETL en T-SQL: `etl.usp_EjecutarTodo` (borra y recarga, con auditoría) |
| `sql/05_validacion.sql` | Totales de referencia → `sql/referencia.csv` |
| `sql/tests/` | Pruebas T-SQL (fallan con `THROW` si una regla no se cumple) |
| `sql/ejecutar_todo.ps1` | Reconstruye todo desde cero y corre las pruebas |
| `powerbi/NOTARIA_LOZANO.pbip` | Reporte de Power BI (proyecto). **Abrir este archivo** |
| `tools/gen_modelo.py`, `tools/medidas.py` | Generan el modelo semántico (tablas, relaciones, 56 medidas DAX) |
| `tools/paginas.py`, `tools/build_assets.py`, `tools/build_report.py` | Diseño de páginas, fondos PNG y visuales |
| `tools/dax.ps1`, `tools/tests/t05_medidas.ps1` | Consulta DAX al modelo abierto y conciliación SQL ↔ Power BI |
| `capturas/` | Capturas de las 5 páginas |
| Scripts `.sql` de la raíz y `NOTARIA_LOZANO_COLOR.pbix` | Versión original (sin cambios, evidencia del informe) |

## Cómo reconstruir y actualizar

1. Base de datos y DW (SQL Server Express local `.\SQLEXPRESS`):
   ```powershell
   powershell -ExecutionPolicy Bypass -File sql\ejecutar_todo.ps1
   ```
2. Abrir `powerbi\NOTARIA_LOZANO.pbip` en Power BI Desktop y pulsar **Inicio › Actualizar**.
3. (Opcional) Verificar, con el reporte abierto, que Power BI cuadra con SQL y que cada segmentación filtra su página:
   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\tests\t05_medidas.ps1
   ```
   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\tests\t06_filtros.ps1
   ```

Para regenerar el diseño tras editar `tools/paginas.py` o `tools/medidas.py`, primero **cierra Power BI Desktop**:
```powershell
python -I tools\gen_modelo.py; python -I tools\build_assets.py; python -I tools\build_report.py
```

## Dashboard web animado (carpeta `web/`)

Versión con estilo vidrio y animaciones (entradas escalonadas, gráficos que se dibujan, números que cuentan, transiciones entre secciones, filtrado con clic). Muestra los mismos números que Power BI y SQL.

- **Abrir:** doble clic en `web\index.html`, o con un servidor local:
  ```powershell
  python -m http.server 8765 --directory web
  ```
  y entrar a `http://localhost:8765`. No necesita internet ni instalar nada.
- **Actualizar los datos** tras reconstruir la base: `python -I tools\exportar_web.py` (regenera `web\datos.js`).
- **Verificar que cuadra con SQL:** `node tools\tests\t07_web.js`.
- **Capturas sin animación:** agregar `?captura` a la dirección (por ejemplo `index.html?captura#finanzas`).
- Archivos: `estilos.css` (vidrio y animaciones), `calculos.js` (mismas definiciones que las medidas DAX), `graficos.js` (gráficos SVG animados), `app.js` (páginas, filtros y navegación).

## Definiciones de los indicadores

- **Importe cobrado**: pagos en estado *Pagado*. **Facturado**: importe de los trámites no anulados. **Por cobrar**: pagos *Pendiente*. Los *Anulados* no suman.
- **Margen** = cobrado − costo asociado (insumos y tasas). No es utilidad neta.
- **Variación mensual**: el último mes del filtro (hasta la fecha de corte) contra los mismos días del mes anterior. Junio queda en blanco porque no tiene mes anterior.

## Páginas

Resumen ejecutivo · Finanzas (P1–P3) · Operaciones y tiempos (P7–P8) · Producción documental (P4–P6) · Clientes · Tooltip "Detalle del servicio" (aparece al pasar el cursor sobre un servicio).
