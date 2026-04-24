# Claude Agent Pipeline — Orchestration Rules

For EVERY user input, run the pipeline below. Do not respond conversationally. Do not skip steps.

## How to Spawn Agents (Agent Tool Protocol)

"Spawn @agentname" means — DO THIS EVERY TIME, no exceptions:
1. Read `~/.claude/agents/<agentname>.md` to get its instructions
2. Call the Agent tool:
   - `subagent_type`: always `"general-purpose"`
   - `model`: map from the .md frontmatter — `claude-haiku-4-5-20251001` → `"haiku"`, `claude-sonnet-4-6` → `"sonnet"`, `claude-opus-4-7` → `"opus"`
   - `description`: `"<agentname> agent"`
   - `prompt`: full contents of the .md file (everything after the frontmatter `---`) + `\n\n---\nINPUT:\n` + the input JSON string
3. Parse JSON from the agent's response text (extract the first ```json ... ``` block or bare JSON object)

Never respond inline for pipeline steps. Always use the Agent tool.

## Direct Prompt Detection

If user input does NOT start with `@` AND is not a short reply (yes/no/single word) AND is not a needs_input response:
- Print FIRST: `⚠️  Direct prompt detected. Next time use: @router <your message>`
- Then still run the pipeline — do not block.

## @router Entry Point

When input starts with `@router <message>`, classify inline using this table — NO agent spawn for routing:

| Keywords in message | Route |
|---|---|
| run, execute, start, restart, stop, open, show, list, print, display, check if, verify, status, git, commit, push, pull, node, python, npm, bash | direct |
| add, build, fix, create, implement, set up, refactor, update, write, migrate | rephraser |
| where is, which file, what path, what version, find | lookup |
| what is, how does, explain, difference between, why, tell me | explain |
| done, completed, verified, task N done | task-manager |
| resume, catch me up, new session | task-manager |
| usage, tokens used, daily, weekly, limit | usage-reporter |
| error, failing, recurring issue, verify error | error-tracker |

Then branch:
- `direct`         → execute inline immediately, no agents spawned, STOP
- `rephraser`      → start full pipeline at Step 1
- `explain`        → **INLINE CHECK FIRST**: Can this be answered in 1-3 sentences from general knowledge, no file reads? YES → answer inline, STOP. NO → spawn @explain (haiku), STOP
- `lookup`         → **INLINE CHECK FIRST**: Is the answer already in conversation context? YES → answer inline, STOP. NO → spawn @lookup (haiku), STOP
- `task-manager`   → handle inline (read session-memory.json), STOP
- `usage-reporter` → spawn @usage-reporter (haiku), STOP
- `error-tracker`  → spawn @error-tracker (haiku), STOP

Only spawn @router agent if input is genuinely ambiguous (matches multiple routes or no route).

## Pipeline

### Step 1 — Caveman + Rephraser `[ haiku ]`
a. Spawn @caveman (model: haiku) with raw user input to compress it to terse form.
b. Spawn @rephraser (model: haiku) with caveman output.
- `status: needs_input` → surface the question clearly, STOP. Resume rephraser when user answers.
- `status: ready` → assess complexity inline (see Step 1c), then go to Step 2 or fast-path.

c. **Complexity triage** (inline, no agent):
   - **SIMPLE** = effort is clearly `low` AND single file/function AND no mentioned errors/crashes → skip Steps 2 & 3b, go directly to Step 3c with effort=low
   - **COMPLEX** = multi-file, architecture change, new feature, or effort=high → run full pipeline (Steps 2 → 3)
   - **DEFAULT** = anything else → run full pipeline

### Step 2 — Planner `[ opus ]`
Skip if triage = SIMPLE.

Spawn @planner (model: opus) with the rephraser JSON output.
- `status: needs_input` → surface the question clearly, STOP. Resume planner when user answers.
- `status: ready` → go to Step 3.

### Step 3 — Per-task execution
For EACH task in planner's `now` array (or the single SIMPLE task), in order:

a. Print: `[ task <id> → <effort> → <model> ]`

b. **Error-tracker check** — ONLY run if task mentions error/bug/failing/crash/broken OR error-log.json exists with relevant entries. Otherwise skip.
   If run: Spawn @error-tracker (model: haiku) with `check <task_action>`.
   - `all_clear: true` → proceed to (c)
   - `all_clear: false` AND recurring error → spawn @error-tracker `verify <ids>` → if still_present → surface, STOP
   - `all_clear: false` but no recurring → print warning, proceed

c. Dispatch by effort:
   - `effort: low`    → spawn @haiku-executor  (model: haiku)  with `{ task, context }`
   - `effort: medium` → spawn @sonnet-executor (model: sonnet) with `{ task, context }`
   - `effort: high`   → spawn @opus-executor   (model: opus)   with `{ task, context }`

d. After executor returns `status: done` → spawn @caveman (model: haiku) with executor's plain-text output. Print caveman's compressed output to user instead of raw executor output.

e. `status: needs_input` → surface question as-is (no caveman), STOP. User must confirm before resuming.

e. Continue to next task only after current returns `status: done`

### Step 4 — Task Manager
**Only run when user explicitly requests it** (`@task-manager task <id> done`).
Do NOT auto-spawn after executor completes.

## Token-Tracker
**Removed from mandatory pipeline.** Only spawn @token-tracker when user explicitly asks for token usage stats.

## Direct Agent Exceptions (no pipeline)
@router, @explain, @lookup, @usage-reporter, @error-tracker, @task-manager, @token-tracker, @caveman
These are invoked directly — still use the Agent tool with correct model, but skip the full pipeline chain.

## END-OF-TASK RULE
After an executor returns `status: done`, print:
```
---
✅ Task complete.
Next: @task-manager task <id> done   ← saves memory to .claude/session-memory.json
Then: /clear                          ← safe to reset context once memory is saved
New session: @task-manager resume     ← restores goals, tasks, and decisions
---
```
Does NOT fire for: @router, @explain, @lookup, @usage-reporter, @error-tracker, @task-manager, @token-tracker.

## Rules
- On needs_input: show the question clearly, wait for user reply, resume the SAME step
- Skip rephraser only if input is already structured JSON from a previous pipeline step
- NEVER skip the Agent tool call — inline responses are forbidden for pipeline steps
- Caveman always runs before rephraser — never bypass it
