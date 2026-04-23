# Claude Agent Pipeline — Orchestration Rules

For EVERY user input in this project, run the pipeline below automatically.
Do not respond conversationally. Do not skip steps.

## Direct Prompt Detection

If user input does NOT start with `@` AND is not a short reply (yes/no/single word) AND is not a needs_input response:
- Print FIRST before doing anything else:
  `⚠️  Direct prompt detected. Next time use: @router <your message>`
- Then still run the pipeline below — do not block.

## Pipeline

1. **Rephraser** `[ rephraser → haiku ]`
   → spawn @rephraser with the user's raw input
   - `needs_input` → surface question, STOP. Resume rephraser when answered.
   - `ready` → call @token-tracker: `rephraser <output>`, then proceed to step 2

2. **Planner** `[ planner → opus ]`
   → spawn @planner with the rephraser JSON output
   - `needs_input` → surface question, STOP. Resume planner when answered.
   - `ready` → call @token-tracker: `planner <output>`, then proceed to step 3

3. **Per-task execution** (replaces single @executor call)
   For EACH task in planner's `now` array, in order:
   a. Print header: `[ task <id> → <effort> → <model> ]`
   b. Dispatch based on effort field:
      - `effort: low`    → spawn @haiku-executor  with `{ task, context }`
      - `effort: medium` → spawn @sonnet-executor with `{ task, context }`
      - `effort: high`   → spawn @opus-executor   with `{ task, context }`
   c. After completion → call @token-tracker: `<agent-name> <output>`
   d. `needs_input` → surface question + error recommendation if error-related, STOP. User must confirm fix before resuming same sub-executor.
   e. Continue to next task only after current task returns `status: done`

4. **Task manager**
   → spawn @task-manager with the completed task ids
   - After completion → call @token-tracker: `task-manager <output>`

5. **End-of-task reminder** — ALWAYS print this after all tasks are done, whether or not task-manager was spawned:
   ```
   ---
   ✅ All tasks complete.
   Run: @task-manager task <id> done   ← saves session memory
   Then: /clear                         ← safe to reset context
   Next session: @task-manager resume   ← restores where you left off
   ---
   ```

## Rules
- On needs_input: show the question clearly, wait for user reply, resume the SAME step
- Skip rephraser only if user input is already structured JSON from a previous step
- Direct agent exceptions (invoke without pipeline, no token-tracker): @router, @explain, @lookup, @usage-reporter, @error-tracker, @task-manager, @token-tracker
