# Claude Agent Pipeline

A modular agent pipeline for Claude Code that converts plain statements into structured, executed tasks — with token-efficient JSON communication between agents. Just type your request; the pipeline runs automatically via `CLAUDE.md`.

## Agents

| Agent | Model | Role |
|-------|-------|------|
| `router` | Haiku | Classifies input, routes to the correct agent or pipeline entry point |
| `rephraser` | Haiku | Converts plain statements to structured intent JSON. Asks 1 question max. |
| `planner` | Opus | Explores codebase, splits tasks into `now` / `later`, writes `.claude/todo.json` |
| `haiku-executor` | Haiku | Executes low-effort tasks (single file edit, config change) |
| `sonnet-executor` | Sonnet | Executes medium-effort tasks (multi-file changes, new component) |
| `opus-executor` | Opus | Executes high-effort tasks (architecture design, complex algorithm) |
| `task-manager` | Haiku | Marks tasks done, saves session memory, prompts `/clear` |
| `token-tracker` | Haiku | Logs token usage estimates, reports savings vs prose baseline |
| `error-tracker` | Haiku | Logs errors, detects recurring issues, verifies fix before retry |
| `explain` | Haiku | Explains concepts, code, and how things work |
| `lookup` | Haiku | Finds files, paths, versions across the codebase |
| `usage-reporter` | Haiku | Reads real Claude Code usage stats, delivers daily/weekly reports |

## How the Pipeline Works

Every agent outputs a JSON envelope:
- `"status": "ready"` — pass output to next agent
- `"status": "needs_input"` — Claude surfaces one question, pauses, then resumes when answered
- `"status": "done"` — task complete, hand off to task-manager

`CLAUDE.md` orchestrates the full pipeline automatically. You never manually chain agents.

### Effort-based executor routing

The planner tags each task with an `effort` field. The pipeline dispatches automatically:

| Effort | Agent | When used |
|--------|-------|-----------|
| `low` | `haiku-executor` | Single file edit, config tweak, rename |
| `medium` | `sonnet-executor` | Multi-file change, new component, refactor |
| `high` | `opus-executor` | Architecture decisions, complex algorithm, system redesign |

## Concrete Pipeline Example

**User types:** `add dark mode toggle to the settings page`

The pipeline runs automatically (CLAUDE.md triggers it):

```
⚠️  Direct prompt detected. Next time use: @router <your message>
```

**Step 1 — rephraser (haiku)**

```json
{
  "status": "ready",
  "rephrased": "Add a dark mode toggle to the settings page that switches between light/dark themes and persists the user's preference in localStorage.",
  "intent": { "action": "add", "target": "dark mode toggle", "location": "settings page" },
  "context_needed": []
}
```

**Step 2 — planner (opus)**

Explores codebase, writes `.claude/todo.json`, outputs:

```json
{
  "status": "ready",
  "goal": "Add persistent dark mode toggle to settings page",
  "now": [
    { "id": 1, "action": "Add CSS variables for dark theme", "location": "src/index.css", "effort": "low", "done": false },
    { "id": 2, "action": "Create DarkModeToggle component", "location": "src/components/DarkModeToggle.tsx", "effort": "medium", "done": false },
    { "id": 3, "action": "Wire toggle into SettingsPage", "location": "src/pages/SettingsPage.tsx", "effort": "medium", "done": false }
  ],
  "later": [
    { "id": 4, "action": "Add prefers-color-scheme system detection", "reason_deferred": "Nice to have, not blocking core feature" }
  ]
}
```

**Step 3 — per-task execution**

```
[ task 1 → low → haiku-executor ]
[ task 2 → medium → sonnet-executor ]
[ task 3 → medium → sonnet-executor ]
```

Each executor completes its task and returns `status: done` before the next begins.

**Step 4 — task-manager (haiku)**

Marks tasks done, saves session memory to `.claude/session-memory.json`, prompts `/clear`.

No manual chaining. You typed one sentence; the pipeline handled the rest.

## Task Manager + /clear Workflow

The task-manager preserves your context across `/clear` resets. Follow this order every time.

### After verifying a task works

```
@task-manager task <id> done
```

This:
1. Marks the task complete in `.claude/todo.json`
2. Saves full session context to `.claude/session-memory.json`
3. Prompts you to run `/clear`

### Then run /clear

```
/clear
```

Safe to run because context is already saved. Resets the conversation window without losing progress.

### Next session — restore context

```
@task-manager resume
```

Loads `.claude/session-memory.json`, restores goals, completed tasks, and pending work.

> **WARNING:** Running `/clear` before `@task-manager task <id> done` = lost context. Always save first.

## Usage

### Automatic pipeline (recommended)

Just type your request — `CLAUDE.md` runs the full pipeline automatically:

```
add dark mode toggle to the settings page
refactor the auth module to use JWT
fix the flickering on the dashboard chart
```

The pipeline runs: rephraser → planner → haiku/sonnet/opus-executor → task-manager.

> **Note:** If you type without `@router`, you'll see:
> `⚠️  Direct prompt detected. Next time use: @router <your message>`
> The pipeline still runs — this is a reminder, not a blocker.

### Direct agent access

For specific tasks that bypass the pipeline:

```
@router        <your message>           # explicit pipeline entry
@explain       <concept or code>        # explain how something works
@lookup        <file, path, or version> # find things in the codebase
@error-tracker log <error>             # log an error
@error-tracker report                  # show recurring issues
@task-manager  task <id> done          # mark task complete + save memory
@task-manager  resume                  # restore context after /clear
@token-tracker stats                   # show cumulative token savings
@usage-reporter daily                  # today's Claude Code usage
@usage-reporter weekly                 # this week's usage summary
```

## Install

```bash
bash scripts/install.sh
```

Copies all agents to `~/.claude/agents/` so they are available in every project.

## Scheduled Usage Reports

The `usage-reporter` agent reads your real Claude Code token stats (`~/.claude/stats-cache.json`) and delivers daily and weekly reports. Set it up once; it runs automatically.

### Linux / macOS / Windows WSL

```bash
bash scripts/setup-schedule.sh
```

Adds two crontab entries (daily 9am, weekly Monday 9am). Logs to `~/.claude/usage-reports.log`.

> **WSL note:** The cron daemon stops when WSL restarts. Add `sudo service cron start` to your `~/.bashrc` or `~/.zshrc` to auto-start it.

### Windows (without WSL) — PowerShell as Administrator

```powershell
.\scripts\setup-schedule.ps1
```

Uses Windows Task Scheduler. To remove: `.\scripts\setup-schedule.ps1 -Remove`

### Check reports manually anytime

```
@usage-reporter daily
@usage-reporter weekly
@usage-reporter summary
@usage-reporter log limit hit
```

### Why not a remote/cloud scheduler?

The usage stats file (`~/.claude/stats-cache.json`) lives on your local machine. Cloud schedulers cannot access local files, so local scheduling is the right fit here.

## Token Savings

JSON communication between agents saves ~60% tokens vs equivalent markdown prose. The token-tracker runs automatically after each agent step.

```
@token-tracker stats
```

Shows cumulative savings across all sessions.

## Compatibility

| Layer | Portable to other AI vendors? |
|-------|-------------------------------|
| JSON envelope protocol | Yes — pure prompt pattern |
| System prompt instructions | Yes — copy into any LLM |
| `.md` frontmatter + tool names | No — Claude Code specific |

See `agents/` for each agent's system prompt. See `prompts/` for vendor-neutral versions.

## Status

- [x] Router agent — classifies and routes input
- [x] Rephraser agent — plain text to structured JSON
- [x] Planner agent — codebase exploration + task splitting
- [x] Effort-based executor routing (haiku / sonnet / opus)
- [x] Task manager — session memory + /clear workflow
- [x] Token tracker — per-agent logging + stats
- [x] Error tracker — error logging + recurrence detection
- [x] Explain + Lookup agents
- [x] Usage reporter — real stats from stats-cache.json
- [x] CLAUDE.md auto-pipeline (no manual chaining)
- [x] Scheduled usage reports (cron + Windows Task Scheduler)
- [ ] Tested on 10+ real tasks across different project types
- [ ] needs_input flow tested at each pipeline stage
