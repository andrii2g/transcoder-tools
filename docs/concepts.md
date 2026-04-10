# Core concepts

`vtx` is designed around user-friendly transcoding concepts instead of raw `ffmpeg` command-line flags.

## How it works

`vtx` uses two config types:

- job files
- profile files

A job file defines the shared input and execution settings. It can reference one or more output profile files:

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
audio_sample_rate=48000
quality=standard
output=./out/source-1080p.mp4
```

The first implementation resolves each profile independently and executes one `ffmpeg` command per output, sequentially.

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

- `360p` -> `640x360`, `600k` video, `64k` audio
- `480p` -> `854x480`, `900k` video, `128k` audio
- `720p` -> `1280x720`, `1200k` video, `128k` audio
- `1080p` -> `1920x1080`, `4500k` video, `192k` audio
- `2K` -> `2560x1440`, `8000k` video, `192k` audio
- `4K` -> `3840x2160`, `16000k` video, `320k` audio
- `8K` -> `7680x4320`, `40000k` video, `320k` audio
- `custom` -> requires `width`, `height`, `video_bitrate`, and `audio_bitrate`

If `width`, `height`, `video_bitrate`, or `audio_bitrate` are explicitly set in a profile, they override the preset defaults where applicable.

## Quality model

The user-facing `quality` setting maps to CRF values:

- `standard` -> `22`
- `high` -> `18`
- `small` -> `25`
- `custom` -> requires explicit `crf`

CRF is applied for H.264 and H.265 outputs in v1.
