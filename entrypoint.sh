#!/usr/bin/env bash
# Container main process: expose pi's RPC protocol on a TCP port.
#
# pi has no built-in network transport (`pi --mode rpc` speaks JSONL on
# stdin/stdout), so socat bridges TCP <-> stdio and forks one pi process per
# accepted connection: one connection == one client session.
#
# Need cumora instead of the RPC service? Override the entrypoint:
#   docker run --entrypoint cumora <image> agent computer
set -euo pipefail

PORT="${PI_RPC_PORT:-9333}"
WORKDIR="${PI_WORKDIR:-/workspace}"
AGENT_DIR="${PI_CODING_AGENT_DIR:-/data/agent}"
MAX_CHILDREN="${PI_RPC_MAX_CHILDREN:-8}"

mkdir -p "$WORKDIR" "$AGENT_DIR"
cd "$WORKDIR"

if [ -z "${PI_MODEL:-}" ]; then
  echo "[pi-rpc] note: PI_MODEL unset; clients should call set_model or set PI_MODEL" >&2
fi

echo "[pi-rpc] pi $(pi --version 2>/dev/null || echo unknown) (cumora available at /usr/local/bin/cumora)" >&2
echo "[pi-rpc] listening on 0.0.0.0:${PORT} workdir=${WORKDIR} agent_dir=${AGENT_DIR} max_children=${MAX_CHILDREN}" >&2

exec socat \
  -d -d \
  "TCP-LISTEN:${PORT},fork,reuseaddr,max-children=${MAX_CHILDREN}" \
  "EXEC:/usr/local/bin/pi-rpc.sh,stderr"
