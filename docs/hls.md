# HLS mode

`mode=hls` creates HTTP Live Streaming outputs from one input video.

In the first implementation, `vtx` builds one FFmpeg process for all referenced output profiles. Each profile becomes one HLS variant playlist, and segment files are written next to that playlist.

## Job example

```config
input=./input/source.mp4
ffmpeg=ffmpeg
mode=hls
overwrite=true
cpu_limit=50%
hls_segment_time=6
hls_playlist_type=vod
hls_flags=independent_segments
hls_master_playlist=./out/hls/master.m3u8
outputs=./profiles/hls-360p.conf,./profiles/hls-720p.conf,./profiles/hls-1080p.conf
```

Run it in dry-run mode first:

```bash
./bin/vtx.sh transcode --job ./jobs/example-hls.conf --dry-run --verbose
```

## Profile example

For HLS mode, each profile `output=` must point to a variant playlist ending in `.m3u8`:

```config
name=hls-720p
preset=720p
output=./out/hls/720p/index.m3u8
```

Segments are generated beside the playlist. For the output above, `vtx` generates this segment pattern:

```text
./out/hls/720p/index_%03d.ts
```

## HLS job fields

- `mode=hls`: enables HLS output mode
- `hls_segment_time`: optional segment duration in seconds, defaults to `6`
- `hls_playlist_type`: optional playlist type, defaults to `vod`; supported values are `vod` and `event`
- `hls_flags`: optional FFmpeg HLS flags, defaults to `independent_segments`
- `hls_master_playlist`: required for `mode=hls`, path for the generated master playlist

`cpu_limit` remains job-level because HLS mode uses one FFmpeg process for all variants.

## Output model

A profile still describes one rendition: dimensions, codecs, bitrates, quality, and output path. In HLS mode, the output path is a variant playlist instead of an MP4 file.

Example output tree:

```text
out/hls/
  master.m3u8
  360p/
    index.m3u8
    index_000.ts
    index_001.ts
  720p/
    index.m3u8
    index_000.ts
    index_001.ts
  1080p/
    index.m3u8
    index_000.ts
    index_001.ts
```

## Master playlist

`vtx` writes the configured `hls_master_playlist` before FFmpeg starts. The master playlist includes one `EXT-X-STREAM-INF` entry per profile using the resolved bandwidth and resolution, so a player can discover variant playlists while segments are being produced.

In dry-run mode, `vtx` prints where the master playlist would be written but does not create files.

## Current limitations

- HLS mode currently writes MPEG-TS segments (`.ts`).
- Master playlist generation is intentionally simple and does not include detailed codec strings yet.
- Live HLS and OBS ingest are still future work.
