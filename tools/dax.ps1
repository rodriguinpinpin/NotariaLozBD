param([Parameter(Mandatory)][string]$Consulta)
# Ejecuta una consulta DAX contra el modelo abierto en Power BI Desktop (motor local msmdsrv).
# Devuelve filas como objetos. Uso: .\tools\dax.ps1 'EVALUATE ROW("v", [Importe cobrado])'
$ErrorActionPreference = 'Stop'
$pkg = (Get-AppxPackage Microsoft.MicrosoftPowerBIDesktop).InstallLocation
Add-Type -Path (Join-Path $pkg 'bin\Microsoft.PowerBI.AdomdClient.dll') | Out-Null

$pids = (Get-Process msmdsrv -ErrorAction SilentlyContinue).Id
if (-not $pids) { throw 'Power BI Desktop no tiene un modelo abierto (no hay msmdsrv).' }
$puertos = netstat -ano | Select-String 'LISTENING' | ForEach-Object {
    $c = ($_ -split '\s+') | Where-Object { $_ }
    if ($pids -contains [int]$c[-1] -and $c[1] -like '127.0.0.1:*') { ($c[1] -split ':')[-1] }
} | Select-Object -Unique

foreach ($puerto in $puertos) {
    $cn = New-Object Microsoft.AnalysisServices.AdomdClient.AdomdConnection "Data Source=localhost:$puerto"
    try {
        $cn.Open()
        $cmd = $cn.CreateCommand(); $cmd.CommandText = $Consulta
        $rd = $cmd.ExecuteReader()
        $filas = @()
        while ($rd.Read()) {
            $o = [ordered]@{}
            for ($i = 0; $i -lt $rd.FieldCount; $i++) { $o[($rd.GetName($i) -replace '^.*\[|\]$', '')] = $rd.GetValue($i) }
            $filas += [pscustomobject]$o
        }
        $rd.Close(); $cn.Close()
        return $filas
    } catch {
        $ultimoError = $_
        if ($cn.State -eq 'Open') { $cn.Close() }
    }
}
throw "Ningun modelo abierto respondio la consulta. Ultimo error: $ultimoError"
