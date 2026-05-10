# AGENTS.md — Hebrew Text Tools

> Source of truth for any AI agent working on this project.
> Bootstrapped: 2026-05-06
> Mode: brownfield-retrofit

## 1. What this project is

כלי טקסט עברי — אוסף כלים לעבודה עם טקסט עברי בעייתי (ג'יבריש, פריסת מקלדת שגויה, encoding שבור, קישורים מלאים בפרמטרי מעקב, סימנים מיוחדים, טקסט Unicode מעוצב).

מורכב משני חלקים:
1. **`hebrew-text-tools.html`** — אפליקציית עמוד יחיד עצמאית (HTML+CSS+JS, ללא תלויות). 4 טאבים: תיקון טקסט, ניקוי URL, סימנים מיוחדים, טקסט Unicode מעוצב. נבנה אפריל 2026, מאוחסן ב-GitHub.
2. **`local/`** — שכבת אוטומציה לוקלית (Node + PowerShell + AHK) שמאפשרת להפעיל את לוגיקת התיקון בכל מקום במחשב דרך hotkeys גלובליים. נבנה מאי 2026.

הזרימה הפעילה היום: המשתמש מסמן טקסט בכל אפליקציה → Alt+F5 → `hotkeys.ps1` שולח Ctrl+C, מעביר את הטקסט ל-`fix.js` (Node), מקבל את התוצאה המתוקנת, מדביק במקום עם Ctrl+V.

## 2. How to build / run / test

**אין build step.** הכל סקריפטים שרצים ישירות.

- **HTML standalone:** דאבל-קליק על `hebrew-text-tools.html` → נפתח בדפדפן.
- **Node engine:** `node local/fix.js auto` — קורא טקסט מ-stdin, כותב לתוצאה ל-stdout.
- **בדיקה ידנית:** `echo akuo | node local/fix.js auto` → אמור להחזיר `שלום`.
- **Hotkey listener (אקטיבי):** `local/start-hotkeys.bat` — מפעיל את `hotkeys.ps1` ברקע עם tray icon.
- **Hotkey listener (חלופי, לא בשימוש):** הקיצורים ב-`install-shortcuts.ps1` יוצרים .lnk עם hotkeys של Ctrl+Alt+אות (ללא תהליך מתמשך).
- **AHK alternative (לא מותקן):** `hebrew-text-tools.ahk` — דורש AutoHotkey v2; חלופה ל-`hotkeys.ps1` עם פחות overhead.

## 3. Architecture at a glance

- **שתי שכבות עצמאיות:**
  - HTML עצמאי — מודולי לוגיקה ב-JavaScript, פועל בדפדפן בלבד
  - Node-based local — פורט של הלוגיקה ל-CommonJS, נצרך ע"י wrappers (PowerShell/AHK)
- **`fix.js`** — נקודת הכניסה ללוגיקת התיקון. מייצא `applyFix(input, mode)` ו-`autoDetect(text)`. תומך ב-15 modes (auto, engToHeb, hebToEng, visualToLogical, logicalToVisual, dosToWin, winToDos, htmlEncode, htmlDecode, urlEncode, urlDecode, fixEncoding, reverseWords, cleanUrl, ועוד).
- **`hotkeys.ps1`** — תהליך .NET WinForms שרושם את Alt+F5/F6/F7/F8 דרך user32!RegisterHotKey, בעל לולאת הודעות עם NotifyIcon. מתקשר עם `fix.js` דרך קבצי טמפ ב-`%TEMP%` (לא stdin/stdout כי זה אמין יותר עם Hebrew encoding).
- **`fix.ps1`** — wrapper חד-פעמי (לא תהליך מתמשך). נשמר כרגע אבל פחות בשימוש מאז ש-`hotkeys.ps1` רץ.
- **שני קונבנציות hotkey:**
  - **Alt+F5/F6/F7/F8** דרך `hotkeys.ps1` (הפעיל היום — auto/cleanUrl/visualToLogical/engToHeb בהתאמה)
  - **Ctrl+Alt+H/U/R/K** דרך `install-shortcuts.ps1` (חלופי, אם `hotkeys.ps1` לא רץ)
- **מנוע הזיהוי האוטומטי** (`autoDetect` ב-`fix.js`) עובר על 9 בדיקות לפי סדר עדיפות: URL→HTML→URL encoding→Latin-1 mojibake→UTF-8 mojibake→עברית ויזואלית→מקלדת אנג→מקלדת עב→DOS. כולל heuristic חכם (`looksLikeUsefulHebrewMapping`) שלא ממיר אנגלית לעברית אם התוצאה אינה מילים אמיתיות.

For deeper detail, see:
- `_System/INDEX.md` — קטלוג של מסמכי עזר
- `_System/HISTORY.md` — שחזור של ההיסטוריה של הפרויקט מהמקורות הקיימים

## 4. Conventions & rules

- **לא git repo** — אין כרגע גרסאות מקומיות. הריפו ב-GitHub הוא הקאנון, אבל לא נגוע מאז אפריל. אם המשתמש מבקש לנהל גרסאות — להציע `git init` במפורש.
- **שתי שכבות נפרדות** — אל תשבור את העצמאות בין `hebrew-text-tools.html` ל-`local/`. ה-HTML חייב להישאר בלי תלויות חיצוניות.
- **Encoding תמיד UTF-8 בלי BOM** — `fix.ps1`, `hotkeys.ps1` ו-`fix.js` מתואמים כך. אם משנים את אופן ההעברה (stdin/file), לוודא שעברית לא נשברת.
- **Hotkeys על Ctrl+Alt לא נרשמים** — מתנגש עם AltGr על מקלדת עברית. רק Alt+F# או Ctrl+Alt+אות לטינית.
- **לוגיקת התיקון היא של המשתמש** — `fix.js` הוא פורט ישיר של ה-JavaScript ב-`hebrew-text-tools.html`. שום קוד מ-LangOver או כלים מסחריים אחרים לא נכנס לפה. רק UX inspiration מ-LangOver (סמן→hotkey→החלפה במקום).
- **בקש לפני שינויים גדולים** — הפרויקט בסטטוס שימוש פעיל-אבל-לא-פיתוח-אקטיבי. תיקוני באגים בסדר; refactor או הוספת תלויות דורש אישור.

## 5. 🔄 Agent Protocol — READ THIS FIRST EVERY SESSION

This protocol is identical across all of Tal's projects. Follow without exception.

### A. Session Start
1. Read `CHANGELOG.md` — last 50 lines for recent context.
2. Scan `_System/INDEX.md` — know what reference docs are available.
3. State what you understood in 1-2 sentences before acting.

### B. During Work (CRITICAL — not optional)
After EACH file change, BEFORE moving to the next task — append to `CHANGELOG.md`:

```
## YYYY-MM-DD HH:MM — <agent-name>
- Changed: <one line>
- Why: <one line>
- Files: <path:line>[, <path:line>...]
- Status: done | in-progress | blocked | rejected
```

If you decided NOT to do something — log with `Status: rejected` and the reason.

### C. Reference Docs
If you uncover architecture or non-obvious behavior worth keeping:
- Create/update a doc under `_System/`
- Add a one-liner to `_System/INDEX.md`

### D. Session End (or anytime credits/context might run out)
- Project is not a git repo — skip the commit step until/unless `git init` happens.
- Confirm last CHANGELOG entry exists and reflects what you actually did.

### E. Universal Rules
- Never edit AGENTS.md silently — architecture changes need explicit user approval.
- Never delete CHANGELOG entries — append-only.
- Match the project's language in entries (Hebrew preferred for narrative; English for technical fields).
- One source of truth — don't duplicate info from AGENTS.md elsewhere.

## 6. References

- Recent changes: `CHANGELOG.md`
- Reference docs: `_System/INDEX.md`
- Project history (reconstructed): `_System/HISTORY.md`
- Original web app: `hebrew-text-tools.html`
- Local automation: `local/` (fix.js, hotkeys.ps1, hebrew-text-tools.ahk, fix.ps1, install-shortcuts.ps1, start-hotkeys.bat)
- Operational log: `local/hotkeys.log` (telemetry from hotkeys.ps1)
- Agent-personal context: `~/.claude/projects/C--Dev-Projects-hebrew-text-tools/memory/` (kept as-is; not for project knowledge)
