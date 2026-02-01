Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptUrl = "https://raw.githubusercontent.com/taizxyz/deploy-tools/main/DeployPackages.ps1"

function CheckAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function ElevateIfNeeded {
    if (CheckAdmin) { return }
    $params = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-WindowStyle", "Hidden",
        "-Command", "irm $ScriptUrl | iex"
    )
    $proc = Start-Process powershell -Verb RunAs -ArgumentList $params -PassThru
    $proc.WaitForExit()
    if ($proc.ExitCode -ne 0) {
        throw "Failed to elevate to admin (exit code $($proc.ExitCode))."
    }
    exit
}

function OpenWindowsUpdate {
    Start-Process "ms-settings:windowsupdate"
}

function CheckWinget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget not found, make sure App Installer is installed."
    }
}

function IsInstalled([string]$Id) {
    $out = winget list --id $Id -e 2>&1
    return ($LASTEXITCODE -eq 0 -and ($out -match [regex]::Escape($Id)))
}

function InstallApp([string]$Id) {
    if (IsInstalled $Id) {
        Write-Host "$Id is already installed."
        return
    }

    Write-Host "Installing $Id..."
    winget install --id $Id -e `
        --silent --disable-interactivity `
        --accept-source-agreements --accept-package-agreements `
        --scope machine `
        --force
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "Failed to install $Id (exit code $exitCode)."
    }
    Write-Host "$Id installed successfully."
}

ElevateIfNeeded
OpenWindowsUpdate
CheckWinget

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
        Write-Host "ERROR: $_" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "Done — $ok succeeded, $failed failed."