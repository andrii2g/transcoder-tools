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

## Segment duration

`hls_segment_time` tells FFmpeg the target length of each HLS media segment, in seconds.

The default is:

```config
hls_segment_time=6
```

Shorter segments can make playback start faster and reduce latency, but they create more files and more playlist updates. Longer segments create fewer files and can be more efficient for static VOD delivery, but playback may start more slowly.

Practical starting points:

- `4`: shorter segments for faster startup or lower-latency experiments
- `6`: balanced default for normal VOD-style output
- `10`: fewer segment files for longer videos or simpler hosting

This is a target duration. Actual segment boundaries depend on keyframes and FFmpeg's HLS muxer behavior.

## HLS flags

`hls_flags` passes selected HLS muxer flags to FFmpeg.

The default is:

```config
hls_flags=independent_segments
```

`independent_segments` tells players that each segment can be decoded independently. This is useful for adaptive streaming because players can switch between renditions more safely at segment boundaries.

For most current `vtx` HLS jobs, keep the default. Advanced users can change this field when they know they need different FFmpeg HLS muxer behavior.

Internally this maps to FFmpeg's `-hls_flags` option.
## Playlist type

`hls_playlist_type` tells FFmpeg what kind of HLS playlist to write.

Supported values:

- `vod`: video-on-demand playlist for finished files. This is the default and the recommended value for normal `vtx` file-to-HLS jobs.
- `event`: event-style playlist for content that grows over time while old segments remain available. This can be useful for long-running event workflows, but it is not the same as a true live sliding playlist.

For most current `vtx` jobs, use:

```config
hls_playlist_type=vod
```

Internally this maps to FFmpeg's `-hls_playlist_type` option.
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
