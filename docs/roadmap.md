# Roadmap

`vtx` is a config-driven wrapper for common transcoding workflows. The roadmap focuses on capabilities that are not implemented yet.

## HLS improvements

Future HLS work may include:

- fMP4 segment support
- richer master playlist metadata, including codec strings
- audio group and subtitle group support
- stricter bitrate ladder validation for streaming outputs
- configurable segment naming strategies

## Live OBS mode

Future live-focused work is expected to support inputs from OBS or similar live publishers.

Possible direction:

- consume live input URLs or local ingest points
- transcode live inputs into multiple renditions
- write live HLS outputs for local serving or upload workflows
- tune HLS settings for ongoing live streams instead of VOD-only jobs

## Adaptive streaming support

Later versions should make adaptive bitrate ladders easier to define and validate.

That likely means:

- richer preset bundles for streaming ladders
- validation rules for bitrate, resolution, and naming consistency
- generated manifest relationships across video, audio, and subtitle outputs
- cleaner support for player-ready output folder structures
