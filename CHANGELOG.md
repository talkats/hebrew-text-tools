# CHANGELOG — Hebrew Text Tools

> Append-only journal. Every meaningful change gets an entry.
> Format: see AGENTS.md § 5.B
> Never delete entries. Correct mistakes with a NEW entry.

---

## 2026-05-10 — Claude Code (autostart setup)
- Changed: added `setup-autostart.ps1` — יוצר קיצור דרך ב-Startup folder (auto-start בכל login) וקיצור על שולחן העבודה (הפעלה ידנית)
- Why: אחרי ריסטארט של המחשב hotkeys.ps1 לא רץ; המשתמש צריך דרך קלה להפעיל מחדש
- Files: local/setup-autostart.ps1 (new), Startup folder shortcut, Desktop shortcut
- Status: done

---

## 2026-05-06 16:45 — init-agents (BROWNFIELD retrofit)
- Changed: bootstrapped AGENTS.md protocol on existing project
- Why: vendor-neutral persistence across agents (Claude Code ↔ Codex ↔ future); ping-pong workflow already in evidence (hotkeys.ps1 was added by another session — `originSessionId` exists in auto-memory frontmatter)
- Files: AGENTS.md (new), CLAUDE.md (new — `@AGENTS.md`), CHANGELOG.md (this), _System/INDEX.md (new), _System/HISTORY.md (new — reconstructed from sources)
- Sources ingested: hebrew-text-tools.html (architecture), local/fix.js (engine logic), local/hotkeys.ps1 (active hotkey listener), local/fix.ps1, local/hebrew-text-tools.ahk, local/install-shortcuts.ps1, local/start-hotkeys.bat, local/hotkeys.log (operational), ~/.claude/projects/C--Dev-Projects-hebrew-text-tools/memory/{MEMORY.md,project_overview.md}
- Status: done
- Notes: project is not a git repo, so no commit step. Auto-memory at ~/.claude/projects/.../memory/ kept as-is (agent-personal context, not project knowledge). Original hebrew-text-tools.html and all local/ files left untouched.

---

## 2026-05-06 12:00 — Tal (live testing)
- Changed: confirmed Alt+F5 working end-to-end after hotkeys.ps1 was started; auto-detect handles all 9 categories (UTM cleanup, HTML/URL decode, Latin-1/UTF-8 mojibake, visual Hebrew, keyboard layout both directions, DOS encoding)
- Why: post-build smoke test
- Files: local/hotkeys.log:6-40 (telemetry — multiple "Hotkey invoked: auto" / "Pasting result" lines)
- Status: done
- Notes: telemetry shows ~15 invocations across 2026-05-05 → 2026-05-06 with various input lengths (4 → 227 chars).

---

## 2026-05-05 17:58 — codex/other-agent (persistent hotkey listener added)
- Changed: created hotkeys.ps1 — a persistent .NET WinForms process that registers Alt+F5/F6/F7/F8 via Win32 RegisterHotKey, with NotifyIcon for tray presence; also added start-hotkeys.bat launcher
- Why: provide Alt+F5 hotkey (matching what Tal originally requested) without requiring AutoHotkey installation; Windows .lnk shortcuts can't bind F-keys, only Ctrl+Alt+letter
- Files: local/hotkeys.ps1 (new), local/start-hotkeys.bat (new), local/fix.js (refined autoDetect with COMMON_MAPPED_HEBREW_WORDS heuristic), local/fix.ps1 (refactored to use temp files instead of stdin/stdout)
- Status: done
- Notes: reconstructed from file timestamps and content inspection during retrofit. This entry is retroactive.

---

## 2026-05-05 09:47 — Claude Code (initial local automation build)
- Changed: built local/ subtree — Node engine (fix.js), AHK script (hebrew-text-tools.ahk), PowerShell script (fix.ps1), shortcut installer (install-shortcuts.ps1)
- Why: convert the HTML web tool into a global hotkey-driven utility (LangOver-style UX) so Tal doesn't need to switch to the browser to fix gibberish in any app
- Files: local/fix.js (new), local/hebrew-text-tools.ahk (new), local/fix.ps1 (new), local/install-shortcuts.ps1 (new)
- Status: done
- Notes: ported all autoDetect + transform logic from hebrew-text-tools.html (lines 290-538) to Node CommonJS. AHK was the original recommendation but Tal had PowerToys (no AHK), so PowerShell path was added in parallel.

---

## ~2026-04-15 — Tal + Claude Code (greenfield)
- Changed: built hebrew-text-tools.html — single-file web app with 4 tabs (text fix, URL clean, special symbols, styled Unicode text)
- Why: utility for personal use across multiple text-related needs (gibberish, tracking links, formatting)
- Files: hebrew-text-tools.html (1003 lines)
- Status: done — pushed to GitHub, then dormant
- Notes: reconstructed from file mtime (2026-04-15 15:42) and auto-memory project_overview.md. This entry is retroactive.
