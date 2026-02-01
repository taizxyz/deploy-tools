Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptUrl = "https://raw.githubusercontent.com/taizxyz/deploy-tools/main/DeployPackages.ps1"

function CheckAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function ElevateIfNeeded {
    if (CheckAdmin) { return }

    $args = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-WindowStyle", "Hidden",
        "-Command", "irm $ScriptUrl | iex"
    )

    $proc = Start-Process "powershell" -Verb RunAs -ArgumentList $args -PassThru
    $proc.WaitForExit()

    if ($proc.ExitCode -ne 0) {
        throw "Elevation failed (exit code $($proc.ExitCode))."
    }
    exit
}

function OpenWindowsUpdate {
    Start-Process "ms-settings:windowsupdate" | Out-Null
}

function CheckWinget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget not found."
    }
}

function IsInstalled([string]$Id) {
    $out = (winget list --id $Id -e 2>&1 | Out-String)
    if ($out -match "No installed package found") { return $false }
    return ($out -match [regex]::Escape($Id))
}

function InstallApp([string]$Id) {
    if (IsInstalled $Id) {
        Write-Host "$Id already installed."
        return
    }

    $logDir = Join-Path $env:TEMP "deploy-tools-logs"
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    $log = Join-Path $logDir "$Id.log"

    Write-Host "Installing $Id..."

    winget install --id $Id -e `
        --silent --disable-interactivity `
        --accept-source-agreements --accept-package-agreements `
        --verbose-logs --log $log

    $code = $LASTEXITCODE
    if ($code -ne 0) {
        throw "Install failed for $Id (exit $code). Log: $log"
    }

    Write-Host "$Id installed."
}

ElevateIfNeeded
OpenWindowsUpdate
CheckWinget

winget source reset --force | Out-Null

$apps = @(
    "Google.Chrome",
    "Adobe.Acrobat.Reader.64-bit",
    "VideoLAN.VLC",
    "TheDocumentFoundation.LibreOffice"
)

$ok = 0
$failed = 0

foreach ($app in $apps) {
    try {
        InstallApp $app
        $ok++
    }
    catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "Done: $ok ok, $failed failed."
