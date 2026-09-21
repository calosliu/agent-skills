---
name: implement-spec
description: Implements a saved specification and keeps its progress checklist current. Use when the user asks to implement a spec, continue a plan, or update implementation progress.
---

# Implement a spec

1. Read the requested spec completely. If no path is given, inspect `.spec/`; use the only active spec or ask which one when ambiguous.
2. Turn scope and acceptance criteria into a short checklist. Read applicable project instructions and trace the relevant code before editing.
3. Implement the smallest complete slice. Preserve unrelated changes and existing configuration; stop before destructive operations or unresolved conflicts.
4. Run targeted checks plus a direct behavioral probe. Record commands and actual results; a build alone is not proof that a feature works.
5. Update the spec's status, checkboxes, evidence log, and blockers. Check an item only after verification. Mark unavailable environments or credentials as blocked, not passed.
6. Report changed paths, checks run, and remaining work. Do not commit or push unless requested.

Example: “Implement `.spec/2026-09-20_01_personal-agent-repo.md` and track progress.”

Prerequisites: repository read/write access and the project's documented check commands. Use the current agent's native file and command tools; no specific harness or plugin is required.
