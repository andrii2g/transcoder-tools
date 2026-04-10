# Presets

`vtx` provides a small set of normalized output presets so users can think in common delivery sizes and bandwidth targets instead of raw scale and bitrate flags.

## Supported presets

| Preset | Dimensions | Video bitrate | Audio bitrate | Notes |
| --- | --- | --- | --- | --- |
| `360p` | `640x360` | `600k` | `64k` | Low-resolution web and mobile profile |
| `480p` | `854x480` | `900k` | `128k` | Standard definition profile |
| `720p` | `1280x720` | `1200k` | `128k` | HD profile |
| `1080p` | `1920x1080` | `4500k` | `192k` | Full HD profile |
| `2K` | `2560x1440` | `8000k` | `192k` | In `vtx`, `2K` is intentionally treated as a practical QHD-style preset |
| `4K` | `3840x2160` | `16000k` | `320k` | Ultra HD |
| `8K` | `7680x4320` | `40000k` | `320k` | Very high resolution output |
| `custom` | user-defined | required | required | Requires explicit `width`, `height`, `video_bitrate`, and `audio_bitrate` |

The bitrate defaults are intentionally practical starting points, not strict delivery recommendations for every source. Use explicit profile values when you need tighter control.

## Width, height, and bitrate overrides

Profiles can override preset dimensions by setting both `width` and `height`.

Profiles can also override preset bandwidth defaults by setting `video_bitrate`, `audio_bitrate`, or both.

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
- `preset=custom` always requires `width`, `height`, `video_bitrate`, and `audio_bitrate`
- explicit dimensions win over preset dimensions
- explicit bitrates win over preset bitrates

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
