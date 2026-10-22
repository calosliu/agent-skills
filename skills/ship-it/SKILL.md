---
name: ship-it
description: Commits the current changes, pushes them on a feature branch, and optionally creates or reuses a GitHub pull request. Use when the user says ship it, asks to commit and push, or requests 提交、推送、提交并推送。
---

# Ship it

Complete commit → branch push by default, adding a PR only when asked or required by project policy, without merging or deploying.
Use the current harness's native tools; no plugin is required.

## Contract

- Input: agreed change scope plus optional repository, base, push remote, branch, commit message, and draft preference.
- Prerequisites: a Git worktree, Git, an authenticated `gh` account with **write** access to the target repository, a resolvable writable remote, and project checks.
- Side effects: may create a feature branch and commit, push that branch, and — only when requested or required by policy — create or reuse one PR.
- Stop conditions and required completion output are defined below; any unresolved destination, scope, secret, conflict, auth failure, or failed mandatory check blocks later writes.

## Authorization and boundaries

- An explicit request to run `ship-it` authorizes the whole sequence for the agreed changes: inspect, branch, commit, push, plus a PR when asked or required. Carry it out end to end without re-asking for steps it already covers; report the branch, remote, and base as you resolve them. Writing/discussing this skill does not authorize anything.
- Honor narrower requests such as commit-only, push-only, or draft PR. When the user says "current changes" without naming paths, the agreed scope is the whole reviewed working tree.
- Preserve changes outside the agreed scope. Stage exactly that scope: `git add -- <reviewed-paths>` for named paths, or `git add -A` for an explicit whole-worktree scope, after reviewing the staged diff for secrets and out-of-scope files. Never stage credentials, tokens, runtime databases, or session data even when in scope. If unrelated changes are already staged, ask before changing the index or committing.
- Never force-push, amend existing commits, bypass hooks/checks, reset, clean, stash, or rewrite history to make shipping succeed. Do not merge the PR, publish releases, change visibility, or deploy.
- Stop on secrets, unresolved conflicts, ambiguous scope/destination, or failed commands. Report completed steps and the blocker; do not proceed to later write steps.

## Workflow

### 1. Inspect and resolve destinations

- Read project instructions and PR templates. Inspect `git status --short --branch`, unstaged/staged diffs, relevant untracked files, current branch, remotes, and recent commit conventions. Do not print secret contents.
- Check Git and `gh` availability and `gh auth status` for the target host. If missing or unauthenticated, stop with setup instructions; never install tools or change credentials silently.
- Confirm that account can write to the target repository: `gh api repos/<owner>/<repo> -q .permissions` (needs `push`, or owner). A read-only token returns `404` on every write and can report stale merge state, such as `BLOCKED`, on an otherwise clean PR. If the write-capable account is not active, select it explicitly; do not switch accounts silently or borrow another owner's token without being asked.
- Resolve the target GitHub repository, base branch, writable push remote, and head owner. For the base, use the user's choice, existing PR base, then repository default; a feature branch's tracking upstream is not its PR base. Use the user's chosen push remote or verified branch tracking remote; do not assume `origin` or `main`. Ask if ambiguous, including forks.
- Fetch the relevant remotes without changing the working tree. Inspect the full branch diff and commits relative to the intended base, plus local commits not on the push destination. All of these may be published, not just the next commit; stop if any are outside the agreed scope.
- Detached HEAD, unfinished merge/rebase/cherry-pick, or a missing base branch requires clarification before writes.

### 2. Use a feature branch

- Reuse an appropriate current feature branch. On the base/default/protected branch, create a descriptive, unused branch with `git switch -c <branch>` before committing. Never push directly to those branches.
- Preserve existing edits. If switching cannot proceed safely, stop rather than discarding or stashing work. Pick a descriptive, unused branch name and continue; ask only when the remote, base, or fork target is genuinely ambiguous.

### 3. Validate and commit

- Run the project's required checks plus targeted checks for these changes. Record actual results; if checks fail or cannot run, stop before commit/push unless the user explicitly accepts the stated limitation. Never bypass mandatory checks or hooks.
- Stage exactly the agreed scope with `git add -- <reviewed-paths>` (or `git add -A` for a whole-worktree scope) or an available hunk-staging tool. Never blanket-stage files the scope excludes; review `git diff --cached` for scope and secrets; run `git diff --cached --check`.
- If the index has changes, commit with a concise message matching repository conventions: `git commit -m <message>`. Inspect the resulting commit and status. If hooks changed files or failed, review and revalidate before retrying; do not blindly restage or amend.
- If there is nothing new to commit, skip commit; an existing branch may still need pushing or a PR. If there is also no difference from the base, report nothing to ship and stop.
- Before pushing, ensure all intended changes are committed and the outgoing history/diff matches the agreed scope. Leave unrelated local edits alone and report them.

### 4. Push

With `remote` and `branch` resolved above, push only the feature branch:

```sh
git push --no-follow-tags --set-upstream "$remote" "HEAD:refs/heads/$branch"
```

If rejected, stop and explain; do not force, auto-merge, or auto-rebase. Verify the destination ref matches local HEAD with `git ls-remote --heads "$remote" "refs/heads/$branch"` and `git rev-parse HEAD`. A mismatch or verification error blocks PR creation.

### 5. Create or reuse the PR (only when requested or required)

If no PR was asked for and project policy does not require one, skip this step and report the pushed branch instead.

- Query `gh pr list --repo "$repo" --head "$branch" --state open --json number,url,baseRefName,headRefName,headRepositoryOwner`. Verify the head owner and base, not just the branch name. Reuse a matching open PR and return its URL; if an existing PR targets a different base or the result is ambiguous, ask rather than creating a duplicate or retargeting it.
- Query errors are not an empty result. If no matching open PR exists, prepare a concise title and body covering summary, checks/results, and risks or unverified behavior. Follow the repository PR template; do not invent issue links or claim unrun tests passed.
- Set `repo` to the explicit target repository (`HOST/OWNER/REPO` if needed), `base` to the chosen base, and `head` to the branch (or `owner:branch` for a fork). Write the body to a temporary file outside the worktree to avoid shell quoting/interpolation mistakes, then create:

```sh
gh pr create --repo "$repo" --base "$base" --head "$head" --title "$title" --body-file "$body_file"
```

- Add `--draft` only when requested or required by project policy. Remove only the temporary body file you created. If creation errors or times out, query again before retrying: the PR may already exist. Preserve successful commit/push results; never roll them back automatically.
- Verify the returned PR URL, head/base, and open state with `gh pr view --repo "$repo" <number> --json url,state,baseRefName,headRefName,headRepositoryOwner`. Report any mismatch as incomplete, not success.

## Completion

Return commit SHA (or commit skipped), pushed remote/branch, PR URL (created/reused), checks run, and any remaining local changes or blockers. Do not equate a successful push with passing CI.

Example: “Ship it: commit the login fix, push a feature branch, and create a PR against develop.”
