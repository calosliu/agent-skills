#!/usr/bin/env bash
# ponytail: single-process setup; use a lock if concurrent installs become necessary.
set -euo pipefail

usage() {
  printf 'Usage: bash scripts/install.sh [--dry-run]\nUpdates managed agent instruction sections and links shared rules and owned skills.\n'
}
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
[[ $# -le 1 ]] || { usage >&2; exit 2; }
dry_run=false
case "${1-}" in
  '') [[ $# == 0 ]] || { usage >&2; exit 2; } ;;
  --dry-run) dry_run=true ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
: "${HOME:?HOME must be set}"
pi_home=${PI_CODING_AGENT_DIR-"$HOME/.pi/agent"}
codex_home=${CODEX_HOME-"$HOME/.codex"}
claude_home=${CLAUDE_CONFIG_DIR-"$HOME/.claude"}
for dir in "$HOME" "$pi_home" "$codex_home" "$claude_home"; do
  [[ "$dir" == /* && "$dir" != / ]] || fail "Agent homes must be absolute, non-root paths: $dir"
done
export LC_ALL=C
shopt -s nullglob
rules=("$repo"/instructions/*.md)
[[ ${#rules[@]} -gt 0 ]] || fail 'No shared instruction files found'
agent_files=("$pi_home/AGENTS.md")
agent_kinds=(agents)
if [[ "$pi_home" != "$codex_home" ]]; then
  agent_files+=("$codex_home/AGENTS.md")
  agent_kinds+=(agents)
fi
agent_files+=("$claude_home/CLAUDE.md")
agent_kinds+=(claude)
sources=() targets=()
for rule in "${rules[@]}"; do
  name=${rule##*/}
  [[ -f "$rule" && ! -L "$rule" && -s "$rule" && "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*\.md$ ]] || fail "Invalid instruction file: $rule"
  for target in "${agent_files[@]}"; do
    sources+=("$rule")
    targets+=("${target%/*}/agent-skills-$name")
  done
done
for skill in "$repo"/skills/*; do
  [[ -d "$skill" && ! -L "$skill" && -s "$skill/SKILL.md" ]] || fail "Expected a local skill directory with SKILL.md: $skill"
  name=${skill##*/}
  [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ && ${#name} -le 64 ]] || fail "Invalid skill directory name: $name"
  sources+=("$skill" "$skill")
  targets+=("$HOME/.agents/skills/$name" "$claude_home/skills/$name")
done

check_parent() {
  local parent=${1%/*}
  while [[ -n "$parent" && "$parent" != / ]]; do
    if [[ ( -e "$parent" || -L "$parent" ) && ! -d "$parent" ]]; then
      fail "CONFLICT parent is not a directory: $parent"
    fi
    parent=${parent%/*}
  done
}
correct_link() { [[ -L "$2" && "$(readlink "$2")" == "$1" ]]; }
begin='<!-- agent-skills:begin -->'
end='<!-- agent-skills:end -->'

# Keep every byte outside our section, including CRLF and missing final newlines.
prepare_instructions() {
  local target=$1 kind=$2 prefix rest middle suffix rule name rule_target block
  block="$begin"$'\n## Shared personal instructions\n'
  if [[ "$kind" == claude ]]; then
    block+=$'\n'
  else
    block+=$'\nRead and follow every rule file below before starting work. Each line contains an exact absolute path; do not resolve it against the project working directory. If a file cannot be read, report it rather than silently skipping it.\n'
  fi
  for rule in "${rules[@]}"; do
    name=${rule##*/}
    rule_target="${target%/*}/agent-skills-$name"
    if [[ "$kind" == claude ]]; then
      block+="@$rule_target"$'\n'
    else
      block+=$'\n'"- ${name%.md} absolute path: $rule_target"
    fi
  done
  [[ "$kind" != claude ]] || block=${block%$'\n'}
  block+=$'\n'"$end"
  original=''
  if [[ -L "$target" || ( -e "$target" && ! -f "$target" ) ]]; then
    fail "CONFLICT instruction file must be regular, not a symlink/directory: $target"
  fi
  if [[ -f "$target" ]]; then
    cmp -s "$target" <(tr -d '\000' < "$target") || fail "Expected text without NUL bytes: $target"
    original=$(cat -- "$target" && printf '\001') || fail "Cannot read: $target"
    original=${original%$'\001'}
  fi
  if [[ "$original" == *"$begin"* || "$original" == *"$end"* ]]; then
    [[ "$original" == *"$begin"* ]] || fail "Malformed managed markers: $target"
    prefix=${original%%"$begin"*}
    rest=${original#*"$begin"}
    [[ "$rest" == *"$end"* && "$prefix" != *"$end"* && "$rest" != *"$begin"* ]] || fail "Malformed managed markers: $target"
    middle=${rest%%"$end"*}
    suffix=${rest#*"$end"}
    [[ "$suffix" != *"$end"* ]] || fail "Duplicate managed markers: $target"
    [[ -z "$prefix" || "$prefix" == *$'\n' ]] || fail "Markers must be on their own lines: $target"
    [[ "$rest" == $'\n'* || "$rest" == $'\r\n'* ]] || fail "Markers must be on their own lines: $target"
    [[ "$middle" == *$'\n' ]] || fail "Markers must be on their own lines: $target"
    [[ -z "$suffix" || "$suffix" == $'\n'* || "$suffix" == $'\r\n'* ]] || fail "Markers must be on their own lines: $target"
    updated="$prefix$block$suffix"
  else
    updated=$original
    if [[ -n "$updated" ]]; then
      [[ "$updated" == *$'\n' ]] || updated+=$'\n'
      updated+=$'\n'
    fi
    updated+="$block"$'\n'
  fi
}

# Preflight all text and link targets before creating anything, even in dry-run.
contents=() originals=()
for i in "${!agent_files[@]}"; do
  target=${agent_files[$i]}
  check_parent "$target"
  prepare_instructions "$target" "${agent_kinds[$i]}"
  originals+=("$original")
  contents+=("$updated")
  if [[ "$updated" == "$original" ]]; then printf 'OK %s\n' "$target"; else printf 'UPDATE %s\n' "$target"; fi
done
for i in "${!sources[@]}"; do
  source=${sources[$i]} target=${targets[$i]}
  check_parent "$target"
  if correct_link "$source" "$target"; then
    printf 'OK %s\n' "$target"
  elif [[ -e "$target" || -L "$target" ]]; then
    fail "CONFLICT $target (left untouched; no changes made)"
  else
    printf 'LINK %s -> %s\n' "$target" "$source"
  fi
done
"$dry_run" && exit 0

pending=''
trap '[[ -z "$pending" ]] || rm -f -- "$pending"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
for i in "${!sources[@]}"; do
  source=${sources[$i]} target=${targets[$i]}
  correct_link "$source" "$target" && continue
  mkdir -p -- "${target%/*}"
  ln -s -- "$source" "$target"
done
for i in "${!agent_files[@]}"; do
  target=${agent_files[$i]}
  [[ "${originals[$i]}" != "${contents[$i]}" ]] || continue
  pending=$(mktemp "$target.tmp.XXXXXX")
  if [[ -f "$target" ]]; then
    backup=$(mktemp "$target.backup.XXXXXX")
    cp -p -- "$target" "$backup"
    cp -p -- "$target" "$pending"
    printf 'BACKUP %s\n' "$backup"
  fi
  printf '%s' "${contents[$i]}" > "$pending"
  mv -f -- "$pending" "$target"
  pending=''
done
printf 'Installed. Existing instruction content outside managed sections was preserved.\n'
