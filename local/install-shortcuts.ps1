# Creates Desktop shortcuts with global hotkeys.
# Run once:
#   powershell -ExecutionPolicy Bypass -File install-shortcuts.ps1
# Hotkeys are limited by Windows .lnk files to Ctrl+Alt+Letter:
#   Ctrl+Alt+H - auto-fix
#   Ctrl+Alt+U - clean URL
#   Ctrl+Alt+R - reverse text
#   Ctrl+Alt+K - keyboard layout conversion

$scriptDir = $PSScriptRoot
$desktop = [Environment]::GetFolderPath('Desktop')
$shortcuts = @(
    @{ Name = 'HebFix-Auto';     Mode = 'auto';            Hotkey = 'Ctrl+Alt+H' },
    @{ Name = 'HebFix-CleanUrl'; Mode = 'cleanUrl';        Hotkey = 'Ctrl+Alt+U' },
    @{ Name = 'HebFix-Reverse';  Mode = 'visualToLogical'; Hotkey = 'Ctrl+Alt+R' },
    @{ Name = 'HebFix-Keyboard'; Mode = 'engToHeb';        Hotkey = 'Ctrl+Alt+K' }
)

$shell = New-Object -ComObject WScript.Shell
foreach ($s in $shortcuts) {
    $path = Join-Path $desktop "$($s.Name).lnk"
    $sc = $shell.CreateShortcut($path)
    $sc.TargetPath = 'powershell.exe'
    $sc.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptDir\fix.ps1`" -Mode $($s.Mode)"
    $sc.WorkingDirectory = $scriptDir
    $sc.WindowStyle = 7
    $sc.Hotkey = $s.Hotkey
    $sc.Save()
    Write-Host "Created: $path -> $($s.Hotkey)"
}

Write-Host ''
Write-Host 'Shortcuts created.'
Write-Host 'Windows shortcut hotkeys may take about one second to run.'
Write-Host 'For faster Alt+F5-style behavior, install AutoHotkey v2 and run hebrew-text-tools.ahk.'
