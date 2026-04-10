# Roadmap

`vtx` starts as a config-driven wrapper for file-to-file transcoding. The repository is intentionally structured so later work can extend the same model without turning the CLI into a raw `ffmpeg` flag passthrough.

## Planned HLS mode

Near-term direction:

- add output profile types for HLS packaging
- generate segment and playlist paths from config
- support multi-variant output sets from one job

Likely additions:

- `mode=hls`
- HLS segment duration settings
- generated variant playlists
- generated master playlists

## Planned live OBS mode

Future live-focused work is expected to support inputs from OBS or similar live publishers.

Possible direction:

- consume live input URLs or local ingest points
- transcode to multiple live renditions
- write HLS outputs for local serving or upload workflows

## Planned adaptive streaming support

Later versions should be able to define an adaptive bitrate ladder in a single job and emit a complete multi-rendition package.

That likely means:

- richer preset bundles
- validation rules for bitrate ladders
- generated manifest relationships

## Generated master playlists

Master playlist generation is intentionally deferred from v1. It fits naturally once multiple HLS renditions are modeled as a first-class output group instead of independent MP4 outputs.
