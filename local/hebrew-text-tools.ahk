#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"

; ═══════════════════════════════════════════════════════════════════
; Hebrew Text Tools — global hotkeys
; Alt+F5  — auto-detect & fix selected text  (כמו F10 ב-LangOver)
; Alt+F6  — clean tracking params from URL
; Alt+F7  — reverse text (visual ↔ logical)
; Alt+F8  — toggle keyboard layout (eng↔heb) without auto-detect
; Alt+F9  — show menu of all conversions
; ═══════════════════════════════════════════════════════════════════

NODE_EXE := "C:\Program Files\nodejs\node.exe"
FIX_JS   := A_ScriptDir . "\fix.js"
IN_FILE  := A_Temp . "\hebfix_in.txt"
OUT_FILE := A_Temp . "\hebfix_out.txt"

if !FileExist(NODE_EXE) {
    MsgBox "Node.js לא נמצא ב:`n" . NODE_EXE . "`n`nערוך את הסקריפט והתאם את הנתיב.", "Hebrew Text Tools", 0x10
    ExitApp
}
if !FileExist(FIX_JS) {
    MsgBox "fix.js לא נמצא ב:`n" . FIX_JS, "Hebrew Text Tools", 0x10
    ExitApp
}

A_TrayMenu.Delete()
A_TrayMenu.Add("Hebrew Text Tools", (*) => "")
A_TrayMenu.Disable("Hebrew Text Tools")
A_TrayMenu.Add()
A_TrayMenu.Add("Alt+F5  —  תיקון אוטומטי", (*) => RunFix("auto"))
A_TrayMenu.Add("Alt+F6  —  ניקוי URL", (*) => RunFix("cleanUrl"))
A_TrayMenu.Add("Alt+F7  —  היפוך טקסט", (*) => RunFix("visualToLogical"))
A_TrayMenu.Add("Alt+F8  —  המרת מקלדת", (*) => RunFix("engToHeb"))
A_TrayMenu.Add()
A_TrayMenu.Add("יציאה", (*) => ExitApp())
A_IconTip := "Hebrew Text Tools — Alt+F5 לתיקון"

!F5::RunFix("auto")
!F6::RunFix("cleanUrl")
!F7::RunFix("visualToLogical")
!F8::RunFix("engToHeb")
!F9::ShowMenu()

ShowMenu() {
    m := Menu()
    m.Add("תיקון אוטומטי`tAlt+F5", (*) => RunFix("auto"))
    m.Add("ניקוי URL`tAlt+F6", (*) => RunFix("cleanUrl"))
    m.Add("היפוך ויזואלי↔לוגי`tAlt+F7", (*) => RunFix("visualToLogical"))
    m.Add()
    m.Add("מקלדת אנג→עב", (*) => RunFix("engToHeb"))
    m.Add("מקלדת עב→אנג", (*) => RunFix("hebToEng"))
    m.Add()
    m.Add("HTML Decode", (*) => RunFix("htmlDecode"))
    m.Add("URL Decode", (*) => RunFix("urlDecode"))
    m.Add("תיקון Encoding", (*) => RunFix("fixEncoding"))
    m.Add("DOS → Windows", (*) => RunFix("dosToWin"))
    m.Show()
}

RunFix(mode) {
    global NODE_EXE, FIX_JS, IN_FILE, OUT_FILE

    saved := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(0.6) {
        A_Clipboard := saved
        TrayTip "לא נבחר טקסט", "סמן קודם את הטקסט שברצונך לתקן", "Iconi"
        SetTimer () => TrayTip(), -2000
        return
    }

    input := A_Clipboard
    if (Trim(input) = "") {
        A_Clipboard := saved
        return
    }

    try FileDelete IN_FILE
    try FileDelete OUT_FILE
    FileAppend input, IN_FILE, "UTF-8-RAW"

    cmd := A_ComSpec . ' /c ""' . NODE_EXE . '" "' . FIX_JS . '" ' . mode . ' < "' . IN_FILE . '" > "' . OUT_FILE . '""'
    RunWait cmd, , "Hide"

    if !FileExist(OUT_FILE) {
        A_Clipboard := saved
        TrayTip "שגיאה", "Node.js לא הצליח להריץ את fix.js", "Iconx"
        SetTimer () => TrayTip(), -2000
        return
    }

    result := FileRead(OUT_FILE, "UTF-8-RAW")
    if (result = "" || result = input) {
        A_Clipboard := saved
        TrayTip "אין שינוי", "לא זוהתה בעיה לתיקון", "Iconi"
        SetTimer () => TrayTip(), -1500
        return
    }

    A_Clipboard := result
    if !ClipWait(0.4) {
        A_Clipboard := saved
        return
    }
    Send "^v"
    Sleep 120

    SetTimer () => RestoreClipboard(saved), -800
}

RestoreClipboard(saved) {
    A_Clipboard := saved
}
