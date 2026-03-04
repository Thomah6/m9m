ARG NODE_VERSION=24.13.1

# ========== Stage 1: Build from source ==========
FROM node:${NODE_VERSION}-alpine AS builder

# Install build dependencies
RUN apk add --no-cache python3 make g++ git

# Enable corepack for pnpm
RUN corepack enable && corepack prepare pnpm@10.22.0 --activate

WORKDIR /build

# Copy workspace config files first (better layer caching)
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY patches/ ./patches/

# Copy all package.json files to resolve workspace dependencies
COPY packages/ ./packages/

# Install all dependencies
RUN pnpm install --frozen-lockfile

# Build the entire project
RUN pnpm build

# Generate pruned production deployment into /build/compiled
RUN NODE_ENV=production DOCKER_BUILD=true pnpm --filter=n8n --prod --legacy deploy --no-optional ./compiled

# ========== Stage 2: Production image ==========
FROM n8nio/base:${NODE_VERSION}

ARG N8N_VERSION=snapshot
ARG N8N_RELEASE_TYPE=dev
ENV NODE_ENV=production
ENV N8N_RELEASE_TYPE=${N8N_RELEASE_TYPE}
ENV SHELL=/bin/sh

WORKDIR /home/node

COPY --from=builder /build/compiled /usr/local/lib/node_modules/n8n
COPY docker/images/n8n/docker-entrypoint.sh /

RUN cd /usr/local/lib/node_modules/n8n && \
    npm rebuild sqlite3 && \
    ln -s /usr/local/lib/node_modules/n8n/bin/n8n /usr/local/bin/n8n && \
    mkdir -p /home/node/.n8n && \
    chown -R node:node /home/node && \
    rm -rf /root/.npm /tmp/*

EXPOSE 5678/tcp
USER node
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]

LABEL org.opencontainers.image.title="n8n" \
      org.opencontainers.image.description="Workflow Automation Tool" \
      org.opencontainers.image.source="https://github.com/n8n-io/n8n" \
      org.opencontainers.image.url="https://n8n.io" \
      org.opencontainers.image.version=${N8N_VERSION}
