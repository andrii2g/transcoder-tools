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
  local normalized_preset
  local quality_input
  local normalized_quality
  local width
  local height
  local video_bitrate
  local audio_bitrate

  read_config_file "$profile_path" "$profile_name"
  print_config_map "Resolved profile config from $profile_path" "$profile_name"

  [[ -n "$(config_get "$profile_name" name)" ]] || die "Profile field name is required: $profile_path"
  [[ -n "$(config_get "$profile_name" output)" ]] || die "Profile field output is required: $profile_path"
  [[ -n "$(config_get "$profile_name" video_codec)" ]] || die "Profile field video_codec is required: $profile_path"
  [[ -n "$(config_get "$profile_name" audio_codec)" ]] || die "Profile field audio_codec is required: $profile_path"

  preset_input="$(config_get "$profile_name" preset)"
  [[ -n "$preset_input" ]] || die "Profile field preset is required: $profile_path"
  normalized_preset="$(normalize_preset_name "$preset_input")" || die "Unsupported preset in $profile_path: $preset_input"
  profile_ref[preset]="$normalized_preset"

  quality_input="$(config_get "$profile_name" quality standard)"
  normalized_quality="$(normalize_quality_name "$quality_input")" || die "Unsupported quality in $profile_path: $quality_input"
  profile_ref[quality]="$normalized_quality"

  width="$(config_get "$profile_name" width)"
  height="$(config_get "$profile_name" height)"
  video_bitrate="$(config_get "$profile_name" video_bitrate)"
  audio_bitrate="$(config_get "$profile_name" audio_bitrate)"

  if [[ "$normalized_preset" == "custom" ]]; then
    [[ -n "$width" && -n "$height" ]] || die "preset=custom requires width and height in $profile_path"
    [[ -n "$video_bitrate" ]] || die "preset=custom requires video_bitrate in $profile_path"
    [[ -n "$audio_bitrate" ]] || die "preset=custom requires audio_bitrate in $profile_path"
  fi

  if [[ -n "$width" || -n "$height" ]]; then
    [[ -n "$width" && -n "$height" ]] || die "width and height must both be set in $profile_path"
    [[ "$width" =~ ^[0-9]+$ ]] || die "width must be numeric in $profile_path"
    [[ "$height" =~ ^[0-9]+$ ]] || die "height must be numeric in $profile_path"
  fi

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
