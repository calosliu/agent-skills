# Agent support matrix

“Supported” here means this repository's personal instructions and owned skills were installed and observed in a real model session. It does not claim every model, plugin, MCP server, or machine configuration works.

| Agent | Tested version / model | Personal instruction entry | Owned skill entry | Config example | Last smoke | Status |
| --- | --- | --- | --- | --- | --- | --- |
| Pi | 0.86.1 / `openai-codex/gpt-5.5` | `~/.pi/agent/AGENTS.md` managed references | `~/.agents/skills/<name>/SKILL.md` | [`pi/settings.example.json`](pi/settings.example.json) | 2026-09-22 | supported |
| Codex | 0.153.4 / configured default | `~/.codex/AGENTS.md` managed references | `~/.agents/skills/<name>/SKILL.md` | [`codex/config.example.toml`](codex/config.example.toml) | 2026-09-22 | supported |
| Claude Code | 2.1.236 / `deepseek-v4-pro[1m]` | `~/.claude/CLAUDE.md` managed native `@` imports | `~/.claude/skills/<name>/SKILL.md` | None; installer does not change settings, smoke used `--permission-mode plan --tools ''` | 2026-09-22 | supported |

## Instruction precedence and reload

All three agents load personal guidance plus project guidance. In the verified conflict fixture, a project rule explicitly narrowed the personal “match the user's language” default; Pi, Codex, and Claude each returned the project-only token. System, user authorization, sandbox, and [`../docs/security-model.md`](../docs/security-model.md) boundaries still cannot be widened by project content.

- **Pi:** personal entry is its agent-home `AGENTS.md`; project `AGENTS.md` applies in the active project. Start a fresh session after changing instructions. The generated personal references require observable file reads, so support is model-specific: `gpt-5.5` passed; `gpt-5.3-codex-spark` did not perform the required reads.
- **Codex:** personal entry is `~/.codex/AGENTS.md`; project instruction discovery follows the AGENTS hierarchy, with closer project guidance taking precedence when scopes conflict. `AGENTS.override.md` may supersede an `AGENTS.md`. Start a fresh session after changes.
- **Claude Code:** direct `AGENTS.md` loading failed the 2.1.236 no-tool probe while `CLAUDE.md` control passed. The installer therefore creates/preserves `~/.claude/CLAUDE.md` and adds native absolute `@` imports. Project and nested `CLAUDE.md` files are additive; more-specific guidance wins conflicts. Explicit `/implement-spec` and `/ship-it` passed, but implicit `ship-it` selection did not expose the skill's unique remote/head/PR-reuse contract in the current model probe. Require explicit `/skill-name` invocation for high-risk Claude workflows. Start a fresh session or inspect `/memory` after changes.

## Reproducible checks

```sh
bash scripts/check.sh
CODEX_HOME="$HOME/.codex" bash scripts/install.sh --dry-run
```

Offline checks use an isolated temporary `HOME` and verify all three entry points, conflicts, preservation, native Claude imports, skill links, and idempotence. Model-backed checks may incur usage charges and require local authentication:

1. Use a scratch project outside this repository.
2. Give its project instruction file a unique token (`AGENTS.md` for Pi/Codex, `CLAUDE.md` for Claude).
3. In fresh sessions, ask for one personal rule and the project token.
4. Invoke `implement-spec` using the agent-native form and verify a phrase unique to its `SKILL.md` or execute the documented scratch-spec fixture.
5. For precedence, make the project rule explicitly override the personal language default and inspect only the final assistant response.
6. Record agent, CLI/model version, tool reads, outputs, and blockers in the active `.spec/` plan.

Evidence for the current rows is recorded in [`.spec/2026-09-21_02_personal-agent-tooling-hardening.md`](../.spec/2026-09-21_02_personal-agent-tooling-hardening.md). Official Claude behavior: [memory/imports](https://docs.anthropic.com/en/docs/claude-code/memory) and [personal skills](https://code.claude.com/docs/en/skills).
