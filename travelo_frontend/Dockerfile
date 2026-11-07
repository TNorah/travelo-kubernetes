# Partie 1
FROM node:22-alpine AS build
WORKDIR /app
COPY ["package.json", "package-lock.json", "./"]
RUN npm install --no-audit --no-fund
COPY . .
ARG REACT_APP_API_URL=http://backend.exam.local
ENV REACT_APP_API_URL=$REACT_APP_API_URL
RUN npm run build

# Partie 2
FROM nginxinc/nginx-unprivileged:alpine-slim
USER root
RUN apk upgrade --no-cache \
 && apk del --no-cache curl libxml2 2>/dev/null || true
USER 101
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/ >/dev/null || exit 1
