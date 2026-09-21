# Tool and MCP policy

This repository installs no agent runtime, extension, MCP server, or external CLI. [`sources.lock.tsv`](sources.lock.tsv) records the exact versions observed during the supported smoke baseline; it is an audit lock, not an install manifest.

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

Baseline contains 17 observed Pi extensions. Budget is **no growth**: adding one requires a concrete missing capability, source review, exact lock entry, acceptance case, and removal criterion; overlapping additions should replace an existing route. Core repository checks and installation must still work with every optional extension absent.

## External CLIs

- Bash and Git are required for offline checks/installation.
- Pi, Codex, and Claude are required only for their respective manual smoke claims.
- `gh` is required only for `ship-it` and read-only GitHub audits.
- Owners update tools outside this repository. Updating a support claim requires release-note/source diff review, lock update, offline checks, and targeted model smoke.

## MCP and hooks

No MCP server or hook is installed, configured, or enabled by this repository. Machine-local MCP/hook configuration remains outside version control and outside current support claims. Before enabling a remote MCP, record operator, exact server/version, data sent, requested scopes, auth storage, write-capable tools, revocation procedure, owner, and removal criterion. Reject token passthrough, wildcard scopes, silent consent, and metadata changes that have not been reviewed.

## Removal

Remove optional tools from live agent configuration first, start a fresh session, and run `bash scripts/check.sh` plus affected smoke cases. Then remove their lock row in the same reviewed change. Do not retain inactive entries “for later.” Never delete agent homes or credential stores as an uninstall shortcut.

## Known blockers

Third-party installed skills have provenance folder hashes but not reviewed upstream commit pins, so they are not represented as reproducible Git rows. Review source and pin an upstream commit before adding one. Machine-local Orca components and remote MCP endpoints are likewise excluded until their exact source/version and data boundary can be audited.
