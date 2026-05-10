param(
    [switch]$Quiet
)

# Hebrew Text Tools - persistent global hotkeys.
# Run with:
#   powershell -STA -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File hotkeys.ps1

$ErrorActionPreference = 'Stop'
$nodeExe = 'C:\Program Files\nodejs\node.exe'
$fixJs = Join-Path $PSScriptRoot 'fix.js'
$logFile = Join-Path $PSScriptRoot 'hotkeys.log'

function Write-Log([string]$Message) {
    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message
    Add-Content -Path $logFile -Value $line -Encoding UTF8
}

Write-Log 'Starting Hebrew Text Tools hotkey runner.'

if (-not (Test-Path $nodeExe)) { throw "Node.js was not found: $nodeExe" }
if (-not (Test-Path $fixJs)) { throw "fix.js was not found: $fixJs" }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies System.Windows.Forms,System.Drawing @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class HotkeyWindow : Form
{
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    public event Action<int> HotkeyPressed;

    protected override void SetVisibleCore(bool value)
    {
        base.SetVisibleCore(false);
    }

    protected override void WndProc(ref Message m)
    {
        if (m.Msg == 0x0312)
        {
            if (HotkeyPressed != null)
            {
                HotkeyPressed(m.WParam.ToInt32());
            }
        }
        base.WndProc(ref m);
    }
}

public static class NativeKeys
{
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

    public const uint KEYEVENTF_KEYUP = 0x0002;
    public const byte VK_CONTROL = 0x11;
    public const byte VK_MENU = 0x12;
    public const byte VK_SHIFT = 0x10;
    public const byte VK_C = 0x43;
    public const byte VK_V = 0x56;
}
"@

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

function Wait-ModifierKeysReleased {
    for ($i = 0; $i -lt 40; $i++) {
        $alt = [NativeKeys]::GetAsyncKeyState([NativeKeys]::VK_MENU) -band 0x8000
        $ctrl = [NativeKeys]::GetAsyncKeyState([NativeKeys]::VK_CONTROL) -band 0x8000
        $shift = [NativeKeys]::GetAsyncKeyState([NativeKeys]::VK_SHIFT) -band 0x8000
        if (-not $alt -and -not $ctrl -and -not $shift) { return }
        Start-Sleep -Milliseconds 25
    }
}

function Send-CtrlKey([byte]$Key) {
    Wait-ModifierKeysReleased
    Start-Sleep -Milliseconds 40
    [NativeKeys]::keybd_event([NativeKeys]::VK_CONTROL, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 20
    [NativeKeys]::keybd_event($Key, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 20
    [NativeKeys]::keybd_event($Key, 0, [NativeKeys]::KEYEVENTF_KEYUP, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 20
    [NativeKeys]::keybd_event([NativeKeys]::VK_CONTROL, 0, [NativeKeys]::KEYEVENTF_KEYUP, [UIntPtr]::Zero)
}

function Invoke-HebrewFix([string]$Mode) {
    Write-Log "Hotkey invoked: $Mode"
    $savedClipboard = Get-ClipboardTextSafe
    try { [System.Windows.Forms.Clipboard]::Clear() } catch { }

    Start-Sleep -Milliseconds 120
    Send-CtrlKey ([NativeKeys]::VK_C)

    $input = ''
    for ($i = 0; $i -lt 12; $i++) {
        Start-Sleep -Milliseconds 80
        $input = Get-ClipboardTextSafe
        if (-not [string]::IsNullOrEmpty($input)) { break }
    }

    if ([string]::IsNullOrWhiteSpace($input)) {
        Write-Log 'No selected text copied.'
        if ($savedClipboard) { [void](Set-ClipboardTextSafe $savedClipboard) }
        return
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
    $proc.WaitForExit()
    $result = ''
    if (Test-Path $tempOut) {
        $result = [System.IO.File]::ReadAllText($tempOut, [System.Text.Encoding]::UTF8)
    }
    Remove-Item -LiteralPath $tempIn -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tempOut -ErrorAction SilentlyContinue

    if ([string]::IsNullOrEmpty($result) -or $result -eq $input) {
        Write-Log 'No change produced.'
        if ($savedClipboard) { [void](Set-ClipboardTextSafe $savedClipboard) }
        return
    }

    if (Set-ClipboardTextSafe $result) {
        Write-Log "Pasting result. Input length=$($input.Length), output length=$($result.Length)."
        Start-Sleep -Milliseconds 80
        Send-CtrlKey ([NativeKeys]::VK_V)
        if ($savedClipboard) {
            Start-Sleep -Milliseconds 400
            [void](Set-ClipboardTextSafe $savedClipboard)
        }
    }
}

$modes = @{
    1 = 'auto'
    2 = 'cleanUrl'
    3 = 'visualToLogical'
    4 = 'engToHeb'
    5 = 'auto'
    6 = 'cleanUrl'
    7 = 'visualToLogical'
    8 = 'engToHeb'
}

$form = New-Object HotkeyWindow
$null = $form.Handle

$MOD_ALT = 0x0001
$MOD_CONTROL = 0x0002

function Register-HebrewHotkey([int]$Id, [uint32]$Modifiers, [uint32]$Vk, [string]$Name) {
    $ok = [HotkeyWindow]::RegisterHotKey($form.Handle, $Id, $Modifiers, $Vk)
    if ($ok) {
        Write-Log "Registered $Name"
    } else {
        $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-Log "FAILED to register $Name. Win32Error=$err"
    }
    return $ok
}

# Alt+F5/F6/F7/F8
[void](Register-HebrewHotkey 1 $MOD_ALT 0x74 'Alt+F5')
[void](Register-HebrewHotkey 2 $MOD_ALT 0x75 'Alt+F6')
[void](Register-HebrewHotkey 3 $MOD_ALT 0x76 'Alt+F7')
[void](Register-HebrewHotkey 4 $MOD_ALT 0x77 'Alt+F8')

# Ctrl+Alt is intentionally not registered: on Hebrew keyboards it behaves like AltGr.

$form.add_HotkeyPressed({
    param($id)
    if ($modes.ContainsKey($id)) {
        Invoke-HebrewFix $modes[$id]
    }
})

$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.SystemIcons]::Information
$notify.Text = 'Hebrew Text Tools'
$notify.Visible = $true
$notify.ContextMenuStrip = New-Object System.Windows.Forms.ContextMenuStrip
$null = $notify.ContextMenuStrip.Items.Add('Exit', $null, {
    $notify.Visible = $false
    [System.Windows.Forms.Application]::Exit()
})

if (-not $Quiet) {
    $notify.ShowBalloonTip(2500, 'Hebrew Text Tools', 'Hotkeys active: Alt+F5, Alt+F6, Alt+F7, Alt+F8', [System.Windows.Forms.ToolTipIcon]::Info)
}

try {
    [System.Windows.Forms.Application]::Run($form)
}
finally {
    Write-Log 'Stopping Hebrew Text Tools hotkey runner.'
    foreach ($id in 1..8) {
        [void][HotkeyWindow]::UnregisterHotKey($form.Handle, $id)
    }
    $notify.Visible = $false
}
