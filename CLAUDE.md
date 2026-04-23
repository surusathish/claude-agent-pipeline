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
   b. Run @"error-tracker" check with the task action.
      - If `all_clear: true` → proceed to step c.
      - If `all_clear: false` AND any error has `recurring: true` → run @"error-tracker" verify <id1> <id2> ... (all recurring ids at once).
        - If any `still_present: true` → surface the error recommendation. STOP. User must confirm fix before resuming.
        - If all resolved → proceed to step c.
      - If `all_clear: false` but no recurring errors → print warnings, proceed to step c.
   c. Dispatch based on effort field:
      - `effort: low`    → spawn @haiku-executor  with `{ task, context }`
      - `effort: medium` → spawn @sonnet-executor with `{ task, context }`
      - `effort: high`   → spawn @opus-executor   with `{ task, context }`
   d. After completion → call @token-tracker: `<agent-name> <output>`
   e. `needs_input` → surface question, STOP. User must confirm before resuming same sub-executor.
   f. Continue to next task only after current task returns `status: done`

4. **Task manager**
   → spawn @task-manager with the completed task ids
   - After completion → call @token-tracker: `task-manager <output>`

## Rules
- On needs_input: show the question clearly, wait for user reply, resume the SAME step
- Skip rephraser only if user input is already structured JSON from a previous step
- Direct agent exceptions (invoke without pipeline, no token-tracker): @router, @explain, @lookup, @usage-reporter, @error-tracker, @task-manager, @token-tracker
- **END-OF-TASK RULE:** After @task-manager completes, OR after a sub-executor (@haiku-executor, @sonnet-executor, @opus-executor) is called directly outside the pipeline and returns `status: done`, immediately print:
  ```
  ---
  ✅ Task complete.
  Next: @task-manager task <id> done   ← saves memory to .claude/session-memory.json
  Then: /clear                          ← safe to reset context once memory is saved
  New session: @task-manager resume     ← restores goals, tasks, and decisions
  ---
  ```
  Does NOT fire for @router, @explain, @lookup, @usage-reporter, @error-tracker, @task-manager, @token-tracker.
