# Maintenance

Use event-driven maintenance. Do not schedule work that has no changed dependency, security signal, or release need.

## Agent, package, or action update

1. Read release notes and source diff from the locked version.
2. Confirm capability, owner, risk, removal criterion, and whether an existing tool should be removed.
3. Update exact version/commit, source, integrity, risk, and review date in `agents/sources.lock.tsv`.
4. Run `bash scripts/check.sh`, `bash scripts/doctor.sh`, and affected model cases.
5. Update support/evidence only after observed behavior passes. Never claim one model's result for all models.

## New skill or tool

- State concrete unmet workflow and why native/current routes do not cover it.
- For skills, add contract plus positive, negative, and outcome cases.
- For executable tools, review source and exact pin before enablement; no-growth budget means overlapping tools replace rather than accumulate.
- For remote MCP, document operator, data sent, scopes, auth storage, write tools, revocation, and removal before connection.
- Remove the component when its workflow disappears or a default route supersedes it.

## Security advisory

Disable affected optional capability first. Preserve evidence without secret values, review upstream fix/diff, update the lock, then run offline and targeted safety cases before re-enabling.

## Release checklist

A reviewed baseline/tag requires all of:

- clean `bash scripts/check.sh` under current Bash and macOS Bash 3.2;
- clean `bash scripts/doctor.sh` against canonical agent homes;
- successful fresh-checkout/temp-HOME dry-run, install, doctor, uninstall/reinstall;
- green read-only CI and active default-branch ruleset requiring its exact check name;
- verified repository secret-protection status;
- current support matrix and source lock;
- supported-agent instruction/skill smokes;
- 3/3 independently recreated outcomes for every high-risk release case;
- reviewed diff/secret scan and no unresolved blockers in active `.spec/` files.

Do not tag while any required item is blocked. Add a changelog only after a second release creates useful history.

## Quarterly quiet-period check

Only when no triggering update occurred: run doctor, inspect stale pins/links, confirm default-branch rules and credential hygiene, then record date/result in the active evidence log. No ceremony beyond that.

## Rollback

Checkout the previous reviewed commit/tag, dry-run installer, review targets, install, then doctor. Remove only confirmed stale links and managed blocks. Never delete whole agent homes, credentials, settings, or unrelated instruction text.
