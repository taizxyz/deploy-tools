deploy-tools

Small PowerShell script to bootstrap a fresh Windows install.

I use it mostly after a clean OS reinstall where I don't want to spend 20 minutes
downloading stuff one by one. Run it once, done.

It auto-elevates, installs everything silently via winget, and opens Windows Update
in the background so the system can patch itself while it works.

What gets installed

- Google Chrome
- Adobe Acrobat Reader
- VLC
- LibreOffice

Easy to edit, just change the list in the script.

Requirements

- Windows 10 or 11
- PowerShell 5.1+
- winget

How to run

Open PowerShell, no admin needed:
```powershell
irm https://raw.githubusercontent.com/taizxyz/deploy-tools/main/DeployPackages.ps1 | iex
```

That's it.