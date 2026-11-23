# Prueba T8 (revision final): cada segmentacion de pagina filtra los indicadores de esa pagina.
# Un filtro que no aplica devolveria el mismo valor que el total.
$ErrorActionPreference = 'Stop'
$dax = Join-Path (Split-Path (Split-Path $PSScriptRoot)) 'tools\dax.ps1'
$casos = @(
    @('[Importe facturado]', 'DIM_METODO_PAGO[Tipo_Pago] = "Yape"'),
    @('[Tramites registrados]', 'DIM_METODO_PAGO[Tipo_Pago] = "Yape"'),
    @('[Importe cobrado]', 'DIM_TURNO[Nombre_Turno] = "Tarde"'),
    @('[Margen]', 'DIM_TURNO[Nombre_Turno] = "Tarde"'),
    @('[Documentos otorgados]', 'DIM_TURNO[Nombre_Turno] = "Tarde"'),
    @('[Atencion media minutos]', 'DIM_CLIENTE[Tipo_Cliente] = "Juridica"'),
    @('[Documentos otorgados]', 'DIM_NOTARIO[Rol] = "Suplente"'),
    @('[Importe cobrado]', 'DIM_NOTARIO[Rol] = "Suplente"'),
    @('[Atenciones registradas]', 'DIM_NOTARIO[Rol] = "Suplente"')
)
$fallos = @()
foreach ($c in $casos) {
    $r = & $dax "EVALUATE ROW(""total"", $($c[0]), ""filtrado"", CALCULATE($($c[0]), $($c[1])))"
    if ($null -eq $r.filtrado -or $r.filtrado -is [DBNull] -or [double]$r.filtrado -eq [double]$r.total) {
        $fallos += "$($c[0]) no responde a $($c[1]) (total=$($r.total), filtrado=$($r.filtrado))"
    }
}
# El ultimo mes parcial se etiqueta y no entra al mini grafico de tendencia
$nov = (& $dax 'EVALUATE ROW("v", CALCULATE(MAX(DIM_TIEMPO[Mes_Etiqueta]), DIM_TIEMPO[Anio_Mes] = "2026-11"))').v
if ($nov -ne 'Nov (al 22)') { $fallos += "Etiqueta de noviembre: '$nov'" }
if ($fallos) { $fallos | % { Write-Host "FALLO $_" -ForegroundColor Red }; exit 1 }
Write-Host "t06_filtros: PASS ($($casos.Count + 1) comprobaciones)" -ForegroundColor Green; exit 0
