#!/usr/bin/env bash

resolve_profile_runtime() {
  local profile_name="$1"
  local -n profile_ref="$profile_name"
  local width
  local height
  local video_bitrate
  local audio_bitrate
  local preset
  local video_codec
  local audio_codec
  local quality
  local crf_value
  local video_filter

  preset="$(config_get "$profile_name" preset)"
  resolve_dimensions \
    "$preset" \
    "$(config_get "$profile_name" width)" \
    "$(config_get "$profile_name" height)" \
    width \
    height

  resolve_bitrates \
    "$preset" \
    "$(config_get "$profile_name" video_bitrate)" \
    "$(config_get "$profile_name" audio_bitrate)" \
    video_bitrate \
    audio_bitrate

  video_codec="$(map_video_codec "$(config_get "$profile_name" video_codec)")"
  audio_codec="$(map_audio_codec "$(config_get "$profile_name" audio_codec)")"
  quality="$(config_get "$profile_name" quality standard)"
  crf_value="$(quality_to_crf "$quality" "$(config_get "$profile_name" crf)")"

  profile_ref[resolved_width]="$width"
  profile_ref[resolved_height]="$height"
  profile_ref[resolved_video_bitrate]="$video_bitrate"
  profile_ref[resolved_audio_bitrate]="$audio_bitrate"
  profile_ref[resolved_video_codec]="$video_codec"
  profile_ref[resolved_audio_codec]="$audio_codec"
  video_filter="$(config_get "$profile_name" video_filter)"
  if [[ -z "$video_filter" ]]; then
    video_filter="scale=${width}:${height}"
  fi

  profile_ref[resolved_crf]="$crf_value"
  profile_ref[resolved_video_filter]="$video_filter"

  log_verbose "Profile $(config_get "$profile_name" name) resolved preset=${preset} width=${width} height=${height}"
  log_verbose "Profile $(config_get "$profile_name" name) bitrate map video=${video_bitrate} audio=${audio_bitrate}"
  log_verbose "Profile $(config_get "$profile_name" name) filter=${video_filter}"
  log_verbose "Profile $(config_get "$profile_name" name) codec map video=${video_codec} audio=${audio_codec} crf=${crf_value}"
}

build_ffmpeg_command() {
  local job_name="$1"
  local profile_name="$2"
  local cmd_name="$3"
  local -n job_ref="$job_name"
  local -n profile_ref="$profile_name"
  local -n cmd_ref="$cmd_name"
  local overwrite_flag
  local ffmpeg_bin
  local input_path
  local output_path
  local audio_sample_rate
  local extra_output_args
  local -a extra_args=()

  ffmpeg_bin="$(config_get "$job_name" ffmpeg ffmpeg)"
  input_path="$(config_get "$job_name" input)"
  output_path="$(config_get "$profile_name" output)"
  overwrite_flag="$(normalize_bool "$(config_get "$job_name" overwrite false)")"

  cmd_ref=("$ffmpeg_bin")
  if [[ "$overwrite_flag" == "true" ]]; then
    cmd_ref+=("-y")
  else
    cmd_ref+=("-n")
  fi

  cmd_ref+=(
    "-i" "$input_path"
    "-vf" "${profile_ref[resolved_video_filter]}"
    "-c:v" "${profile_ref[resolved_video_codec]}"
    "-b:v" "${profile_ref[resolved_video_bitrate]}"
    "-c:a" "${profile_ref[resolved_audio_codec]}"
    "-b:a" "${profile_ref[resolved_audio_bitrate]}"
  )

  audio_sample_rate="$(config_get "$profile_name" audio_sample_rate)"
  if [[ -n "$audio_sample_rate" && "$audio_sample_rate" != "source" ]]; then
    cmd_ref+=("-ar" "$audio_sample_rate")
  fi

  case "${profile_ref[resolved_video_codec]}" in
    libx264|libx265)
      cmd_ref+=("-crf" "${profile_ref[resolved_crf]}")
      ;;
  esac

  extra_output_args="$(config_get "$profile_name" extra_output_args)"
  if [[ -n "$extra_output_args" ]]; then
    split_words "$extra_output_args" extra_args
    cmd_ref+=("${extra_args[@]}")
  fi

  cmd_ref+=(
    "-movflags" "+faststart"
    "$output_path"
  )
}

run_ffmpeg_command() {
  local cmd_name="$1"
  local -n cmd_ref="$cmd_name"
  local status

  if [[ "${VTX_VERBOSE}" == "1" ]]; then
    log_info "Executing: $(join_command_for_display "${cmd_ref[@]}")"
  fi

  if [[ -n "${VTX_LOG_FILE:-}" ]]; then
    set +e
    "${cmd_ref[@]}" 2>&1 | tee -a "$VTX_LOG_FILE"
    status=${PIPESTATUS[0]}
    set -e
    return "$status"
  fi

  "${cmd_ref[@]}"
}
