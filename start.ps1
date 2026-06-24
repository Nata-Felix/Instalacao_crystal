$Base = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script = Join-Path $Base "instalar.ps1"

if (!(Test-Path $Script)) {
    Write-Host "ERRO: Arquivo nao encontrado:"
    Write-Host $Script
    pause
    exit 1
}

$Argumentos = "-ExecutionPolicy Bypass -NoExit -File `"$Script`""

Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $Argumentos