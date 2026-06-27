# LOGS (Execution Log)

This file records execution history of the project.

---

## Log Entry Format
Each entry MUST follow this structure:

- timestamp:
- actor: (GPT / Codex / Human)
- action:
- result:
- notes:

---

## Rules

- Only record facts of executed actions
- Do NOT store future plans
- Do NOT store project state (STATE owns state)
- Do NOT store tasks (TASKS owns tasks)
- Must be append-only in real usage

---

## Purpose

Provide traceability of what actually happened during execution.

---

## Constraint

This file is a passive log system and does not influence execution logic.