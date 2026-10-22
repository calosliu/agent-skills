# Post-merge release closeout

- Created: 2026-09-25
- Updated: 2026-10-11
- Status: Blocked on credentialed clean-machine smoke — bounded source audit completed under owner-revised scope; unknown old skill commits and unreviewed live version drift are documented accepted limits, not reproducible snapshots.
- Depends on: `.spec/2026-09-21_02_personal-agent-tooling-hardening.md`
- Goal: Close reproducible release gaps after PR #1, while keeping third-party code, credentials, and live agent settings safe.
- Constraint: No vendoring, credential copying, live config mutation, PR merge, tag, or broad cleanup without separate explicit approval.

## Baseline

- PR #1 is merged; `main-required-offline-check` (ruleset 23949977) requires `offline` on `main`.
- PR #2 records ruleset evidence; latest read-only check: OPEN, `offline: SUCCESS`. The new closeout spec is currently local/untracked and not included in PR #2. Do not merge it as part of this closeout without explicit merge authorization.
- Local temporary-HOME install/doctor and a local `git clone --no-local` already passed. This does not prove a network clone or clean-machine model/auth smoke.
- Pi/Codex high-risk cases have 3/3 evidence. Claude high-risk implicit `ship-it` selection is not supported; invoke `/ship-it` explicitly.

## Phase 1 — network fresh-clone restore

- [x] Clone public `main` from GitHub into a new temporary directory (not from the current local worktree).
- [x] Use isolated temporary `HOME`; run `bash scripts/check.sh`, installer dry-run, installer, offline doctor, and installer rerun.
- [x] Verify rerun is idempotent and no credential files or model/provider tokens were copied into the temporary home.
- [x] Remove only the temporary clone and HOME after capturing exit-status evidence (cleanup ran in `finally`).

Acceptance: all commands pass from the network clone; second install creates no new backup or changed managed file. Do not claim fresh-machine authenticated model acceptance.

## Phase 2 — third-party provenance and safety review

- [x] Inventory the 14 installed third-party shared skills and 18 active direct Pi packages from read-only metadata.
- [x] Trace skill sources in `.skill-lock.json`: 12 map to `mattpocock/skills`, one to `vercel-labs/skills`, one to `stablyai/orca`; recorded 40-hex values are folder hashes, not Git commits. Queried current upstream HEADs without representing them as installed pins.
- [x] Read all 14 installed `SKILL.md` files; classify explicit install/network, vault/file-write, browser, Orca, and issue-tracker side effects. No skill commands were executed.
- [x] Recommend retain-by-default with per-task side-effect authorization; owner confirmed retain `pi-hypa` and `pi-lmstudio`. LM Studio source/lock review completed on 2026-10-11; remaining unknown commits/unreviewed versions are explicitly recorded under owner-revised scope. No live third-party content changed.
- [x] Verify `pi-lmstudio@1.5.0` against registry metadata, tarball SHA-512, and five installed release files; inspect source and run isolated mocked probes.
- [x] Record bounded-audit disposition: all 14 installed third-party skill commits are unknown; old folder hashes are not commit pins. Owner accepted stopping historical reconstruction and reviewing exact revisions when an actual update/restore is requested. Live version drift remains unreviewed; preserve the existing reviewed baseline.

Revised acceptance: retain verified audit records, explicitly mark unknown/unreviewed artifacts, and require source/version review on actual update or restore. This closes the repository-only audit task by approved scope revision, not by verifying every old snapshot. Full third-party restoration and current-runtime compatibility remain unclaimed.

## Phase 3 — live-tool duplicate audit (read-only)

- [x] Compare current active Pi extensions against `agents/tool-policy.md`; `settings.json` has no `mcpServers` key.
- [x] Identify candidates: `@ff-labs/pi-fff` is policy default search; `@hypabolic/pi-hypa` is active alternate with overlapping search. `pi-lmstudio@1.5.0` is active but absent from the repo lock.
- [x] Owner decision (2026-09-30): retain both `@hypabolic/pi-hypa` and `pi-lmstudio`; no removal or config change.

Acceptance: no live settings changed. Apply removals or source-lock updates only after separate approval of exact entries and target files.

## Phase 2 findings — third-party skills

| Installed skill | Source mapping | First-pass action / risk | Disposition |
| --- | --- | --- | --- |
| `diagnose` | `mattpocock/skills` | May run shell, curl/HTTP, or browser probes; inspect task-specific commands first | Keep; user-task only |
| `edit-article` | `mattpocock/skills` | Text edits only | Keep |
| `find-skills` | `vercel-labs/skills` | `npx skills` search/install; installation is network/package mutation | Keep; never install without explicit request |
| `grill-me` | `mattpocock/skills` | Conversation only | Keep |
| `grill-with-docs` | `mattpocock/skills` | May create/update CONTEXT/ADR files | Keep; confirm edits |
| `handoff` | `mattpocock/skills` | Writes temporary handoff; directs redaction | Keep; inspect output path/content |
| `improve-codebase-architecture` | `mattpocock/skills` | Writes temp HTML and opens browser | Keep; user-task only |
| `obsidian-vault` | `mattpocock/skills` | Reads/writes user's vault | Keep; confirm vault/path |
| `orca-cli` | `stablyai/orca` | Orca worktree/terminal/repo/network side effects possible | Keep; explicit task only |
| `setup-matt-pocock-skills` | `mattpocock/skills` | Edits agent/project guidance after confirmation | Keep; preserve approval step |
| `teach` | `mattpocock/skills` | May create lesson/knowledge files or open UI | Keep; user-task only |
| `triage` | `mattpocock/skills` | Can alter issues/labels and write project files | Keep; explicit scope and approvals |
| `write-a-skill` | `mattpocock/skills` | Creates/edits skill files | Keep; requested skill work only |
| `zoom-out` | `mattpocock/skills` | Conversation only | Keep |

Upstream HEADs observed during read-only review: `mattpocock/skills@d81f3a183412e71a5b1e84ca21bc1a35eea03a60`, `vercel-labs/skills@3694740352eeef5cdd689af694c485f1ff62eec3`, `stablyai/orca@5fa290fa507403cd417012a6b7a9f2c42366548c`. These are current upstream refs, **not proven installed revisions**. The lock's folder hashes did not equal upstream Git tree hashes; several recorded paths no longer exist at current HEAD. Do not silently refresh skills or invent pins.

## Phase 3 findings — live Pi inventory

- Read-only sources: `/Users/congliu/.pi/agent/settings.json`, `/Users/congliu/.pi/agent/npm/package.json`, and its `package-lock.json`; no credential values were read or returned.
- 18 direct packages are configured. Package-manager lock has exact versions/integrity; manifest uses semver ranges. Against `agents/sources.lock.tsv`, 6 versions match, 11 differ, and `pi-lmstudio@1.5.0` has no repo lock row. This audit lock describes the 2026-09-22 baseline; it is not an installer manifest.
- Owner confirmed retain both `@hypabolic/pi-hypa` and `pi-lmstudio`. Hypa remains an alternate search/file/shell route; LM Studio remains a local-model provider. Its exact npm version/integrity is now in the repo audit lock, with source risks documented in `agents/tool-policy.md`. No live config changed.
- Owner canceled the 3–5 owned-skill quota; retain `implement-spec` and `ship-it`. Fabric repair is deferred, not a prerequisite for these repository checks.
- No configured MCP server was found in `settings.json`; `pi-mcp-adapter` remains installed. No live config changed.

## Phase 4 — closeout

- [x] Run current Bash and macOS Bash 3.2 offline checks on resulting spec changes; both passed.
- [x] Update this checklist/evidence only for verified outcomes; unresolved items remain explicitly pending.
- [x] Report completed work, exact blockers, and whether PR #2 is still open; do not merge, tag, or publish a release.

## Explicitly blocked / out of scope

- [ ] Fresh-machine credentialed model smoke: requires a genuinely separate clean machine/profile and user-owned authentication; do not transplant credentials.
- Claude implicit high-risk skill activation: current probe did not expose the full ship-it contract; require explicit `/ship-it`.
- Third-party installation/update/removal and live Pi/Codex/Claude configuration edits: require per-item user approval.
- PR merge, release tag, visibility changes, and additional branch-rule changes: not authorized by this spec.

## 2026-10-11 continuation

Owner authorized repository-only source/version review and audit-lock updates, not installation, upgrade, removal, or live settings edits.

- `pi-lmstudio@1.5.0`: registry metadata equals local npm lock; downloaded tarball SHA-512 verified; all five published files match installed bytes. Added a high-risk audit-lock row without altering previous baseline versions.
- Read the complete provider implementation. Mocked default discovery, remote Bearer-header handling, and unreachable-server probes passed with filesystem/network stubs. Invalid-entry warning reproduced token logging using a fixture value only; risk is recorded, not patched in installed code.
- No live LM Studio config/token, endpoint, or model was accessed. Source-audited status does not establish current Pi/LM Studio model compatibility.
- Owned-skill quantity target canceled per explicit owner confirmation; setup/hardening specs reflect the revised scope. Historical evidence below remains unchanged.
- Bounded-audit scope revision: owner accepted recording old commits as unknown and avoiding unlimited source-history reconstruction. Rechecked local source metadata: 14 installed third-party skills have source mappings/folder hashes but no recorded commits. Documented unreviewed live package drift; no live files or old version pins changed.
- Verification: `bash scripts/check.sh` and macOS system-PATH `/bin/bash scripts/check.sh` both exited 0; exact lock-row/integrity and scope assertions passed; `git diff --check` passed. Active LSP probes initially reported all three edited Markdown files clean; a final probe covers all four edited Markdown files.

## Bounded-audit closeout verification (2026-10-11)

- Rechecked installed third-party source metadata: all 14 have source mappings and folder hashes, but no recorded installed commit. No source-history reconstruction or live mutation performed.
- Owner-approved scope revision is reflected in all three plans and `agents/tool-policy.md`: unknown old revisions and unreviewed version drift are accepted documented limits, reviewed at the next actual update/restore. No fabricated commit pins or expanded compatibility claims.
- Both current Bash and macOS Bash 3.2 offline checks exited 0; scope/unknown-state assertions and `git diff --check` passed; active LSP diagnostics on the four edited Markdown files returned 0 findings.
- Each plan now has one remaining unchecked acceptance item: independent clean-environment authentication/model smoke. No commit, push, PR merge, or release performed.

## Evidence log

| Date | Step | Evidence | Status |
| --- | --- | --- | --- |
| 2026-09-25 | Baseline | PR #1 merged; ruleset 23949977 active; local clone restore and offline gates previously passed; PR #2 offline check passed at inspection | verified |
| 2026-09-25 | Phase 1 network restore | `git clone --depth 1 --branch main https://github.com/calosliu/agent-skills.git` at `5c1805d`; isolated HOME, no GitHub/provider tokens in child env; check, dry-run, install, offline doctor, reinstall all exit 0; complete HOME snapshot unchanged after reinstall and credential-free; temp clone/HOME removed | verified |
| 2026-09-25 | Phase 2/3 audit + Phase 4 checks | 14 skill docs read; three upstream repos identified; Pi direct dependency inventory compared (6 exact lock matches, 11 version drifts, one untracked package); no live settings changed. Dual-Bash offline checks, `git diff --check`, and spec diagnostics all passed. PR #2 remains OPEN, offline check SUCCESS; closeout spec remains local/untracked | verified with blockers |
| 2026-09-30 | Owner tool decision | User chose to retain `@hypabolic/pi-hypa` and `pi-lmstudio`; no live config change requested or made | verified |
| 2026-09-30 | Plan reconciliation | Reconciled 2020/2021 checklists against recorded evidence; current Bash and macOS Bash 3.2 checks passed, all three plan diagnostics clean. Exact third-party pins, owned-workflow selection, and authenticated clean-machine smoke remain open | verified with blockers |
