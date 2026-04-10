#!/usr/bin/env bash

VTX_BUILTIN_PRESETS=(360p 480p 720p 1080p 2k 4k 8k custom)

normalize_preset_name() {
  local preset
  preset="$(lower "$(trim "$1")")"
  preset="${preset%.conf}"
  [[ -n "$preset" ]] || return 1
  printf '%s' "$preset"
}

preset_file_for() {
  local preset="$1"
  local normalized
  normalized="$(normalize_preset_name "$preset")" || return 1

  if [[ "$preset" == */* || "$preset" == *\\* ]]; then
    [[ -f "$preset" ]] || return 1
    printf '%s' "$preset"
    return 0
  fi

  local candidate="$VTX_ROOT/presets/${normalized}.conf"
  [[ -f "$candidate" ]] || return 1
  printf '%s' "$candidate"
}

load_preset_config() {
  local preset="$1"
  local out_name="$2"
  local preset_path

  preset_path="$(preset_file_for "$preset")" || return 1
  read_config_file "$preset_path" "$out_name"
}

apply_profile_preset_defaults() {
  local profile_name="$1"
  local preset_name="$2"
  local -n profile_ref="$profile_name"
  local -A preset_cfg=()
  local key

  load_preset_config "$preset_name" preset_cfg || die "Unsupported preset or preset file not found: $preset_name"
  profile_ref[preset]="$(normalize_preset_name "$preset_name")"

  for key in width height video_bitrate audio_bitrate video_codec audio_codec audio_sample_rate quality crf video_filter extra_output_args; do
    if [[ -z "$(config_get "$profile_name" "$key")" && -n "$(config_get preset_cfg "$key")" ]]; then
      profile_ref["$key"]="$(config_get preset_cfg "$key")"
    fi
  done

  log_verbose "Applied preset defaults from $(preset_file_for "$preset_name")"
}

normalize_quality_name() {
  local quality
  quality="$(lower "$(trim "$1")")"
  case "$quality" in
    standard) printf 'standard' ;;
    high|small|custom) printf '%s' "$quality" ;;
    *) return 1 ;;
  esac
}

quality_to_crf() {
  local quality="$1"
  local custom_crf="${2-}"
  case "$quality" in
    standard) printf '22' ;;
    high) printf '18' ;;
    small) printf '25' ;;
    custom)
      [[ -n "$custom_crf" ]] || die "quality=custom requires crf"
      printf '%s' "$custom_crf"
      ;;
    *) die "Unsupported quality: $quality" ;;
  esac
}

map_video_codec() {
  local codec
  codec="$(lower "$(trim "$1")")"
  case "$codec" in
    h264) printf 'libx264' ;;
    h265) printf 'libx265' ;;
    *) printf '%s' "$codec" ;;
  esac
}

map_audio_codec() {
  local codec
  codec="$(lower "$(trim "$1")")"
  case "$codec" in
    aac) printf 'aac' ;;
    mp3) printf 'libmp3lame' ;;
    *) printf '%s' "$codec" ;;
  esac
}

resolve_dimensions() {
  local preset="$1"
  local explicit_width="${2-}"
  local explicit_height="${3-}"
  local -n out_width_ref="$4"
  local -n out_height_ref="$5"

  [[ -n "$explicit_width" && -n "$explicit_height" ]] || die "preset=$preset requires width and height"
  out_width_ref="$explicit_width"
  out_height_ref="$explicit_height"
}

resolve_bitrates() {
  local preset="$1"
  local explicit_video_bitrate="${2-}"
  local explicit_audio_bitrate="${3-}"
  local -n out_video_bitrate_ref="$4"
  local -n out_audio_bitrate_ref="$5"

  [[ -n "$explicit_video_bitrate" ]] || die "preset=$preset requires video_bitrate"
  [[ -n "$explicit_audio_bitrate" ]] || die "preset=$preset requires audio_bitrate"
  out_video_bitrate_ref="$explicit_video_bitrate"
  out_audio_bitrate_ref="$explicit_audio_bitrate"
}

print_preset_row() {
  local preset_file="$1"
  local -A preset_cfg=()
  local preset_name
  local width
  local height
  local video_bitrate
  local audio_bitrate
  local description

  read_config_file "$preset_file" preset_cfg
  preset_name="$(config_get preset_cfg name "$(basename "$preset_file" .conf)")"
  width="$(config_get preset_cfg width user-defined)"
  height="$(config_get preset_cfg height user-defined)"
  video_bitrate="$(config_get preset_cfg video_bitrate)"
  audio_bitrate="$(config_get preset_cfg audio_bitrate)"
  [[ -n "$video_bitrate" ]] || video_bitrate="required"
  [[ -n "$audio_bitrate" ]] || audio_bitrate="required"
  description="$(config_get preset_cfg description '')"

  if [[ -n "$width" && -n "$height" && "$width" != "user-defined" && "$height" != "user-defined" ]]; then
    printf '%-16s %-14s %-14s %-14s %s\n' "$preset_name" "${width}x${height}" "$video_bitrate" "$audio_bitrate" "$description"
  else
    printf '%-16s %-14s %-14s %-14s %s\n' "$preset_name" "user-defined" "$video_bitrate" "$audio_bitrate" "$description"
  fi
}

list_presets_table() {
  local preset
  local preset_file
  local seen=""

  printf '%-16s %-14s %-14s %-14s %s\n' "Preset" "Dimensions" "Video bitrate" "Audio bitrate" "Typical use"
  printf '%-16s %-14s %-14s %-14s %s\n' "------" "----------" "-------------" "-------------" "-----------"

  for preset in "${VTX_BUILTIN_PRESETS[@]}"; do
    preset_file="$VTX_ROOT/presets/${preset}.conf"
    if [[ -f "$preset_file" ]]; then
      print_preset_row "$preset_file"
      seen="${seen}|${preset}|"
    fi
  done

  for preset_file in "$VTX_ROOT"/presets/*.conf; do
    [[ -f "$preset_file" ]] || continue
    preset="$(basename "$preset_file" .conf)"
    if [[ "$seen" == *"|${preset}|"* ]]; then
      continue
    fi
    print_preset_row "$preset_file"
  done
}
