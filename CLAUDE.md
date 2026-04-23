# Claude Agent Pipeline — Orchestration Rules

For EVERY user input, run the pipeline below. Do not respond conversationally. Do not skip steps.

## How to Spawn Agents (Agent Tool Protocol)

"Spawn @agentname" means — DO THIS EVERY TIME, no exceptions:
1. Read `/home/sathishkumar_b_s/.claude/agents/<agentname>.md` to get its instructions
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

When input starts with `@router <message>`:
1. Spawn @router (model: haiku) with `<message>` as input
2. Parse routing JSON → get `route`, `effort`, `model`, `input`
3. Branch:
   - `route: direct`    → execute the command/action inline immediately, no agents spawned, STOP
   - `route: rephraser` → start full pipeline at Step 1 with `input` as raw input
   - `route: explain`   → spawn @explain (haiku), print result, STOP
   - `route: lookup`    → spawn @lookup (haiku), print result, STOP
   - `route: task-manager` → handle as @task-manager call, STOP
   - `route: usage-reporter` → spawn @usage-reporter (haiku), print result, STOP
   - `route: error-tracker` → spawn @error-tracker (haiku), print result, STOP

## Pipeline

### Step 1 — Rephraser `[ haiku ]`
Spawn @rephraser (model: haiku) with raw user input.
- `status: needs_input` → surface the question clearly, STOP. Resume rephraser when user answers.
- `status: ready` → spawn @token-tracker (model: haiku) with `rephraser <rephraser_output_json>`, then go to Step 2.

### Step 2 — Planner `[ opus ]`
Spawn @planner (model: opus) with the rephraser JSON output.
- `status: needs_input` → surface the question clearly, STOP. Resume planner when user answers.
- `status: ready` → spawn @token-tracker (model: haiku) with `planner <planner_output_json>`, then go to Step 3.

### Step 3 — Per-task execution
For EACH task in planner's `now` array, in order:

a. Print: `[ task <id> → <effort> → <model> ]`

b. Spawn @error-tracker (model: haiku) with `check <task_action>`.
   - `all_clear: true` → proceed to (c)
   - `all_clear: false` AND any error has `recurring: true`:
     → Spawn @error-tracker with `verify <id1> <id2> ...` (all recurring ids at once)
     → If any `still_present: true` → surface recommendation, STOP. User must confirm before continuing.
     → If all resolved → proceed to (c)
   - `all_clear: false` but no recurring → print warnings, proceed to (c)

c. Dispatch by effort:
   - `effort: low`    → spawn @haiku-executor  (model: haiku)  with `{ task, context }`
   - `effort: medium` → spawn @sonnet-executor (model: sonnet) with `{ task, context }`
   - `effort: high`   → spawn @opus-executor   (model: opus)   with `{ task, context }`

d. After executor returns → spawn @token-tracker (model: haiku) with `<executor-name> <output>`

e. `status: needs_input` → surface question, STOP. User must confirm before resuming same executor.

f. Continue to next task only after current task returns `status: done`

### Step 4 — Task Manager
Spawn @task-manager (model: haiku) with completed task ids.
After completion → spawn @token-tracker (model: haiku) with `task-manager <output>`

## Direct Agent Exceptions (no pipeline, no token-tracker)
@router, @explain, @lookup, @usage-reporter, @error-tracker, @task-manager, @token-tracker
These are invoked directly — still use the Agent tool with correct model, but skip the rephraser/planner/executor chain.

## END-OF-TASK RULE
After @task-manager completes OR after an executor returns `status: done` (when called directly outside pipeline), print:
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
