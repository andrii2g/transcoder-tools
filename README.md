# Transcoder Tools

`transcoder-tools` is a Bash toolkit for running common `ffmpeg` transcoding workflows through small, readable config files instead of long command lines.

The main CLI is `vtx`, a config-driven video transcoder that turns one input video into one or more outputs using friendly concepts such as `720p`, `h264`, `aac`, `video_bitrate`, `audio_bitrate`, and `quality`.

## Why we need it?

`ffmpeg` is powerful, but routine transcoding jobs are easy to make inconsistent and hard to review when every invocation is hand-written. `vtx` puts a narrow, opinionated layer on top:

- user-friendly abstraction over raw `ffmpeg` flags
- config-driven jobs that are easy to save and rerun
- simple first version that stays extensible for HLS, live, and OBS workflows (planned)

## Current scope

`vtx` currently focuses on simple file-to-file MP4 transcoding from one input video into one or more output profiles.

See [CHANGELOG.md](CHANGELOG.md) for version-specific release notes.

## Quick start

Requirements:

- Bash 4+
- `ffmpeg`

Basic usage:

```bash
./bin/vtx.sh --version
./bin/vtx.sh list-presets
./bin/vtx.sh validate --job ./jobs/example-multi-output.conf
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf --dry-run
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf --verbose
```

Make the script executable on Linux if needed:

```bash
chmod +x ./bin/vtx.sh
```

## How it works

`vtx` uses two config types:

- job files
- profile files

One job can reference multiple profile files:

```config
input=./input/source.mp4
ffmpeg=ffmpeg
overwrite=true
outputs=./profiles/example-1080p.conf,./profiles/example-custom.conf
```

Each profile is self-contained and includes its own `output=` field:

```config
name=1080p-h264-aac
preset=1080p
video_codec=h264
audio_codec=aac
video_bitrate=5000k
audio_bitrate=192k
audio_sample_rate=48000
quality=standard
output=./out/source-1080p.mp4
```

## Presets

Supported preset names:

- `360p`
- `480p`
- `720p`
- `1080p`
- `2K`
- `4K`
- `8K`
- `custom`

Resolved mappings in v1:

- `360p` -> `640x360`
- `480p` -> `854x480`
- `720p` -> `1280x720`
- `1080p` -> `1920x1080`
- `2K` -> `2560x1440`
- `4K` -> `3840x2160`
- `8K` -> `7680x4320`
- `custom` -> requires `width` and `height`

If `width` and `height` are explicitly set in a profile, they override the preset defaults.

## Quality model

The user-facing `quality` setting maps to CRF values:

- `standard` -> `22`
- `high` -> `18`
- `small` -> `25`
- `custom` -> requires explicit `crf`

## Dry-run mode

Dry-run mode fully resolves and validates the configs, then prints the generated `ffmpeg` commands without executing them:

```bash
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf --dry-run
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

## Notes

- Sample jobs point at `./input/source.mp4`. Replace that file with a real input video before running real transcodes.
- Output directories are created automatically before execution.
- The v1 implementation intentionally hides most raw `ffmpeg` flags.

## Documentation

- [CLI reference](transcoder-tools/docs/cli.md)
- [Config format](transcoder-tools/docs/config-format.md)
- [Preset details](transcoder-tools/docs/presets.md)
- [Roadmap](transcoder-tools/docs/roadmap.md)
- [Changelog](CHANGELOG.md)

## Future direction

This repository is intentionally structured so `vtx` can grow into HLS packaging workflows, live transcoding modes for OBS-driven inputs, adaptive bitrate output sets, and generated HLS master playlists.

