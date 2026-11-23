# Reconstruye todo desde cero: OLTP -> datos -> DW -> ETL -> validación.
# Se detiene en el primer fallo. Uso:  powershell -File sql\ejecutar_todo.ps1
$ErrorActionPreference = 'Stop'
$sql = $PSScriptRoot
$pasos = @(
    '01_crear_oltp.sql', 'tests\t01_oltp.sql',
    '02_datos_oltp.sql', 'tests\t02_datos.sql',
    '03_crear_dw.sql',   '04_etl_dw.sql', 'tests\t03_dw.sql', 'tests\t04_claves.sql'
)
foreach ($p in $pasos) {
    & "$sql\run.ps1" (Join-Path $sql $p) | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "FALLO en $p" -ForegroundColor Red; exit 1 }
    Write-Host "OK  $p" -ForegroundColor Green
}

$csv = Join-Path $sql 'referencia.csv'
$filas = & sqlcmd -S '.\SQLEXPRESS' -E -C -b -f 65001 -W -h -1 -s ';' -i (Join-Path $sql '05_validacion.sql')
if ($LASTEXITCODE -ne 0) { Write-Host 'FALLO en 05_validacion.sql' -ForegroundColor Red; exit 1 }
$filas = $filas | Where-Object { $_ -match ';' }
@('Indicador;Filtro;Valor') + $filas | Set-Content -Path $csv -Encoding UTF8
if ($filas.Count -lt 60) { Write-Host "referencia.csv tiene solo $($filas.Count) filas" -ForegroundColor Red; exit 1 }
Write-Host "OK  05_validacion.sql -> referencia.csv ($($filas.Count) filas)" -ForegroundColor Green
exit 0
