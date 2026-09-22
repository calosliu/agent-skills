# Repository working rules

- This repository contains personal agent dotfiles, not an agent runtime.
- Read the active plan in `.spec/` before implementation; update its checklist and evidence after verified changes.
- `instructions/*.md` are independent shared personal rules. This root file governs maintenance of this repository only.
- Keep owned skills portable under `skills/<name>/SKILL.md`. Use matching lowercase directory/name values and unquoted, single-line `name` and `description` frontmatter fields. Add resources only when needed.
- Keep agent-specific configuration under `agents/`; examples must contain no credentials, machine paths, or trust overrides.
- Do not vendor third-party installed skills or packages. Record sources and exact known versions instead.
- Installation has one default flow: preserve/create regular native instruction files (`AGENTS.md` for Pi/Codex, `CLAUDE.md` for Claude), update only their unique `agent-skills:begin/end` blocks, and link `instructions/*.md` beside them. Never overwrite conflicting links or text outside the block; back up changed existing files and replace atomically.
- Keep rule files self-contained. Generated Pi/Codex absolute references are explicit read instructions; generated Claude `@` imports use its verified native mechanism.
- Test using an isolated temporary `HOME`; do not change live agent homes to make a test pass.
- Shell scripts support Bash 3.2+ on macOS/Linux. No new dependencies for installation or offline checks.
- After changing scripts or skills, run `bash scripts/check.sh`. Agent discovery requires separate live smoke tests documented in `README.md`.
- Do not commit, push, or change remote visibility without an explicit request.
