# Changelog

All notable changes to `transcoder-tools` are documented here.

## 0.1.0

Initial Bash MVP for the `vtx` CLI.

Version `0.1.0` supports:

- one input video per job
- one or more output profiles per job
- sequential `ffmpeg` execution, one command per output
- validation before execution
- dry-run output for generated commands
- verbose mode for resolved config details

Outputs are MP4-focused in v1.
