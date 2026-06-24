$Base = Split-Path -Parent $MyInvocation.MyCommand.Path

$Log = Join-Path $Base "install_final_log.txt"
$CrystalLog = Join-Path $Base "crystal_install.log"
$CrystalUninstallLog = Join-Path $Base "crystal_uninstall.log"

$Net48 = Join-Path $Base "4.8 OFFLINE.exe"
$VCx86 = Join-Path $Base "VC_redist.x86.exe"
$VCx64 = Join-Path $Base "VC_redist.x64.exe"
$CrystalMsi = Join-Path $Base "CRRuntime_32bit_13_0_39.msi"
$FixZip = Join-Path $Base "crdb_adoplus.zip"

$DestinoCrystal = "C:\Program Files (x86)\SAP BusinessObjects\Crystal Reports for .NET Framework 4.0\Common\SAP BusinessObjects Enterprise XI 4.0\win32_x86"
$TempFix = "C:\Windows\Temp\crdb_adoplus_fix"

function LogMsg {
    param([string]$Texto)
    $Linha = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Texto"
    Add-Content -Path $Log -Value $Linha
    Write-Host $Linha
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function InstalarExe {
    param(
        [string]$Caminho,
        [string]$Argumentos,
        [string]$Nome
    )

    LogMsg "====================================="
    LogMsg "Iniciando: $Nome"
    LogMsg "Arquivo: $Caminho"
    LogMsg "Argumentos: $Argumentos"

    if (!(Test-Path $Caminho)) {
        LogMsg "ERRO: Arquivo nao encontrado: $Caminho"
        return $false
    }

    Unblock-File $Caminho -ErrorAction SilentlyContinue

    if ([string]::IsNullOrWhiteSpace($Argumentos)) {
        $Processo = Start-Process -FilePath $Caminho -Wait -PassThru
    }
    else {
        $Processo = Start-Process -FilePath $Caminho -ArgumentList $Argumentos -Wait -PassThru
    }

    LogMsg "$Nome finalizado. ExitCode: $($Processo.ExitCode)"

    if ($Processo.ExitCode -eq 0 -or $Processo.ExitCode -eq 3010) {
        return $true
    }

    return $false
}

Clear-Host

LogMsg "====================================="
LogMsg "INSTALADOR FINAL - DEPENDENCIAS TEKFARMA"
LogMsg "====================================="

if (!(Test-Admin)) {
    LogMsg "ERRO: Este script NAO esta rodando como Administrador."
    LogMsg "Execute pelo start.ps1 para elevar automaticamente."
    exit 1
}

InstalarExe $Net48 "/q /norestart" ".NET Framework 4.8 Offline"
InstalarExe $VCx86 "/install /quiet /norestart" "Visual C++ Redistributable x86"
InstalarExe $VCx64 "/install /quiet /norestart" "Visual C++ Redistributable x64"

LogMsg "====================================="
LogMsg "Procurando instalacoes antigas do Crystal Reports..."

$CrystalInstalados = Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", `
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -ErrorAction SilentlyContinue |
    Where-Object {
        ($_.DisplayName -like "*Crystal*Reports*") -or
        ($_.DisplayName -like "*SAP Crystal*") -or
        ($_.DisplayName -like "*runtime engine for .NET Framework*")
    }

if ($CrystalInstalados) {
    foreach ($Crystal in $CrystalInstalados) {
        LogMsg "Encontrado: $($Crystal.DisplayName) - $($Crystal.DisplayVersion)"
        LogMsg "PSChildName: $($Crystal.PSChildName)"
        LogMsg "UninstallString: $($Crystal.UninstallString)"

        if ($Crystal.PSChildName -match "^\{.*\}$") {
            $Guid = $Crystal.PSChildName

            LogMsg "Desinstalando Crystal via MSI: $Guid"

            $ProcUninstall = Start-Process -FilePath "msiexec.exe" `
                -ArgumentList "/x $Guid /qn /norestart /L*v `"$CrystalUninstallLog`"" `
                -Wait -PassThru

            LogMsg "Desinstalacao Crystal ExitCode: $($ProcUninstall.ExitCode)"

            if ($ProcUninstall.ExitCode -ne 0 -and $ProcUninstall.ExitCode -ne 3010 -and $ProcUninstall.ExitCode -ne 1605) {
                LogMsg "AVISO: Falha ao desinstalar pelo MSI. O registro pode continuar aparecendo no appwiz.cpl."
            }
        }
        else {
            LogMsg "AVISO: ProductCode/GUID nao encontrado. Nao foi possivel desinstalar automaticamente este item."
        }
    }
}
else {
    LogMsg "Nenhuma instalacao do Crystal encontrada no registro."
}

LogMsg "====================================="
LogMsg "Limpando pastas antigas SAP BusinessObjects..."

$PastasCrystal = @(
    "C:\Program Files (x86)\SAP BusinessObjects",
    "C:\Program Files\SAP BusinessObjects"
)

foreach ($Pasta in $PastasCrystal) {
    if (Test-Path $Pasta) {
        LogMsg "Apagando pasta: $Pasta"
        try {
            Remove-Item -LiteralPath $Pasta -Recurse -Force -ErrorAction Stop
            LogMsg "Pasta apagada com sucesso: $Pasta"
        }
        catch {
            LogMsg "AVISO: Nao foi possivel apagar totalmente a pasta: $Pasta"
            LogMsg "Motivo: $($_.Exception.Message)"
        }
    }
    else {
        LogMsg "Pasta nao existe: $Pasta"
    }
}

LogMsg "====================================="
LogMsg "Instalando Crystal Reports Runtime novo..."

if (!(Test-Path $CrystalMsi)) {
    LogMsg "ERRO: MSI nao encontrado: $CrystalMsi"
    exit 1
}

Unblock-File $CrystalMsi -ErrorAction SilentlyContinue

$Processo = Start-Process -FilePath "msiexec.exe" `
    -ArgumentList "/i `"$CrystalMsi`" /qn /norestart /L*v `"$CrystalLog`"" `
    -Wait -PassThru

LogMsg "Crystal Reports Runtime finalizado. ExitCode: $($Processo.ExitCode)"

if ($Processo.ExitCode -ne 0 -and $Processo.ExitCode -ne 3010) {
    LogMsg "ERRO: Crystal nao instalou corretamente. Veja o log: $CrystalLog"
    exit 1
}

LogMsg "====================================="
LogMsg "Aplicando crdb_adoplus.zip..."

if (!(Test-Path $FixZip)) {
    LogMsg "ERRO: ZIP nao encontrado: $FixZip"
    exit 1
}

if (!(Test-Path $DestinoCrystal)) {
    LogMsg "ERRO: Pasta destino do Crystal nao encontrada: $DestinoCrystal"
    exit 1
}

if (Test-Path $TempFix) {
    Remove-Item -LiteralPath $TempFix -Recurse -Force -ErrorAction SilentlyContinue
}

New-Item -ItemType Directory -Path $TempFix -Force | Out-Null

try {
    Unblock-File $FixZip -ErrorAction SilentlyContinue

    Expand-Archive -LiteralPath $FixZip -DestinationPath $TempFix -Force

    LogMsg "Copiando arquivos do fix para: $DestinoCrystal"

    Copy-Item -LiteralPath (Join-Path $TempFix "*") `
        -Destination $DestinoCrystal `
        -Recurse `
        -Force `
        -ErrorAction Stop

    LogMsg "Fix crdb_adoplus aplicado com sucesso."
}
catch {
    LogMsg "ERRO ao aplicar fix: $($_.Exception.Message)"
    exit 1
}
finally {
    if (Test-Path $TempFix) {
        Remove-Item -LiteralPath $TempFix -Recurse -Force -ErrorAction SilentlyContinue
    }
}

LogMsg "====================================="
LogMsg "PROCESSO FINALIZADO COM SUCESSO"
LogMsg "Log geral: $Log"
LogMsg "Log Crystal install: $CrystalLog"
LogMsg "Log Crystal uninstall: $CrystalUninstallLog"
LogMsg "====================================="