@echo off
start "" powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0hotkeys.ps1" -Quiet
