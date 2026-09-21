#!/usr/bin/env bash
# ponytail: single-process setup; use a lock if concurrent installs become necessary.
set -euo pipefail

usage() {
  printf 'Usage: bash scripts/install.sh [--dry-run]\nUpdates a managed AGENTS.md section and links shared rules and owned skills.\n'
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
for dir in "$HOME" "$pi_home" "$codex_home"; do
  [[ "$dir" == /* && "$dir" != / ]] || fail "Agent homes must be absolute, non-root paths: $dir"
done
export LC_ALL=C
shopt -s nullglob
rules=("$repo"/instructions/*.md)
[[ ${#rules[@]} -gt 0 ]] || fail 'No shared instruction files found'
agent_files=("$pi_home/AGENTS.md" "$codex_home/AGENTS.md")
[[ "$pi_home" != "$codex_home" ]] || agent_files=("$pi_home/AGENTS.md")
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
  sources+=("$skill")
  targets+=("$HOME/.agents/skills/$name")
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
block="$begin"$'\n## Shared personal instructions\n\nRead and follow every linked rule file before starting work. Paths are relative to this AGENTS.md, not the project working directory. If a file cannot be read, report it rather than silently skipping it.\n'
for rule in "${rules[@]}"; do
  name=${rule##*/}
  block+=$'\n'"- [${name%.md}](agent-skills-$name)"
done
block+=$'\n'"$end"

# Keep every byte outside our section, including CRLF and missing final newlines.
prepare_agents() {
  local target=$1 prefix rest middle suffix
  original=''
  if [[ -L "$target" || ( -e "$target" && ! -f "$target" ) ]]; then
    fail "CONFLICT AGENTS.md must be a regular file, not a symlink/directory: $target"
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
for target in "${agent_files[@]}"; do
  check_parent "$target"
  prepare_agents "$target"
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
printf 'Installed. Existing AGENTS.md content outside our section was preserved.\n'
