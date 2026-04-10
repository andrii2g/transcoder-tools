# Config format

`vtx` uses simple `key=value` files.

Rules:

- blank lines are ignored
- lines beginning with `#` are ignored
- keys and values are trimmed
- one file contains one job, one output profile, or one preset

## Job files

Job files define the shared execution context for one input video.

Example:

```config
input=./input/source.mp4
ffmpeg=ffmpeg
overwrite=true
outputs=./profiles/example-1080p.conf,./profiles/example-custom-preset.conf
```

### Job fields

- `input`: required source media path
- `ffmpeg`: optional ffmpeg executable, defaults to `ffmpeg`
- `overwrite`: optional boolean, defaults to `false`
- `outputs`: required comma-separated list of profile file paths

## Profile files

Profile files define one output video.

Minimal profile using preset defaults:

```config
name=720p-output
preset=720p
output=./out/source-720p.mp4
```

Profile overriding preset defaults:

```config
name=720p-h264-aac-custom-bitrate
preset=720p
video_bitrate=2500k
audio_bitrate=128k
audio_sample_rate=source
quality=high
output=./out/source-720p.mp4
```

Required profile fields:

- `name`
- `output`

Use `preset=<name>` to load `./presets/<name>.conf`. You can also use a direct path such as `preset=./presets/examples/social-square.conf`.

If `preset=` is omitted, `vtx` tries to use the profile `name` as the preset name. Explicit `preset=` is recommended for readability.

The final resolved profile must have `width`, `height`, `video_codec`, `audio_codec`, `video_bitrate`, and `audio_bitrate`. These can come from the preset file, the profile file, or both.

Optional profile fields:

- `preset`
- `width` and `height`
- `video_codec` and `audio_codec`
- `video_bitrate` and `audio_bitrate`
- `audio_sample_rate`
- `quality`, defaults to `standard`
- `crf`, required only when `quality=custom`

Advanced ffmpeg fields such as `video_filter` and `extra_output_args` are not allowed in profile files. Put them in custom preset files instead.

## Audio sample rate

Bundled presets default to `audio_sample_rate=48000`, which is common for video workflows.

Set a numeric value to emit `-ar <value>`:

```config
audio_sample_rate=44100
```

Set `source` to preserve the source sample rate by omitting `-ar` from the generated ffmpeg command:

```config
audio_sample_rate=source
```

## Preset files

Preset files define reusable transcoding defaults.

Example custom preset:

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

Save it as `presets/examples/social-square.conf`, then use it from a profile:

```config
name=social-square-output
preset=social-square
output=./out/source-social-square.mp4
```

## Advanced preset fields

Advanced users can add selected raw ffmpeg behavior to custom preset files.

Supported fields:

- `video_filter`: replaces the generated `scale=WIDTH:HEIGHT` filter
- `extra_output_args`: appends simple whitespace-separated ffmpeg output arguments before the output file

Example:

```config
video_filter=scale=854:480:force_original_aspect_ratio=decrease,pad=854:480:(ow-iw)/2:(oh-ih)/2
extra_output_args=-pix_fmt yuv420p
```

Do not put these fields in profile files. `vtx` rejects them there so advanced ffmpeg details stay reusable and centralized in presets.

## Override rules

Preset values are defaults. Profile values win.

Rules in v1:

- if either `width` or `height` is set, both must be set
- explicit profile dimensions override preset dimensions
- explicit profile bitrates override preset bitrates independently
- explicit profile codecs override preset codecs
- explicit profile `audio_sample_rate` overrides preset sample rate
- `audio_sample_rate=source` preserves source sample rate by omitting `-ar`
- `quality=custom` requires `crf=<value>`

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
