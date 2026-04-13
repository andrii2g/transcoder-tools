# Changelog

All notable changes to `transcoder-tools` are documented here.

## 0.6.0

Added initial live RTMP-to-HLS support.

Version `0.6.0` adds:

- `input_mode=file|rtmp` with RTMP URL validation and file-input backward compatibility
- job-level `input_args` for advanced FFmpeg input flags, mainly for live ingest tuning
- `mode=live-hls` for ingesting an RTMP stream and producing multiple HLS renditions in one FFmpeg process
- live HLS fields: `hls_list_size`, `hls_delete_segments`, and `hls_append_list`
- computed live HLS flags when `hls_flags` is omitted
- live RTMP-to-HLS example job and profiles
- low-latency live tuning fields in profiles: `gop`, `keyint_min`, `sc_threshold`, `video_preset`, and `video_tune`
- OBS-to-HLS quick-start documentation using a local MediaMTX container
- updated HLS and config documentation for file-to-HLS versus live RTMP-to-HLS behavior

## 0.5.0

Added initial HLS output mode.

Version `0.5.0` adds:

- `mode=hls` for producing multiple HLS variant playlists from one input in a single FFmpeg process
- HLS segment generation beside each profile playlist output
- job-level HLS settings: `hls_segment_time`, `hls_playlist_type`, `hls_flags`, and required `hls_master_playlist`
- HLS documentation in `docs/hls.md`
- simple browser HLS test player in `docs/hls-player.html`
- workflow guide with Mermaid decision diagram in `docs/workflows.md`

## 0.4.0

Added multi-output transcode mode.

Version `0.4.0` adds:

- `mode=multi-output` for producing multiple MP4 outputs from one input in a single FFmpeg process
- default `mode=sequential` behavior preserved for existing jobs
- multi-output command generation using `filter_complex`, `split`, and per-output stream mapping
- optional audio mapping with `-map 0:a?` so source videos without audio do not fail only because audio is missing
- job-level `cpu_limit=<percent>%`; profile-level `cpu_limit` is rejected
- example multi-output mode job file

## 0.3.0

Added profile-level CPU management for transcode runs.

Version `0.3.0` adds:

- profile-only `cpu_limit=<percent>%` to resolve a best-effort FFmpeg `-threads` value from detected CPU cores
- validation for `cpu_limit` percentages from `1%` through `100%`
- verbose logging of detected CPU cores and resolved thread count
- example managed CPU job and profile files

Note: `cpu_limit` moved from profile-level to job-level in `0.4.0` because it controls one FFmpeg process.
