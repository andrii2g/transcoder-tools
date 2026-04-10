# Presets

`vtx` provides a small set of normalized output presets so users can think in common delivery sizes instead of raw scale filters.

## Supported presets

| Preset | Resolved dimensions | Notes |
| --- | --- | --- |
| `360p` | `640x360` | Low-resolution web and mobile profile |
| `480p` | `854x480` | Standard definition profile |
| `720p` | `1280x720` | HD profile |
| `1080p` | `1920x1080` | Full HD profile |
| `2K` | `2560x1440` | In `vtx`, `2K` is intentionally treated as a practical QHD-style preset |
| `4K` | `3840x2160` | Ultra HD |
| `8K` | `7680x4320` | Very high resolution output |
| `custom` | user-defined | Requires explicit `width` and `height` |

## Width and height overrides

Profiles can override preset dimensions by setting both `width` and `height`.

Example:

```config
name=wide-720-override
preset=720p
width=1024
height=576
video_codec=h264
audio_codec=aac
video_bitrate=2200k
audio_bitrate=128k
output=./out/wide-override.mp4
```

Rules:

- both `width` and `height` must be present together
- `preset=custom` always requires both fields
- explicit dimensions win over preset defaults

## Codec mappings

The v1 codec abstraction keeps the user-facing config small:

- video
  - `h264` -> `libx264`
  - `h265` -> `libx265`
- audio
  - `aac` -> `aac`
  - `mp3` -> `libmp3lame`

Custom codec names are passed through if you want to target another known `ffmpeg` codec directly.

## Quality mappings

`quality` maps to CRF values:

- `standard` -> `22`
- `high` -> `18`
- `small` -> `25`
- `custom` -> `crf=<value>`
