# Multi-stage production build.
# Stage 1: build the Flutter web app.
FROM ghcr.io/cirruslabs/flutter:3.44.0 AS builder

WORKDIR /app

ARG APP_ENV=production
ARG SUPABASE_URL=""
ARG SUPABASE_ANON_KEY=""

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# --no-web-resources-cdn serves CanvasKit from this origin, so the CSP can keep script-src 'self'.
RUN flutter build web --release --no-web-resources-cdn \
    --dart-define=APP_ENV=${APP_ENV} \
    --dart-define=SUPABASE_URL=${SUPABASE_URL} \
    --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}

# Stage 2: serve with an unprivileged nginx (no root process, port 8080).
FROM nginxinc/nginx-unprivileged:1.27-alpine

USER root
RUN rm -rf /usr/share/nginx/html/* && mkdir -p /etc/nginx/snippets /etc/nginx/templates

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY nginx/security-headers.conf /etc/nginx/templates/security-headers.conf.template
COPY docker-entrypoint.sh /docker-entrypoint.sh

# Static files are read-only for the server; only the two generated files are writable.
RUN chmod 0755 /docker-entrypoint.sh \
    && chown -R root:root /usr/share/nginx/html && chmod -R a-w /usr/share/nginx/html \
    && touch /usr/share/nginx/html/env.js /etc/nginx/snippets/security-headers.conf \
    && chown 101:101 /usr/share/nginx/html/env.js /etc/nginx/snippets/security-headers.conf \
    && chmod 0644 /usr/share/nginx/html/env.js

USER 101

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://127.0.0.1:8080/ || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
