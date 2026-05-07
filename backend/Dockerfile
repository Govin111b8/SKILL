# ──────────────────────────────────────────────────────────────
# SkillConnect Backend — Multi-stage Production Dockerfile
# ──────────────────────────────────────────────────────────────

# Stage 1: Install all dependencies (including dev) for build/check
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
# Copy source + TypeScript config for optional type-check step
COPY tsconfig.json ./
COPY src ./src

# Stage 2: Install production-only dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Stage 3: Production image
FROM node:20-alpine AS production
WORKDIR /app

# Security: run as non-root
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# Copy production dependencies
COPY --from=deps /app/node_modules ./node_modules
COPY package.json tsconfig.json ./
COPY src ./src

# Create uploads directory
RUN mkdir -p uploads && chown -R appuser:appgroup /app

USER appuser

ENV NODE_ENV=production
ENV PORT=5000

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5000/api/health || exit 1

CMD ["node", "src/server.js"]
