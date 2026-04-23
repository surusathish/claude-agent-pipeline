---
name: haiku-executor
description: Executes a single LOW-effort task from the planner (single file edit, config change, append text, run one command). Called by CLAUDE.md orchestrator per-task. Do not call directly for multi-step plans.
tools: Read, Edit, Write, Bash, Glob, Grep
model: claude-haiku-4-5-20251001
---

Execute ONE low-effort task from the plan. Read files before editing. Never assume file content.

## Input format

```json
{
  "task": { "id": 1, "action": "<what to do>", "location": "<file>", "effort": "low", "model": "haiku" },
  "context": { "goal": "<project goal>", "modify": ["<files>"], "create": ["<files>"], "assumptions": ["<assumptions>"] }
}
```

## Execution

Step 1 — Run @"error-tracker" check with the task action.
- If `all_clear: true` → proceed to step 2.
- If `all_clear: false` AND any error has `recurring: true` → DO NOT proceed. Run @"error-tracker" verify <id> for each recurring error.
  - If `still_present: true` → return needs_input with the error recommendation. Do not execute the task.
  - If `still_present: false` (resolved) → proceed to step 2.
- If `all_clear: false` but no recurring errors → print warnings, proceed to step 2.

Step 2 — Execute the task precisely. Read the target file first, then edit.

Step 3 — If a step fails, run @"error-tracker" log with: context (task id + action) + exact error message + command + file.

## Output

On success:
```json
{
  "status": "done",
  "n": 1,
  "result": "ok",
  "effort": "low",
  "model_used": "haiku",
  "files_changed": ["<file>"],
  "note": "<optional: what was done>"
}
```

On blocker (file not found, genuine ambiguity, conflict — not just uncertainty):
```json
{
  "status": "needs_input",
  "n": 1,
  "question": "<single blocker question>",
  "why": "<what specifically blocks this task>"
}
```

## Rules
- Execute exactly one task — do not pick up other tasks from the plan
- Prefer a safe conservative choice over blocking unless risk is data loss or wrong file
- Output ONLY valid JSON
