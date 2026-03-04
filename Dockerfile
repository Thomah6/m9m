# Use Node.js base image
FROM node:24.13.1-alpine

# Set working directory
WORKDIR /home/node

# Install pnpm
RUN npm install -g pnpm

# Copy package files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages/cli/package.json ./packages/cli/
COPY packages/core/package.json ./packages/core/
COPY packages/workflow/package.json ./packages/workflow/

# Install dependencies
RUN pnpm install --frozen-lockfile --prod=false

# Copy source code
COPY packages/ ./packages/
COPY scripts/ ./scripts/
COPY tsconfig.json ./

# Build project
RUN pnpm build:n8n

# Create entrypoint
RUN echo '#!/bin/sh\n\
if [ -d /opt/custom-certificates ]; then\n\
  echo "Trusting custom certificates from /opt/custom-certificates."\n\
  export NODE_OPTIONS="--use-openssl-ca $NODE_OPTIONS"\n\
  export SSL_CERT_DIR=/opt/custom-certificates\n\
  c_rehash /opt/custom-certificates\n\
fi\n\
\n\
if [ "$#" -gt 0 ]; then\n\
  exec node ./packages/cli/bin/n8n "$@"\n\
else\n\
  exec node ./packages/cli/bin/n8n\n\
fi' > /docker-entrypoint.sh && chmod +x /docker-entrypoint.sh

# Set environment variables
ENV NODE_ENV=production
ENV N8N_HOST=0.0.0.0
ENV PORT=5678

# Expose port
EXPOSE 5678

# Create user and set permissions
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /home/node

USER nodejs

# Start n8n
ENTRYPOINT ["/docker-entrypoint.sh"]
