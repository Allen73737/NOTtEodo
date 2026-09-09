# Multi-Stage Enterprise Production Dockerfile
# Stage 1: Build Flutter Web Application
FROM ghcr.io/cirruslabs/flutter:3.24.0 AS builder

WORKDIR /app

# Copy dependency definitions and resolve packages
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy full application source code
COPY . .

# Build optimized production web release bundle
RUN flutter build web --release --pwa-strategy=offline-first

# Stage 2: Serve with Hardened Nginx Alpine
FROM nginx:1.27-alpine

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy built web artifacts from builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy enterprise hardened Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Set unprivileged permissions and healthcheck
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
