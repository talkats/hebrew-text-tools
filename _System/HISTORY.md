# Project History — Hebrew Text Tools

> Reconstructed on 2026-05-06 during the AGENTS.md brownfield retrofit, from sources that lacked dated entries.
> For dated changes from this point forward, see `CHANGELOG.md`.

## Origin

הפרויקט נולד באפריל 2026 כעמוד יחיד (`hebrew-text-tools.html`) שמרכז כלים שטל זקוק להם תכופות בעבודת טקסט: תיקון ג'יבריש, ניקוי URL, סימנים מיוחדים, וטקסט Unicode מעוצב. נבנה ב-co-design עם Claude Code, ללא תלויות חיצוניות, ופורסם ב-GitHub. אחרי הפרסום הראשוני הפרויקט נכנס לתרדמת — לא נגוע במשך כשלושה שבועות.

מקור: `~/.claude/projects/C--Dev-Projects-hebrew-text-tools/memory/project_overview.md` (auto-memory).

## Timeline

- **2026-04-15** — `hebrew-text-tools.html` נוצר/הסתיים. הקובץ מכיל ~1003 שורות, 4 טאבים מלאים (תיקון, URL, סימנים, מעוצב), כ-15 פונקציות תיקון. *(מקור: file mtime + auto-memory)*

- **2026-04 → 2026-05-04** — תקופת תרדמת. אין שינויים. *(מקור: היעדר עדויות לשינויים בקבצים)*

- **2026-05-05 09:08** — תיקיית הפרויקט נוצרה לוקלית במחשב של טל (`C:\Dev\Projects\hebrew-text-tools\`). *(מקור: mtime של התיקייה)*

- **2026-05-05 09:15** — Claude Code כתב את ה-auto-memory הראשון: "הפרויקט בסטטוס תחזוקה/הזנחה". *(מקור: auto-memory project_overview.md)*

- **2026-05-05 09:47** — Claude Code בנה את שכבת ה-`local/` (פאזה ראשונה): `fix.js` כפורט של ה-JS מה-HTML, `hebrew-text-tools.ahk` עבור AutoHotkey, `fix.ps1` כחלופת PowerShell, `install-shortcuts.ps1` ליצירת .lnk עם hotkeys. הסיבה: לאפשר תיקון טקסט מכל מקום במחשב בלי לקפוץ לדפדפן (UX בהשראת LangOver). *(מקור: file mtimes + תוכן הקבצים + שיחה בסשן)*

- **2026-05-05 17:38 → 17:58** — סוכן אחר (סביר: Codex או linter עם capabilities מורחבות) נכנס לפרויקט והרחיב אותו: יצר `hotkeys.ps1` — תהליך WinForms .NET שרושם את Alt+F5/F6/F7/F8 דרך Win32 `RegisterHotKey`, עם NotifyIcon ב-tray. גם נוסף `start-hotkeys.bat` להפעלה אילמת. במקביל שופץ `fix.ps1` לעבוד עם קבצי טמפ במקום stdin/stdout (אמינות עברית), ו-`fix.js` שודרג עם `COMMON_MAPPED_HEBREW_WORDS` ו-`looksLikeUsefulHebrewMapping` — heuristic שמונע המרת אנגלית לעברית אם התוצאה לא מילים אמיתיות. *(מקור: file mtimes + תוכן הקבצים + ה-frontmatter `originSessionId` ב-auto-memory מצביע על סשן אחר)*

- **2026-05-05 17:58:16** — `hotkeys.ps1` הופעל לראשונה. רישום מוצלח של 4 ה-hotkeys. *(מקור: hotkeys.log שורה 1-5)*

- **2026-05-05 18:02 → 2026-05-06 16:50** — שימוש פעיל של טל. ה-log מתעד 15+ הפעלות של Alt+F5 על קלטים בגדלים שונים (4 עד 227 תווים). *(מקור: hotkeys.log שורות 6-40+)*

- **2026-05-06 16:45** — Claude Code (סשן זה) ביצע retrofit של פרוטוקול AGENTS.md. *(מקור: סשן זה; ה-CHANGELOG החדש)*

## Key technical decisions (reconstructed)

- **שתי שכבות עצמאיות (HTML / local)** — נבחר במכוון. ה-HTML חייב להישאר עצמאי לחלוטין כדי לתפקד ב-GitHub Pages או בפתיחה ישירה כקובץ. שכבת ה-local יכולה להיות עשירה יותר (Node + PS) כי היא ממילא מותקנת על המחשב.

- **שלוש דרכי hotkey במקביל** — AHK (`hebrew-text-tools.ahk`, לא בשימוש), PowerShell-once (`fix.ps1` + `install-shortcuts.ps1`, חלופי), PowerShell-persistent (`hotkeys.ps1`, פעיל). הפעיל היום הוא הפתרון הטוב ביותר כי הוא תומך ב-F-keys (שלא נתמכים ב-Windows .lnk hotkeys) ולא דורש התקנה (שלא כמו AHK).

- **קבצי טמפ במקום pipes** — `hotkeys.ps1` ו-`fix.ps1` מעבירים טקסט ל-Node דרך `%TEMP%\hebrew-text-tools-in-{guid}.txt` ולא דרך stdin. הסיבה: אמינות UTF-8 על Windows כשמדובר בעברית.

- **9 בדיקות בסדר עדיפות ב-`autoDetect`** — URL → HTML entities → URL encoding → Latin-1 mojibake → UTF-8 mojibake → עברית ויזואלית → אנג→עב → עב→אנג → DOS. הסדר חשוב: בדיקות יותר ספציפיות קודם.

- **Hotkeys על Ctrl+Alt לא נרשמים ב-`hotkeys.ps1`** — `# Ctrl+Alt is intentionally not registered: on Hebrew keyboards it behaves like AltGr.` — קונבנציה חשובה לכל סוכן עתידי שיוסיף hotkeys.
