# Transcoder Tools

`transcoder-tools` is a Bash toolkit for running common `ffmpeg` transcoding workflows through small, readable config files instead of long command lines.

The main CLI is `vtx`, a config-driven video transcoder that turns one input video into one or more outputs using friendly concepts such as `720p`, `h264`, `aac`, `video_bitrate`, `audio_bitrate`, and `quality`.

## Why we need it?

`ffmpeg` is powerful, but routine transcoding jobs are easy to make inconsistent and hard to review when every invocation is hand-written. `vtx` puts a narrow, opinionated layer on top:

- user-friendly abstraction over raw `ffmpeg` flags
- config-driven jobs that are easy to save and rerun
- simple first version that stays extensible for HLS, live, and OBS workflows (planned)

## Quick start

Requirements: Bash 4+ and `ffmpeg`.

See [Installation](docs/installation.md) for `ffmpeg` setup, executable permissions, and optional `PATH` configuration.

Basic usage:

```bash
./bin/vtx.sh --version
./bin/vtx.sh list-presets
./bin/vtx.sh validate --job ./jobs/example-multi-output.conf
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf --dry-run
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf --verbose --log ./logs/transcode.log
```

Make the script executable on Linux if needed:

```bash
chmod +x ./bin/vtx.sh
```

## Core concepts

`vtx` uses job files, profile files, friendly preset names, and a small quality model to hide most raw `ffmpeg` flags from end users.

See [Core concepts](docs/concepts.md) for how jobs, profiles, presets, and quality values work.

## Dry-run mode

Dry-run mode fully resolves and validates the configs, then prints the generated `ffmpeg` commands without executing them:

```bash
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf --dry-run
```

Use `--log <path>` with `transcode` when you want to save generated commands, verbose resolution details, and `ffmpeg` output for later analysis:

```bash
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf --verbose --log ./logs/transcode.log
```

## Directory overview

```text
transcoder-tools/
  bin/
  lib/
  presets/
  jobs/
  profiles/
  docs/
```

- [`bin/vtx.sh`](transcoder-tools/bin/vtx.sh): main CLI entrypoint
- [`lib/`](transcoder-tools/lib): parser, presets, validation, and ffmpeg command builder
- [`jobs/`](transcoder-tools/jobs): sample job configs
- [`profiles/`](transcoder-tools/profiles): sample output profile configs
- [`presets/`](transcoder-tools/presets): preset reference files
- [`docs/`](transcoder-tools/docs): user-facing docs

## Example commands

```bash
./bin/vtx.sh list-presets
./bin/vtx.sh validate --job ./jobs/example-multi-output.conf
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf
./bin/vtx.sh transcode --job ./jobs/example-custom.conf --dry-run --verbose
```

## Documentation

- [Installation](docs/installation.md): ffmpeg setup and vtx shell configuration
- [CLI reference](docs/cli.md): commands, flags, and examples
- [Core concepts](docs/concepts.md): how jobs, profiles, presets, and quality values work
- [Config format](docs/config-format.md): required fields, optional fields, and override rules
- [Preset details](docs/presets.md): preset dimensions, width/height overrides, and codec mappings
- [Roadmap](docs/roadmap.md): planned HLS, live OBS, and adaptive streaming work
- [References](docs/references.md): external FFmpeg, HLS, CORS, and player resources
- [Changelog](CHANGELOG.md): version-specific release notes
