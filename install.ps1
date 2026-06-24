$ErrorActionPreference = "Stop"

$Version = "v1.0"
$Repo = "Nata-Felix/Instalacao_crystal"

$BaseUrl = "https://github.com/$Repo/releases/download/$Version"
$RawUrl = "https://raw.githubusercontent.com/$Repo/main"

$Destino = "C:\Windows\Temp\InstalacaoCrystal"

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
    $Url = "$BaseUrl/$Arquivo"
    $Out = Join-Path $Destino $Arquivo

    Write-Host "Baixando: $Arquivo"

    Invoke-WebRequest `
        -Uri $Url `
        -OutFile $Out `
        -UseBasicParsing
}

Write-Host "Baixando: instalar.ps1"

Invoke-WebRequest `
    -Uri "$RawUrl/instalar.ps1" `
    -OutFile "$Destino\instalar.ps1" `
    -UseBasicParsing

Write-Host "Iniciando instalador como Administrador..."

Start-Process powershell.exe `
    -Verb RunAs `
    -ArgumentList "-ExecutionPolicy Bypass -NoExit -File `"$Destino\instalar.ps1`""
