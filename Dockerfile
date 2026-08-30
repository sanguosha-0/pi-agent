FROM node:22-slim
RUN apt-get update && apt-get install -y --no-install-recommends git curl bash ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent@latest
RUN npm install -g cumora@latest
WORKDIR /workspace
CMD ["sh", "-c", "cumora agent computer"]
