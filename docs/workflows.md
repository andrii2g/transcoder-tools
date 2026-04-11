# Workflow guide

Use this guide to choose the right `vtx` job style and the minimum config fields to edit.

## Decision diagram

```mermaid
flowchart TD
  A[Start with one source video file] --> B{What do you want to create}

  B --> C[One output video]
  C --> C1[Use jobs/example-basic.conf]
  C1 --> C2[Set input, one profile, output path]
  C2 --> Z[Validate, dry-run, transcode]

  B --> D[Several MP4 videos]
  D --> D1{Prefer simplest processing}
  D1 -->|Yes| D2[Use jobs/example-multi-video.conf]
  D2 --> D3[Default mode is sequential]
  D3 --> D4[Set input and outputs list]
  D4 --> Z

  D1 -->|No| E[Use jobs/example-multi-output-mode.conf]
  E --> E1[Set mode=multi-output]
  E1 --> E2[Use one profile per MP4 output]
  E2 --> Z

  B --> F[HLS streaming files]
  F --> F1[Use jobs/example-hls.conf]
  F1 --> F2[Set mode=hls]
  F2 --> F3[Set m3u8 outputs and hls_master_playlist]
  F3 --> F4[Test with docs/hls-player.html]
  F4 --> Z

  Z --> Z1[validate --job JOB_FILE]
  Z1 --> Z2[transcode --job JOB_FILE --dry-run --verbose]
  Z2 --> Z3[transcode --job JOB_FILE]
```

If this block appears as plain code in your editor preview, the editor does not render Mermaid diagrams by default. GitHub renders Mermaid blocks natively; VS Code may need a Mermaid preview extension.

## Basic single output

Use this when you want one input video converted to one output preset, such as `720p` or `1080p`.

Start from:

```bash
./bin/vtx.sh transcode --job ./jobs/example-basic.conf --dry-run --verbose
```

Job fields to check:

- `input`: source video path
- `ffmpeg`: usually `ffmpeg`
- `overwrite`: `true` or `false`
- `outputs`: one profile file

Profile fields to check:

- `name`: readable output name
- `preset`: preset name such as `720p`, `1080p`, or a custom preset path
- `output`: final MP4 path

## Several MP4 videos, sequential mode

Use this when you want several output videos and prefer the simplest, safest behavior. `vtx` runs one FFmpeg command per profile, one after another.

Start from:

```bash
./bin/vtx.sh transcode --job ./jobs/example-multi-video.conf --dry-run --verbose
```

Job fields to check:

- `input`: source video path
- `outputs`: comma-separated profile files
- `cpu_limit`: optional job-level processing limit such as `50%`

Profile fields to check:

- `preset`: one preset per output video
- `output`: one MP4 path per profile
- optional overrides: `video_bitrate`, `audio_bitrate`, `quality`, `width`, `height`

Choose this mode first unless you specifically need one FFmpeg process.

## Several MP4 videos, multi-output mode

Use this when you want several MP4 outputs from one FFmpeg process. This is useful when you want the source decoded once and split into multiple renditions.

Start from:

```bash
./bin/vtx.sh transcode --job ./jobs/example-multi-output-mode.conf --dry-run --verbose
```

Job fields to check:

- `mode=multi-output`
- `input`: source video path
- `outputs`: comma-separated profile files
- `cpu_limit`: optional job-level processing limit such as `50%`

Profile fields to check:

- `preset`: one preset per output video
- `output`: one MP4 path per profile

Use dry-run first and review the generated `filter_complex` command. Multi-output mode is more efficient for some workflows, but it is less simple than sequential mode.

## HLS streaming output

Use this when you want HLS playlists and segments for a web player.

Start from:

```bash
./bin/vtx.sh transcode --job ./jobs/example-hls.conf --dry-run --verbose
```

Job fields to check:

- `mode=hls`
- `input`: source video path
- `hls_master_playlist`: required master playlist path, for example `./out/hls/master.m3u8`
- `hls_segment_time`: optional target segment length, default `6`
- `hls_playlist_type`: optional, usually `vod`
- `hls_flags`: optional, usually `independent_segments`
- `outputs`: comma-separated HLS profile files

Profile fields to check:

- `preset`: one preset per HLS rendition
- `output`: variant playlist path ending with `.m3u8`, for example `./out/hls/720p/index.m3u8`

After generating HLS files, test playback with the browser test page:

```bash
python3 -m http.server 8080
```

Open:

```text
http://localhost:8080/docs/hls-player.html?src=/out/hls/master.m3u8
```

## Recommended command flow

For every job, use the same safe command flow:

```bash
./bin/vtx.sh validate --job ./jobs/example-hls.conf
./bin/vtx.sh transcode --job ./jobs/example-hls.conf --dry-run --verbose
./bin/vtx.sh transcode --job ./jobs/example-hls.conf --verbose --log ./logs/hls.log
```

`validate` catches config problems. `--dry-run --verbose` lets you inspect the generated FFmpeg command. `--log` saves details for later review.
