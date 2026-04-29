# ---------- ETAPA 1: builder ----------
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./

# OJO: aqui SI necesitamos devDependencies (Angular CLI), por lo
# tanto NO se usa --omit=dev en esta etapa.
RUN if [ -f package-lock.json ]; then \
      npm ci; \
    else \
      echo ">>> AVISO: sin package-lock.json, usando npm install"; \
      npm install; \
    fi

COPY . .
RUN npm run build && \
    mkdir -p /app/build-output && \
    ( cp -r /app/dist/*/browser/* /app/build-output/ 2>/dev/null || \
      cp -r /app/dist/*/* /app/build-output/ )

# ---------- ETAPA 2: runtime ----------
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime
COPY --chown=nginx:nginx nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder --chown=nginx:nginx /app/build-output/ /usr/share/nginx/html/
USER nginx
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/ > /dev/null || exit 1
