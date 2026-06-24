$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Version = "v1.0"
$Repo = "Nata-Felix/Instalacao_crystal"

$BaseUrl = "https://github.com/$Repo/releases/download/$Version"
$RawUrl = "https://raw.githubusercontent.com/$Repo/master"

$Destino = "C:\Windows\Temp\InstalacaoCrystal"

function BaixarArquivo {
param(
[string]$Url,
[string]$DestinoArquivo,
[string]$Nome
)

```
Write-Host ""
Write-Host "Baixando: $Nome"

$Request = [System.Net.HttpWebRequest]::Create($Url)
$Response = $Request.GetResponse()
$TotalBytes = $Response.ContentLength

$Stream = $Response.GetResponseStream()
$FileStream = [System.IO.File]::Create($DestinoArquivo)

# Buffer maior para baixar mais rapido que 8192 bytes
$Buffer = New-Object byte[] 1048576
$TotalLido = 0

do {
    $Lido = $Stream.Read($Buffer, 0, $Buffer.Length)

    if ($Lido -gt 0) {
        $FileStream.Write($Buffer, 0, $Lido)
        $TotalLido += $Lido

        if ($TotalBytes -gt 0) {
            $Percentual = [math]::Round(($TotalLido / $TotalBytes) * 100, 2)
            $MBLido = [math]::Round($TotalLido / 1MB, 2)
            $MBTotal = [math]::Round($TotalBytes / 1MB, 2)

            Write-Progress `
                -Activity "Baixando dependencias" `
                -Status "$Nome - $MBLido MB de $MBTotal MB" `
                -PercentComplete $Percentual
        }
    }

} while ($Lido -gt 0)

$FileStream.Close()
$Stream.Close()
$Response.Close()

Write-Progress -Activity "Baixando dependencias" -Completed
Write-Host "Concluido: $Nome"
```

}

Write-Host "====================================="
Write-Host "BOOTSTRAP INSTALACAO CRYSTAL"
Write-Host "====================================="

if (Test-Path $Destino) {
Remove-Item -LiteralPath $Destino -Recurse -Force -ErrorAction SilentlyContinue
}

New-Item -ItemType Directory -Path $Destino -Force | Out-Null

$ArquivosRelease = @(
"dotnet48.exe",
"VC_redist.x86.exe",
"VC_redist.x64.exe",
"CRRuntime_32bit_13_0_39.msi",
"crdb_adoplus.zip"
)

foreach ($Arquivo in $ArquivosRelease) {
BaixarArquivo `        -Url "$BaseUrl/$Arquivo"`
-DestinoArquivo "$Destino$Arquivo" `
-Nome $Arquivo
}

BaixarArquivo `    -Url "$RawUrl/instalar.ps1"`
-DestinoArquivo "$Destino\instalar.ps1" `
-Nome "instalar.ps1"

Write-Host ""
Write-Host "Iniciando instalador como Administrador..."

Start-Process powershell.exe `    -Verb RunAs`
-ArgumentList "-ExecutionPolicy Bypass -NoExit -File `"$Destino\instalar.ps1`""
