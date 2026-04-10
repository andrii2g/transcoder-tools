# Installation

`vtx` is a Bash CLI wrapper around `ffmpeg`. It does not bundle `ffmpeg`; install `ffmpeg` separately and make sure it is available on your `PATH`.

## Requirements

- Bash 4+
- `ffmpeg`
- `ffprobe` is recommended for future validation features, but is not required by the current MVP

## Install ffmpeg

### Ubuntu and Debian

```bash
sudo apt update
sudo apt install ffmpeg
```

### Fedora

```bash
sudo dnf install ffmpeg
```

Some Fedora installations require RPM Fusion repositories before `ffmpeg` is available.

### Arch Linux

```bash
sudo pacman -S ffmpeg
```

### macOS with Homebrew

```bash
brew install ffmpeg
```

### Windows

The Bash version of `vtx` is intended for Git Bash, WSL, or another Bash-compatible environment.

Recommended options:

- Use WSL and install `ffmpeg` with your Linux distribution package manager.
- Use Git Bash and install `ffmpeg` with a Windows package manager such as Chocolatey, Scoop, or winget.

Examples:

```powershell
winget install Gyan.FFmpeg
```

```powershell
choco install ffmpeg
```

```powershell
scoop install ffmpeg
```

After installing on Windows, open a new terminal so the updated `PATH` is available.

## Verify ffmpeg

```bash
ffmpeg -version
```

If that command fails, `vtx` will not be able to run real transcodes unless your job file points `ffmpeg=` to a valid executable path.

## Prepare vtx

From the repository root:

```bash
chmod +x ./bin/vtx.sh
./bin/vtx.sh --version
./bin/vtx.sh list-presets
```

On Windows Git Bash, `chmod` may not be necessary, and you can usually run:

```bash
bash ./bin/vtx.sh --version
```

## Optional PATH setup

You can run `vtx` directly from the repository:

```bash
./bin/vtx.sh list-presets
```

If you want to call it from anywhere, add the repository `bin` directory to your shell `PATH`.

Example for Bash:

```bash
export PATH="$PATH:/path/to/transcoder-tools/bin"
```

Then you can run:

```bash
vtx.sh list-presets
```

The project still documents examples as `./bin/vtx.sh ...` to keep commands explicit and portable.

## First dry run

The sample jobs reference `./input/source.mp4`. Replace that placeholder with a real media file, then run:

```bash
./bin/vtx.sh validate --job ./jobs/example-multi-output.conf
./bin/vtx.sh transcode --job ./jobs/example-multi-output.conf --dry-run --verbose --log ./logs/dry-run.log
```

Dry-run mode prints generated `ffmpeg` commands without creating outputs.
