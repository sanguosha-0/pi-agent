FROM node:24-bookworm-slim

ARG PI_VERSION=0.87.1
ARG CUMORA_VERSION=0.18.7

LABEL org.opencontainers.image.title="pi-agent" \
      org.opencontainers.image.description="pi coding agent as a container service (RPC over TCP) + cumora CLI" \
      org.opencontainers.image.source="https://github.com/sanguosha-0/pi-agent" \
      org.opencontainers.image.version="${PI_VERSION}" \
      org.opencontainers.image.base.name="docker.io/library/node:24-bookworm-slim"

# bash/ripgrep: pi's built-in tools shell out to them. socat: TCP <-> RPC stdio bridge.
# tini: proper PID 1 signal handling. curl/ca-certificates: TLS + fetch tooling.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      curl \
      git \
      ripgrep \
      socat \
      tini; \
    rm -rf /var/lib/apt/lists/*

# Pinned versions - never @latest, so a rebuild is reproducible (see deploy SOP).
RUN set -eux; \
    npm install -g --ignore-scripts \
      "@earendil-works/pi-coding-agent@${PI_VERSION}" \
      "cumora@${CUMORA_VERSION}"; \
    npm cache clean --force; \
    pi --version

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY pi-rpc.sh /usr/local/bin/pi-rpc.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/pi-rpc.sh

# /data/agent holds auth.json, sessions and settings -> mount it to persist.
# Defaults to writable paths so the image also works with a non-root user.
ENV PI_CODING_AGENT_DIR=/data/agent \
    PI_RPC_PORT=9333 \
    PI_WORKDIR=/workspace \
    HOME=/home/pi

RUN mkdir -p /data/agent /workspace /home/pi && chmod 777 /data /workspace /home/pi

WORKDIR /workspace

# 9333/tcp: pi RPC protocol, one JSON record per line. Reachable only from the
# docker network it is attached to - never publish it to the host.
EXPOSE 9333

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
