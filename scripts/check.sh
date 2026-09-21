#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
bash -n "$repo/scripts/install.sh" "$repo/scripts/check.sh"
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
printf 'PASS skill metadata and unique names\n'

tmp=$(mktemp -d "${TMPDIR:-/tmp}/agent-skills-check.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
checkout="$tmp/checkout with spaces"
mkdir -p "$checkout"
checkout=$(cd -- "$checkout" && pwd -P)
cp -R "$repo/scripts" "$repo/instructions" "$repo/skills" "$checkout/"
export HOME="$tmp/home with spaces"
unset PI_CODING_AGENT_DIR CODEX_HOME
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
  local dir rule name skill target
  for dir in "$pi_dir" "$codex_dir"; do
    [[ -f "$dir/AGENTS.md" && ! -L "$dir/AGENTS.md" ]] || fail 'AGENTS.md is not a regular file'
    [[ $(grep -Fxc "$begin" "$dir/AGENTS.md") == 1 && $(grep -Fxc "$end" "$dir/AGENTS.md") == 1 ]] || fail 'Expected exactly one managed block'
    for rule in "$checkout"/instructions/*.md; do
      name=${rule##*/}
      target="$dir/agent-skills-$name"
      [[ -L "$target" && -f "$target" && "$(readlink "$target")" == "$rule" ]] || fail "Bad rule link: $target"
      grep -Fq -- "- [${name%.md}](agent-skills-$name)" "$dir/AGENTS.md" || fail "Missing reference: $name"
      cmp -s "$rule" "$target" || fail 'Rule reference resolves to wrong content'
    done
  done
  for skill in "$checkout"/skills/*; do
    target="$HOME/.agents/skills/${skill##*/}"
    [[ -L "$target" && -f "$target/SKILL.md" && "$(readlink "$target")" == "$skill" ]] || fail "Bad skill link: $target"
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
printf 'PASS AGENTS.md directory and live/broken symlinks preserved\n'

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
mkdir -p "$HOME/.agents/skills/unmanaged"
printf 'keep\n' > "$HOME/.agents/skills/unmanaged/sentinel"
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
[[ "$(cat "$HOME/.codex/config.toml")" == 'local settings' && "$(cat "$HOME/.agents/skills/unmanaged/sentinel")" == keep ]] || fail 'Unmanaged content changed'
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
block=$(cat "$HOME/.pi/agent/AGENTS.md")
printf 'prefix\r\n%s\r\nsuffix without newline' "$block" > "$tmp/expected"
run_install
cmp -s "$tmp/expected" "$HOME/.codex/AGENTS.md" || fail 'Replacement changed outside bytes'
printf 'PASS managed-section replacement preserves CRLF and missing final newline outside section\n'

printf '\nUpdated rule content.\n' >> "$checkout/instructions/workflow.md"
cmp -s "$checkout/instructions/workflow.md" "$HOME/.codex/agent-skills-workflow.md" || fail 'Rule update not visible via link'
printf '# Added rule\n' > "$checkout/instructions/added.md"
run_install
grep -Fq '[added](agent-skills-added.md)' "$HOME/.codex/AGENTS.md" || fail 'New rule not referenced'
[[ -L "$HOME/.codex/agent-skills-added.md" ]] || fail 'New rule not linked'
rm "$checkout/instructions/added.md"
run_install
! grep -Fq '[added]' "$HOME/.codex/AGENTS.md" || fail 'Removed rule still referenced'
printf 'PASS source edits visible immediately; adding/removing rules refreshes reference list\n'

export HOME="$tmp/custom home" PI_CODING_AGENT_DIR="$tmp/custom pi" CODEX_HOME="$tmp/custom codex"
run_install
assert_install
[[ ! -e "$HOME/.pi" && ! -e "$HOME/.codex" ]] || fail 'Custom homes ignored'
export HOME="$tmp/shared home" PI_CODING_AGENT_DIR="$tmp/shared agent" CODEX_HOME="$tmp/shared agent"
run_install
assert_install
printf 'PASS custom agent homes, including shared instruction destination\n'
if CODEX_HOME=relative bash "$install" > "$tmp/invalid.log" 2>&1; then fail 'Relative home accepted'; fi
if CODEX_HOME='' bash "$install" > "$tmp/invalid.log" 2>&1; then fail 'Empty home accepted'; fi
expect_failure --unknown
expect_failure --dry-run extra
expect_failure --help extra
printf 'PASS invalid homes and arguments rejected\n'
printf 'PASS all offline checks; model-backed reading of linked rules remains a separate smoke test.\n'
