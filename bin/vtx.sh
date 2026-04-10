#!/usr/bin/env bash

set -euo pipefail

VTX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellchecks

source "$VTX_ROOT/lib/utils.sh"
source "$VTX_ROOT/lib/parser.sh"
source "$VTX_ROOT/lib/presets.sh"
source "$VTX_ROOT/lib/validate.sh"
source "$VTX_ROOT/lib/ffmpeg-builder.sh"
source "$VTX_ROOT/lib/cli.sh"

vtx_main "$@"
