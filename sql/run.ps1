param([Parameter(Mandatory)][string]$Archivo, [string]$Servidor = '.\SQLEXPRESS')
# Ejecuta un script T-SQL contra la instancia local; sale con error si el script falla.
$ErrorActionPreference = 'Stop'
$ruta = Resolve-Path $Archivo
if ((Split-Path $ruta -Leaf) -like '02_*') {
    $prohibidos = Select-String -Path $ruta -Pattern 'NEWID\(|RAND\(' -SimpleMatch:$false
    if ($prohibidos) { Write-Error "El generador usa NEWID()/RAND(): no es determinista. Lineas: $($prohibidos.LineNumber -join ',')" }
}
& sqlcmd -S $Servidor -E -C -b -I -f 65001 -i $ruta
if ($LASTEXITCODE -ne 0) { Write-Host "FALLO: $Archivo" -ForegroundColor Red; exit $LASTEXITCODE }
Write-Host "OK: $Archivo" -ForegroundColor Green
