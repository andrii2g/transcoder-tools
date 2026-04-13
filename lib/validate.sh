#!/usr/bin/env bash

validate_cpu_limit_value() {
  local cpu_limit="$1"
  local context="$2"
  [[ "$cpu_limit" =~ ^[0-9]+%$ ]] || die "cpu_limit must be a percentage like 50% in $context"
  local cpu_percent="${cpu_limit%%%}"
  [[ "$cpu_percent" -ge 1 && "$cpu_percent" -le 100 ]] || die "cpu_limit must be between 1% and 100% in $context"
}

validate_positive_integer() {
  local value="$1"
  local field_name="$2"
  local context="$3"
  [[ "$value" =~ ^[0-9]+$ && "$value" -ge 1 ]] || die "${field_name} must be a positive number in $context"
}

validate_job_config() {
  local job_path="$1"
  local job_name="$2"
  local outputs_name="$3"
  local -n job_ref="$job_name"
  local input_path
  local input_mode
  local overwrite_value
  local outputs_raw
  local mode_value
  local cpu_limit

  read_config_file "$job_path" "$job_name"
  print_config_map "Resolved job config from $job_path" "$job_name"

  input_path="$(config_get "$job_name" input)"
  [[ -n "$input_path" ]] || die "Job field input is required"

  input_mode="$(config_get "$job_name" input_mode file)"
  case "$input_mode" in
    file)
      [[ -f "$input_path" ]] || die "Input file not found: $input_path"
      ;;
    rtmp)
      [[ "$input_path" == rtmp://* ]] || die "RTMP input must begin with rtmp:// in $job_path"
      ;;
    *)
      die "Unsupported input_mode in $job_path: $input_mode"
      ;;
  esac
  job_ref[input_mode]="$input_mode"

  outputs_raw="$(config_get "$job_name" outputs)"
  parse_outputs_field "$outputs_raw" "$outputs_name"

  overwrite_value="$(config_get "$job_name" overwrite false)"
  normalize_bool "$overwrite_value" >/dev/null || die "Invalid overwrite value: $overwrite_value"

  mode_value="$(config_get "$job_name" mode sequential)"
  case "$mode_value" in
    sequential|multi-output|hls|live-hls) job_ref[mode]="$mode_value" ;;
    *) die "Unsupported mode in $job_path: $mode_value" ;;
  esac

  cpu_limit="$(config_get "$job_name" cpu_limit)"
  if [[ -n "$cpu_limit" ]]; then
    validate_cpu_limit_value "$cpu_limit" "$job_path"
  fi

  case "$mode_value" in
    hls)
      validate_hls_job_fields "$job_name" "$job_path"
      ;;
    live-hls)
      validate_live_hls_job_fields "$job_name" "$job_path"
      ;;
  esac

  local ffmpeg_bin
  ffmpeg_bin="$(config_get "$job_name" ffmpeg ffmpeg)"
  [[ -n "$ffmpeg_bin" ]] || die "Job field ffmpeg cannot be empty"
}

validate_hls_job_fields() {
  local job_name="$1"
  local job_path="$2"
  local segment_time
  local playlist_type
  local master_playlist

  segment_time="$(config_get "$job_name" hls_segment_time 6)"
  validate_positive_integer "$segment_time" "hls_segment_time" "$job_path"

  playlist_type="$(config_get "$job_name" hls_playlist_type vod)"
  case "$playlist_type" in
    vod|event) ;;
    *) die "hls_playlist_type must be vod or event in $job_path" ;;
  esac

  master_playlist="$(config_get "$job_name" hls_master_playlist)"
  [[ -n "$master_playlist" ]] || die "hls_master_playlist is required when mode=hls in $job_path"
  if [[ "$master_playlist" != *.m3u8 ]]; then
    die "hls_master_playlist must end with .m3u8 in $job_path"
  fi
}

validate_live_hls_job_fields() {
  local job_name="$1"
  local job_path="$2"
  local segment_time
  local list_size
  local master_playlist
  local delete_segments
  local append_list

  [[ "$(config_get "$job_name" input_mode file)" == "rtmp" ]] || die "mode=live-hls requires input_mode=rtmp in $job_path"

  segment_time="$(config_get "$job_name" hls_segment_time 2)"
  validate_positive_integer "$segment_time" "hls_segment_time" "$job_path"

  list_size="$(config_get "$job_name" hls_list_size 8)"
  validate_positive_integer "$list_size" "hls_list_size" "$job_path"

  master_playlist="$(config_get "$job_name" hls_master_playlist)"
  [[ -n "$master_playlist" ]] || die "hls_master_playlist is required when mode=live-hls in $job_path"
  [[ "$master_playlist" == *.m3u8 ]] || die "hls_master_playlist must end with .m3u8 in $job_path"

  delete_segments="$(config_get "$job_name" hls_delete_segments true)"
  normalize_bool "$delete_segments" >/dev/null || die "Invalid hls_delete_segments value in $job_path: $delete_segments"

  append_list="$(config_get "$job_name" hls_append_list true)"
  normalize_bool "$append_list" >/dev/null || die "Invalid hls_append_list value in $job_path: $append_list"

  if [[ -n "$(config_get "$job_name" hls_playlist_type)" ]]; then
    die "hls_playlist_type is not supported for mode=live-hls in $job_path"
  fi
}

validate_hls_profile_output() {
  local profile_path="$1"
  local profile_name="$2"
  local output_path

  output_path="$(config_get "$profile_name" output)"
  [[ "$output_path" == *.m3u8 ]] || die "HLS profile output must be a .m3u8 playlist: $profile_path"
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
  local audio_sample_rate

  read_config_file "$profile_path" "$profile_name"
  print_config_map "Resolved profile config from $profile_path" "$profile_name"

  profile_display_name="$(config_get "$profile_name" name)"
  [[ -n "$profile_display_name" ]] || die "Profile field name is required: $profile_path"
  [[ -n "$(config_get "$profile_name" output)" ]] || die "Profile field output is required: $profile_path"

  [[ -z "$(config_get "$profile_name" video_filter)" ]] || die "video_filter is only supported in preset files: $profile_path"
  [[ -z "$(config_get "$profile_name" extra_output_args)" ]] || die "extra_output_args is only supported in preset files: $profile_path"
  [[ -z "$(config_get "$profile_name" cpu_limit)" ]] || die "cpu_limit is only supported in job files: $profile_path"

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

  audio_sample_rate="$(config_get "$profile_name" audio_sample_rate)"
  if [[ -n "$audio_sample_rate" && "$audio_sample_rate" != "source" ]]; then
    [[ "$audio_sample_rate" =~ ^[0-9]+$ ]] || die "audio_sample_rate must be numeric or source in $profile_path"
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
