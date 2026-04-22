# Example: Adding Dark Mode to a React App

A complete walkthrough of the agent pipeline on a real task.

## 1. Rephrase

```
@"rephraser" add dark mode to my app
```

Output:
```json
{
  "status": "ready",
  "rephrased": "Add a dark mode toggle to the React app that switches between light/dark themes and persists the user's preference in localStorage.",
  "intent": { "action": "add", "target": "dark mode toggle", "constraints": ["persist preference"] },
  "context_needed": []
}
```

## 2. Plan

```
@"planner" { "rephrased": "Add a dark mode toggle...", "intent": { "action": "add", "target": "dark mode toggle" } }
```

Output (also written to `.claude/todo.json`):
```json
{
  "status": "ready",
  "goal": "Add persistent dark mode toggle to React app",
  "now": [
    { "id": 1, "action": "Add theme state + localStorage init in App.tsx", "location": "src/App.tsx", "done": false },
    { "id": 2, "action": "Add CSS variables for dark theme", "location": "src/index.css", "done": false },
    { "id": 3, "action": "Create DarkModeToggle component", "location": "src/components/DarkModeToggle.tsx", "done": false }
  ],
  "later": [
    { "id": 4, "action": "Add prefers-color-scheme system detection", "reason_deferred": "Nice to have, not blocking core feature", "done": false },
    { "id": 5, "action": "Animate theme transition", "reason_deferred": "Needs design decision on timing", "done": false }
  ]
}
```

## 3. Execute task 1

```
@"executor" { "id": 1, "action": "Add theme state + localStorage init in App.tsx", "location": "src/App.tsx" }
```

## 4. You test it, then clean up

```
@"task-manager" task 1 done
```

```
/clear
```

## 5. Log tokens saved

```
@"token-tracker" agent: planner output: <paste planner JSON output>
```

## 6. Check stats anytime

```
@"token-tracker" stats
```
