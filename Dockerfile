# syntax=docker/dockerfile:1

# Cloud Run requires the container to listen on a single HTTP port (the
# PORT env var, injected automatically -- usually 8080). This app already
# does that correctly (server.ts reads process.env.PORT and binds
# 0.0.0.0), and all V2Ray/VLESS/VMess/Trojan/SSH traffic is tunneled over
# WebSocket through that same port, so no extra exposed ports are needed.

FROM node:22-slim AS base
WORKDIR /app

# ---- install ALL deps (incl. devDependencies, needed to run esbuild) ----
FROM base AS deps
# build-essential/python3 are a safety net in case any native addon
# (e.g. ssh2's optional cpu-features) has no prebuilt binary for this
# platform and falls back to compiling from source.
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 make g++ \
    && rm -rf /var/lib/apt/lists/*
COPY package.json ./
RUN npm install

# ---- bundle server.ts -> dist/server.cjs ----
FROM deps AS build
COPY server.ts tsconfig.json ./
RUN npm run build

# ---- production-only node_modules (no devDependencies) ----
FROM base AS prod-deps
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 make g++ \
    && rm -rf /var/lib/apt/lists/*
COPY package.json ./
RUN npm install --omit=dev

# ---- final runtime image ----
FROM base AS runtime
ENV NODE_ENV=production
COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh && mkdir -p /app/data

# Documentation only -- Cloud Run ignores EXPOSE and injects its own PORT.
EXPOSE 8080

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["node", "dist/server.cjs"]
