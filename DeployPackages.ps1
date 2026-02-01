Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Self = "https://raw.githubusercontent.com/taizxyz/deploy-tools/main/DeployPackages.ps1"

$admin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $admin) {
    Start-Process powershell -Verb RunAs -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy Bypass",
        "-Command irm $Self | iex"
    )
    exit
}

$Winget = (Get-Command winget.exe -ErrorAction SilentlyContinue).Source
if (-not $Winget) {
    $Winget = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
}
if (-not (Test-Path $Winget)) {
    throw "winget not found (install App Installer from Microsoft Store)"
}

function Installed($id) {
    & $Winget list --id $id -e 2>&1 | Select-String $id | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Install($id) {
    if (Installed $id) {
        Write-Host "$id already installed"
        return
    }

    Write-Host "Installing $id (silent)..."
    & $Winget install --id $id -e `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Silent failed, retrying normal..." -ForegroundColor Yellow
        & $Winget install --id $id -e `
            --accept-package-agreements `
            --accept-source-agreements

        if ($LASTEXITCODE -ne 0) {
            throw "Install failed: $id"
        }
    }

    Write-Host "$id installed"
}

Start-Process "ms-settings:windowsupdate" | Out-Null

$apps = @(
    "Google.Chrome",
    "Adobe.Acrobat.Reader.64-bit",
    "VideoLAN.VLC",
    "TheDocumentFoundation.LibreOffice"
)

$ok = 0
$fail = 0

foreach ($a in $apps) {
    try { Install $a; $ok++ }
    catch { Write-Host $_ -ForegroundColor Red; $fail++ }
}

Write-Host ""
Write-Host "Done. $ok ok / $fail failed."
