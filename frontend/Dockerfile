# ──────────────────────────────────────────────────────────────
# SkillConnect Frontend — Multi-stage Production Dockerfile
# ──────────────────────────────────────────────────────────────

# Stage 1: Build
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Serve with nginx (non-root)
FROM nginx:alpine AS production

# Create a non-root nginx user and adjust permissions
RUN addgroup -g 1001 -S nginxuser && \
    adduser -u 1001 -S nginxuser -G nginxuser && \
    chown -R nginxuser:nginxuser /var/cache/nginx /var/log/nginx /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown nginxuser:nginxuser /var/run/nginx.pid

COPY --from=build /app/dist /usr/share/nginx/html
COPY well-known /etc/nginx/well-known
RUN chown -R nginxuser:nginxuser /usr/share/nginx/html /etc/nginx/well-known

COPY nginx.conf /etc/nginx/conf.d/default.conf

USER nginxuser
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:80/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
