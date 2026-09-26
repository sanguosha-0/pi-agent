#!/usr/bin/env bash
# Per-connection child process: run pi in RPC mode on socat's stdio.
set -euo pipefail

args=(--mode rpc --no-session)

[ -n "${PI_PROVIDER:-}" ] && args+=(--provider "${PI_PROVIDER}")
[ -n "${PI_MODEL:-}" ] && args+=(--model "${PI_MODEL}")
[ -n "${PI_THINKING:-}" ] && args+=(--thinking "${PI_THINKING}")
[ -n "${PI_TOOLS:-}" ] && args+=(--tools "${PI_TOOLS}")

exec pi "${args[@]}"
