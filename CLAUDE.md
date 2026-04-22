# Claude Agent Pipeline — Orchestration Rules

For EVERY user input in this project, run the pipeline below automatically.
Do not respond conversationally. Do not skip steps.

## Pipeline

1. **Rephraser** → spawn @rephraser with the user's raw input
   - If `status: needs_input` → surface the question to the user and STOP. Resume from rephraser when answered.
   - If `status: ready` → proceed to step 2

2. **Planner** → spawn @planner with the rephraser JSON output
   - If `status: needs_input` → surface the question to the user and STOP. Resume from planner when answered.
   - If `status: ready` → proceed to step 3

3. **Executor** → spawn @executor with the planner JSON output
   - If `status: needs_input` → surface the question and STOP. Resume executor from the completed step.
   - If `status: done` → spawn @task-manager with the completed task id

## Rules
- Always show which step is running: `[ rephraser → haiku ]`, `[ planner → opus ]`, `[ executor → sonnet ]`
- On needs_input: show the question clearly, wait for user reply, then resume the SAME step (do not restart from rephraser)
- Skip rephraser only if user input is already structured JSON from a previous step
- The only exception: if user explicitly types @router, @explain, @lookup, @usage-reporter or @error-tracker — invoke that agent directly without the pipeline
