#!/usr/bin/env bash

declare -Ar VTX_PRESET_WIDTHS=(
  [360p]=640
  [480p]=854
  [720p]=1280
  [1080p]=1920
  [2k]=2560
  [4k]=3840
  [8k]=7680
)

declare -Ar VTX_PRESET_HEIGHTS=(
  [360p]=360
  [480p]=480
  [720p]=720
  [1080p]=1080
  [2k]=1440
  [4k]=2160
  [8k]=4320
)

declare -Ar VTX_PRESET_VIDEO_BITRATES=(
  [360p]=600k
  [480p]=900k
  [720p]=1200k
  [1080p]=4500k
  [2k]=8000k
  [4k]=16000k
  [8k]=40000k
)

declare -Ar VTX_PRESET_AUDIO_BITRATES=(
  [360p]=64k
  [480p]=128k
  [720p]=128k
  [1080p]=192k
  [2k]=192k
  [4k]=320k
  [8k]=320k
)

declare -Ar VTX_PRESET_DESCRIPTIONS=(
  [360p]="Low resolution web/mobile profile"
  [480p]="Standard definition profile"
  [720p]="HD profile"
  [1080p]="Full HD profile"
  [2k]="Practical 2560x1440 profile for this tool"
  [4k]="Ultra HD 3840x2160 profile"
  [8k]="Ultra high resolution 7680x4320 profile"
  [custom]="User-defined dimensions and bitrates"
)

normalize_preset_name() {
  local preset
  preset="$(lower "$(trim "$1")")"
  case "$preset" in
    2k) printf '2k' ;;
    4k) printf '4k' ;;
    8k) printf '8k' ;;
    360p|480p|720p|1080p|custom) printf '%s' "$preset" ;;
    *) return 1 ;;
  esac
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

  if [[ -n "$explicit_width" || -n "$explicit_height" ]]; then
    [[ -n "$explicit_width" && -n "$explicit_height" ]] || die "width and height must be provided together"
    out_width_ref="$explicit_width"
    out_height_ref="$explicit_height"
    return 0
  fi

  if [[ "$preset" == "custom" ]]; then
    die "preset=custom requires width and height"
  fi

  out_width_ref="${VTX_PRESET_WIDTHS[$preset]}"
  out_height_ref="${VTX_PRESET_HEIGHTS[$preset]}"
}

resolve_bitrates() {
  local preset="$1"
  local explicit_video_bitrate="${2-}"
  local explicit_audio_bitrate="${3-}"
  local -n out_video_bitrate_ref="$4"
  local -n out_audio_bitrate_ref="$5"

  if [[ "$preset" == "custom" ]]; then
    [[ -n "$explicit_video_bitrate" ]] || die "preset=custom requires video_bitrate"
    [[ -n "$explicit_audio_bitrate" ]] || die "preset=custom requires audio_bitrate"
  fi

  if [[ -n "$explicit_video_bitrate" ]]; then
    out_video_bitrate_ref="$explicit_video_bitrate"
  else
    out_video_bitrate_ref="${VTX_PRESET_VIDEO_BITRATES[$preset]}"
  fi

  if [[ -n "$explicit_audio_bitrate" ]]; then
    out_audio_bitrate_ref="$explicit_audio_bitrate"
  else
    out_audio_bitrate_ref="${VTX_PRESET_AUDIO_BITRATES[$preset]}"
  fi
}

list_presets_table() {
  printf '%-10s %-14s %-14s %-14s %s\n' "Preset" "Dimensions" "Video bitrate" "Audio bitrate" "Typical use"
  printf '%-10s %-14s %-14s %-14s %s\n' "------" "----------" "-------------" "-------------" "-----------"
  printf '%-10s %-14s %-14s %-14s %s\n' "360p" "640x360" "${VTX_PRESET_VIDEO_BITRATES[360p]}" "${VTX_PRESET_AUDIO_BITRATES[360p]}" "${VTX_PRESET_DESCRIPTIONS[360p]}"
  printf '%-10s %-14s %-14s %-14s %s\n' "480p" "854x480" "${VTX_PRESET_VIDEO_BITRATES[480p]}" "${VTX_PRESET_AUDIO_BITRATES[480p]}" "${VTX_PRESET_DESCRIPTIONS[480p]}"
  printf '%-10s %-14s %-14s %-14s %s\n' "720p" "1280x720" "${VTX_PRESET_VIDEO_BITRATES[720p]}" "${VTX_PRESET_AUDIO_BITRATES[720p]}" "${VTX_PRESET_DESCRIPTIONS[720p]}"
  printf '%-10s %-14s %-14s %-14s %s\n' "1080p" "1920x1080" "${VTX_PRESET_VIDEO_BITRATES[1080p]}" "${VTX_PRESET_AUDIO_BITRATES[1080p]}" "${VTX_PRESET_DESCRIPTIONS[1080p]}"
  printf '%-10s %-14s %-14s %-14s %s\n' "2K" "2560x1440" "${VTX_PRESET_VIDEO_BITRATES[2k]}" "${VTX_PRESET_AUDIO_BITRATES[2k]}" "${VTX_PRESET_DESCRIPTIONS[2k]}"
  printf '%-10s %-14s %-14s %-14s %s\n' "4K" "3840x2160" "${VTX_PRESET_VIDEO_BITRATES[4k]}" "${VTX_PRESET_AUDIO_BITRATES[4k]}" "${VTX_PRESET_DESCRIPTIONS[4k]}"
  printf '%-10s %-14s %-14s %-14s %s\n' "8K" "7680x4320" "${VTX_PRESET_VIDEO_BITRATES[8k]}" "${VTX_PRESET_AUDIO_BITRATES[8k]}" "${VTX_PRESET_DESCRIPTIONS[8k]}"
  printf '%-10s %-14s %-14s %-14s %s\n' "custom" "user-defined" "required" "required" "${VTX_PRESET_DESCRIPTIONS[custom]}"
}
