#!/usr/bin/env bash

print_usage() {
  cat <<'EOF'
Usage:
  ./bin/vtx.sh list-presets
  ./bin/vtx.sh validate --job <job.conf> [--verbose]
  ./bin/vtx.sh transcode --job <job.conf> [--dry-run] [--verbose] [--log <path>]
  ./bin/vtx.sh --version

Commands:
  list-presets   Print supported presets and their resolved dimensions
  validate       Validate a job file and all referenced profiles
  transcode      Validate, resolve, and run one ffmpeg command per profile

Flags:
  --job <path>   Job config path
  --dry-run      Print ffmpeg commands without executing them
  --verbose      Print resolved config and command details
  --log <path>   Write transcode output and ffmpeg output to a log file
  --version      Print vtx version
  -h, --help     Show help
EOF
}

run_list_presets() {
  list_presets_table
}

load_and_validate_job_bundle() {
  local job_path="$1"
  local job_name="$2"
  local outputs_name="$3"

  validate_job_config "$job_path" "$job_name" "$outputs_name"
  validate_profile_paths "$outputs_name"
}

run_validate() {
  local job_path="$1"
  local -A job_cfg=()
  local -a output_paths=()
  local -A profile_cfg=()
  local profile_path

  load_and_validate_job_bundle "$job_path" job_cfg output_paths

  for profile_path in "${output_paths[@]}"; do
    profile_cfg=()
    validate_profile_config "$profile_path" profile_cfg
    resolve_profile_runtime profile_cfg
  done

  emit_line "Validation successful for $job_path"
}

run_transcode() {
  local job_path="$1"
  local dry_run="$2"
  local -A job_cfg=()
  local -a output_paths=()
  local -A profile_cfg=()
  local -a ffmpeg_cmd=()
  local profile_path
  local output_path

  load_and_validate_job_bundle "$job_path" job_cfg output_paths

  if [[ "$dry_run" != "1" ]]; then
    require_command "$(config_get job_cfg ffmpeg ffmpeg)"
  fi

  for profile_path in "${output_paths[@]}"; do
    profile_cfg=()
    validate_profile_config "$profile_path" profile_cfg
    resolve_profile_runtime profile_cfg
    build_ffmpeg_command job_cfg profile_cfg ffmpeg_cmd
    output_path="$(config_get profile_cfg output)"

    emit_line "$(join_command_for_display "${ffmpeg_cmd[@]}")"

    if [[ "$dry_run" == "1" ]]; then
      continue
    fi

    ensure_parent_dir "$output_path"
    run_ffmpeg_command ffmpeg_cmd
  done
}

vtx_main() {
  local command=""
  local job_path=""
  local log_path=""
  local dry_run=0

  if [[ $# -eq 0 ]]; then
    print_usage
    exit 1
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      transcode|validate|list-presets)
        if [[ -n "$command" ]]; then
          die "Only one command may be specified"
        fi
        command="$1"
        shift
        ;;
      --job)
        [[ $# -ge 2 ]] || die "--job requires a value"
        job_path="$2"
        shift 2
        ;;
      --dry-run)
        dry_run=1
        shift
        ;;
      --verbose)
        VTX_VERBOSE=1
        shift
        ;;
      --log)
        [[ $# -ge 2 ]] || die "--log requires a value"
        log_path="$2"
        shift 2
        ;;
      --version)
        printf 'vtx %s\n' "$VTX_VERSION"
        exit 0
        ;;
      -h|--help)
        print_usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done

  if [[ -n "$log_path" && "$command" != "transcode" ]]; then
    die "--log is only supported for transcode"
  fi

  if [[ -n "$log_path" ]]; then
    log_init "$log_path"
  fi

  case "$command" in
    list-presets)
      run_list_presets
      ;;
    validate)
      [[ -n "$job_path" ]] || die "validate requires --job"
      run_validate "$job_path"
      ;;
    transcode)
      [[ -n "$job_path" ]] || die "transcode requires --job"
      run_transcode "$job_path" "$dry_run"
      ;;
    *)
      die "No command specified"
      ;;
  esac
}
