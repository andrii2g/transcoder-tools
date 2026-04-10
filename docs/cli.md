# CLI reference

Main entrypoint:

```bash
./bin/vtx.sh
```

## Commands

### `list-presets`

Print all supported presets with resolved dimensions and a short description.

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
- required profile fields are present
- preset names are supported
- custom dimensions follow the required rules
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

Print resolved config values, preset dimensions, codec mappings, and execution details.

```bash
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf --verbose
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

Run multiple outputs from one input:

```bash
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf
```
