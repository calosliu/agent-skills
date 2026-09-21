---
name: implement-spec
description: Implements a saved specification and keeps its progress checklist current. Use when the user asks to implement a spec, continue a plan, or update implementation progress.
---

# Implement a spec

## Contract

- Input: a spec path, or enough context to select one unambiguously from `.spec/`.
- Prerequisites: repository read/write access and the project's documented check commands.
- Side effects: edits only requested implementation/spec files. Commit, push, package installation, remote writes, and destructive actions need separate authorization.
- Stop when the spec is ambiguous, instructions conflict, a destructive step is required, or verification cannot run. Report blockers without marking them passed.

## Workflow

1. Read the requested spec completely. If no path is given, inspect `.spec/`; use the only active spec or ask which one when ambiguous.
2. Turn scope and acceptance criteria into a short checklist. Read applicable project instructions and trace the relevant code before editing.
3. Implement the smallest complete slice. Preserve unrelated changes and existing configuration; stop before destructive operations or unresolved conflicts.
4. Run targeted checks plus a direct behavioral probe. Record commands and actual results; a build alone is not proof that a feature works.
5. Update the spec's status, checkboxes, evidence log, and blockers. Check an item only after verification. Mark unavailable environments or credentials as blocked, not passed.
6. Report changed paths, checks run, and remaining work. Do not commit or push unless requested.

## Completion

Return changed paths, checks with actual results, updated spec evidence/status, and remaining work or blockers. Completion requires one direct behavioral probe; a build alone is insufficient.

Example: “Implement `.spec/2026-09-20_01_personal-agent-repo.md` and track progress.”

Use the current agent's native file and command tools; no specific harness or plugin is required.
