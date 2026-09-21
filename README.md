# Personal agent dotfiles

Shared working agreements and owned skills for Pi, Codex, and Claude Code. One default installer: managed AGENTS.md references plus symlinked rule files and skills. No agent runtime or config generator.

## Setup

Requirements: macOS or Linux, Bash 3.2+, standard command-line utilities, Git, and the agents you use. Install and authenticate each agent separately. The installer and offline checks need no Node packages, network access, or credentials.

```sh
git clone <your-repository-url> agent-skills
cd agent-skills
bash scripts/check.sh
bash scripts/install.sh --dry-run
bash scripts/install.sh
```

Dry-run validates the full plan without filesystem changes. Installation preserves or creates each agent's regular instruction file (`AGENTS.md` for Pi/Codex, `CLAUDE.md` for Claude), then inserts or refreshes one managed section. Text outside that section is preserved byte-for-byte, including CRLF and missing final newlines. An appended section adds a separating newline when necessary. Changed existing files receive a unique adjacent `AGENTS.md.backup.*` copy; replacement is atomic per file and preserves permissions. Unchanged files are not rewritten or backed up again.

Malformed/duplicate markers, an instruction-file symlink/directory, or conflicting rule/skill targets cause a nonzero exit before any changes. Existing regular AGENTS.md files are expected and are not conflicts. Unexpected I/O failures may leave some new links/files; reruns resume safely. This is not a transaction across both agent homes.

The installer is single-process: do not run simultaneous installs or edit destination paths while it runs. Keep the checkout in a stable location; links point to its absolute physical path.

| Source | Default target |
| --- | --- |
| Generated reference/import section | `~/.pi/agent/AGENTS.md`, `~/.codex/AGENTS.md`, and `~/.claude/CLAUDE.md` (regular files) |
| `instructions/<topic>.md` | `agent-skills-<topic>.md` symlink beside each instruction file |
| `skills/<name>/` | `~/.agents/skills/<name>/` for Pi/Codex and `~/.claude/skills/<name>/` for Claude |

### Shared instruction files

Rules are split by concern, not copied into AGENTS.md:

```text
instructions/communication.md   # Language and response style
instructions/workflow.md        # Implementation, verification, progress
instructions/safety.md          # Data, configuration, publication boundaries

~/.codex/                       # Same AGENTS layout in ~/.pi/agent/
├── AGENTS.md                   # Existing text + managed reference section
├── agent-skills-communication.md -> <repo>/instructions/communication.md
├── agent-skills-safety.md        -> <repo>/instructions/safety.md
└── agent-skills-workflow.md      -> <repo>/instructions/workflow.md
```

Pi and Codex use these markers and machine-specific installed paths:

```markdown
<!-- agent-skills:begin -->
## Shared personal instructions

Read and follow every rule file below before starting work. Each line contains an exact absolute path; do not resolve it against the project working directory. If a file cannot be read, report it rather than silently skipping it.

- communication absolute path: <agent-home>/agent-skills-communication.md
- safety absolute path: <agent-home>/agent-skills-safety.md
- workflow absolute path: <agent-home>/agent-skills-workflow.md
<!-- agent-skills:end -->
```

The installer writes real absolute paths separately for each agent home. This avoids a verified Codex behavior where relative references from global AGENTS.md were resolved against the project working directory. Pi/Codex references are explicit read instructions, not guaranteed native includes; model-backed smoke tests must inspect actual tool reads.

Claude Code 2.1.236 did not load `AGENTS.md` in a no-tool control probe, but did load `CLAUDE.md`. Its managed block therefore uses Claude's documented native imports:

```markdown
<!-- agent-skills:begin -->
## Shared personal instructions

@<claude-home>/agent-skills-communication.md
@<claude-home>/agent-skills-safety.md
@<claude-home>/agent-skills-workflow.md
<!-- agent-skills:end -->
```

Edit a rule's contents and the symlink reflects it immediately; start a fresh agent session or ask the running agent to reread it. Add/remove/rename rule files and rerun the installer to refresh the reference list. Rule filenames must be lowercase kebab-case `.md` files. Old unreferenced links are not deleted automatically; inspect them before removal.

Pi and Codex discover owned skills from `~/.agents/skills/`; Claude discovers matching links from `~/.claude/skills/`. Do not add duplicate explicit skill paths.

`PI_CODING_AGENT_DIR`, `CODEX_HOME`, and `CLAUDE_CONFIG_DIR` override their respective instruction destinations. They must be absolute, non-root paths; empty values are rejected. Pi/Codex shared skills use `$HOME/.agents/skills/`; Claude skills use `$CLAUDE_CONFIG_DIR/skills/` or `~/.claude/skills/`.

Orca may inject a runtime `CODEX_HOME` whose `AGENTS.md` is a symlink to canonical `~/.codex/AGENTS.md`. The installer rejects arbitrary AGENTS.md symlinks and will stop. Do not delete or replace the shim. If `realpath "$CODEX_HOME/AGENTS.md"` and `realpath "$HOME/.codex/AGENTS.md"` are identical, run installation with explicit `CODEX_HOME="$HOME/.codex"`; otherwise review manually.

For an isolated installation:

```sh
HOME=/absolute/path/to/test-home \
PI_CODING_AGENT_DIR=/absolute/path/to/test-pi \
CODEX_HOME=/absolute/path/to/test-codex \
CLAUDE_CONFIG_DIR=/absolute/path/to/test-claude \
bash scripts/install.sh --dry-run
```

Set the same home variables when launching the agents. Setting only `HOME` while retaining a real custom agent-home variable is not isolated.

### Existing configuration

- Root `AGENTS.md` governs maintenance of this repo. Independent `instructions/*.md` files contain personal defaults shared across projects.
- Keep project commands and architecture in each project's instructions.
- Merge reviewed values from `agents/pi/settings.example.json` and `agents/codex/config.example.toml` manually. The installer does not write settings.
- Choose models and authenticate locally. No credentials, sessions, trust decisions, or memory databases belong here.
- Review any existing `AGENTS.override.md`; it can supersede AGENTS.md in Pi/Codex. Claude uses `CLAUDE.md` hierarchy/imports. The installer leaves project overrides untouched.
- If a target conflicts, review it and back it up outside this repo before manually freeing that exact path. Do not bypass the check with a force install.

### Security model

[`docs/security-model.md`](docs/security-model.md) defines assets, trust boundaries, instruction-injection handling, and approval/verification requirements by side-effect class. [`docs/maintenance.md`](docs/maintenance.md) defines event-driven updates, release gates, quiet-period checks, and rollback. Agent settings are defense in depth: repository or web content cannot widen user authorization, sandbox access, credential access, or remote-write scope.

Current examples intentionally stay small: Pi asks before trusting a project; Codex uses workspace-write with on-request approval. Add no agent-specific setting until its installed version and behavior are verified.

### Remove or relocate

Remove only the `agent-skills:begin/end` section from each managed `AGENTS.md`/`CLAUDE.md`; leave all other text untouched. Run `readlink` on each adjacent rule link and skill link, confirm it points to this checkout, then use `unlink <target>` (no trailing slash). Never delete an entire instruction file to uninstall. Review adjacent backups before restoring them; a backup may predate later personal edits.

After moving the checkout, confirmed stale rule/skill links must be removed before reinstalling; they are conflicts, not silently rewritten. An instruction-file symlink left by another installer must be manually backed up/materialized as a regular file first; this installer never writes through arbitrary symlinks.

## Skills

| Owned skill | Purpose |
| --- | --- |
| `implement-spec` | Implement a saved spec, verify behavior, and keep progress evidence current |
| `ship-it` | Commit scoped changes, push a feature branch, and create or reuse a GitHub PR |

No plugin prerequisites. Skills use the current harness's native file and command tools. New skills use matching lowercase directory/name values and unquoted, single-line `name` and `description` fields; descriptions state when to invoke them. Each owned skill declares inputs, prerequisites, authorized side effects, stop conditions, and completion output. Keep bundled paths relative to the skill and reference every resource from `SKILL.md`. `check.sh` validates this deliberately small contract, not arbitrary YAML.

`ship-it` requires Git, authenticated GitHub CLI (`gh`), and push/PR permissions. Example: “Ship it: commit this fix, push a feature branch, and create a PR.” Explicit invocation authorizes that sequence; adding the skill does not execute it. It preserves unrelated changes, stops on failures, and never force-pushes or merges. Rerun `bash scripts/install.sh` to link newly added skills.

### Existing third-party skills

Inventory on 2026-09-21 found all 14 installed shared skills attributed to external repositories. They are not owned content and have not been copied or replaced. The planned 3–5 owned-skill migration is deferred until owned workflows are identified; `implement-spec` and `ship-it` are newly authored owned workflows.

Three useful existing workflows remain managed outside this repo:

| Skill | Source path in `https://github.com/mattpocock/skills` | Recorded skill-folder hash |
| --- | --- | --- |
| `diagnose` | `skills/engineering/diagnose/` | `43d464d0e9d1049b9d525975c0f7367ab7e01a5f` |
| `handoff` | `skills/productivity/handoff/` | `7bbb60d64c911617cee7f71b2ba9e24364faa14e` |
| `write-a-skill` | `skills/productivity/write-a-skill/` | `2f252b35aa238879afc5a230ac30343708dee0b3` |

These are provenance hashes from the existing skill installer lock, **not verified Git commit pins**. Do not use them as checkout refs. Reproducible third-party skill restoration needs a reviewed upstream commit and installation procedure; it is not part of the current bootstrap. Other observed skill sources: `vercel-labs/skills` and `stablyai/orca`.

### Pi package inventory

Observed installed versions on 2026-09-21, not automatically installed or enabled by this repo. Exact versions, registry integrity, sources, and risk labels are recorded in [`agents/sources.lock.tsv`](agents/sources.lock.tsv); routing, budget, MCP boundaries, update ownership, and removal are in [`agents/tool-policy.md`](agents/tool-policy.md). Existing live settings may still use unpinned sources; the lock is an audit baseline, not an installer. Review source code and choose only what you need. Pi extensions execute with full system access.

```text
npm:@petechu/pi-extension-toggle@0.1.3
npm:@hypabolic/pi-hypa@0.1.15
npm:pi-subagents@0.70.0
npm:pi-fabric@0.92.33
npm:pi-powerline-footer@0.17.1
npm:context-mode@1.0.169
npm:pi-context-usage@1.0.2
npm:pi-context-prune@1.4.0
npm:pi-hermes-memory@0.9.9
npm:pi-mcp-adapter@2.34.0
npm:pi-web-access@0.30.0
npm:pi-lens@4.2.1
npm:pi-smart-compact@9.7.0
npm:pi-caveman@1.0.8
npm:pi-ponytail@0.1.2
npm:@narumitw/pi-sync@0.51.0
npm:@ff-labs/pi-fff@0.10.6
```

Install an explicitly selected pin with `pi install npm:<package>@<version>`. Package installation is separate from the symlink installer; do not blindly install this entire inventory. Local Orca-specific Pi extensions and Codex MCP/plugin configuration remain machine-local.

## Verification

```sh
bash scripts/check.sh
bash scripts/doctor.sh           # live read-only versions, links, config, auth presence
bash scripts/doctor.sh --offline # skip agent/gh version and auth probes
```

Offline checks cover skill metadata/contracts/resources, [`tests/skill-cases.tsv`](tests/skill-cases.tsv) structural coverage, repository safety negative fixtures, Pi/Codex absolute references, Claude native imports, fresh/missing instruction files, appending to existing text, managed-block replacement, exact outside-byte preservation, backups and permissions, malformed markers/NUL bytes, symlink/directory conflicts, dry-run, idempotence, rule changes, spaces, custom homes, and preservation of settings/unmanaged skills. Tests create and remove only a temporary home and checkout. They do not invoke models or prove agent discovery.

### Live smoke tests

Use a scratch project outside this repo with a distinctive project rule in `AGENTS.md` for Pi/Codex and `CLAUDE.md` for Claude. Authenticate locally first; model calls may incur usage charges.

1. Start Pi, Codex, and Claude separately in the scratch project after installing links. Pi can use `--no-extensions`; Claude can use `--permission-mode plan --tools ''` for a no-tool instruction probe.
2. Ask each to restate one personal rule plus the project test rule. Inspect actual file reads for Pi/Codex; for Claude, compare a no-tool `AGENTS.md` negative control with a `CLAUDE.md`/native-import positive control.
3. Invoke `implement-spec` explicitly (`/skill:implement-spec` in Pi, `$implement-spec` in Codex, `/implement-spec` in Claude) against a tiny scratch spec: create a text file, verify its exact contents, then update the spec's evidence/checklist.
4. Inspect the transcript for the actual `skills/implement-spec/SKILL.md` read, check the created file and updated spec, and confirm the skill is listed once. A plausible response alone is not sufficient.
5. Record agent versions, commands, observed results, and any blockers in `.spec/2026-09-20_01_personal-agent-repo.md`.

Canonical prompts, deterministic graders, repetition rules, and redacted result fields are in [`tests/model-cases.tsv`](tests/model-cases.tsv), [`tests/model-results.tsv`](tests/model-results.tsv), and [`docs/model-smoke.md`](docs/model-smoke.md). High-risk support/release claims require 3/3 independently recreated safe outcomes; a single pass is capability evidence only.

A fresh-machine acceptance run includes clone, offline checks, dry-run, install, doctor, local authentication, and these smoke tests. No claim of completion until those steps are exercised.

### Rollback

Checkout the previous reviewed tag/commit, rerun `bash scripts/install.sh --dry-run`, review exact targets, then run the installer and doctor. Rollback updates managed blocks and links to that checkout; it must not delete whole agent homes, credential stores, settings, or text outside managed blocks. If the checkout moves, inspect and unlink only confirmed stale links before reinstalling.

## Security and scope

The existing remote was **PUBLIC** during inventory. No visibility change, commit, or push is performed by setup. `.github/workflows/check.yml` runs only the offline Bash gate with `contents: read`; it stores no model/provider credentials. Review files before staging, even if you later make the repo private; `.gitignore` is not a secret scanner.

Runtime state under `.pi/` is ignored except explicitly reviewed `settings.json` and `AGENTS.md`; `.codex/`, `.claude/`, `.agents/`, local config overrides, credential files, logs, and dependencies are ignored. Never use this repo as an agent home or store authentication here.

Deferred: universal config generation, shared memory/session storage, custom launchers, MCP orchestration, publication, and untested agent adapters.

Support status and precedence: [`agents/support-matrix.md`](agents/support-matrix.md). References: [Claude memory/imports](https://docs.anthropic.com/en/docs/claude-code/memory), [Claude skills](https://code.claude.com/docs/en/skills), [Codex skills](https://developers.openai.com/codex/skills), [Codex instructions](https://developers.openai.com/codex/guides/agents-md), [Codex configuration](https://developers.openai.com/codex/config-reference), and Pi's installed `docs/skills.md`, `docs/settings.md`, and `docs/packages.md`.
