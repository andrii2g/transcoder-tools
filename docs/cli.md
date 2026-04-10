# CLI reference

Main entrypoint:

```bash
./bin/vtx.sh
```

## Commands

### `list-presets`

Print all supported presets with resolved dimensions, default bitrates, and a short description.

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
- required profile fields are present after preset resolution
- preset names or preset file paths are supported
- dimensions and bitrate rules are valid
- quality settings are valid

The command exits nonzero on failure.

### `transcode`

Run one `ffmpeg` command per output profile, sequentially.

```bash
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf
```

Each profile becomes one output file.

### `--dry-run`

Resolve and validate the job, then print generated `ffmpeg` commands without executing them.

```bash
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf --dry-run
```

### `--verbose`

Print resolved config values, preset dimensions, codec mappings, bitrate mappings, and execution details.

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

Generate commands and save them to a log:

```bash
./bin/vtx.sh transcode --job ./jobs/example-custom.conf --dry-run --verbose --log ./logs/custom-dry-run.log
```

Run multiple outputs from one input and save detailed logs:

```bash
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf --verbose --log ./logs/multi-output.log
```
