param(
    [string]$Mode = 'auto'
)

# Hebrew Text Tools - PowerShell launcher.
# Copies the selected text, runs fix.js via Node, then pastes the result back.

$ErrorActionPreference = 'Stop'
$nodeExe = 'C:\Program Files\nodejs\node.exe'
$fixJs = Join-Path $PSScriptRoot 'fix.js'

if (-not (Test-Path $nodeExe)) { throw "Node.js was not found: $nodeExe" }
if (-not (Test-Path $fixJs)) { throw "fix.js was not found: $fixJs" }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

function Get-ClipboardTextSafe {
    try {
        if ([System.Windows.Forms.Clipboard]::ContainsText()) {
            return [System.Windows.Forms.Clipboard]::GetText()
        }
    } catch { }
    return ''
}

function Set-ClipboardTextSafe([string]$Text) {
    for ($i = 0; $i -lt 8; $i++) {
        try {
            [System.Windows.Forms.Clipboard]::SetText($Text)
            return $true
        } catch {
            Start-Sleep -Milliseconds 80
        }
    }
    return $false
}

function Send-KeyChord([string]$Keys) {
    $wshell = New-Object -ComObject WScript.Shell
    $wshell.SendKeys($Keys)
}

$savedClipboard = Get-ClipboardTextSafe

try { [System.Windows.Forms.Clipboard]::Clear() } catch { }

# Give Windows a moment to return focus to the app that invoked the shortcut.
Start-Sleep -Milliseconds 250
Send-KeyChord '^c'

$input = ''
for ($i = 0; $i -lt 12; $i++) {
    Start-Sleep -Milliseconds 100
    $input = Get-ClipboardTextSafe
    if (-not [string]::IsNullOrEmpty($input)) { break }
}

if ([string]::IsNullOrWhiteSpace($input)) {
    if ($savedClipboard) { [void](Set-ClipboardTextSafe $savedClipboard) }
    [System.Windows.Forms.MessageBox]::Show(
        'No selected text was copied. Select text and press the shortcut again.',
        'Hebrew Text Tools',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
    exit 1
}

$tempIn = Join-Path $env:TEMP ("hebrew-text-tools-in-{0}.txt" -f ([guid]::NewGuid()))
$tempOut = Join-Path $env:TEMP ("hebrew-text-tools-out-{0}.txt" -f ([guid]::NewGuid()))
[System.IO.File]::WriteAllText($tempIn, $input, [System.Text.Encoding]::UTF8)

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $nodeExe
$psi.Arguments = "`"$fixJs`" $Mode `"$tempIn`" `"$tempOut`""
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$proc = [System.Diagnostics.Process]::Start($psi)
$errorText = $proc.StandardError.ReadToEnd()
$proc.WaitForExit()
$result = ''
if (Test-Path $tempOut) {
    $result = [System.IO.File]::ReadAllText($tempOut, [System.Text.Encoding]::UTF8)
}
Remove-Item -LiteralPath $tempIn -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $tempOut -ErrorAction SilentlyContinue

if ($proc.ExitCode -ne 0) {
    if ($savedClipboard) { [void](Set-ClipboardTextSafe $savedClipboard) }
    [System.Windows.Forms.MessageBox]::Show(
        "Node fixer failed.`r`n$errorText",
        'Hebrew Text Tools',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit $proc.ExitCode
}

if ([string]::IsNullOrEmpty($result) -or $result -eq $input) {
    if ($savedClipboard) { [void](Set-ClipboardTextSafe $savedClipboard) }
    exit 0
}

if (-not (Set-ClipboardTextSafe $result)) {
    [System.Windows.Forms.MessageBox]::Show(
        'Could not write the fixed text to the clipboard.',
        'Hebrew Text Tools',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

Start-Sleep -Milliseconds 100
Send-KeyChord '^v'

if ($savedClipboard) {
    Start-Sleep -Milliseconds 500
    [void](Set-ClipboardTextSafe $savedClipboard)
}
