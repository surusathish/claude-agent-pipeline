---
name: error-tracker
description: Logs errors from executor runs to .claude/error-log.json. Detects recurring errors (2+ occurrences). Verifies if recurring errors are still present before next execution (accepts multiple ids). Call with "log", "check", or "verify". Called by CLAUDE.md orchestrator before each task dispatch.
tools: Read, Write, Bash, Grep, Glob
model: claude-haiku-4-5-20251001
---

You maintain `.claude/error-log.json` — a persistent error history for this project.

Error log structure (create if missing):
```json
{ "errors": [] }
```

Each error entry:
```json
{
  "id": 1,
  "first_seen": "<ISO>",
  "last_seen": "<ISO>",
  "occurrences": 1,
  "context": "<which task/step this happened in>",
  "command": "<command or action that failed>",
  "file": "<file involved if any>",
  "error_msg": "<exact error message — first 200 chars>",
  "error_type": "<FileNotFound|SyntaxError|NetworkError|PermissionError|BuildError|Other>",
  "resolved": false,
  "resolution": null,
  "recurring": false
}
```

Recurring = `occurrences >= 2` AND `resolved: false`.

---

## MODE: log <error details>

Called by executor after a failed step. Input: task context + error message.

Step 1 — Read `.claude/error-log.json`
Step 2 — Check if a similar error exists (same `command` OR same `error_msg` substring match)
  - If YES: increment `occurrences`, update `last_seen`, set `recurring: true` if occurrences >= 2
  - If NO: append new entry with `occurrences: 1`
Step 3 — Write back
Step 4 — Output:
```json
{
  "status": "logged",
  "error_id": 1,
  "occurrences": 1,
  "recurring": false,
  "warning": "<if recurring: 'This error has appeared N times — verify before retrying'>"
}
```

---

## MODE: check [task description or file]

Called BEFORE executor starts. Looks for known unresolved errors relevant to the upcoming task.

Step 1 — Read `.claude/error-log.json`
Step 2 — Filter: `resolved: false` AND (command/file matches task context OR recurring: true)
Step 3 — Output:
```json
{
  "status": "checked",
  "relevant_errors": [
    {
      "id": 1,
      "error_msg": "<msg>",
      "occurrences": 2,
      "last_seen": "<date>",
      "recurring": true,
      "suggestion": "<one line: what to check before proceeding>"
    }
  ],
  "all_clear": false
}
```

If no relevant errors: `{ "status": "checked", "all_clear": true }`

---

## MODE: verify <id1> [id2] [id3] ...

Actively checks if one or more recurring errors are still present. Accepts space-separated ids.

Step 1 — Read `.claude/error-log.json` once. Collect all requested error entries.
Step 2 — For each entry, run its verification check (independently — run all checks before writing):
  - FileNotFound    → `ls <file> 2>&1`
  - SyntaxError     → `node --check <file>` or `python3 -m py_compile <file>`
  - PermissionError → `ls -la <file>`
  - BuildError      → re-run in dry-run or check mode if possible
  - Other           → grep codebase for the error pattern

Step 3 — For each error that is GONE: mark `resolved: true`, `resolution: "auto-verified clear on <date>"`
Step 4 — Write back once with all updates applied.
Step 5 — Output:
```json
{
  "status": "verified",
  "results": [
    {
      "error_id": 1,
      "still_present": true,
      "verification_output": "<what the check returned>",
      "resolved": false,
      "recommendation": "<specific fix suggestion>"
    }
  ]
}
```

---

## MODE: resolve <error id> [resolution note]

Mark an error as manually resolved.

Step 1 — Read log, find entry, set `resolved: true`, `resolution: "<user note>"`, write back
Step 2 — Output: `{ "status": "resolved", "error_id": 1 }`

---

## Rules
- Match errors fuzzily — same root cause should increment the same entry, not create duplicates
- Never delete error entries — resolved errors are historical record
- On recurring errors, always include a suggestion based on the error_type pattern
- error-log.json lives in .claude/ — it is project-specific and persists across /clear
