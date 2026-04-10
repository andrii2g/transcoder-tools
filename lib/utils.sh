#!/usr/bin/env bash

VTX_VERSION="0.2.0"
VTX_VERBOSE=0
VTX_LOG_FILE=""

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

log_init() {
  local log_path="$1"
  [[ -n "$log_path" ]] || die "--log requires a non-empty path"
  ensure_parent_dir "$log_path"
  : > "$log_path" || die "Cannot write log file: $log_path"
  VTX_LOG_FILE="$log_path"
  log_info "Writing log to $log_path"
}

write_log_line() {
  if [[ -n "${VTX_LOG_FILE:-}" ]]; then
    printf '%s\n' "$*" >> "$VTX_LOG_FILE"
  fi
}

emit_line() {
  printf '%s\n' "$*"
  write_log_line "$*"
}

log_info() {
  local message="[INFO] $*"
  printf '%s\n' "$message" >&2
  write_log_line "$message"
}

log_verbose() {
  if [[ "${VTX_VERBOSE}" == "1" ]]; then
    local message="[VERBOSE] $*"
    printf '%s\n' "$message" >&2
    write_log_line "$message"
  fi
}

log_error() {
  local message="[ERROR] $*"
  printf '%s\n' "$message" >&2
  write_log_line "$message"
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


split_words() {
  local input="$1"
  local out_name="$2"
  local -n out_ref="$out_name"
  out_ref=()
  [[ -n "$input" ]] || return 0
  read -r -a out_ref <<< "$input"
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
