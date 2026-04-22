# Claude Agent Pipeline

A modular agent pipeline for Claude Code that converts plain statements into structured, executed tasks — with token-efficient JSON communication between agents.

## Agents

| Agent | Model | Role |
|-------|-------|------|
| `rephraser` | Haiku | Converts plain statements to structured intent. Asks 1 question max. |
| `planner` | Opus 4.7 | Explores codebase, splits tasks into `now` / `later`, writes `.claude/todo.json` |
| `executor` | Sonnet 4.6 | Executes the plan step by step |
| `task-manager` | Haiku | Marks tasks done, shows next task, prompts `/clear` |
| `token-tracker` | Haiku | Logs token usage estimates and reports savings vs prose baseline |
| `usage-reporter` | Haiku | Reads real Claude Code usage stats, reports daily/weekly, flags high-usage days |

## Install

```bash
bash scripts/install.sh
```

This copies agents to `~/.claude/agents/` so they are available in all your projects.

## Scheduled Usage Reports

The `usage-reporter` agent reads your real Claude Code token stats (`~/.claude/stats-cache.json`) and delivers daily and weekly reports. Set it up once, it runs automatically.

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
@"usage-reporter" daily
@"usage-reporter" weekly
@"usage-reporter" summary
@"usage-reporter" log limit hit
```

### Why not a remote/cloud scheduler?

The usage stats file (`~/.claude/stats-cache.json`) lives on your local machine. Cloud schedulers cannot access local files, so local scheduling is the right fit here.

## Usage

```
@"rephraser"     <your plain statement>
@"planner"       <rephraser JSON output>
@"executor"      <single task from planner now[] array>
@"task-manager"  task <id> done
@"token-tracker" agent: <name> output: <JSON output to measure>
@"token-tracker" stats
```

After each verified task, run `/clear` to reset context before the next task.

## How it works

Every agent outputs a JSON envelope:
- `"status": "ready"` — pass output to next agent
- `"status": "needs_input"` — Claude pauses and asks you one question, then continues

This pattern works across all agents, not just at the start.

## Token savings

JSON communication between agents saves ~60% tokens vs equivalent markdown prose.
Use `@"token-tracker" stats` to see your cumulative savings.

## Compatibility

| Layer | Portable to other AI vendors? |
|-------|-------------------------------|
| JSON envelope protocol | ✅ Yes — pure prompt pattern |
| System prompt instructions | ✅ Yes — copy into any LLM |
| `.md` frontmatter + tool names | ❌ No — Claude Code specific |

See `prompts/` for vendor-neutral versions of each agent's system prompt.

## Status

- [ ] Tested on 5+ real tasks
- [ ] needs_input flow tested at each stage
- [ ] Token tracker validated
- [ ] Ready for public use
