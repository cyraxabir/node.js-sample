# ──────────────────────────────────────────────
#  Stage 1 – Install production dependencies
# ──────────────────────────────────────────────
FROM node:20-alpine AS deps

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev --no-package-lock

# ──────────────────────────────────────────────
#  Stage 2 – Production image
# ──────────────────────────────────────────────
FROM node:20-alpine

WORKDIR /app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=deps --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --chown=appuser:appgroup src/ ./src/
COPY --chown=appuser:appgroup package.json ./

USER appuser
EXPOSE 8080

ENV NODE_ENV=production PORT=8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/health', (r) => r.statusCode === 200 ? process.exit(0) : process.exit(1))"

CMD ["node", "--enable-source-maps", "src/server.js"]
