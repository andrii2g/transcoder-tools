# HLS mode

`vtx` supports two HLS workflows:

- `mode=hls` for file-to-HLS packaging
- `mode=live-hls` for live RTMP-to-HLS transcoding

Both modes build one FFmpeg process for all referenced output profiles. Each profile becomes one HLS variant playlist, and segment files are written next to that playlist.

If you want the fastest end-to-end local test with OBS and Docker, start with [Live streaming quick start](live-quick-start.md).

## File-to-HLS job example

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

## Live RTMP-to-HLS job example

```config
input_mode=rtmp
input=rtmp://127.0.0.1:1935/live/browser
input_args=-fflags nobuffer
ffmpeg=ffmpeg
mode=live-hls
overwrite=true
cpu_limit=50%
hls_segment_time=2
hls_list_size=8
hls_delete_segments=true
hls_append_list=true
hls_master_playlist=./out/live/master.m3u8
outputs=./profiles/live-hls-360p.conf,./profiles/live-hls-720p.conf,./profiles/live-hls-1080p.conf
```

Run it in dry-run mode first:

```bash
./bin/vtx.sh transcode --job ./jobs/example-live-hls.conf --dry-run --verbose
```

## Profile example

For both HLS modes, each profile `output=` must point to a variant playlist ending in `.m3u8`:

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

Common fields:

- `mode=hls` or `mode=live-hls`
- `hls_segment_time`: target segment duration in seconds
- `hls_flags`: HLS muxer flags
- `hls_master_playlist`: required path for the generated master playlist

File-to-HLS specific fields:

- `hls_playlist_type`: supported values are `vod` and `event`

Live RTMP-to-HLS specific fields:

- `input_mode=rtmp`
- `input_args`: optional FFmpeg input flags, such as `-fflags nobuffer`
- `hls_list_size`: live playlist window size
- `hls_delete_segments`: whether older segments are removed
- `hls_append_list`: whether FFmpeg appends to an existing playlist

`cpu_limit` remains job-level because HLS mode uses one FFmpeg process for all variants.

## Segment duration

`hls_segment_time` tells FFmpeg the target length of each HLS media segment, in seconds.

Defaults:

- file-to-HLS: `6`
- live RTMP-to-HLS: `2`

Shorter segments can make playback start faster and reduce latency, but they create more files and more playlist updates. Longer segments create fewer files and can be more efficient for static VOD delivery, but playback may start more slowly.

Practical starting points:

- `2`: live RTMP ingest
- `4`: shorter VOD segments for faster startup
- `6`: balanced default for normal file-to-HLS output
- `10`: fewer segment files for longer videos or simpler hosting

This is a target duration. Actual segment boundaries depend on keyframes and FFmpeg's HLS muxer behavior.

## HLS flags

`hls_flags` passes selected HLS muxer flags to FFmpeg.

Default for file-to-HLS:

```config
hls_flags=independent_segments
```

Default for live RTMP-to-HLS when `hls_flags` is omitted:

```config
hls_delete_segments=true
hls_append_list=true
```

That resolves to these HLS flags:

```config
independent_segments+append_list+delete_segments
```

`independent_segments` tells players that each segment can be decoded independently. This is useful for adaptive streaming because players can switch between renditions more safely at segment boundaries.

For most current `vtx` jobs, keep the defaults. Advanced users can set `hls_flags` explicitly when they know they need different FFmpeg HLS muxer behavior.

Internally this maps to FFmpeg's `-hls_flags` option.

## Playlist type

`hls_playlist_type` tells FFmpeg what kind of HLS playlist to write.

Supported values for `mode=hls`:

- `vod`: video-on-demand playlist for finished files. This is the default and the recommended value for file-to-HLS jobs.
- `event`: event-style playlist for content that grows over time while old segments remain available.

For file-to-HLS jobs, use:

```config
hls_playlist_type=vod
```

`hls_playlist_type` is not used for `mode=live-hls`.

Internally this maps to FFmpeg's `-hls_playlist_type` option.

## Live playlist behavior

`mode=live-hls` is the RTMP-first live ingest mode.

It differs from file-to-HLS in these ways:

- `input_mode=rtmp` is required
- `input` is validated as an RTMP URL instead of a local file path
- `input_args` can be added before `-i` for ingest tuning
- `hls_playlist_type` is not used
- `hls_list_size` controls the live playlist window
- live HLS flags are computed from `hls_delete_segments` and `hls_append_list` when `hls_flags` is omitted

The first live version does not include built-in restart loops, watch mode, PID files, or health files.

For a concrete local setup using OBS and a local MediaMTX container, see [Live streaming quick start](live-quick-start.md).

## Output model

A profile still describes one rendition: dimensions, codecs, bitrates, quality, and output path. In both HLS modes, the output path is a variant playlist instead of an MP4 file.

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

## Testing playback

The repository includes a simple browser test page at `docs/hls-player.html`.

After generating HLS output, serve the repository root with a local static server:

```bash
python3 -m http.server 8080
```

Then open:

```text
http://localhost:8080/docs/hls-player.html?src=/out/hls/master.m3u8
```

The page accepts either a master playlist or a variant playlist. Safari can usually play HLS natively. Chrome, Edge, and Firefox use hls.js loaded from a CDN.

Do not test HLS by opening `docs/hls-player.html` directly from the filesystem. Browser security rules and segment loading usually require HTTP.

## Current limitations

- HLS mode currently writes MPEG-TS segments (`.ts`).
- Master playlist generation is intentionally simple and does not include detailed codec strings yet.
- Live RTMP-to-HLS is RTMP-first and does not yet include built-in process supervision.
