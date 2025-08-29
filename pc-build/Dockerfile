FROM node:20-bullseye

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  libnss3 libatk-bridge2.0-0 libgtk-3-0 libx11-xcb1 libxcomposite1 libxrandr2 \
  libasound2 libpangocairo-1.0-0 libxdamage1 libxfixes3 libgbm1 libpango-1.0-0 \
  libcairo2 xvfb xauth wget ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY pc-preview ./pc-preview
WORKDIR /app/pc-preview

RUN npm ci || npm install

# Build Linux AppImage by default
RUN npx electron-builder --linux AppImage

CMD ["bash", "-lc", "ls -la dist"]

