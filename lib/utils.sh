#!/usr/bin/env bash

VTX_VERSION="0.1.0"
VTX_VERBOSE=0

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

normalize_bool() {
  case "$(lower "$(trim "$1")")" in
    1|true|yes|y|on) printf 'true' ;;
    0|false|no|n|off) printf 'false' ;;
    *) return 1 ;;
  esac
}

log_info() {
  printf '[INFO] %s\n' "$*" >&2
}

log_verbose() {
  if [[ "${VTX_VERBOSE}" == "1" ]]; then
    printf '[VERBOSE] %s\n' "$*" >&2
  fi
}

log_error() {
  printf '[ERROR] %s\n' "$*" >&2
}

die() {
  log_error "$*"
  exit 1
}

require_file() {
  local file="$1"
  [[ -f "$file" ]] || die "File not found: $file"
}

require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

split_csv() {
  local input="$1"
  local out_name="$2"
  local -n out_ref="$out_name"
  local old_ifs="$IFS"
  out_ref=()
  IFS=',' read -r -a out_ref <<< "$input"
  IFS="$old_ifs"
  local item
  for item in "${!out_ref[@]}"; do
    out_ref[$item]="$(trim "${out_ref[$item]}")"
  done
}

ensure_parent_dir() {
  local target="$1"
  local parent
  parent="$(dirname "$target")"
  mkdir -p "$parent"
}

join_command_for_display() {
  local result=""
  local part
  for part in "$@"; do
    if [[ -n "$result" ]]; then
      result+=" "
    fi
    printf -v part '%q' "$part"
    result+="$part"
  done
  printf '%s' "$result"
}
