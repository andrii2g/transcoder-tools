# CLI reference

Main entrypoint:

```bash
./bin/vtx.sh
```

## Commands

### `list-presets`

Print all supported root presets with resolved dimensions, default bitrates, and a short description.

```bash
./bin/vtx.sh list-presets
```

### `validate`

Validate one job file and every profile it references.

```bash
./bin/vtx.sh validate --job ./jobs/example-multi-output.conf
```

Validation checks include:

- job file exists
- input file exists
- referenced profile files exist
- job `mode` is supported
- required profile fields are present after preset resolution
- preset names or preset file paths are supported
- dimensions and bitrate rules are valid
- quality settings are valid
- job-level `cpu_limit` is valid when present

The command exits nonzero on failure.

### `transcode`

Run a transcode job.

```bash
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf
```

By default, jobs use `mode=sequential`, which runs one FFmpeg command per output profile. Jobs can also use `mode=multi-output`, which builds one MP4-oriented FFmpeg command for all output profiles, or `mode=hls`, which creates HLS variant playlists and segments.

### `--dry-run`

Resolve and validate the job, then print generated `ffmpeg` commands without executing them.

```bash
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf --dry-run
```

### `--verbose`

Print resolved config values, preset dimensions, codec mappings, bitrate mappings, CPU thread resolution, and execution details.

```bash
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf --verbose
```

### `--log`

Write transcode output to a log file. During real transcodes, `ffmpeg` output is appended to the same log file.

```bash
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf --verbose --log ./logs/transcode.log
```

The log directory is created automatically if needed. Existing log files are overwritten at the start of the transcode run.

Dry-run logging is useful for reviewing generated commands:

```bash
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf --dry-run --verbose --log ./logs/dry-run.log
```

### `--version`

Print the CLI version.

```bash
./bin/vtx.sh --version
```

## Flags

- `--job <path>`: path to a job config file
- `--dry-run`: print generated commands only
- `--verbose`: print resolved details for debugging and review
- `--log <path>`: save generated commands, verbose transcode messages, and `ffmpeg` output to a file; only supported with `transcode`
- `--version`: print `vtx` version
- `--help`: show usage

## Examples

List presets:

```bash
./bin/vtx.sh list-presets
```

Validate before running:

```bash
./bin/vtx.sh validate --job ./jobs/example-basic.conf
```

Generate commands only:

```bash
./bin/vtx.sh transcode --job ./jobs/example-custom.conf --dry-run --verbose
```

Generate one multi-output FFmpeg command:

```bash
./bin/vtx.sh transcode --job ./jobs/example-multi-output-mode.conf --dry-run --verbose
```

Generate an HLS command and planned master playlist:

```bash
./bin/vtx.sh transcode --job ./jobs/example-hls.conf --dry-run --verbose
```

Run multiple outputs sequentially and save detailed logs:

```bash
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf --verbose --log ./logs/multi-output.log
```
