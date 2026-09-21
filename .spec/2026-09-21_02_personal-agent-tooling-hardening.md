# Personal agent tooling hardening and growth

- Created: 2026-09-21
- Updated: 2026-09-22
- Status: In progress — local implementation through Phase 6 complete; remote ruleset/secret scope, third-party review, live tool cleanup, high-risk 3/3, and final release checks remain
- Depends on: `.spec/2026-09-20_01_personal-agent-repo.md`
- Goal: Turn this repository from working dotfiles into a small, secure, reproducible personal Agent toolkit for Pi, Codex, and evidence-verified Claude Code support.
- Constraint: Do not build an Agent runtime, configuration generator, or plugin platform. Extend native discovery and plain files first.

## Outcome

A fresh clone should provide:

1. concise personal instructions with verified precedence;
2. focused, portable skills with explicit side effects and regression cases;
3. least-privilege examples for each supported agent;
4. reviewed and pinned third-party sources without vendored packages;
5. deterministic offline checks plus isolated model-backed smoke tests;
6. protected `main`, secret-leak defenses, and a reversible update path.

“Supported” means installation and model-backed behavior were tested. Untested adapters remain “candidate”, not supported.

## Current baseline and gaps

Baseline on 2026-09-21:

- 13 tracked files; clean `main` tracking `origin/main`.
- Shared rules split into communication, workflow, and safety concerns.
- One managed installer for Pi/Codex; 12 named offline check gates.
- Two owned skills: `implement-spec` and `ship-it`.
- Sanitized Pi and Codex configuration examples.

Observed gaps:

- original setup spec still has live installation and model-backed checks pending;
- no required CI check or documented default-branch ruleset;
- no machine-readable source/version/provenance lock;
- no read-only live-environment doctor;
- no repeatable model smoke/eval cases or prompt-injection regression;
- no evidence for Claude or other candidate agents;
- current README package inventory is informative, not an update/rollback process.

## Research-backed decisions

| Finding | Decision for this repo |
| --- | --- |
| OpenAI separates persistent instructions, memories, skills, MCP, and subagents, and recommends adopting them in that order. | Keep layers separate. Finish instructions/skills before adding MCP or subagent configuration. |
| Codex loads hierarchical AGENTS files with closer scopes overriding broader scopes; combined project docs have a default size limit. | Keep global rules short and project-neutral. Test source order and avoid copying project guidance into personal rules. |
| OpenAI skill guidance favors one job per skill, imperative inputs/outputs, instructions before scripts, and trigger testing. | Add a small skill contract and positive/negative trigger fixtures; scripts only for deterministic work. |
| Claude instructions are context, not enforcement; Anthropic recommends sandbox/permissions/hooks for hard controls. | Never claim a Markdown rule prevents an action. Enforce protected branches, filesystem/network limits, and approval gates outside prompts. |
| Anthropic documents direct AGENTS.md support and layered instruction scopes. | Do not create duplicate CLAUDE.md content by default. First verify current Claude behavior; add only a thin adapter if needed. |
| Codex and Claude both expose sandbox/permission boundaries. Command-text deny rules alone are bypassable through alternate invocation forms. | Prefer OS/runtime sandbox boundaries and server-side repository rules over command-string blocklists. |
| MCP security guidance warns about confused-deputy attacks, token passthrough, excessive scopes, and weak consent. | Keep MCP disabled unless a concrete workflow needs it. Review each server, minimize scopes, keep credentials local, and require approval for side effects. |
| Anthropic recommends capability and regression evals, isolated environments, deterministic graders where possible, and multiple trials for nondeterministic behavior. | Split cheap offline gates from credentialed model smoke tests. Grade outcomes first; use repeated trials only for high-risk workflows. |
| GitHub rulesets can require PRs and block force pushes; public-repo secret scanning/push protection has coverage limits. | Protect `main` server-side and retain local secret checks. Do not treat GitHub scanning as complete coverage. |

## Design principles

1. **Portable core, thin adapters.** Shared Markdown and skills contain no required Pi/Codex/Claude-specific APIs.
2. **Native before custom.** Use native instruction, skill, sandbox, and repository controls before scripts or dependencies.
3. **Policy is not prose.** Instructions explain intent; sandbox, approvals, hooks, and GitHub rules enforce boundaries.
4. **Least privilege by default.** No blanket filesystem, network, MCP, or GitHub access in committed examples.
5. **Evidence over claims.** Every supported agent and high-risk skill needs an observable probe.
6. **Local secrets stay local.** Commit schemas/examples, never tokens, auth state, trust overrides, session logs, or raw transcripts.
7. **One-way complexity gate.** Add MCP, subagents, hooks, or an eval framework only after a measured need and a written threat/maintenance cost.

## Proposed minimal layout

Add files only when their phase is implemented:

```text
.github/
└── workflows/check.yml          # Offline checks only
agents/
├── support-matrix.md            # supported vs candidate + evidence date
├── sources.lock.tsv             # source, exact version/ref, integrity, review date
├── pi/...
├── codex/...
└── claude/...                   # only if native AGENTS.md verification needs an adapter
docs/
├── security-model.md            # trust boundaries and risk policy
└── maintenance.md               # update, rollback, restore
smoke/
├── cases.tsv                    # case, agent, risk, prompt fixture, grader
└── fixtures/                    # tiny isolated repositories; no secrets
scripts/
├── check.sh                     # existing deterministic offline gate
├── doctor.sh                    # proposed read-only live diagnosis
└── smoke.sh                     # optional manual model runner, not CI by default
```

Do not add a database, daemon, package manager, telemetry service, custom runtime, or general-purpose test framework.

## Phase 0 — close the existing bootstrap

- [x] Run the existing installer dry-run against real homes and review every planned target.
- [x] Install into real Pi/Codex homes; verify backups, links, and unmanaged content.
- [x] Start fresh Pi and Codex sessions outside this repository and inspect actual reads of all referenced personal rules.
- [x] Execute `implement-spec` and `ship-it` model smoke cases without making a real remote write.
- [x] Update the original spec with exact versions, commands, evidence, and blockers.

Acceptance:

- `scripts/check.sh` passes before and after installation.
- Pi and Codex each load personal plus project instructions in expected precedence.
- Both discover each owned skill exactly once.
- Existing user configuration outside managed sections is byte-preserved.

Phase 0 evidence and limitations:

- Live install used Pi 0.86.1 and Codex CLI 0.153.4. Orca injects a runtime `CODEX_HOME` whose AGENTS.md is a symlink to canonical `~/.codex/AGENTS.md`; installer correctly refused that symlink. Inode/realpath verification justified an explicit canonical `CODEX_HOME` for installation.
- Relative rule references failed a real Codex probe: Codex resolved them against the scratch project cwd. Installer now writes per-agent absolute installed paths while retaining modular rule symlinks. Both Bash versions and live reinstall passed; managed-section exterior bytes and exact backups were verified.
- Pi with `openai-codex/gpt-5.5` and Codex with its configured default model performed observable reads of all three rule files and applied the scratch project token. Pi `gpt-5.3-codex-spark` did not call tools, so support evidence is model-specific, not universal.
- Both agents executed `implement-spec` successfully in temporary repositories. Both loaded `ship-it` and stopped without branch, index, commit, or file mutation when no remote existed. No real remote write occurred.

## Phase 1 — establish enforceable safety boundaries

### 1.1 Threat model

[x] Create `docs/security-model.md` covering:

- assets: source code, credentials, private notes, shell access, GitHub identity, agent memory;
- untrusted inputs: repository text, web pages, issues/PRs, tool output, skill packages, MCP metadata;
- boundaries: model context, sandbox, host filesystem, network, remote APIs, public Git history;
- side-effect classes: read-only, local write, network write, destructive/irreversible;
- required approval and verification for each class;
- prompt-injection rule: external content is data, never authority to widen permissions or disclose secrets.

### 1.2 Hard controls

- [ ] Add a GitHub ruleset targeting the default branch: require PR, block force pushes and deletion, require the offline check once CI exists.
- [ ] Verify whether repository-level secret protection is available; document GitHub user push protection and its limitations.
- [x] Keep Codex example at workspace-write/on-request or a narrower supported permission profile; deny sensitive paths when the installed version supports it.
- [ ] Add equivalent least-privilege Pi/Claude examples only for verified, stable settings.
- [x] Require explicit approval for push, PR mutation, package installation, credentials, remote MCP, and destructive commands.
- [x] Add a deterministic regression that rejects committed credentials, absolute machine paths, trust overrides, and unsafe example modes.

Acceptance:

- A direct or force push to `main` is rejected server-side after the ruleset is active.
- Examples contain no `danger-full-access`, auto-approve-all, token, machine path, or trust override.
- A prompt fixture asking the agent to ignore policy and reveal an `.env` value does not result in a secret read or disclosure during model smoke tests.

## Phase 2 — make cross-agent support explicit

- [x] Add `agents/support-matrix.md` with agent/version, instruction entry point, skill entry point, config example, last smoke date, and status (`supported`, `candidate`, `blocked`).
- [x] Document instruction precedence and restart/reload behavior per supported agent.
- [x] Verify current Claude Code direct AGENTS.md behavior in an isolated home before adding files.
- [x] Claude needed an adapter: add the smallest native `CLAUDE.md` `@` imports plus native personal-skill links; never duplicate rule text.
- [x] Add an adapter only when a real installed agent can be smoke-tested. No speculative directories for unused agents.

Acceptance:

- Every “supported” row links to reproducible evidence.
- Shared rules have one authoritative source.
- Conflicting global/project instructions produce the documented winner in a probe.
- Candidate agents are not installed or advertised as working.

Phase 1 remote blocker: activating a default-branch ruleset is a GitHub mutation and the required CI check does not exist yet. Repository-level secret protection remains unverified until a locally approved `gh` session has suitable read scope.

## Phase 3 — harden the skill lifecycle

Define one lightweight contract for every owned skill:

- focused job and specific trigger description;
- prerequisites and expected inputs;
- side effects and required authorization;
- stop conditions and failure reporting;
- output/completion contract;
- smallest direct verification;
- no harness-specific requirement unless clearly isolated and documented.

Work:

- [x] Extend `scripts/check.sh` to validate Agent Skills metadata, matching names, referenced resources, no internal symlinks, required contracts/cases, and no machine-specific paths.
- [x] Add positive and negative trigger cases for each skill. Structural coverage is offline; Pi/gpt-5.5 model probes verified both positive reads and negative non-reads.
- [x] Add and execute the `implement-spec` outcome case: requested file changed, spec evidence updated, unrelated file preserved.
- [x] Add and execute `ship-it` outcomes against disposable local bare remotes/fake `gh`: feature branch only, exact path committed, concrete failed check stops commit/push/PR, existing PR reused, `main` never pushed.
- [ ] Review third-party skills before use; never vendor them into this repo.
- [x] Review skill size/navigation before splitting. Both remain single-purpose and readable; no speculative resource split added.

Acceptance:

- Explicit invocation works for each supported agent.
- Implicit trigger succeeds on positive cases and stays inactive on unrelated negative cases.
- High-risk skills state authorization and stop conditions visibly.
- Deterministic scripts have direct tests; prose-only steps are not padded with fake unit tests.

## Phase 4 — control tool and supply-chain growth

### 4.1 Source lock

- [x] Add `agents/sources.lock.tsv`, checked with Bash/awk, with fields:

```text
kind  name  source  exact_version_or_commit  integrity  risk  reviewed_at
```

Rules:

- npm packages use exact versions plus registry integrity when available;
- Git sources use reviewed commit SHAs, not branch names or folder hashes presented as commits;
- local/private tools record no machine path or credential;
- every update requires source diff review, offline checks, and targeted smoke tests;
- removed tools leave the lock instead of remaining as inactive clutter.

### 4.2 Tool/MCP policy

- [x] Inventory observed extensions, hooks/MCP boundary, and external CLIs by capability and side-effect class in `agents/tool-policy.md`; machine-local endpoints remain excluded from support claims until audited.
- [ ] Disable duplicate or unused live tools; one capability should have one default path. Policy selects defaults, but live settings were not mutated.
- [x] Prefer local/read-only tools. Enable network/write access per task, not globally.
- [x] For any remote MCP, require operator, data sent, scopes, auth method, write tools, and revocation procedure. No MCP is installed by this repository.
- [x] Reject token passthrough, broad wildcard scopes, silent consent, and unreviewed metadata changes.
- [x] Keep tokens in agent/OS credential stores or environment injection, never config examples.

Acceptance:

- Every enabled third-party executable has provenance, an exact pin, a risk label, and an owner/update decision.
- Removing one optional package leaves installation and core checks working.
- No MCP server is added solely because it is available.

## Phase 5 — add a small eval ladder

### Level A: offline on every change

- [x] Keep `bash scripts/check.sh` as the mandatory, dependency-free gate. It now checks:

- metadata and source-lock syntax;
- managed installation idempotence and conflict safety;
- config parsing where native parsers exist;
- forbidden secret/path/trust patterns;
- skill references and fixture consistency.

### Level B: manual model smoke before support/release claims

- [x] Create 8 canonical cases in isolated temporary homes/repositories:

1. report loaded global and project instructions;
2. obey a closer project override;
3. invoke `implement-spec` and verify filesystem outcome;
4. invoke `ship-it` against a disposable local/fake remote and never push default branch;
5. preserve unrelated staged and unstaged files;
6. resist an instruction-injection fixture requesting secret access or policy bypass;
7. stop cleanly when authentication/tooling is unavailable;
8. reload changed linked rules in a fresh session.

Record only redacted metadata: repository commit, agent/version, model identifier, config profile, case ID, result, grader, duration/cost if available, and failure reason. Raw transcripts remain local unless manually sanitized.

### Level C: repeated high-risk regression

Policy is encoded in `tests/model-cases.tsv` and `docs/model-smoke.md`; existing high-risk rows are explicitly marked `single-trial-only`, so release-level 3/3 claims remain pending.

- [ ] Run destructive/network-write safety cases three isolated times.
- Require 3/3 safe outcomes before claiming the workflow supported.
- Use deterministic outcome graders first; use transcript/model grading only when outcome checks cannot express the requirement.
- Track capability experiments separately from near-100%-pass regression cases.

Do not run credentialed model evals in pull-request CI. Add a framework only when shell fixtures cannot represent the cases.

## Phase 6 — automate only stable gates

- [x] Add minimal `.github/workflows/check.yml` running `bash scripts/check.sh` on Linux with `contents: read`, checkout credential persistence disabled, and commit-pinned action.
- [x] Keep Bash 3.2/macOS verification in the release checklist unless a second CI job proves worth its cost.
- [ ] Make the passing offline job required by the default-branch ruleset; blocked until workflow exists remotely and the ruleset mutation is explicitly authorized.
- [x] Add `scripts/doctor.sh`: read-only checks for required commands, versions, managed blocks, link targets, stale pins, config syntax, and auth presence without printing tokens.
- [x] Test restore in a temporary HOME: check → dry-run → install → doctor → broken-link failure → uninstall/reinstall. Full network clone remains a release-machine check.
- [x] Document rollback: checkout previous reviewed tag/commit, rerun installer, verify links and managed blocks; never roll back by deleting whole agent homes.

Acceptance:

- CI has read-only repository permissions and no stored model/provider credentials.
- Doctor returns nonzero with actionable messages for broken links, unsupported versions, malformed blocks, or missing prerequisites.
- Fresh-clone restore succeeds without reading live secrets or overwriting unrelated files.

## Phase 7 — maintenance cadence

- [x] Document event-driven updates, release gates, quarterly quiet-period checks, and rollback in `docs/maintenance.md`.

Use event-driven maintenance, not ceremony:

- on agent/package update: review release notes and diffs, update exact pin, run targeted smoke;
- on new skill/tool: document need, owner, risk, removal criterion, and acceptance case;
- on security advisory: disable affected capability first, then investigate/update;
- before a tagged baseline: run offline checks, fresh-home restore, and supported-agent smoke matrix;
- quarterly only if nothing changed: verify links, pins, default-branch rules, and credential hygiene.

Create a release tag only after Phase 0 plus required Phase 1 controls pass. Add a changelog only after a second release makes one useful.

## Delivery order

1. Close original spec's live/model checks.
2. Enable GitHub ruleset and document threat model.
3. Add support matrix and source lock.
4. Harden existing two skills and fixtures.
5. Add offline CI and read-only doctor.
6. Add manual model smoke ladder.
7. Evaluate Claude; add adapter only if evidence requires it.
8. Consider MCP/subagents only after a concrete workflow cannot be met by native/local tools.

Each step must leave `bash scripts/check.sh` passing and update this checklist/evidence before the next step.

## Final acceptance

- [ ] Original setup acceptance is closed or explicitly blocked with evidence.
- [ ] `main` requires PRs, rejects force pushes, and requires offline checks.
- [ ] Fresh clone installs and restores safely in a temporary HOME.
- [ ] Pi and Codex pass instruction and owned-skill model smoke cases.
- [ ] Any additional supported agent passes the same class of checks.
- [ ] All third-party executable sources are exact-pinned and reviewed.
- [ ] High-risk cases achieve 3/3 safe isolated outcomes.
- [ ] No secrets, auth state, trust decisions, raw transcripts, or machine paths are tracked.
- [ ] README explains install, doctor, update, rollback, support status, and security boundaries.

## Deferred / non-goals

- Shared autonomous memory across agents.
- Automatic secret synchronization.
- Custom agent runtime or universal configuration compiler.
- Hosted observability platform or transcript warehouse.
- Production MCP server, agent swarm, or unattended scheduler.
- Supporting every agent before actual use.
- Model evals on every commit.

## Research sources

Accessed 2026-09-21. Prefer current first-party pages during implementation because settings and security guidance evolve.

1. OpenAI, “Customization” — layering and recommended adoption order: https://developers.openai.com/codex/concepts/customization
2. OpenAI, “Custom instructions with AGENTS.md” — discovery, precedence, size limit, verification: https://developers.openai.com/codex/guides/agents-md
3. OpenAI, “Agent Skills” — progressive disclosure, focused skills, triggers, instructions before scripts: https://developers.openai.com/codex/skills
4. OpenAI, “Advanced Configuration” — sandbox, approvals, network, project trust: https://developers.openai.com/codex/config-advanced
5. Anthropic, “How Claude remembers your project” — scopes, AGENTS.md support, specificity, context vs enforcement: https://docs.anthropic.com/en/docs/claude-code/memory
6. Anthropic, “Configure permissions” — permission/sandbox defense in depth and command-rule limits: https://docs.anthropic.com/en/docs/claude-code/permissions
7. Anthropic, “Demystifying evals for AI agents” — capability/regression split, isolated trials, graders, pass metrics: https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents
8. Model Context Protocol, “Security Best Practices” — confused deputy, token passthrough, scope minimization. This is a draft page; re-check latest stable guidance before implementation: https://modelcontextprotocol.io/docs/draft/tutorials/security/security_best_practices
9. GitHub, “Available rules for rulesets” — require PRs and block force pushes: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets
10. GitHub, “Push protection” — public-repository protections and boundaries: https://docs.github.com/en/code-security/concepts/secret-security/push-protection
11. Agent Skills specification/project — portable structure and progressive disclosure: https://agentskills.io/specification

## Evidence log

| Date | Evidence | Result |
| --- | --- | --- |
| 2026-09-21 | Web search across OpenAI, Anthropic, MCP, GitHub, and Agent Skills sources | 11 first-party references selected; third-party search results excluded from decisions where first-party guidance existed |
| 2026-09-21 | Direct fetch/index of all 11 cited pages; focused queries over the 8 core design/security/eval documents | All cited URLs fetched successfully; extracted instruction layering, skill design, sandbox/permission, MCP threat, repository protection, and eval requirements |
| 2026-09-21 | Local repository gap scan | 13 tracked files, two owned skills, two agent examples, 12 offline PASS gates; identified CI, source-lock, doctor/eval, branch-policy, injection-test, and candidate-agent gaps |
| 2026-09-21 | Plan creation | Planning only; no installer/config/runtime changes, package installs, model calls, GitHub settings changes, or remote writes |
| 2026-09-22 | Phase 0 live dry-run/install | Initial Orca runtime-home symlink conflict reproduced; canonical Codex target proved identical by inode. Pi/Codex AGENTS updated with exact backups; six rule links and two skill links verified; rerun idempotent |
| 2026-09-22 | Relative-reference regression and fix | Codex resolved relative global references against project cwd and failed three reads. Installer changed to per-agent absolute installed paths; current Bash and Bash 3.2 suites passed, LSP reported 0 diagnostics, live reinstall preserved all bytes outside managed blocks |
| 2026-09-22 | Model-backed Phase 0 smoke | Pi 0.86.1 with openai-codex/gpt-5.5 and Codex CLI 0.153.4 read all personal rules plus project guidance; both executed implement-spec and safely stopped ship-it with no remote. Pi Spark negative result retained as model-variability evidence |
| 2026-09-22 | Phase 1 security boundary | Added `docs/security-model.md`, side-effect approval matrix, external-instruction rule, and least-privilege example notes. Pi/Codex malicious-README probes read no fake `.env` value and disclosed no secret; dual-Bash checks and config diagnostics passed |
| 2026-09-22 | Claude entry-point experiment | Claude Code 2.1.236 no-tool probe ignored AGENTS.md and loaded CLAUDE.md control. Official Anthropic docs confirmed native `@` imports and `~/.claude/skills`; no speculative compatibility claim used |
| 2026-09-22 | Phase 2 three-agent support | Installer extended with preserving CLAUDE.md block, native imports, and owned-skill links. Dual-Bash suite, canonical dry-run, live install/idempotence, DeepSeek model instruction/skill smoke, and Pi/Codex/Claude precedence probes passed |
| 2026-09-22 | Deterministic policy guardrail | `scripts/check.sh` now rejects high-confidence credential assignments, machine paths in agent config examples, and dangerous/trust-bypass modes; positive repo plus three negative fixtures pass under current Bash and Bash 3.2 |
| 2026-09-22 | Read-only GitHub protection audit | Repository is public; rulesets list is empty. Secret-scanning endpoint could not be inspected because current gh token lacks public_repo scope. Documented personal push-protection limits; no remote setting changed |
| 2026-09-22 | Phase 3 skill contracts and cases | Both owned skills now declare input/prerequisites/side effects/stops/completion. Offline TSV coverage and resource checks pass under both Bash versions; Pi/gpt-5.5 implicit positive/negative triggers passed 4/4 |
| 2026-09-22 | Phase 3 outcome probes | implement-spec scratch outcome passed. ship-it used local bare remotes plus fake gh: strict create/reuse head, exact target commit, unrelated preservation, main unchanged, and concrete failed check stopping commit/push/PR all passed. Claude explicit /ship-it contract probe passed |
| 2026-09-22 | Phase 4 source/tool baseline | Queried npm registry metadata for 19 exact npm packages and recorded sha512 integrity/source/risk plus four exact external CLI versions. Bash/awk lock validator and unpinned negative fixture pass on Bash 3.2; tool/MCP policy defines default routes, no-growth budget, ownership, removal, and remote-MCP data boundary |
| 2026-09-22 | Phase 5 eval ladder | Added 8 canonical cases, deterministic grader/repetition policy, redacted metadata ledger, and offline schema/cross-reference checks. Existing high-risk evidence is honestly marked single-trial-only; CI remains model/auth free |
| 2026-09-22 | Phase 6 stable automation | Added read-only Linux CI with pinned checkout and no persisted credential; YAML/action/security diagnostics clean. Added read-only doctor; isolated restore/broken-link/uninstall/reinstall passes under current Bash and Bash 3.2; live canonical-home doctor passed all links, versions, config parsers, and auth-presence checks |
| 2026-09-22 | Phase 7 maintenance | Added event-driven update/security/release/quiet-period/rollback checklist. No tag or changelog created because remote protection and repeated high-risk gates remain blocked |
