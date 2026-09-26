# pi-agent

Container image for [`pi`](https://github.com/earendil-works/pi) (the terminal coding agent),
packaged as a **long-running RPC service** that other containers can drive, plus the
[`cumora`](https://www.npmjs.com/package/cumora) CLI.

Image: `ghcr.io/sanguosha-0/pi-agent` — tags are the exact pi version (e.g. `0.87.1`) and `latest`.

## Why this wrapper exists

Upstream ships no Docker image, no compose file, and no network transport. Its
[containerization docs](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/containerization.md)
only cover running the interactive CLI in a container, and `pi --mode rpc` speaks
**JSONL over stdin/stdout** — there is no TCP/HTTP server built in.

This repo closes that gap: `entrypoint.sh` runs `socat` as the container main process, so
`TCP-LISTEN:<port>` bridges straight onto `pi --mode rpc`'s stdio. One accepted connection
forks one pi process, i.e. one connection == one client session.

Versions of pi and cumora are pinned at build time (resolved from npm and passed as build
args), so images are reproducible and never silently `@latest`.

## Layout

| File | Purpose |
|---|---|
| `Dockerfile` | `node:24-bookworm-slim` + pinned pi + pinned cumora + socat + tini |
| `entrypoint.sh` | container main process: socat TCP → RPC child, `max-children` capped |
| `pi-rpc.sh` | per-connection child: assembles the `pi --mode rpc` command |
| `.github/workflows/docker-publish.yml` | builds/pushes on demand, daily version check, and on changes to the files above |

## Build

Automatic: push to `main` (touching the files above), the daily schedule, or run the
workflow manually with a specific version. Locally:

```bash
docker build --build-arg PI_VERSION=0.87.1 --build-arg CUMORA_VERSION=0.18.7 -t pi-agent:0.87.1 .
```

## Run

```bash
docker run -d --name pi \
  --restart unless-stopped \
  -e PI_MODEL=anthropic/claude-sonnet-4-20250514 \
  -e ANTHROPIC_API_KEY=... \
  -v ./data:/data \
  -v ./workspace:/workspace \
  pi-agent:0.87.1
```

Persist `/data` (agent dir: `auth.json`, sessions, settings) and mount whatever
`/workspace` the agent should operate on.

## Calling it from another container

```bash
# one-shot prompt; stream JSONL events until agent_settled
printf '%s\n' '{"id":"1","type":"prompt","message":"say hi"}' | nc pi 9333
```

Records are the ones documented in the upstream
[RPC protocol](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/rpc.md)
and [RPC commands](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/rpc-commands.md)
(`prompt`, `bash`, `set_model`, `get_state`, …; events such as `message_update`, `agent_settled`).

> **Security**: RPC mode is unauthenticated and pi can run shell commands with the
> provider keys you hand it. Keep this container on a private docker network and
> **never publish port 9333 to the host or the LAN**.

## Environment variables

| Variable | Default | Meaning |
|---|---|---|
| `PI_RPC_PORT` | `9333` | TCP port for the RPC frontend inside the container |
| `PI_WORKDIR` | `/workspace` | working directory pi operates on |
| `PI_CODING_AGENT_DIR` | `/data/agent` | pi agent dir — mount `/data` to persist |
| `PI_RPC_MAX_CHILDREN` | `8` | max concurrent RPC connections |
| `PI_MODEL` | unset | default model, e.g. `anthropic/claude-sonnet-4-20250514` |
| `PI_PROVIDER` | unset | restrict model lookup to one provider |
| `PI_THINKING` | unset | `off` / `minimal` / `low` / `medium` / `high` / `xhigh` / `max` |
| `PI_TOOLS` | unset | comma-separated tool allowlist |
| provider keys | unset | `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `DEEPSEEK_API_KEY`, `OPENROUTER_API_KEY`, `GROQ_API_KEY`, … |

## Using cumora instead of the RPC service

The cumora CLI is installed in the same image; override the entrypoint:

```bash
docker run --rm --entrypoint cumora pi-agent:0.87.1 agent computer
```
