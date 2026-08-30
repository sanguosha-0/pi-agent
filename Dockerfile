FROM node:22-alpine
RUN apk add --no-cache git curl bash
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent@latest
RUN npm install -g cumora@latest
WORKDIR /workspace
CMD ["sh", "-c", "cumora agent computer"]
```
4. 点 **Commit changes...** → **Commit directly to the main branch** → **Commit changes**
**第 3 步——workflow**
1. 再点 **Add file → Create new file**
2. 文件名输入 `.github/workflows/docker-publish.yml`
3. 粘贴：
```yaml
name: Build pi-agent → ghcr.io
on:
  workflow_dispatch:
concurrency:
  group: pi-agent-publish
  cancel-in-progress: true
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-qemu-action@v3
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64
          push: true
          tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
