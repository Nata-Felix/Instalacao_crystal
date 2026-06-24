$ErrorActionPreference = "Stop"

$Version = "v1.0"
$Repo = "Nata-Felix/Instalacao_crystal"

$BaseUrl = "https://github.com/$Repo/releases/download/$Version"
$RawUrl = "https://raw.githubusercontent.com/$Repo/main"

$Destino = "C:\Windows\Temp\InstalacaoCrystal"

function BaixarArquivo {
param(
[string]$Url,
[string]$DestinoArquivo,
[string]$Nome
)

```
Write-Host ""
Write-Host "====================================="
Write-Host "Baixando: $Nome"
Write-Host "====================================="

$Request = [System.Net.HttpWebRequest]::Create($Url)
$Response = $Request.GetResponse()

$TotalBytes = $Response.ContentLength

$Stream = $Response.GetResponseStream()
$FileStream = [System.IO.File]::Create($DestinoArquivo)

$Buffer = New-Object byte[] 1048576
$TotalLido = 0
$UltimoPercentual = -1

do {

    $Lido = $Stream.Read($Buffer, 0, $Buffer.Length)

    if ($Lido -gt 0) {

        $FileStream.Write($Buffer, 0, $Lido)

        $TotalLido += $Lido

        if ($TotalBytes -gt 0) {

            $Percentual = [math]::Floor(($TotalLido / $TotalBytes) * 100)

            if ($Percentual -ne $UltimoPercentual) {

                $UltimoPercentual = $Percentual

                $BlocosTotal = 20
                $BlocosCheios = [math]::Floor($Percentual / 5)
                $BlocosVazios = $BlocosTotal - $BlocosCheios

                $Barra = "[" +
                    ("#" * $BlocosCheios) +
                    ("." * $BlocosVazios) +
                    "]"

                $MBLido = [math]::Round($TotalLido / 1MB, 1)
                $MBTotal = [math]::Round($TotalBytes / 1MB, 1)

                Write-Host "`r$Barra $Percentual% ($MBLido MB / $MBTotal MB)" -NoNewline
            }
        }
    }

} while ($Lido -gt 0)

$FileStream.Close()
$Stream.Close()
$Response.Close()

Write-Host ""
Write-Host "Concluido."
```

}

Clear-Host

Write-Host ""
Write-Host "====================================="
Write-Host " INSTALACAO AUTOMATICA CRYSTAL "
Write-Host "====================================="
Write-Host ""

if (Test-Path $Destino) {
Remove-Item -LiteralPath $Destino -Recurse -Force -ErrorAction SilentlyContinue
}

New-Item `    -ItemType Directory`
-Path $Destino `
-Force | Out-Null

$ArquivosRelease = @(
"dotnet48.exe",
"VC_redist.x86.exe",
"VC_redist.x64.exe",
"CRRuntime_32bit_13_0_39.msi",
"crdb_adoplus.zip"
)

foreach ($Arquivo in $ArquivosRelease) {

```
BaixarArquivo `
    -Url "$BaseUrl/$Arquivo" `
    -DestinoArquivo "$Destino\$Arquivo" `
    -Nome $Arquivo
```

}

BaixarArquivo `    -Url "$RawUrl/instalar.ps1"`
-DestinoArquivo "$Destino\instalar.ps1" `
-Nome "instalar.ps1"

Write-Host ""
Write-Host "====================================="
Write-Host "Downloads concluidos"
Write-Host "====================================="
Write-Host ""

Write-Host "Executando instalador como Administrador..."

Start-Process `    -FilePath "powershell.exe"`
-Verb RunAs `    -ArgumentList "-ExecutionPolicy Bypass -NoExit -File`"$Destino\instalar.ps1`""
