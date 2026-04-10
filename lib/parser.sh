#!/usr/bin/env bash

read_config_file() {
  local config_path="$1"
  local out_name="$2"
  local -n out_ref="$out_name"
  local line
  local key
  local value

  require_file "$config_path"
  out_ref=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="$(trim "$line")"
    [[ -z "$line" ]] && continue
    [[ "${line:0:1}" == "#" ]] && continue
    [[ "$line" == *=* ]] || die "Invalid config line in $config_path: $line"
    key="$(trim "${line%%=*}")"
    value="$(trim "${line#*=}")"
    [[ -n "$key" ]] || die "Empty key in $config_path"
    out_ref["$key"]="$value"
  done < "$config_path"
}

config_get() {
  local cfg_name="$1"
  local -n cfg_ref="$cfg_name"
  local key="$2"
  local default_value="${3-}"
  if [[ -v cfg_ref["$key"] ]]; then
    printf '%s' "${cfg_ref[$key]}"
  else
    printf '%s' "$default_value"
  fi
}

parse_outputs_field() {
  local outputs_value="$1"
  local out_name="$2"
  local -n out_ref="$out_name"
  [[ -n "$outputs_value" ]] || die "Job field outputs is required"
  split_csv "$outputs_value" "$out_name"
  [[ "${#out_ref[@]}" -gt 0 ]] || die "Job outputs field is empty"
}

print_config_map() {
  local title="$1"
  local cfg_name="$2"
  local -n cfg_ref="$cfg_name"
  local key
  log_verbose "$title"
  for key in "${!cfg_ref[@]}"; do
    log_verbose "  $key=${cfg_ref[$key]}"
  done
}
