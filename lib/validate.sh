#!/usr/bin/env bash

validate_job_config() {
  local job_path="$1"
  local job_name="$2"
  local outputs_name="$3"
  local -n job_ref="$job_name"
  local input_path
  local overwrite_value
  local outputs_raw

  read_config_file "$job_path" "$job_name"
  print_config_map "Resolved job config from $job_path" "$job_name"

  input_path="$(config_get "$job_name" input)"
  [[ -n "$input_path" ]] || die "Job field input is required"
  [[ -f "$input_path" ]] || die "Input file not found: $input_path"

  outputs_raw="$(config_get "$job_name" outputs)"
  parse_outputs_field "$outputs_raw" "$outputs_name"

  overwrite_value="$(config_get "$job_name" overwrite false)"
  normalize_bool "$overwrite_value" >/dev/null || die "Invalid overwrite value: $overwrite_value"

  local ffmpeg_bin
  ffmpeg_bin="$(config_get "$job_name" ffmpeg ffmpeg)"
  [[ -n "$ffmpeg_bin" ]] || die "Job field ffmpeg cannot be empty"
}

validate_profile_config() {
  local profile_path="$1"
  local profile_name="$2"
  local -n profile_ref="$profile_name"
  local preset_input
  local profile_display_name
  local quality_input
  local normalized_quality
  local width
  local height

  read_config_file "$profile_path" "$profile_name"
  print_config_map "Resolved profile config from $profile_path" "$profile_name"

  profile_display_name="$(config_get "$profile_name" name)"
  [[ -n "$profile_display_name" ]] || die "Profile field name is required: $profile_path"
  [[ -n "$(config_get "$profile_name" output)" ]] || die "Profile field output is required: $profile_path"

  [[ -z "$(config_get "$profile_name" video_filter)" ]] || die "video_filter is only supported in preset files: $profile_path"
  [[ -z "$(config_get "$profile_name" extra_output_args)" ]] || die "extra_output_args is only supported in preset files: $profile_path"

  preset_input="$(config_get "$profile_name" preset)"
  if [[ -z "$preset_input" ]]; then
    if preset_file_for "$profile_display_name" >/dev/null 2>&1; then
      preset_input="$profile_display_name"
      profile_ref[preset]="$preset_input"
    else
      die "Profile field preset is required: $profile_path"
    fi
  fi

  apply_profile_preset_defaults "$profile_name" "$preset_input"
  print_config_map "Profile config after applying preset defaults from $preset_input" "$profile_name"

  [[ -n "$(config_get "$profile_name" video_codec)" ]] || die "Profile or preset field video_codec is required: $profile_path"
  [[ -n "$(config_get "$profile_name" audio_codec)" ]] || die "Profile or preset field audio_codec is required: $profile_path"
  [[ -n "$(config_get "$profile_name" video_bitrate)" ]] || die "Profile or preset field video_bitrate is required: $profile_path"
  [[ -n "$(config_get "$profile_name" audio_bitrate)" ]] || die "Profile or preset field audio_bitrate is required: $profile_path"

  quality_input="$(config_get "$profile_name" quality standard)"
  normalized_quality="$(normalize_quality_name "$quality_input")" || die "Unsupported quality in $profile_path: $quality_input"
  profile_ref[quality]="$normalized_quality"

  width="$(config_get "$profile_name" width)"
  height="$(config_get "$profile_name" height)"

  [[ -n "$width" && -n "$height" ]] || die "Profile or preset fields width and height are required: $profile_path"
  [[ "$width" =~ ^[0-9]+$ ]] || die "width must be numeric in $profile_path"
  [[ "$height" =~ ^[0-9]+$ ]] || die "height must be numeric in $profile_path"

  if [[ "$normalized_quality" == "custom" ]]; then
    [[ -n "$(config_get "$profile_name" crf)" ]] || die "quality=custom requires crf in $profile_path"
  fi
}

validate_profile_paths() {
  local outputs_name="$1"
  local -n outputs_ref="$outputs_name"
  local profile_path
  for profile_path in "${outputs_ref[@]}"; do
    [[ -f "$profile_path" ]] || die "Profile file not found: $profile_path"
  done
}
