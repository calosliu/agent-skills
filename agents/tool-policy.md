# Tool and MCP policy

This repository installs no agent runtime, extension, MCP server, or external CLI. [`sources.lock.tsv`](sources.lock.tsv) records the supported smoke baseline plus separately dated source audits; it is an audit lock, not an install manifest. A reviewed artifact does not imply current-runtime/model compatibility.

## Capability routes

Use one default route per job. Alternatives stay optional and should be disabled when unused.

| Capability | Default route | Side effects | Decision |
| --- | --- | --- | --- |
| Repository text search | `pi-fff` | local read | Default fast text route |
| Typed code navigation/diagnostics | `pi-lens` | local read | Default semantic route |
| Large command/output processing | `context-mode` | local process; command-dependent | Use only for bounded output reduction |
| Web research | `pi-web-access` | network read; may send queries | Enable only when current external information is required |
| Tool orchestration | `pi-fabric` | inherits called tool authority | Keep calls explicit and bounded |
| Delegation | `pi-subagents` | inherits delegated tools/context | Use only for separable work with acceptance criteria |
| Persistent memory | `pi-hermes-memory` | durable local write | Store no credentials or one-off state |
| MCP bridge | `pi-mcp-adapter` | server-dependent, potentially remote write | No server is trusted merely because metadata advertises it |
| UI/style/context helpers | powerline, context usage/prune, smart compact, caveman, ponytail | local/session | Optional; remove when unused |
| Alternate search/sync | Hypa, Pi Sync | local/network varies | Non-default; require task-specific need |
| Local-model provider | `pi-lmstudio` | automatic model discovery; configured server receives prompts and optional Bearer token | Owner retained; optional, source-audited only |

The original smoke baseline contains 17 observed Pi extensions. The owner retained an already-installed eighteenth extension, `pi-lmstudio`, separately source-audited on 2026-10-11; this repository installs none of them. Budget is **no growth**: adding one requires a concrete missing capability, source review, exact lock entry, acceptance case, and removal criterion; overlapping additions should replace an existing route. Core repository checks and installation must still work with every optional extension absent.

## External CLIs

- Bash and Git are required for offline checks/installation.
- Pi, Codex, and Claude are required only for their respective manual smoke claims.
- `gh` is required only for `ship-it` and read-only GitHub audits.
- Owners update tools outside this repository. Updating a support claim requires release-note/source diff review, lock update, offline checks, and targeted model smoke.

## MCP and hooks

No MCP server or hook is installed, configured, or enabled by this repository. Machine-local MCP/hook configuration remains outside version control and outside current support claims. Before enabling a remote MCP, record operator, exact server/version, data sent, requested scopes, auth storage, write-capable tools, revocation procedure, owner, and removal criterion. Reject token passthrough, wildcard scopes, silent consent, and metadata changes that have not been reviewed.

## Removal

Remove optional tools from live agent configuration first, start a fresh session, and run `bash scripts/check.sh` plus affected smoke cases. Then remove their lock row in the same reviewed change. Do not retain inactive entries “for later.” Never delete agent homes or credential stores as an uninstall shortcut.

## LM Studio source audit (2026-10-11)

- Owner: repository owner; retain `pi-lmstudio@1.5.0` for LM Studio models. Remove from live configuration only on owner request when this provider is no longer used.
- npm registry metadata and the downloaded tarball SHA-512 match the installed package lock. All five published files match the installed files byte-for-byte. Read the complete provider implementation; no lifecycle scripts are declared in the published manifest.
- Discovery runs at extension initialization and after an assistant message, not only when a model is selected. Default endpoint is loopback; configured remote endpoints receive discovery requests and, when used for inference, conversation/model input. Keep tokens local and use HTTPS for remote servers.
- Confirmed risk: an invalid server entry missing `name` or `url` is logged with the entire entry, potentially including its token. Avoid credential-bearing malformed entries; do not publish those warnings. No live credentials/configuration were inspected or changed.
- Mocked probes passed default discovery, configured remote Bearer-header handling, and unreachable-server behavior; a fixture token reproduced the logging risk. These are isolated behavior checks, not live LM Studio or Pi compatibility/model smoke.
- Registry `gitHead` is metadata, not an independently verified installed Git commit. The exact npm version plus verified tarball integrity is the reproducible artifact identity.

## Accepted provenance limits

Owner chose bounded, event-driven auditing rather than reconstructing every old installation. All 14 currently installed third-party skills have source mappings and folder hashes, but their installed Git commits are **unknown**. Do not put these hashes or current upstream HEADs into commit-pin fields. Keep them outside reproducible Git lock rows; review and pin the selected source when an actual update or restore is requested. No full restoration claim covers these existing snapshots.

The version rows already reviewed are a historical baseline, not a claim that all live executable versions remain reviewed or identical. Observed version drift is **not yet source-reviewed**; do not silently advance pins to match local installations. Review release/source changes and targeted checks at the next requested update or recovery. Fabric repair remains deferred.

Machine-local Orca components and remote MCP endpoints remain outside support claims until source/version and data boundaries are audited. These documented unknowns are accepted limitations for the current repository-only audit scope, not successful verification or permission to install/update tools.
