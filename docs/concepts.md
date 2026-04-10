# Core concepts

`vtx` is designed around user-friendly transcoding concepts instead of raw `ffmpeg` command-line flags.

## How it works

`vtx` uses three small config types:

- job files
- profile files
- preset files

A job file defines the shared input and execution settings. It can reference one or more output profile files:

```config
input=./input/source.mp4
ffmpeg=ffmpeg
overwrite=true
outputs=./profiles/example-1080p.conf,./profiles/example-custom-preset.conf
```

Each profile defines one output and references a preset:

```config
name=1080p-output
preset=1080p
output=./out/source-1080p.mp4
```

The preset provides reusable transcoding defaults:

```config
name=1080p
width=1920
height=1080
video_codec=h264
audio_codec=aac
video_bitrate=4500k
audio_bitrate=192k
audio_sample_rate=48000
quality=standard
```

The first implementation resolves each profile independently and executes one `ffmpeg` command per output, sequentially.

## Presets

Bundled preset names:

- `360p`
- `480p`
- `720p`
- `1080p`
- `2K`
- `4K`
- `8K`
- `custom`

Resolved mappings in v1:

- `360p` -> `640x360`, `600k` video, `64k` audio
- `480p` -> `854x480`, `900k` video, `128k` audio
- `720p` -> `1280x720`, `1200k` video, `128k` audio
- `1080p` -> `1920x1080`, `4500k` video, `192k` audio
- `2K` -> `2560x1440`, `8000k` video, `192k` audio
- `4K` -> `3840x2160`, `16000k` video, `320k` audio
- `8K` -> `7680x4320`, `40000k` video, `320k` audio
- `custom` -> template for user-defined values

You can copy any preset file or create a new one under `presets/`, then reference it from a profile with `preset=<name>`.

Profile values override preset values where applicable.

## Quality model

The user-facing `quality` setting maps to CRF values:

- `standard` -> `22`
- `high` -> `18`
- `small` -> `25`
- `custom` -> requires explicit `crf`

CRF is applied for H.264 and H.265 outputs in v1.
