# Personal agent repo setup

- Created: 2026-09-20
- Updated: 2026-09-22
- Status: In progress — live installation and model-backed acceptance passed; fresh-machine authentication/smokes, third-party skill commit pinning, and deferred skill inventory remain.
- Goal: Clone this repo, install once, and use shared personal guidance and portable skills in Pi and Codex.
- Approach: Personal agent dotfiles, not another agent framework.

## Progress tracking

Update this file as work proceeds. Check tasks only after verification; record evidence and blockers below. Keep credentials and private runtime data out of progress notes.

| Phase | Status |
| --- | --- |
| 1. Inventory | Complete; remote is PUBLIC, existing shared skills are third-party |
| 2. Structure and guidance | Complete |
| 3. Installation | Complete on this macOS host; live Pi/Codex files installed with backups and idempotence verified |
| 4. Skill migration | Partial; two new owned skills, third-party content preserved, 3–5 owned workflows not identified |
| 5. Verification | Offline, native discovery, linked-rule reads, and owned-skill model smokes passed; fresh-machine acceptance pending |

## Target layout

```text
agent-skills/
├── .spec/
│   └── 2026-09-20_01_personal-agent-repo.md
├── README.md
├── AGENTS.md                 # Rules for maintaining this repo
├── instructions/
│   ├── communication.md      # Independent shared rules
│   ├── workflow.md
│   └── safety.md
├── skills/
│   ├── implement-spec/
│   │   └── SKILL.md
│   └── ship-it/
│       └── SKILL.md
├── agents/
│   ├── pi/
│   │   └── settings.example.json
│   └── codex/
│       └── config.example.toml
├── scripts/
│   ├── install.sh
│   └── check.sh
└── .gitignore
```

Create optional references/scripts/assets directories only when needed and populated.

## 1. Inventory before migrating

- [x] Review existing `~/.agents/skills/`, Pi customizations, and Codex configuration structure without exposing credentials.
- [x] Identify owned content to move into this repo: none confirmed among the 14 installed shared skills.
- [x] Record third-party package sources and installed versions in `README.md`; do not copy installed package trees.
- [x] Identify local-only state: credentials, sessions, caches, memory databases, and trust decisions.
- [x] Configure `.gitignore` to exclude runtime state, including `.pi/fabric/`, while allowing reviewed project configuration.
- [x] Confirm repository visibility: remote is PUBLIC. No visibility change performed; private Git would not be secret storage either.

Preserve existing working configuration during migration. Inspect for secrets before staging files. Existing Pi settings contain 17 package sources; installed versions are recorded, but live settings remain unchanged and unpinned. Third-party skill-folder hashes are provenance, not verified Git commit pins.

## 2. Separate guidance layers

- [x] Split shared instructions into `instructions/communication.md`, `workflow.md`, and `safety.md`, preserving the original eight working agreements.
- [x] Write root `AGENTS.md` with rules for maintaining this repository only.
- [x] Keep project build commands, architecture, and domain conventions out of global instructions.
- [x] Keep reusable workflows in on-demand skills rather than expanding global instructions.
- [x] Document installation, prerequisites, supported agents, package versions, and verification in `README.md`.

Global guidance does not impose project-specific commands or Pi-only tool names.

## 3. Install through native discovery

Pi 0.86.0 and Codex CLI 0.153.4 both discovered the installed shared skill in an isolated home. See native-probe evidence below.

| Repo source | Installed target |
| --- | --- |
| Generated managed reference block | Regular `AGENTS.md` in each agent home |
| `instructions/<topic>.md` | `agent-skills-<topic>.md` symlinks beside each AGENTS.md |
| `skills/<name>/` | `~/.agents/skills/<name>/` |

- [x] Implement `scripts/install.sh` using native symlinks.
- [x] Link individual skill directories, not the entire existing skills directory.
- [x] Derive source paths from checkout location; do not hard-code this machine's path.
- [x] Support dry-run without filesystem changes.
- [x] Preserve existing regular AGENTS.md content outside our managed block; refuse conflicting rule/skill links, malformed markers, and non-regular AGENTS.md targets.
- [x] Make reruns safe: already-correct links are no-ops.
- [x] Document how to remove managed links without deleting sources or unrelated files.
- [x] Add sanitized Pi and Codex configuration examples; preserve existing settings through manual integration initially.
- [x] Support absolute `PI_CODING_AGENT_DIR` and `CODEX_HOME` overrides; reject empty, relative, and root destinations. Shared skill destination remains under `$HOME`.
- [x] Implement the user's chosen default: preserve/create AGENTS.md, insert a begin/end section, split rules by concern, link them beside AGENTS.md, and reference them from that section.
- [x] Run the revised installer into real agent homes; exact backups, managed-block exterior bytes, six rule links, two skill links, and idempotent rerun verified.

Do not symlink entire agent configuration directories. Agents may rewrite settings; credentials and runtime state remain local. Known target conflicts are preflighted before any links are created. Unexpected I/O errors may leave some newly created links; reruns resume safely. Concurrent installers are intentionally unsupported.

### 2026-09-21 revision: one default, modular references

User rejected multiple installation modes. Keep only normal installation plus non-mutating `--dry-run`; no `--mode` or `--only` switches.

- [x] Preserve/create regular AGENTS.md; manage exactly one `<!-- agent-skills:begin -->` / `<!-- agent-skills:end -->` section.
- [x] Split rules into three independent topic files and remove the former monolithic `instructions/AGENTS.md`.
- [x] Create prefixed file symlinks beside each agent's AGENTS.md. Initial relative read links failed a real Codex model probe because Codex resolved them against the project cwd; generate per-agent absolute installed paths instead.
- [x] Append or replace only the managed section; preserve outside bytes, including CRLF and missing final newline.
- [x] Back up changed existing files, retain permissions, and atomically replace each file; reruns leave files/links/backups unchanged.
- [x] Reject broken/duplicate/out-of-order/inline markers, NUL text, AGENTS.md symlinks/directories, and conflicting rule/skill targets before writes.
- [x] Verify edits to linked rule contents are visible immediately and rule additions/removals refresh references on rerun.
- [x] Verify real Pi/Codex model tool reads of all referenced rules. Relative references failed Codex and were replaced by generated absolute installed paths; current probes show actual tool reads.

Sources remain portable plain Markdown. Rule filenames use lowercase kebab-case; generated links use the `agent-skills-` prefix to avoid generic-name collisions. Orphaned links are not automatically deleted. Existing override files stay untouched and may supersede AGENTS.md.

## 4. Migrate useful workflows

Original target: 3–5 regularly used owned skills, selected during inventory. Inventory found no confirmed owned skill to migrate, so this target remains deferred rather than satisfied by copying third-party installations or inventing unused workflows.

- [ ] Select 3–5 owned workflows for migration when available.
- [ ] Migrate those owned skills into `skills/<name>/SKILL.md`.
- [x] Add one newly authored portable skill, `implement-spec`, for the specification/progress workflow already used here.
- [x] Include standard `name` and clear trigger `description` metadata; directory and skill names match.
- [x] Keep bundled paths relative where needed; current skills have no bundled resources.
- [x] Keep shared workflows free of required harness-specific tool names.
- [x] Document external prerequisites explicitly; `implement-spec` needs only repository access and project check commands.
- [x] Install shared skills only once, without adding a duplicate Pi package or explicit skill path. Both native loaders report one `implement-spec` entry.

Keep Pi-only extensions under `agents/pi/` when needed. Other harnesses use native adapters; do not pretend extension APIs are portable. Review third-party skills and executable extensions before installation.

Existing useful third-party workflows (`diagnose`, `handoff`, `write-a-skill`) remain installed outside this repo. Their upstream paths and recorded folder hashes are documented in `README.md`. Reproducible fresh-machine restoration still needs reviewed Git commit pins and a verified installation procedure.

### Requested addition: ship-it

- [x] Add portable `skills/ship-it/SKILL.md` for scoped commit → feature-branch push → GitHub PR creation/reuse.
- [x] Verify frontmatter/name, concise instructions, explicit authorization, unrelated-change protection, failure stops, and README registration.
- [x] Run `bash scripts/check.sh` and directly verify the installed `ship-it` symlink/content in an isolated home.
- [x] Perform an explicitly authorized model-backed ship-it safety smoke in disposable local repos. Both agents loaded the skill and stopped without mutation when no remote existed; no real commit/push/PR was requested from the fixture.

Evidence: repository checks passed with both owned skills. Temporary-HOME probes confirmed dry-run safety, exact installed content, and reinstall stability. Model smokes used disposable local repositories, bare remotes, and fake `gh` to verify exact staging, feature-branch pushes, PR create/reuse, unrelated-change preservation, and failure stops. No real GitHub repository, PR, visibility, or protection setting was changed.

## 5. Verification and acceptance

Use `scripts/check.sh` and native/manual smoke tests. Installer tests use a temporary home and checkout, never live configuration.

- [x] Managed links resolve to expected checkout files.
- [x] Skill names are unique and required metadata is present.
- [x] Installer rerun changes nothing; compare link inode/path snapshots as well as targets.
- [x] Dry-run creates or changes nothing.
- [x] Conflicting file, skill directory, or broken symlink remains untouched and installation reports the conflict.
- [x] Non-directory parent paths are rejected before partial installation.
- [x] Checkout and home paths containing spaces work.
- [x] Unrelated settings and unmanaged skills remain untouched.
- [x] Custom agent homes and invalid arguments are checked.
- [x] Pi natively discovers the shared skill once without diagnostics.
- [x] Codex natively discovers the same shared skill once, enabled, without skill errors.
- [x] Pi executes `implement-spec` against a scratch specification through a model-backed run; exact output, sentinel preservation, check evidence, and actual SKILL read verified.
- [x] Codex executes the same skill against a scratch specification through a model-backed run with the same outcome checks.
- [x] Both agents read/apply all referenced personal rules outside this repo through observable tool calls.
- [x] Project-specific instructions apply alongside personal guidance; both probes returned the scratch-only verification token.
- [x] No credentials, sessions, caches, trust decisions, or memory databases are tracked. Bounded plaintext secret-pattern scan found no matches in new implementation files; this is not a complete secret audit.
- [ ] Fresh-machine setup is exercised end to end: clone → install → configure/authenticate locally → model-backed smoke test. Instructions are documented; clean-machine run not performed.

A successful shell script or resource-loader run does not prove model-backed execution, so fresh CLI model sessions were used. Authentication values were not read or copied. Live global files were modified only by the reviewed installer, which created exact adjacent backups.

## Scope boundaries

First milestone remains: shared personal guidance and portable skills working in Pi and Codex, including behavioral smoke tests.

Deferred until needed:
- Universal configuration generator.
- Shared session or memory storage.
- Custom launcher or agent runtime.
- MCP orchestration.
- Plugin marketplace or publication pipeline.
- Additional agent adapters before those agents are used.

## Evidence and implementation log

| Date | Change or check | Result |
| --- | --- | --- |
| 2026-09-20 | Recorded setup plan and acceptance checklist | Planning complete; no implementation performed |
| 2026-09-21 | Inventory of shared skills, agent configuration structure, installed package metadata, and `gh repo view --json visibility --jq .visibility` | 14 third-party shared skills; 17 installed Pi package versions recorded; remote PUBLIC; no visibility change |
| 2026-09-21 | Added installer/check script, guidance files, examples, ignore rules, README, and `implement-spec` | Bootstrap implementation complete; nothing staged, committed, or pushed |
| 2026-09-21 | Initial isolated test | Found macOS `/var` versus physical `/private/var` path mismatch in test expectations; normalized scratch checkout with `pwd -P` |
| 2026-09-21 | `bash scripts/check.sh` and `PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/bash scripts/check.sh` | Both passed; current Bash and macOS Bash 3.2 with native utilities |
| 2026-09-21 | LSP diagnostics on both shell scripts and Pi example JSON | 3 files clean, 0 diagnostics, no unavailable/unsupported outcomes |
| 2026-09-21 | JSON parse plus `git check-ignore` probes | Pi example valid; runtime/secrets ignored; reviewed `.pi/settings.json`, `.pi/AGENTS.md`, and owned skill remain eligible for tracking |
| 2026-09-21 | Isolated native probe: Pi `DefaultResourceLoader.reload()` with extensions disabled, fresh HOME, scratch project outside repo | `implement-spec` discovered exactly once, no diagnostics; both personal and scratch project AGENTS.md loaded |
| 2026-09-21 | Isolated native probe: `codex app-server --strict-config --stdio`, JSON-RPC initialize then `skills/list` | Example config accepted; `implement-spec` discovered exactly once and enabled; no skill errors; no credentials/models used |
| 2026-09-21 | Original single-file installer live dry-run (historical, superseded) | Expected exit 1 for existing Codex AGENTS.md; revised managed-block design removes this regular-file conflict |
| 2026-09-21 | Bounded whitespace and plaintext secret-pattern scan, `git ls-files` | No findings in implementation files; tracked file list empty; no staging/commit/push |
| 2026-09-22 | Live canonical-home install and rerun | Pi/Codex managed blocks installed; existing bytes outside blocks and exact backups verified; six rule links and two skill links resolve; rerun changed no files/backups |
| 2026-09-22 | Codex relative-reference repro, installer fix, Bash 3.2/current Bash checks, LSP | Initial reads failed against scratch cwd; generated absolute installed paths fixed it; both suites passed and shell diagnostics were clean |
| 2026-09-22 | Pi/Codex fresh-session instruction and skill probes | All three personal rules plus project token read; implement-spec succeeded in disposable repos; ship-it stopped safely with no remote and no repository mutation |
| 2026-09-22 | Fresh local clone of `60fadf0` with isolated HOME | `git clone --no-local` followed by check, dry-run, install, and offline doctor all passed; real new-machine auth/model smoke remains pending |

Native probe used an ephemeral test program calling the installed Pi SDK and Codex app-server. It inspected actual loader output, not model claims. Repeatable model-backed smoke procedure is in `README.md`; `scripts/check.sh` remains dependency-free and does not require installed agents.

### Revised-installer evidence

- `bash scripts/check.sh`: passed all checks after fixing a test's leading-hyphen grep pattern.
- `PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/bash scripts/check.sh`: passed with Bash 3.2 and macOS utilities.
- Checked existing-text append, section replacement, CRLF/no-final-newline byte preservation, backups, permissions, preflight failures, source-rule changes, default/custom/shared homes, and idempotence.
- LSP diagnostics: both changed shell scripts clean, 0 diagnostics.
- Live `bash scripts/install.sh --dry-run`: exit 0; plans two AGENTS.md updates, six adjacent rule links, and one shared skill link. Existing Codex file is no longer a conflict. Directory snapshots and AGENTS.md hashes unchanged before/after.
- Historical note: this statement described the pre-install test stage. On 2026-09-22, live installation and model-backed probes were performed with the evidence below.
- Live install initially failed closed because Orca's injected `CODEX_HOME` exposes a symlinked AGENTS.md. Its target and canonical `~/.codex/AGENTS.md` were proven to share an inode; installation used explicit canonical `CODEX_HOME`.
- Real Codex proved relative global references unsafe by resolving them against the project cwd. Generated absolute installed paths fixed the failure; Pi and Codex then read all three rules through observable tool calls.
- Pi 0.86.1 / openai-codex gpt-5.5 and Codex CLI 0.153.4 passed instruction and implement-spec probes. Both agents safely stopped ship-it in no-remote fixtures. Pi gpt-5.3-codex-spark did not issue required reads and is not covered by the successful model claim.

## Blockers and next actions

1. **Skill ownership:** existing shared skills outside this repo remain third-party. Keep them external and identify owned workflows before completing the original 3–5 target.
2. **Third-party reproducibility:** recorded skill-folder hashes are not verified Git refs. Resolve reviewed upstream commit pins before claiming full restoration.
3. **Fresh machine:** exercise full setup on a clean environment. Linux behavior is intended but not tested on a Linux host; tested platform is macOS.
4. **Model variability:** Pi gpt-5.3-codex-spark ignored explicit linked-rule read requests while gpt-5.5 passed. Behavioral support claims must name the tested model/configuration.
5. **Orca environment:** Orca injects a runtime `CODEX_HOME` with symlinked AGENTS.md. Installer fails closed there; use canonical `CODEX_HOME=$HOME/.codex` only after verifying both paths resolve to the same file.
6. **Publication:** remote is public. Review contents before future commit/push; change visibility only on explicit request.

## References

- Codex skills: https://developers.openai.com/codex/skills
- Codex instructions: https://developers.openai.com/codex/guides/agents-md
- Codex configuration: https://developers.openai.com/codex/config-reference
- Pi: installed `README.md`, `docs/skills.md`, `docs/settings.md`, `docs/packages.md`, `docs/sdk.md`, and resource-loading SDK examples; verified with Pi 0.86.0 and Codex CLI 0.153.4.
