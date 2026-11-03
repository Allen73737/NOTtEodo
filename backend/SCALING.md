# Scaling NOTtEodo to 500+ concurrent users

NOTtEodo is local-first. Users read and write their data on the device, so the server
never sits on the critical path of a tap. The server sees only:

| Traffic | When | Cost per request |
|---|---|---|
| Delta pull | app start, sign-in, "Sync now", after pushes | 1 index range scan on `(user_id, updated_at)` |
| Push | 2 s after an edit (debounced, per collection) | 1 single-row upsert |
| AI request | only when the user asks for AI | 1 quota upsert + 1 rate-limit check + model call |

## Capacity estimate

500 users all editing continuously (the k6 scenario below is harsher than real use):

* one sync every ~5 s per user → **~100 pulls/s + ~100 pushes/s**
* each query is index-only and RLS evaluates `auth.uid()` once per statement
  (migration `20261103000000`), so each costs well under 5 ms of database time
* about 200 req/s × 5 ms ≈ **1 CPU core**. The Supabase **Small** compute add-on (2 cores, 2 GB) has room;
  **Micro** works for typical use, where people edit far less often than every 5 s.

PostgREST keeps its own connection pool, so app traffic does not open one database
connection per user. Edge functions are stateless and scale horizontally. Usually the
first limit you hit is the **AI provider's** rate limit, not the database. Per-user
limits (30 AI requests/min, `AI_DAILY_REQUESTS` per day) stop one user from using up
the organisation's quota.

## What the migrations do for scale

* **RLS initPlan rewrite:** every policy's `auth.uid()` becomes `(SELECT auth.uid())`, and
  `mfa_satisfied()` is wrapped the same way. Postgres evaluates it once per statement
  instead of once per row. This is the single biggest RLS speed-up.
* **Indexes:**
  * Every user-scoped table gets an index leading with `user_id`.
  * `user_collections(user_id, updated_at)` serves delta sync.
  * `security_audit_logs(user_id, created_at)` serves the audit throttle.
  * `rate_limit_records(request_timestamp)` serves pruning.
* **No table-wide `DELETE` per request.** Rate-limit pruning runs in `pg_cron` every
  15 minutes; without pg_cron, about 1 request in 200 does it, bounded by the time index.
* **Retention jobs:**
  * rate-limit rows after 1 day
  * AI usage rows after 35 days
  * audit logs after 365 days
* **Autovacuum tuning** on the high-churn tables. `fillfactor = 85` on `user_collections`
  allows HOT updates for the frequent upserts.
* **Bounded rows:** a 5 MB cap per collection row, and a single-row upsert per user per
  day for AI quotas, so there are no hot shared counters.

## Client-side efficiency

* **Delta pulls** fetch only rows changed since the oldest local sync, minus a 10-minute
  margin for clock differences between devices.
* Pushes are debounced (2 s), only dirty collections are sent, and offline edits queue in an outbox.
* All AI grouping, classification and insights run on the device, with no server cost.

## Running the load test

```bash
# 1. A staging project with the migrations applied, and ~50 confirmed test accounts in users.json
# 2. Run (k6: https://k6.io)
k6 run -e SUPABASE_URL=https://<ref>.supabase.co -e ANON_KEY=<anon key> \
       -e USERS_FILE=users.json backend/loadtest/sync_load.js
```

It ramps to 500 concurrent virtual users and holds for 5 minutes. It fails if:

* p95 pull latency is over 400 ms
* p95 push latency is over 600 ms
* more than 1% of requests error

Watch **Database → Query performance** (`pg_stat_statements`) and CPU in the
Supabase dashboard while it runs. Never point it at production.

## Self-hosted (docker-compose)

The bundled Postgres is tuned for its 1 GB limit:

* `shared_buffers=256MB`
* `max_connections=200`
* `statement_timeout` / `idle_in_transaction_session_timeout` guards
* `pg_stat_statements` enabled

Put PgBouncer (transaction mode) in front if anything other than PostgREST connects
directly.
