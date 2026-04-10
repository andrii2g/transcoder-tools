# Config format

`vtx` uses simple `key=value` files.

Rules:

- blank lines are ignored
- lines beginning with `#` are ignored
- keys and values are trimmed
- one file contains one job or one output profile

## Job files

Job files define the shared execution context for one input video.

Example:

```config
input=./input/source.mp4
ffmpeg=ffmpeg
overwrite=true
outputs=./profiles/example-1080p.conf,./profiles/example-custom.conf
```

### Job fields

- `input`
  - required
  - path to the source media file
- `ffmpeg`
  - optional
  - defaults to `ffmpeg`
  - lets you point to a custom binary if needed
- `overwrite`
  - optional
  - defaults to `false`
  - accepted values include `true` and `false`
- `outputs`
  - required
  - comma-separated list of profile file paths

## Profile files

Profile files define one output video.

Example using preset bitrate defaults:

```config
name=720p-h264-aac
preset=720p
video_codec=h264
audio_codec=aac
audio_sample_rate=48000
quality=standard
output=./out/source-720p.mp4
```

Example overriding preset bitrate defaults:

```config
name=720p-h264-aac-custom-bitrate
preset=720p
video_codec=h264
audio_codec=aac
video_bitrate=2500k
audio_bitrate=128k
audio_sample_rate=48000
quality=standard
output=./out/source-720p.mp4
```

### Required profile fields

- `name`
- `preset`
- `video_codec`
- `audio_codec`
- `output`

### Required only for `preset=custom`

- `width`
- `height`
- `video_bitrate`
- `audio_bitrate`

### Optional profile fields

- `video_bitrate`
  - overrides preset default for known presets
- `audio_bitrate`
  - overrides preset default for known presets
- `audio_sample_rate`
- `quality`
  - defaults to `standard`
- `crf`
  - required only when `quality=custom`
- `width`
- `height`

## Override rules

Preset dimensions and bitrates are the default source of `width`, `height`, `video_bitrate`, and `audio_bitrate`.

Rules in v1:

- `preset=custom` requires `width`, `height`, `video_bitrate`, and `audio_bitrate`
- if either `width` or `height` is set, both must be set
- explicit `width` and `height` override preset dimensions
- explicit `video_bitrate` and `audio_bitrate` override preset bitrates independently

## Codec mapping

Friendly values are mapped to common `ffmpeg` codec names:

- `h264` -> `libx264`
- `h265` -> `libx265`
- `aac` -> `aac`
- `mp3` -> `libmp3lame`

Any other value is passed through as-is, which allows controlled custom codec usage without exposing every option in the CLI.

## Quality mapping

- `standard` -> `crf 22`
- `high` -> `crf 18`
- `small` -> `crf 25`
- `custom` -> requires `crf=<value>`

CRF is applied automatically for H.264 and H.265 outputs in v1.
