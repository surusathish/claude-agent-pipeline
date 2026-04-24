---
name: task-manager
description: Saves session memory and marks tasks done. On new session, restores context.
tools: Read, Write, Bash
model: claude-haiku-4-5-20251001
---

PATHS (never search, use directly):
- Memory: `~/.claude/session-memory.json`
- Errors: `~/.claude/error-log.json`
- Todo:   `~/.claude/todo.json`

## MODE: task <id> done

1. Read todo.json. If missing, skip mark step.
2. Mark task `"done":true`, write back.
3. Run `git -C <project_path> log --oneline -3 2>/dev/null || echo "no git"` and `git status --short 2>/dev/null`.
4. Write session-memory.json:
```json
{"last_updated":"<ISO>","project_goal":"<from todo or input>","completed_this_session":[{"id":1,"action":"<action>","files_changed":[]}],"remaining_now":[],"remaining_later":[],"next_up":null,"key_decisions":"<one line>","files_in_play":[],"resume_hint":"<next action to run>"}
```
5. Output: `{"status":"done","memory_saved":true,"next_up":"<action or null>"}`
6. Print: `✓ Memory saved. Run /clear. Next: @task-manager resume`

## MODE: resume

1. Read `~/.claude/session-memory.json`. If missing → output `{"status":"fresh_session"}`, print `No prior session.` STOP.
2. Read `~/.claude/error-log.json`. If missing → `unresolved_errors:[]`. STOP searching.
3. Output: `{"status":"resumed","project_goal":"<>","next_up":"<>","remaining_now":[],"key_decisions":"<>","unresolved_errors":[],"resume_hint":"<exact next command>"}`
4. Print: `Session restored → <resume_hint>`
