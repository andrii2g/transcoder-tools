# Live streaming quick start

This guide is the fastest path to a working local live pipeline:

- OBS publishes RTMP to a local container
- `vtx` ingests that RTMP stream
- `vtx` transcodes it into live HLS
- the browser player opens the generated master playlist

Target flow:

```text
OBS -> MediaMTX -> vtx live-hls -> HLS files -> browser player
```

This quick start uses the local example endpoint:

```text
rtmp://127.0.0.1:1935/live/browser
```

That matches `jobs/example-live-hls.conf`.

## Prerequisites

- Docker
- OBS Studio
- Bash
- `ffmpeg`
- this repository checked out locally

If `ffmpeg` is not ready yet, see [Installation](installation.md).

## 1. Start the RTMP service

From the repository root or any working directory, start MediaMTX with Docker:

```bash
docker run --rm -it -p 1935:1935 -p 8888:8888 bluenviron/mediamtx
```

This exposes:

- RTMP ingest on `rtmp://127.0.0.1:1935/live`
- stream key `browser`
- final publish URL `rtmp://127.0.0.1:1935/live/browser`

Keep this terminal running.

## 2. Configure OBS

In OBS:

1. Open `Settings -> Stream`
2. Set `Service` to `Custom...`
3. Set `Server` to `rtmp://127.0.0.1:1935/live`
4. Set `Stream Key` to `browser`
5. Click `Start Streaming`

That produces the exact RTMP URL used by the sample live job:

```text
rtmp://127.0.0.1:1935/live/browser
```

## 3. Start live HLS transcoding

In a second terminal, from the repository root:

```bash
./bin/vtx.sh validate --job ./jobs/example-live-hls.conf
./bin/vtx.sh transcode --job ./jobs/example-live-hls.conf --verbose --log ./logs/live-hls.log
```

What this does:

- connects to the RTMP stream from OBS
- creates multiple live HLS renditions in one FFmpeg process
- writes the master playlist to `./out/live/master.m3u8`
- writes variant playlists and `.ts` segments under `./out/live/`

Keep this terminal running too.

## 4. Serve the generated HLS files

In a third terminal, serve the repository root over HTTP:

```bash
python3 -m http.server 8080
```

This is only for local playback testing. The browser player should load the playlists over HTTP, not directly from `file://`.

## 5. Open the test player

Open this URL in your browser:

```text
http://localhost:8080/docs/hls-player.html?src=/out/live/master.m3u8
```

Expected result:

- the page loads the live master playlist
- HLS playback starts from the generated output under `./out/live/`
- the player stays near the live edge, subject to normal HLS delay

## Quick checklist

If playback does not start, check these in order:

1. OBS is actively streaming
2. the MediaMTX container is still running
3. `./bin/vtx.sh transcode ...` is still running
4. `./out/live/master.m3u8` exists
5. variant playlists exist:
   - `./out/live/360p/index.m3u8`
   - `./out/live/720p/index.m3u8`
6. the local HTTP server is running on port `8080`

Useful checks:

```bash
tail -f ./logs/live-hls.log
ls -R ./out/live
```

## WSL and Windows notes

If you run `vtx` inside WSL, prefer:

```config
ffmpeg=ffmpeg
```

If you run `vtx` from Git Bash with a Windows FFmpeg install, you can use a Windows-style Bash path such as:

```config
ffmpeg=/c/ffmpeg/ffmpeg.exe
```

Do not use `/c/...` paths inside WSL. In WSL, use `ffmpeg` from Linux packages or a `/mnt/c/...` path.

## Low-latency starting point

The sample live job already uses latency-oriented defaults:

- `hls_segment_time=1`
- `hls_list_size=3`
- `hls_delete_segments=true`
- `hls_append_list=false`
- `input_args=-fflags nobuffer -analyzeduration 0 -probesize 32`

The sample live profiles also use:

- `gop=30`
- `keyint_min=30`
- `sc_threshold=0`
- `video_preset=veryfast`
- `video_tune=zerolatency`

These settings are a reasonable first local test setup. They reduce latency, but standard HLS still will not be true realtime.

## Related documents

- [HLS mode](hls.md)
- [Config format](config-format.md)
- [Workflow guide](workflows.md)
