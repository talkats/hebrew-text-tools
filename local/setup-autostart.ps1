# setup-autostart.ps1
# Run once after install.
# 1. Creates a Startup folder shortcut → hotkeys.ps1 starts automatically on every login.
# 2. Creates a Desktop shortcut → manual restart if Alt+F5 stops responding.

$batPath  = Join-Path $PSScriptRoot 'start-hotkeys.bat'
$iconPath = Join-Path $PSScriptRoot '..\hebrew-text-tools.html'
$shell    = New-Object -ComObject WScript.Shell

function New-Shortcut($destination, $label) {
    $lnk = $shell.CreateShortcut($destination)
    $lnk.TargetPath       = $batPath
    $lnk.WorkingDirectory = $PSScriptRoot
    $lnk.WindowStyle      = 7   # minimized / hidden
    $lnk.Description      = 'Start Hebrew Text Tools hotkey listener (Alt+F5/F6/F7/F8)'
    $lnk.Save()
    Write-Host "Created $label`: $destination"
}

# 1 — Startup folder (auto-start on login)
$startup = [Environment]::GetFolderPath('Startup')
New-Shortcut (Join-Path $startup 'Hebrew Text Tools.lnk') 'Startup shortcut'

# 2 — Desktop (manual restart)
$desktop = [Environment]::GetFolderPath('Desktop')
New-Shortcut (Join-Path $desktop 'Hebrew Text Tools.lnk') 'Desktop shortcut'

Write-Host ''
Write-Host 'Done. The listener will start automatically on next login.'
Write-Host 'To start it now without rebooting, double-click the Desktop shortcut.'
