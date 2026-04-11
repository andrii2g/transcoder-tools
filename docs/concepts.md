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
mode=sequential
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

## Modes

`mode=sequential` is the default and runs one FFmpeg command per output profile.

`mode=multi-output` builds one FFmpeg command for all output profiles. It is useful when one source video should produce several MP4 renditions in one process. The command uses optional audio mapping (`-map 0:a?`) so source videos without audio do not fail only because audio is missing.

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

Profile values override preset values where applicable. Bundled presets default to `audio_sample_rate=48000`, and profiles can use `audio_sample_rate=source` to preserve the source sample rate. Jobs can set `cpu_limit=50%` to make processing less aggressive on the current machine. Advanced ffmpeg details such as custom video filters can live in preset files so profiles remain output-focused.

## Quality model

The user-facing `quality` setting maps to CRF values:

- `standard` -> `22`
- `high` -> `18`
- `small` -> `25`
- `custom` -> requires explicit `crf`

CRF is applied for H.264 and H.265 outputs in v1.
