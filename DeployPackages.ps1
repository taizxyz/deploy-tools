Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptUrl = "https://raw.githubusercontent.com/taizxyz/deploy-tools/main/DeployPackages.ps1"

function IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function RelaunchAsAdmin {
    if (IsAdmin) { return }

    Start-Process powershell -Verb RunAs -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-Command", "irm $ScriptUrl | iex"
    )

    exit
}

function HasWinget {
    Get-Command winget -ErrorAction SilentlyContinue | Out-Null
}

function IsInstalled($Id) {
    $out = winget list --id $Id -e 2>&1 | Out-String
    -not ($out -match "No installed package found")
}

function InstallApp($Id) {
    if (IsInstalled $Id) {
        Write-Host "$Id already installed."
        return
    }

    Write-Host "Installing $Id (silent)..."
    winget install --id $Id -e `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Silent install failed, retrying interactive..." -ForegroundColor Yellow

        winget install --id $Id -e `
            --accept-package-agreements `
            --accept-source-agreements

        if ($LASTEXITCODE -ne 0) {
            throw "Install failed for $Id"
        }
    }

    Write-Host "$Id installed."
}

# ---- main ----

RelaunchAsAdmin

if (-not (HasWinget)) {
    throw "winget not found"
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

foreach ($app in $apps) {
    try {
        InstallApp $app
        $ok++
    }
    catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $fail++
    }
}

Write-Host ""
Write-Host "Done. $ok ok / $fail failed."
