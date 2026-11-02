#!/bin/sh
set -eu

# 1. Runtime config for the web app. Only the public anon key belongs here: it is
#    designed to be public, and row-level security protects the data.
ENV_FILE="/usr/share/nginx/html/env.js"
js_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
cat <<EOF > "$ENV_FILE"
// Runtime environment injected by the NOTtEodo container.
window.__ENV__ = {
  APP_ENV: "$(js_escape "${APP_ENV:-production}")",
  SUPABASE_URL: "$(js_escape "${SUPABASE_URL:-}")",
  SUPABASE_ANON_KEY: "$(js_escape "${SUPABASE_ANON_KEY:-}")"
};
EOF

# 2. CSP connect-src: allow exactly this deployment's Supabase project (HTTPS + realtime WSS).
CSP_CONNECT_SRC=""
if [ -n "${SUPABASE_URL:-}" ]; then
  origin=$(printf '%s' "$SUPABASE_URL" | sed -E 's#^(https?://[^/]+).*$#\1#')
  case "$origin" in
    https://*) CSP_CONNECT_SRC="$origin wss://${origin#https://}" ;;
    http://*)  CSP_CONNECT_SRC="$origin ws://${origin#http://}" ;;  # local development only
  esac
fi
export CSP_CONNECT_SRC
envsubst '${CSP_CONNECT_SRC}' < /etc/nginx/templates/security-headers.conf.template > /etc/nginx/snippets/security-headers.conf

exec "$@"
