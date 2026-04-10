# Changelog

All notable changes to `transcoder-tools` are documented here.

## 0.2.0

Added logging support for deeper run analysis.

Version `0.2.0` adds:

- `--log <path>` for `transcode`
- automatic log directory creation
- generated command logging in normal and dry-run modes
- verbose resolution details in log files when `--verbose` is enabled
- `ffmpeg` output capture into the same log file during real transcodes

## 0.1.0

Initial Bash MVP for the `vtx` CLI.

Version `0.1.0` supports:

- one input video per job
- one or more output profiles per job
- sequential `ffmpeg` execution, one command per output
- validation before execution
- dry-run output for generated commands
- verbose mode for resolved config details
- bundled preset files for `360p`, `480p`, `720p`, `1080p`, `2K`, `4K`, `8K`, and `custom`
- default preset dimensions, video bitrates, audio bitrates, codecs, sample rate, and quality values
- user-created preset files under `presets/`
- custom preset selection with `preset=<name>` or `preset=<path>` in profile files
- small profile files that can inherit defaults from preset files and only define output-specific values
- profile-level overrides for preset dimensions, bitrates, codecs, sample rate, quality, and CRF

Outputs are MP4-focused in v1.
