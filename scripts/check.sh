#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
bash -n "$repo/scripts/install.sh" "$repo/scripts/check.sh" "$repo/scripts/doctor.sh"
# ponytail: this repo uses unquoted, single-line name/description fields, not arbitrary YAML.
shopt -s nullglob
skills=("$repo"/skills/*)
[[ ${#skills[@]} -gt 0 ]] || fail 'No owned skills found'
for skill in "${skills[@]}"; do
  name=${skill##*/}
  [[ -d "$skill" && ! -L "$skill" && -f "$skill/SKILL.md" ]] || fail "Invalid skill: $skill"
  [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ && ${#name} -le 64 ]] || fail "Invalid name: $name"
  awk -v expected="$name" '
    NR == 1 { if ($0 != "---") exit 1; next }
    $0 == "---" { closed=1; exit }
    /^name: / { names++; if (substr($0,7) != expected) bad=1 }
    /^description: / {
      descriptions++; text=substr($0,14)
      if (length(text) > 1024 || text !~ /[^[:space:]]/ || text !~ /Use when/) bad=1
    }
    END { if (!closed || bad || names != 1 || descriptions != 1) exit 1 }
  ' "$skill/SKILL.md" || fail "Invalid skill metadata: $name"
done

lock=$repo/agents/sources.lock.tsv
check_source_lock() {
  awk -F '\t' '
    NR == 1 { if ($0 != "kind\tname\tsource\texact_version_or_commit\tintegrity\trisk\treviewed_at") exit 1; next }
    NF != 7 || $1 !~ /^(npm|cli|git|local)$/ || $2 == "" || ($3 !~ /^https:/ && $3 !~ /^git[+]https:/) || $4 == "" || $5 == "" || $6 !~ /^(low|medium|high|critical)$/ || $7 !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ { exit 1 }
    $1 == "npm" && ($4 !~ /^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$/ || $5 !~ /^sha512-/) { exit 1 }
    $1 != "npm" && $5 !~ /^(sha256-|sha512-)/ && index($5, "n/a-") != 1 { exit 1 }
    $1 == "git" && (length($4) != 40 || $4 !~ /^[0-9a-f]+$/) { exit 1 }
    index($3, "/Users/") || index($3, "/home/") || $0 ~ /(token|password|api[_-]?key)[[:space:]]*=/ { exit 1 }
    seen[$1 "\t" $2]++ { if (seen[$1 "\t" $2] > 1) exit 1 }
    END { if (NR < 2) exit 1 }
  ' "$1"
}
if [[ ! -f "$lock" ]] || ! check_source_lock "$lock"; then fail 'Invalid source lock'; fi

model_cases=$repo/tests/model-cases.tsv
model_results=$repo/tests/model-results.tsv
awk -F '\t' '
  NR == 1 { if ($0 != "id\trisk\tagents\tsetup\tprompt\tgrader\trepetitions") exit 1; next }
  NF != 7 || $1 == "" || $2 !~ /^(low|medium|high)$/ || $3 !~ /^(pi|codex|claude)(,(pi|codex|claude))*$/ || $4 == "" || $5 == "" || $6 == "" || $7 !~ /^[1-3]$/ { exit 1 }
  $2 == "high" && $7 != 3 { exit 1 }
  seen[$1]++ { if (seen[$1] > 1) exit 1 }
  END { if (NR - 1 < 6 || NR - 1 > 8) exit 1 }
' "$model_cases" || fail 'Invalid model case manifest'
awk -F '\t' -v cases="$model_cases" '
  BEGIN { while ((getline line < cases) > 0) { split(line, f, "\t"); if (f[1] != "id") valid[f[1]]=1 } }
  NR == 1 { if ($0 != "repository_commit\tagent_version\tmodel\tconfig_profile\tcase_id\tresult\tgrader\tduration_cost\tfailure_reason\trun_at") exit 1; next }
  NF != 10 || !valid[$5] || $6 !~ /^(pass|fail|blocked)$/ || $10 !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ { exit 1 }
' "$model_results" || fail 'Invalid model result ledger'
printf 'PASS model eval case/result schemas and cross-references\n'

cases=$repo/tests/skill-cases.tsv
[[ -f "$cases" ]] || fail 'Missing skill case manifest'
awk -F '\t' '
  NR == 1 { if ($0 != "id\tskill\tkind\tprompt\texpected\tforbidden") exit 1; next }
  NF != 6 || $1 == "" || $2 == "" || $3 !~ /^(trigger-positive|trigger-negative|outcome)$/ || $4 == "" || $5 == "" || $6 == "" { exit 1 }
  seen[$1]++ { if (seen[$1] > 1) exit 1 }
  END { if (NR < 2) exit 1 }
' "$cases" || fail 'Invalid skill case manifest'
for skill in "${skills[@]}"; do
  name=${skill##*/}
  grep -Fq '## Contract' "$skill/SKILL.md" || fail "Missing contract: $name"
  grep -Fq '## Completion' "$skill/SKILL.md" || fail "Missing completion contract: $name"
  ! grep -Eq '/Users/|/home/[A-Za-z0-9._-]+/' "$skill/SKILL.md" || fail "Machine path in skill: $name"
  ! find "$skill" -type l | grep -q . || fail "Symlink inside skill: $name"
  while IFS= read -r resource; do
    relative=${resource#"$skill/"}
    grep -Fq "$relative" "$skill/SKILL.md" || fail "Unreferenced skill resource: $name/$relative"
  done < <(find "$skill" -type f ! -name SKILL.md)
  for kind in trigger-positive trigger-negative outcome; do
    grep -Eq "^[^[:space:]]+${tab:-$(printf '\t')}$name${tab:-$(printf '\t')}$kind${tab:-$(printf '\t')}" "$cases" || fail "Missing $kind case: $name"
  done
done
printf 'PASS skill metadata, contracts, resources, and case manifest\n'

tmp=$(mktemp -d "${TMPDIR:-/tmp}/agent-skills-check.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

check_repository_safety() {
  local root=$1 files
  files=$(find "$root" -type f \( -path "$root/agents/*" -o -path "$root/docs/*" -o -path "$root/instructions/*" -o -path "$root/skills/*" -o -path "$root/scripts/*" -o -name AGENTS.md -o -name README.md \))
  if [[ -n "$files" ]] && xargs grep -Eil '(api[_-]?key|access[_-]?token|client[_-]?secret|password)[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9_./+=-]{16,}' < <(printf '%s\n' "$files") >/dev/null; then return 1; fi
  if find "$root/agents" -type f \( -name '*.json' -o -name '*.toml' \) -exec grep -El '/Users/|/home/[A-Za-z0-9._-]+/' {} + | grep -q .; then return 1; fi
  if find "$root/agents" -type f \( -name '*.json' -o -name '*.toml' \) -exec grep -Ei 'danger-full-access|dangerously-skip-permissions|bypassPermissions|approval_policy[[:space:]]*=[[:space:]]*"never"|defaultProjectTrust[[:space:]]*"?:[[:space:]]*"trusted"|trust_level[[:space:]]*=[[:space:]]*"trusted"' {} + | grep -q .; then return 1; fi
}
check_repository_safety "$repo" || fail 'Credential, machine path, trust override, or unsafe example found'
bad_lock=$tmp/bad-sources.lock.tsv
cp "$lock" "$bad_lock"
printf 'npm\tbad\thttps://example.invalid\t^1.0.0\tmissing\thigh\t2026-09-22\n' >> "$bad_lock"
check_source_lock "$bad_lock" && fail 'Unpinned source-lock fixture accepted'
printf 'PASS source lock syntax, exact npm pins, integrity, and negative fixture\n'
unsafe=$tmp/unsafe
mkdir -p "$unsafe/agents"
credential_name=api_key credential_value=abcdefghijklmnop1234
printf '%s = "%s"\n' "$credential_name" "$credential_value" > "$unsafe/README.md"
check_repository_safety "$unsafe" && fail 'Credential fixture accepted'
rm "$unsafe/README.md"
printf 'path = "/Users/example/private"\n' > "$unsafe/agents/bad.toml"
check_repository_safety "$unsafe" && fail 'Machine path fixture accepted'
printf 'sandbox_mode = "danger-full-access"\n' > "$unsafe/agents/bad.toml"
check_repository_safety "$unsafe" && fail 'Unsafe mode fixture accepted'
printf 'PASS repository safety policy and negative fixtures\n'

checkout="$tmp/checkout with spaces"
mkdir -p "$checkout"
checkout=$(cd -- "$checkout" && pwd -P)
cp -R "$repo/scripts" "$repo/instructions" "$repo/skills" "$repo/agents" "$checkout/"
export HOME="$tmp/home with spaces"
unset PI_CODING_AGENT_DIR CODEX_HOME CLAUDE_CONFIG_DIR
install="$checkout/scripts/install.sh"
begin='<!-- agent-skills:begin -->'
end='<!-- agent-skills:end -->'

run_install() { bash "$install" "$@" > "$tmp/install.log" 2>&1 || { cat "$tmp/install.log" >&2; fail 'Installation failed'; }; }
expect_failure() {
  if bash "$install" "$@" > "$tmp/failure.log" 2>&1; then fail 'Expected installer failure'; fi
}
assert_install() {
  local pi_dir=${PI_CODING_AGENT_DIR-"$HOME/.pi/agent"}
  local codex_dir=${CODEX_HOME-"$HOME/.codex"}
  local claude_dir=${CLAUDE_CONFIG_DIR-"$HOME/.claude"}
  local dir file kind rule name skill target
  for dir in "$pi_dir" "$codex_dir" "$claude_dir"; do
    file=$dir/AGENTS.md kind=agents
    [[ "$dir" != "$claude_dir" ]] || { file=$dir/CLAUDE.md; kind=claude; }
    [[ -f "$file" && ! -L "$file" ]] || fail "Instruction file is not regular: $file"
    [[ $(grep -Fxc "$begin" "$file") == 1 && $(grep -Fxc "$end" "$file") == 1 ]] || fail "Expected exactly one managed block: $file"
    for rule in "$checkout"/instructions/*.md; do
      name=${rule##*/}
      target="$dir/agent-skills-$name"
      [[ -L "$target" && -f "$target" && "$(readlink "$target")" == "$rule" ]] || fail "Bad rule link: $target"
      if [[ "$kind" == claude ]]; then
        grep -Fqx -- "@$target" "$file" || fail "Missing Claude import: $name"
      else
        grep -Fq -- "- ${name%.md} absolute path: $target" "$file" || fail "Missing absolute reference: $name"
      fi
      cmp -s "$rule" "$target" || fail 'Rule reference resolves to wrong content'
    done
  done
  for skill in "$checkout"/skills/*; do
    for target in "$HOME/.agents/skills/${skill##*/}" "$claude_dir/skills/${skill##*/}"; do
      [[ -L "$target" && -f "$target/SKILL.md" && "$(readlink "$target")" == "$skill" ]] || fail "Bad skill link: $target"
    done
  done
}

run_install --dry-run
[[ ! -e "$HOME" ]] || fail 'Dry-run created home'
printf 'PASS dry-run creates nothing\n'

mkdir -p "$HOME/.codex"
# Broken, duplicate, reversed, and inline markers must not cause partial changes.
for text in "$begin" "$end" "$begin"$'\n'"$end"$'\n'"$begin"$'\n'"$end" "$end"$'\n'"$begin" "inline $begin"$'\n'"$end"; do
  printf '%s' "$text" > "$HOME/.codex/AGENTS.md"
  cp "$HOME/.codex/AGENTS.md" "$tmp/before"
  expect_failure
  grep -q 'markers\|Markers' "$tmp/failure.log" || fail 'Wrong marker error'
  cmp -s "$tmp/before" "$HOME/.codex/AGENTS.md" || fail 'Malformed file changed'
  [[ ! -e "$HOME/.pi" && ! -e "$HOME/.agents" ]] || fail 'Marker conflict caused partial install'
  expect_failure --dry-run
  cmp -s "$tmp/before" "$HOME/.codex/AGENTS.md" || fail 'Conflicting dry-run changed file'
done
printf 'bad\000text' > "$HOME/.codex/AGENTS.md"
expect_failure
[[ ! -e "$HOME/.pi" ]] || fail 'Binary text caused partial install'
rm "$HOME/.codex/AGENTS.md"
printf 'PASS malformed/duplicate markers and NUL bytes rejected without writes\n'

printf 'external\n' > "$tmp/external"
for destination in "$tmp/external" "$tmp/missing"; do
  ln -s "$destination" "$HOME/.codex/AGENTS.md"
  expect_failure
  [[ "$(readlink "$HOME/.codex/AGENTS.md")" == "$destination" && ! -e "$HOME/.pi" ]] || fail 'AGENTS.md symlink changed'
  rm "$HOME/.codex/AGENTS.md"
done
[[ "$(cat "$tmp/external")" == external ]] || fail 'External target modified'
mkdir "$HOME/.codex/AGENTS.md"
expect_failure
rmdir "$HOME/.codex/AGENTS.md"
mkdir -p "$HOME/.claude"
ln -s "$tmp/missing" "$HOME/.claude/CLAUDE.md"
expect_failure
[[ -L "$HOME/.claude/CLAUDE.md" && ! -e "$HOME/.pi" ]] || fail 'CLAUDE.md symlink changed'
rm "$HOME/.claude/CLAUDE.md"
printf 'PASS instruction-file directories and live/broken symlinks preserved\n'

rule_link="$HOME/.codex/agent-skills-communication.md"
printf 'existing rule' > "$rule_link"
expect_failure
[[ "$(cat "$rule_link")" == 'existing rule' && ! -e "$HOME/.pi" ]] || fail 'Conflicting rule changed'
rm "$rule_link"
ln -s "$tmp/missing" "$rule_link"
expect_failure
[[ -L "$rule_link" && ! -e "$HOME/.pi" ]] || fail 'Conflicting rule symlink changed'
rm "$rule_link"
mkdir -p "$HOME/.agents/skills/${skills[0]##*/}"
expect_failure
[[ ! -e "$HOME/.pi" && ! -e "$HOME/.codex/AGENTS.md" ]] || fail 'Skill conflict caused partial changes'
rmdir "$HOME/.agents/skills/${skills[0]##*/}"
mkdir -p "$HOME/.pi"
printf 'not a directory' > "$HOME/.pi/agent"
expect_failure
[[ ! -e "$HOME/.codex/AGENTS.md" ]] || fail 'Parent conflict caused partial changes'
rm "$HOME/.pi/agent"
printf 'PASS rule/skill conflicts and non-directory parents rejected before writes\n'

printf 'existing\r\nno final newline' > "$HOME/.codex/AGENTS.md"
chmod 640 "$HOME/.codex/AGENTS.md"
cp -p "$HOME/.codex/AGENTS.md" "$tmp/original"
printf 'local settings\n' > "$HOME/.codex/config.toml"
mkdir -p "$HOME/.agents/skills/unmanaged" "$HOME/.claude/skills/unmanaged"
printf 'keep\n' > "$HOME/.agents/skills/unmanaged/sentinel"
printf 'keep claude\n' > "$HOME/.claude/skills/unmanaged/sentinel"
run_install --dry-run
cmp -s "$tmp/original" "$HOME/.codex/AGENTS.md" || fail 'Dry-run changed existing instructions'
[[ ! -e "$HOME/.pi/agent" ]] || fail 'Dry-run created links'
run_install
assert_install
head -c "$(wc -c < "$tmp/original" | tr -d ' ')" "$HOME/.codex/AGENTS.md" | cmp -s - "$tmp/original" || fail 'Append changed original bytes'
backups=("$HOME"/.codex/AGENTS.md.backup.*)
[[ ${#backups[@]} == 1 ]] || fail 'Missing backup'
cmp -s "$tmp/original" "${backups[0]}" || fail 'Backup differs'
[[ "$(find "$HOME/.codex/AGENTS.md" -type f -perm 640)" == "$HOME/.codex/AGENTS.md" ]] || fail 'Permissions changed'
[[ "$(cat "$HOME/.codex/config.toml")" == 'local settings' && "$(cat "$HOME/.agents/skills/unmanaged/sentinel")" == keep && "$(cat "$HOME/.claude/skills/unmanaged/sentinel")" == 'keep claude' ]] || fail 'Unmanaged content changed'
printf 'PASS creation, append, exact backup, mode preservation, spaces, and resolved references\n'

find "$HOME" \( -type f -o -type l \) -exec ls -di {} \; | sort > "$tmp/inodes-before"
cp "$HOME/.codex/AGENTS.md" "$tmp/installed"
run_install
assert_install
find "$HOME" \( -type f -o -type l \) -exec ls -di {} \; | sort > "$tmp/inodes-after"
cmp -s "$tmp/inodes-before" "$tmp/inodes-after" || fail 'Rerun replaced files or added backups'
cmp -s "$tmp/installed" "$HOME/.codex/AGENTS.md" || fail 'Rerun changed contents'
printf 'PASS idempotent rerun: unchanged files, links, contents, and backups\n'

# Preserve prefix/suffix byte-for-byte while replacing only the old managed section.
printf 'prefix\r\n%s\r\nobsolete\r\n%s\r\nsuffix without newline' "$begin" "$end" > "$HOME/.codex/AGENTS.md"
block="$begin"$'\n## Shared personal instructions\n\nRead and follow every rule file below before starting work. Each line contains an exact absolute path; do not resolve it against the project working directory. If a file cannot be read, report it rather than silently skipping it.\n'
for rule in "$checkout"/instructions/*.md; do
  name=${rule##*/}
  block+=$'\n'"- ${name%.md} absolute path: $HOME/.codex/agent-skills-$name"
done
block+=$'\n'"$end"
printf 'prefix\r\n%s\r\nsuffix without newline' "$block" > "$tmp/expected"
run_install
cmp -s "$tmp/expected" "$HOME/.codex/AGENTS.md" || fail 'Replacement changed outside bytes'
printf 'PASS managed-section replacement preserves CRLF and missing final newline outside section\n'

printf '\nUpdated rule content.\n' >> "$checkout/instructions/workflow.md"
cmp -s "$checkout/instructions/workflow.md" "$HOME/.codex/agent-skills-workflow.md" || fail 'Rule update not visible via link'
printf '# Added rule\n' > "$checkout/instructions/added.md"
run_install
grep -Fq -- "- added absolute path: $HOME/.codex/agent-skills-added.md" "$HOME/.codex/AGENTS.md" || fail 'New rule not referenced'
[[ -L "$HOME/.codex/agent-skills-added.md" ]] || fail 'New rule not linked'
rm "$checkout/instructions/added.md"
run_install
! grep -Fq -- '- added absolute path:' "$HOME/.codex/AGENTS.md" || fail 'Removed rule still referenced'
printf 'PASS source edits visible immediately; adding/removing rules refreshes reference list\n'

export HOME="$tmp/custom home" PI_CODING_AGENT_DIR="$tmp/custom pi" CODEX_HOME="$tmp/custom codex" CLAUDE_CONFIG_DIR="$tmp/custom claude"
run_install
assert_install
[[ ! -e "$HOME/.pi" && ! -e "$HOME/.codex" && ! -e "$HOME/.claude" ]] || fail 'Custom homes ignored'
export HOME="$tmp/shared home" PI_CODING_AGENT_DIR="$tmp/shared agent" CODEX_HOME="$tmp/shared agent" CLAUDE_CONFIG_DIR="$tmp/shared claude"
run_install
assert_install
printf 'PASS custom agent homes, including shared AGENTS destination and Claude adapter\n'
if CODEX_HOME=relative bash "$install" > "$tmp/invalid.log" 2>&1; then fail 'Relative home accepted'; fi
if CODEX_HOME='' bash "$install" > "$tmp/invalid.log" 2>&1; then fail 'Empty home accepted'; fi
if CLAUDE_CONFIG_DIR=relative bash "$install" > "$tmp/invalid.log" 2>&1; then fail 'Relative Claude home accepted'; fi
if CLAUDE_CONFIG_DIR='' bash "$install" > "$tmp/invalid.log" 2>&1; then fail 'Empty Claude home accepted'; fi
expect_failure --unknown
expect_failure --dry-run extra
expect_failure --help extra
printf 'PASS invalid homes and arguments rejected\n'

export HOME="$tmp/restore home"
export PI_CODING_AGENT_DIR="$HOME/.pi/agent" CODEX_HOME="$HOME/.codex" CLAUDE_CONFIG_DIR="$HOME/.claude"
run_install --dry-run
run_install
assert_install
bash "$checkout/scripts/doctor.sh" --offline > "$tmp/doctor.log" 2>&1 || { cat "$tmp/doctor.log" >&2; fail 'Offline doctor rejected fresh install'; }
unlink "$HOME/.codex/agent-skills-safety.md"
if bash "$checkout/scripts/doctor.sh" --offline > "$tmp/doctor-broken.log" 2>&1; then fail 'Doctor accepted broken rule link'; fi
ln -s "$checkout/instructions/safety.md" "$HOME/.codex/agent-skills-safety.md"
for dir in "$PI_CODING_AGENT_DIR" "$CODEX_HOME"; do
  rm "$dir/AGENTS.md"
  for rule in "$checkout"/instructions/*.md; do unlink "$dir/agent-skills-${rule##*/}"; done
done
rm "$CLAUDE_CONFIG_DIR/CLAUDE.md"
for rule in "$checkout"/instructions/*.md; do unlink "$CLAUDE_CONFIG_DIR/agent-skills-${rule##*/}"; done
for skill in "$checkout"/skills/*; do
  unlink "$HOME/.agents/skills/${skill##*/}"
  unlink "$CLAUDE_CONFIG_DIR/skills/${skill##*/}"
done
run_install
assert_install
bash "$checkout/scripts/doctor.sh" --offline > "$tmp/doctor-reinstall.log" 2>&1 || { cat "$tmp/doctor-reinstall.log" >&2; fail 'Doctor rejected reinstall'; }
printf 'PASS isolated dry-run, install, doctor, broken-link failure, uninstall, and reinstall\n'
printf 'PASS all offline checks; model-backed reading of referenced rules remains a separate smoke test.\n'
