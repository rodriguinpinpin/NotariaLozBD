# Prueba T5: las medidas DAX del modelo abierto en Power BI Desktop coinciden con sql/referencia.csv
$ErrorActionPreference = 'Stop'
$raiz = Split-Path (Split-Path $PSScriptRoot)
$dax = Join-Path $raiz 'tools\dax.ps1'
$ref = Import-Csv (Join-Path $raiz 'sql\referencia.csv') -Delimiter ';' -Encoding UTF8

$medida = @{
    'Importe cobrado' = '[Importe cobrado]'; 'Importe facturado' = '[Importe facturado]'; 'Por cobrar' = '[Por cobrar]'
    'Costo asociado' = '[Costo asociado]'; 'Margen' = '[Margen]'; 'Tramites registrados' = '[Tramites registrados]'
    'Atenciones registradas' = '[Atenciones registradas]'; 'Atencion media minutos' = '[Atencion media minutos]'
    'Espera media minutos' = '[Espera media minutos]'; 'Documentos otorgados' = '[Documentos otorgados]'
    'Clientes unicos' = '[Clientes unicos]'
}
# Pregunta -> (columna de agrupacion, expresion)
$preguntas = @{
    'Servicio con mayor margen'          = @('DIM_SERVICIO[Nombre_Tramite]', '[Margen]')
    'Trimestre con mas tramites'         = @('DIM_TIEMPO[Trimestre_Texto]', '[Tramites registrados]')
    'Empleado con mas efectivo'          = @('DIM_PERSONAL[Nombre_Completo]', 'CALCULATE([Importe cobrado], DIM_METODO_PAGO[Tipo_Pago] = "Efectivo")')
    'Metodo preferido Juridica'          = @('DIM_METODO_PAGO[Tipo_Pago]', 'CALCULATE([Registros financieros], DIM_CLIENTE[Tipo_Cliente] = "Juridica")')
    'Metodo preferido Natural'           = @('DIM_METODO_PAGO[Tipo_Pago]', 'CALCULATE([Registros financieros], DIM_CLIENTE[Tipo_Cliente] = "Natural")')
    'Cargo con mas escrituras publicas'  = @('DIM_PERSONAL[Cargo]', 'CALCULATE([Tramites registrados], KEEPFILTERS(SEARCH("Escrituras", DIM_SERVICIO[Categoria], 1, 0) > 0))')
    'Tipo documental con mas documentos' = @('DIM_TIPO_DOCUMENTO[Nombre_TipoDocumento]', '[Documentos otorgados]')
    'Empleado con mas documentos'        = @('DIM_PERSONAL[Nombre_Completo]', '[Documentos otorgados]')
    'Servicio con mayor atencion media'  = @('DIM_SERVICIO[Nombre_Tramite]', '[Atencion media minutos]')
    'Turno con mayor atencion media'     = @('DIM_TURNO[Nombre_Turno]', '[Atencion media minutos]')
    'Etapa con mayor espera media'       = @('DIM_ETAPA_TRAMITE[Nombre_Etapa]', '[Espera media minutos]')
}

$fallos = @(); $ok = 0
foreach ($r in $ref) {
    if ($medida.ContainsKey($r.Indicador)) {
        $m = $medida[$r.Indicador]
        $expr = if ($r.Filtro -eq 'Total') { $m } else { "CALCULATE($m, DIM_TIEMPO[Anio_Mes] = ""$($r.Filtro.Substring(4))"")" }
        $v = (& $dax "EVALUATE ROW(""v"", $expr)").v
        if ($null -eq $v -or $v -is [DBNull]) { $v = 0 }
        if ([math]::Abs([double]$v - [double]$r.Valor) -gt 0.01) { $fallos += "$($r.Indicador) [$($r.Filtro)]: DAX=$v SQL=$($r.Valor)" } else { $ok++ }
    } elseif ($preguntas.ContainsKey($r.Filtro)) {
        $col, $expr = $preguntas[$r.Filtro]
        $fila = & $dax "EVALUATE TOPN(1, FILTER(ADDCOLUMNS(VALUES($col), ""v"", $expr), NOT ISBLANK([v])), [v], DESC)"
        $nombre = @($fila.PSObject.Properties)[0].Value; $valor = [double]$fila.v
        $esperado, $valEsperado = $r.Valor -split '\|'
        if ($nombre -ne $esperado -or [math]::Abs($valor - [double]$valEsperado) -gt 0.01) {
            $fallos += "$($r.Indicador) $($r.Filtro): DAX=$nombre|$valor SQL=$($r.Valor)"
        } else { $ok++ }
    } else { $fallos += "Sin mapeo: $($r.Indicador) / $($r.Filtro)" }
}

# Junio no tiene mes anterior: la variacion debe quedar en blanco
$jun = (& $dax 'EVALUATE ROW("v", CALCULATE([Variacion mensual cobros], DIM_TIEMPO[Anio_Mes] = "2026-06"))').v
if ($null -ne $jun -and -not ($jun -is [DBNull])) { $fallos += "Variacion de junio deberia estar en blanco y es $jun" } else { $ok++ }
# Julio si tiene variacion (mes a la fecha vs mismos dias de junio)
$jul = (& $dax 'EVALUATE ROW("v", CALCULATE([Variacion mensual cobros], DIM_TIEMPO[Anio_Mes] = "2026-07"))').v
if ($null -eq $jul -or $jul -is [DBNull]) { $fallos += 'Variacion de julio en blanco' } else { $ok++ }

if ($fallos) { $fallos | ForEach-Object { Write-Host "FALLO $_" -ForegroundColor Red }; Write-Host "$ok OK, $($fallos.Count) fallos"; exit 1 }
Write-Host "t05_medidas: PASS ($ok comprobaciones)" -ForegroundColor Green; exit 0
