# Config format

`vtx` uses simple `key=value` files.

Rules:

- blank lines are ignored
- lines beginning with `#` are ignored
- keys and values are trimmed
- one file contains one job, one output profile, or one preset

## Job files

Job files define the shared execution context for one input video or one live RTMP stream.

Example:

```config
input=./input/source.mp4
ffmpeg=ffmpeg
mode=sequential
overwrite=true
outputs=./profiles/example-1080p.conf,./profiles/example-custom-preset.conf
```

Job fields:

- `input`: required source media path or RTMP URL
- `input_mode`: optional, defaults to `file`; supported values are `file` and `rtmp`
- `input_args`: optional job-only ffmpeg input arguments, mainly for live ingest tuning
- `ffmpeg`: optional ffmpeg executable, defaults to `ffmpeg`
- `mode`: optional, defaults to `sequential`
- `overwrite`: optional boolean, defaults to `false`
- `cpu_limit`: optional job-level percentage such as `50%`
- `outputs`: required comma-separated list of profile file paths
- `hls_segment_time`: optional for `mode=hls`, defaults to `6`; optional for `mode=live-hls`, defaults to `2`; target segment length in seconds
- `hls_playlist_type`: optional for `mode=hls`, defaults to `vod`; use `vod` for finished files and `event` for event-style playlists that grow over time
- `hls_flags`: optional for `mode=hls`, defaults to `independent_segments`; optional for `mode=live-hls`, otherwise computed from live flags when omitted
- `hls_master_playlist`: required for `mode=hls` and `mode=live-hls`, path to the generated master playlist
- `hls_list_size`: optional for `mode=live-hls`, defaults to `8`
- `hls_delete_segments`: optional for `mode=live-hls`, defaults to `true`
- `hls_append_list`: optional for `mode=live-hls`, defaults to `true`

## Input modes

`input_mode=file` is the default. It expects a normal local input file and validates that the file exists.

```config
input_mode=file
input=./input/source.mp4
```

`input_mode=rtmp` is the first live ingest mode. It expects an RTMP URL and does not require a local file to exist.

```config
input_mode=rtmp
input=rtmp://127.0.0.1:1935/live/browser
input_args=-fflags nobuffer
```

## Modes

`mode=sequential` is the default. It runs one FFmpeg command per profile, one after another.

```config
mode=sequential
```

`mode=multi-output` builds one FFmpeg command for all profiles. It uses `filter_complex`, `split`, and `-map 0:a?` so a missing source audio stream does not fail the command.

```config
mode=multi-output
```

Use `multi-output` when you want one source video converted into several MP4 outputs in one FFmpeg process.

`mode=hls` builds one FFmpeg command that creates one HLS variant playlist per profile from a file input. Profile `output=` values must end with `.m3u8`.

```config
mode=hls
hls_segment_time=6
hls_playlist_type=vod
hls_flags=independent_segments
hls_master_playlist=./out/hls/master.m3u8
```

Use `hls` when you want multiple streaming renditions and segment playlists from a normal file input. See [HLS mode](hls.md) for details.

`mode=live-hls` is the RTMP-first live ingest path. It does not use `hls_playlist_type`; instead it uses `hls_list_size` and live-oriented HLS flags.

```config
input_mode=rtmp
input=rtmp://127.0.0.1:1935/live/browser
input_args=-fflags nobuffer
mode=live-hls
hls_segment_time=2
hls_list_size=8
hls_delete_segments=true
hls_append_list=true
hls_master_playlist=./out/live/master.m3u8
```

Use `live-hls` when you want to ingest an RTMP stream and generate HLS on the fly. The first live version is RTMP-first and does not include built-in restart supervision.

## CPU limit

Use job-level `cpu_limit` when you want a transcode run to be less aggressive on the current machine.

```config
cpu_limit=50%
```

`vtx` detects the number of CPU cores and converts the percentage to FFmpeg `-threads N`. For example, `cpu_limit=50%` on an 8-core machine resolves to `-threads 4`.

This is a best-effort processing limit, not a hard operating-system CPU cap. Actual CPU usage still depends on codec, filters, disk speed, and FFmpeg internals.

`cpu_limit` is job-only because it controls one FFmpeg process. It is rejected in profile files.

## Profile files

Profile files define one output. In `sequential` and `multi-output` modes that output is normally an MP4 file. In `hls` and `live-hls` modes it is a variant `.m3u8` playlist.

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
- `output`, usually an MP4 path; for `mode=hls` and `mode=live-hls`, this must be a `.m3u8` playlist path

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
- `gop`
- `keyint_min`
- `sc_threshold`
- `video_preset`
- `video_tune`

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

## Live tuning fields

These profile fields are useful mainly for `mode=live-hls`, where lower latency and more predictable segment boundaries matter.

- `gop`: emits `-g <value>` and sets the keyframe interval
- `keyint_min`: emits `-keyint_min <value>` and sets the minimum keyframe interval
- `sc_threshold`: emits `-sc_threshold <value>` and controls scene-cut keyframe insertion
- `video_preset`: emits `-preset <value>` and controls encoder speed versus compression efficiency
- `video_tune`: emits `-tune <value>` for `libx264`

Example:

```config
gop=30
keyint_min=30
sc_threshold=0
video_preset=veryfast
video_tune=zerolatency
```

This is a practical starting point for a 30 fps live HLS profile because it encourages one-second GOP boundaries and reduces encoder buffering. For 60 fps live output, start by testing `gop=60` and `keyint_min=60`.

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
preset=./presets/examples/social-square.conf
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
