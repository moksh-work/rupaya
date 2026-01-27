# Multi-stage Dockerfile for RUPAYA Backend

# Build Stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with specific versions locked
RUN npm ci --only=production && \
    npm cache clean --force

# Copy source code
COPY src ./src
COPY migrations ./migrations

# Prune to remove dev dependencies
RUN npm prune --production

# Final Stage - Minimal image
FROM node:18-alpine

WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1000 app && \
    adduser -D -u 1000 -G app app

# Copy from builder
COPY --from=builder --chown=app:app /app/node_modules ./node_modules
COPY --from=builder --chown=app:app /app/package*.json ./
COPY --from=builder --chown=app:app /app/src ./src
COPY --from=builder --chown=app:app /app/migrations ./migrations

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Switch to non-root user
USER app

# Expose port
EXPOSE 3000

# Use dumb-init to handle signals properly
ENTRYPOINT ["/usr/sbin/dumb-init", "--"]

# Start application
CMD ["node", "src/app.js"]
