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

append_job_cpu_threads() {
  local job_name="$1"
  local cmd_name="$2"
  local -n cmd_ref="$cmd_name"
  local cpu_limit
  local cpu_threads

  cpu_limit="$(config_get "$job_name" cpu_limit)"
  if [[ -n "$cpu_limit" ]]; then
    cpu_threads="$(resolve_cpu_threads "$cpu_limit")"
    cmd_ref+=("-threads" "$cpu_threads")
    log_verbose "Job cpu_limit=${cpu_limit} threads=${cpu_threads} cores=$(detect_cpu_cores)"
  fi
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

  append_job_cpu_threads "$job_name" "$cmd_name"

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

build_multi_output_ffmpeg_command() {
  local job_name="$1"
  local profiles_name="$2"
  local cmd_name="$3"
  local -n profiles_ref="$profiles_name"
  local -n cmd_ref="$cmd_name"
  local ffmpeg_bin
  local input_path
  local overwrite_flag
  local count
  local filter_complex=""
  local split_outputs=""
  local idx
  local profile_name
  local output_path
  local audio_sample_rate
  local extra_output_args
  local -a extra_args=()

  ffmpeg_bin="$(config_get "$job_name" ffmpeg ffmpeg)"
  input_path="$(config_get "$job_name" input)"
  overwrite_flag="$(normalize_bool "$(config_get "$job_name" overwrite false)")"
  count="${#profiles_ref[@]}"

  cmd_ref=("$ffmpeg_bin")
  if [[ "$overwrite_flag" == "true" ]]; then
    cmd_ref+=("-y")
  else
    cmd_ref+=("-n")
  fi

  append_job_cpu_threads "$job_name" "$cmd_name"
  cmd_ref+=("-i" "$input_path")

  for ((idx = 0; idx < count; idx++)); do
    split_outputs+="[v${idx}]"
  done

  filter_complex="[0:v]split=${count}${split_outputs}"
  for ((idx = 0; idx < count; idx++)); do
    profile_name="${profiles_ref[$idx]}"
    local -n profile_ref="$profile_name"
    filter_complex+=";[v${idx}]${profile_ref[resolved_video_filter]}[v${idx}out]"
    unset -n profile_ref
  done

  cmd_ref+=("-filter_complex" "$filter_complex")

  for ((idx = 0; idx < count; idx++)); do
    profile_name="${profiles_ref[$idx]}"
    local -n profile_ref="$profile_name"
    output_path="$(config_get "$profile_name" output)"

    cmd_ref+=(
      "-map" "[v${idx}out]"
      "-map" "0:a?"
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

    cmd_ref+=("-movflags" "+faststart" "$output_path")
    unset -n profile_ref
  done
}
hls_segment_pattern_for_output() {
  local output_path="$1"
  local parent
  local filename
  local stem
  parent="$(dirname "$output_path")"
  filename="$(basename "$output_path")"
  stem="${filename%.*}"
  printf '%s/%s_%%03d.ts' "$parent" "$stem"
}

bitrate_to_bits() {
  local value="$1"
  local number
  local suffix
  value="$(trim "$value")"

  if [[ "$value" =~ ^([0-9]+)([kKmM]?)$ ]]; then
    number="${BASH_REMATCH[1]}"
    suffix="${BASH_REMATCH[2]}"
    case "$suffix" in
      k|K) printf '%s' "$((number * 1000))" ;;
      m|M) printf '%s' "$((number * 1000000))" ;;
      *) printf '%s' "$number" ;;
    esac
    return 0
  fi

  printf '0'
}

hls_variant_bandwidth() {
  local profile_name="$1"
  local -n profile_ref="$profile_name"
  local video_bits
  local audio_bits
  video_bits="$(bitrate_to_bits "${profile_ref[resolved_video_bitrate]}")"
  audio_bits="$(bitrate_to_bits "${profile_ref[resolved_audio_bitrate]}")"
  printf '%s' "$((video_bits + audio_bits))"
}

relative_path_from_dir() {
  local from_dir="$1"
  local target="$2"
  local from_norm
  local target_norm

  if command -v realpath >/dev/null 2>&1; then
    realpath -m --relative-to="$from_dir" "$target" 2>/dev/null && return 0
  fi

  from_norm="${from_dir#./}"
  target_norm="${target#./}"

  if [[ "$from_norm" == "." ]]; then
    printf '%s' "$target_norm"
    return 0
  fi

  if [[ "$target_norm" == "$from_norm"/* ]]; then
    printf '%s' "${target_norm#"$from_norm/"}"
    return 0
  fi

  printf '%s' "$target"
}

write_hls_master_playlist() {
  local master_path="$1"
  local profiles_name="$2"
  local -n profiles_ref="$profiles_name"
  local master_dir
  local profile_name
  local output_path
  local uri
  local bandwidth
  local width
  local height

  [[ -n "$master_path" ]] || return 0
  ensure_parent_dir "$master_path"
  master_dir="$(dirname "$master_path")"

  {
    printf '#EXTM3U\n'
    printf '#EXT-X-VERSION:3\n'
    for profile_name in "${profiles_ref[@]}"; do
      local -n profile_ref="$profile_name"
      output_path="$(config_get "$profile_name" output)"
      uri="$(relative_path_from_dir "$master_dir" "$output_path")"
      bandwidth="$(hls_variant_bandwidth "$profile_name")"
      width="${profile_ref[resolved_width]}"
      height="${profile_ref[resolved_height]}"
      printf '#EXT-X-STREAM-INF:BANDWIDTH=%s,RESOLUTION=%sx%s\n' "$bandwidth" "$width" "$height"
      printf '%s\n' "$uri"
      unset -n profile_ref
    done
  } > "$master_path" || die "Cannot write HLS master playlist: $master_path"

  log_info "Wrote HLS master playlist: $master_path"
}

build_hls_ffmpeg_command() {
  local job_name="$1"
  local profiles_name="$2"
  local cmd_name="$3"
  local -n profiles_ref="$profiles_name"
  local -n cmd_ref="$cmd_name"
  local ffmpeg_bin
  local input_path
  local overwrite_flag
  local count
  local filter_complex=""
  local split_outputs=""
  local idx
  local profile_name
  local output_path
  local audio_sample_rate
  local extra_output_args
  local segment_time
  local playlist_type
  local hls_flags
  local segment_pattern
  local -a extra_args=()

  ffmpeg_bin="$(config_get "$job_name" ffmpeg ffmpeg)"
  input_path="$(config_get "$job_name" input)"
  overwrite_flag="$(normalize_bool "$(config_get "$job_name" overwrite false)")"
  count="${#profiles_ref[@]}"
  segment_time="$(config_get "$job_name" hls_segment_time 6)"
  playlist_type="$(config_get "$job_name" hls_playlist_type vod)"
  hls_flags="$(config_get "$job_name" hls_flags independent_segments)"

  cmd_ref=("$ffmpeg_bin")
  if [[ "$overwrite_flag" == "true" ]]; then
    cmd_ref+=("-y")
  else
    cmd_ref+=("-n")
  fi

  append_job_cpu_threads "$job_name" "$cmd_name"
  cmd_ref+=("-i" "$input_path")

  for ((idx = 0; idx < count; idx++)); do
    split_outputs+="[v${idx}]"
  done

  filter_complex="[0:v]split=${count}${split_outputs}"
  for ((idx = 0; idx < count; idx++)); do
    profile_name="${profiles_ref[$idx]}"
    local -n profile_ref="$profile_name"
    filter_complex+=";[v${idx}]${profile_ref[resolved_video_filter]}[v${idx}out]"
    unset -n profile_ref
  done

  cmd_ref+=("-filter_complex" "$filter_complex")

  for ((idx = 0; idx < count; idx++)); do
    profile_name="${profiles_ref[$idx]}"
    local -n profile_ref="$profile_name"
    output_path="$(config_get "$profile_name" output)"
    segment_pattern="$(hls_segment_pattern_for_output "$output_path")"

    cmd_ref+=(
      "-map" "[v${idx}out]"
      "-map" "0:a?"
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
      "-f" "hls"
      "-hls_time" "$segment_time"
      "-hls_playlist_type" "$playlist_type"
    )

    if [[ -n "$hls_flags" ]]; then
      cmd_ref+=("-hls_flags" "$hls_flags")
    fi

    cmd_ref+=(
      "-hls_segment_filename" "$segment_pattern"
      "$output_path"
    )
    unset -n profile_ref
  done
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
