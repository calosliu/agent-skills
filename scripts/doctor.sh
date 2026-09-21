#!/usr/bin/env bash
set -u

usage() { printf 'Usage: bash scripts/doctor.sh [--offline]\nRead-only validation; --offline skips agent versions and auth status.\n'; }
case ${1-} in
  '') offline=false ;;
  --offline) offline=true ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || { usage >&2; exit 2; }

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
: "${HOME:?HOME must be set}"
pi_home=${PI_CODING_AGENT_DIR-"$HOME/.pi/agent"}
codex_home=${CODEX_HOME-"$HOME/.codex"}
claude_home=${CLAUDE_CONFIG_DIR-"$HOME/.claude"}
lock=$repo/agents/sources.lock.tsv
failures=0
pass() { printf 'PASS %s\n' "$*"; }
warn() { printf 'WARN %s\n' "$*"; }
fail() { printf 'FAIL %s\n' "$*" >&2; failures=$((failures + 1)); }

if (( BASH_VERSINFO[0] < 3 || (BASH_VERSINFO[0] == 3 && BASH_VERSINFO[1] < 2) )); then fail "Bash 3.2+ required: $BASH_VERSION"; else pass "Bash $BASH_VERSION"; fi
if command -v git >/dev/null 2>&1; then pass 'Git available'; else fail 'Git is required'; fi
if [[ -r "$lock" ]]; then pass 'Source lock readable'; else fail "Missing source lock: $lock"; fi

check_instruction_file() {
  local file=$1 begins ends
  if [[ ! -r "$file" ]]; then fail "Missing instruction file: $file"; return; fi
  begins=$(grep -Fxc '<!-- agent-skills:begin -->' "$file" 2>/dev/null || true)
  ends=$(grep -Fxc '<!-- agent-skills:end -->' "$file" 2>/dev/null || true)
  if [[ "$begins" == 1 && "$ends" == 1 ]]; then pass "Managed block: $file"; else fail "Malformed managed block: $file"; fi
}
check_instruction_file "$pi_home/AGENTS.md"
[[ "$codex_home" == "$pi_home" ]] || check_instruction_file "$codex_home/AGENTS.md"
check_instruction_file "$claude_home/CLAUDE.md"

shopt -s nullglob
rules=("$repo"/instructions/*.md)
for rule in "${rules[@]}"; do
  name=${rule##*/}
  for dir in "$pi_home" "$codex_home" "$claude_home"; do
    link=$dir/agent-skills-$name
    if [[ -L "$link" && -r "$link" && "$(readlink "$link")" == "$rule" ]]; then pass "Rule link: $link"; else fail "Broken/stale rule link: $link"; fi
  done
done
skills=("$repo"/skills/*)
for skill in "${skills[@]}"; do
  name=${skill##*/}
  for link in "$HOME/.agents/skills/$name" "$claude_home/skills/$name"; do
    if [[ -L "$link" && -r "$link/SKILL.md" && "$(readlink "$link")" == "$skill" ]]; then pass "Skill link: $link"; else fail "Broken/stale skill link: $link"; fi
  done
done

if command -v python3 >/dev/null 2>&1; then
  if python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$repo/agents/pi/settings.example.json" >/dev/null 2>&1; then pass 'Pi JSON example parses'; else fail 'Pi JSON example is invalid'; fi
  if python3 -c 'import tomllib,sys; tomllib.load(open(sys.argv[1], "rb"))' "$repo/agents/codex/config.example.toml" >/dev/null 2>&1; then pass 'Codex TOML example parses'; else warn 'tomllib unavailable or Codex TOML example invalid'; fi
else
  warn 'python3 unavailable; skipped config parser checks'
fi

expected_version() { awk -F '\t' -v kind="$1" -v name="$2" '$1 == kind && $2 == name { print $4; exit }' "$lock"; }
check_cli() {
  local bin=$1 kind=$2 name=$3 auth_command=$4 expected output
  if ! command -v "$bin" >/dev/null 2>&1; then fail "Missing supported CLI: $bin"; return; fi
  expected=$(expected_version "$kind" "$name")
  output=$($bin --version 2>&1 | head -n 1)
  if [[ -n "$expected" && "$output" == *"$expected"* ]]; then pass "$bin version $expected"; else fail "$bin version differs from lock ($expected): $output"; fi
  if bash -c "$auth_command" >/dev/null 2>&1; then pass "$bin auth present"; else fail "$bin auth unavailable"; fi
}
if ! "$offline"; then
  check_cli pi npm @earendil-works/pi-coding-agent 'pi auth check --provider openai-codex --json --no-refresh'
  check_cli codex npm @openai/codex 'codex login status'
  check_cli claude cli claude-code 'claude auth status'
  check_cli gh cli gh 'gh auth status'
else
  warn 'Offline mode: skipped supported-agent/gh version and auth checks'
fi

if (( failures > 0 )); then printf 'Doctor found %d failure(s).\n' "$failures" >&2; exit 1; fi
printf 'Doctor passed. No files changed.\n'
