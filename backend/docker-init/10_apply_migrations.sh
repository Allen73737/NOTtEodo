#!/bin/sh
# Standalone Postgres only (docker-compose). Supabase applies supabase/migrations itself
# and must never run 00_standalone_auth.sql, which stubs the auth schema.
set -e
for f in /migrations/*.sql; do
  echo "Applying $(basename "$f")"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$f"
done
