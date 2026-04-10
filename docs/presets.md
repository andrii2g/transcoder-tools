# Presets

`vtx` provides a small set of normalized output presets so users can think in common delivery sizes and bandwidth targets instead of raw scale and bitrate flags.

Bundled preset files live directly in `presets/`. Example presets live in `presets/examples/` so they do not mix with the default preset set.

## Supported bundled presets

| Preset | Dimensions | Video bitrate | Audio bitrate | Default codecs | Notes |
| --- | --- | --- | --- | --- | --- |
| `360p` | `640x360` | `600k` | `64k` | `h264` / `aac` | Low-resolution web and mobile profile |
| `480p` | `854x480` | `900k` | `128k` | `h264` / `aac` | Standard definition profile |
| `720p` | `1280x720` | `1200k` | `128k` | `h264` / `aac` | HD profile |
| `1080p` | `1920x1080` | `4500k` | `192k` | `h264` / `aac` | Full HD profile |
| `2K` | `2560x1440` | `8000k` | `192k` | `h264` / `aac` | In `vtx`, `2K` is intentionally treated as a practical QHD-style preset |
| `4K` | `3840x2160` | `16000k` | `320k` | `h265` / `aac` | Ultra HD |
| `8K` | `7680x4320` | `40000k` | `320k` | `h265` / `aac` | Very high resolution output |
| `custom` | user-defined | required | required | required | Template requiring explicit dimensions, codecs, and bitrates |

The bitrate defaults are practical starting points, not strict delivery recommendations for every source. Use explicit profile values or a custom preset when you need tighter control.

## Custom preset files

You can create your own reusable presets by copying a bundled preset file or creating a new file under `presets/` or a project-specific subfolder such as `presets/examples/`.

Example:

```bash
cp ./presets/720p.conf ./presets/examples/social-square.conf
```

Then edit the new preset:

```config
name=social-square
width=1080
height=1080
video_codec=h264
audio_codec=aac
video_bitrate=1800k
audio_bitrate=128k
audio_sample_rate=48000
quality=high
description=Square social media export
```

Reference it from a profile:

```config
name=social-square-output
preset=./presets/examples/social-square.conf
output=./out/source-social-square.mp4
```

The profile can stay small because the preset provides the dimensions, codecs, bitrates, sample rate, and quality. Bundled presets use `audio_sample_rate=48000` by default.

## Advanced preset-only ffmpeg options

Basic users should continue using width, height, codec, bitrate, and quality fields. Advanced users can place selected raw ffmpeg behavior in a custom preset file so output profiles stay simple.

Supported advanced preset-only fields:

- `video_filter`: replaces the generated `scale=WIDTH:HEIGHT` filter
- `extra_output_args`: appends simple whitespace-separated ffmpeg output arguments before the output file

These fields are intentionally only allowed in preset files, not profile files.

Example preset with aspect-ratio preserving scale and centered padding:

```config
name=480p-contain
width=854
height=480
video_codec=h264
audio_codec=aac
video_bitrate=900k
audio_bitrate=128k
audio_sample_rate=48000
quality=standard
video_filter=scale=854:480:force_original_aspect_ratio=decrease,pad=854:480:(ow-iw)/2:(oh-ih)/2
extra_output_args=-pix_fmt yuv420p
description=480p preset preserving aspect ratio with centered padding
```

Profile using that preset:

```config
name=480p-contained-output
preset=./presets/examples/480p-contain.conf
output=./out/source-480p-contained.mp4
```

`extra_output_args` is parsed as simple whitespace-separated arguments. Keep complex shell quoting out of config files in v1.

## Audio sample rate

Preset files can define `audio_sample_rate=48000`, which is the default used by bundled presets.

Profiles can override that value:

```config
audio_sample_rate=44100
```

Profiles or presets can also use `source` to preserve the source sample rate by omitting `-ar`:

```config
audio_sample_rate=source
```

## Preset lookup

`preset=<name>` loads `./presets/<name>.conf` from the repository root.

Examples:

```config
preset=720p
preset=./presets/examples/social-square.conf
preset=./presets/examples/square-h264-aac.conf
```

You can also point directly to a preset file path:

```config
preset=./presets/examples/social-square.conf
```

If a profile omits `preset=`, `vtx` will try to use the profile `name` as a preset name. This is convenient for very small output profiles, but explicit `preset=` is clearer and recommended.

## Override rules

Preset values are defaults. Profile values win.

A profile can override preset dimensions by setting both `width` and `height`.

A profile can override preset bandwidth defaults by setting `video_bitrate`, `audio_bitrate`, or both.

Example:

```config
name=wide-720-override
preset=720p
width=1024
height=576
video_bitrate=2200k
output=./out/wide-override.mp4
```

Rules:

- both `width` and `height` must be present together
- resolved profiles must have `width`, `height`, `video_codec`, `audio_codec`, `video_bitrate`, and `audio_bitrate`
- explicit profile dimensions win over preset dimensions
- explicit profile bitrates win over preset bitrates
- explicit profile codecs win over preset codecs

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
