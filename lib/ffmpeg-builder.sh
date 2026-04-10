#!/usr/bin/env bash

resolve_profile_runtime() {
  local profile_name="$1"
  local -n profile_ref="$profile_name"
  local width
  local height
  local preset
  local video_codec
  local audio_codec
  local quality
  local crf_value

  preset="$(config_get "$profile_name" preset)"
  resolve_dimensions \
    "$preset" \
    "$(config_get "$profile_name" width)" \
    "$(config_get "$profile_name" height)" \
    width \
    height

  video_codec="$(map_video_codec "$(config_get "$profile_name" video_codec)")"
  audio_codec="$(map_audio_codec "$(config_get "$profile_name" audio_codec)")"
  quality="$(config_get "$profile_name" quality standard)"
  crf_value="$(quality_to_crf "$quality" "$(config_get "$profile_name" crf)")"

  profile_ref[resolved_width]="$width"
  profile_ref[resolved_height]="$height"
  profile_ref[resolved_video_codec]="$video_codec"
  profile_ref[resolved_audio_codec]="$audio_codec"
  profile_ref[resolved_crf]="$crf_value"

  log_verbose "Profile $(config_get "$profile_name" name) resolved preset=${preset} width=${width} height=${height}"
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
    "-vf" "scale=${profile_ref[resolved_width]}:${profile_ref[resolved_height]}"
    "-c:v" "${profile_ref[resolved_video_codec]}"
    "-b:v" "$(config_get "$profile_name" video_bitrate)"
    "-c:a" "${profile_ref[resolved_audio_codec]}"
    "-b:a" "$(config_get "$profile_name" audio_bitrate)"
  )

  if [[ -n "$(config_get "$profile_name" audio_sample_rate)" ]]; then
    cmd_ref+=("-ar" "$(config_get "$profile_name" audio_sample_rate)")
  fi

  case "${profile_ref[resolved_video_codec]}" in
    libx264|libx265)
      cmd_ref+=("-crf" "${profile_ref[resolved_crf]}")
      ;;
  esac

  cmd_ref+=(
    "-movflags" "+faststart"
    "$output_path"
  )
}

run_ffmpeg_command() {
  local cmd_name="$1"
  local -n cmd_ref="$cmd_name"
  if [[ "${VTX_VERBOSE}" == "1" ]]; then
    log_info "Executing: $(join_command_for_display "${cmd_ref[@]}")"
  fi
  "${cmd_ref[@]}"
}
