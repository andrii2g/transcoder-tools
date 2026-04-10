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
video_bitrate=5000k
audio_bitrate=192k
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

CRF is applied for H.264 and H.265 outputs in v1.


## Notes

- Sample jobs point at `./input/source.mp4`. Replace that file with a real input video before running real transcodes.
- Output directories are created automatically before execution.
- The v1 implementation intentionally hides most raw `ffmpeg` flags.