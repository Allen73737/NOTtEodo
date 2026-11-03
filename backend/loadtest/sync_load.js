// k6 load test: 500 concurrent signed-in users syncing against a Supabase project.
//
//   k6 run -e SUPABASE_URL=https://<ref>.supabase.co -e ANON_KEY=<anon> \
//          -e USERS_FILE=users.json backend/loadtest/sync_load.js
//
// users.json: [{"email": "...", "password": "..."}, ...] (at least 50 test accounts;
// virtual users share them round-robin). Use a staging project, never production.
//
// Each virtual user behaves like the app: sign in once, then every few seconds
// a delta pull (rows changed since the last sync) and an upsert of one collection.
import http from 'k6/http';
import { check, sleep } from 'k6';
import { SharedArray } from 'k6/data';
import { Trend, Rate } from 'k6/metrics';

const URL = __ENV.SUPABASE_URL;
const KEY = __ENV.ANON_KEY;
const users = new SharedArray('users', () => JSON.parse(open(__ENV.USERS_FILE || 'users.json')));

const pullLatency = new Trend('sync_pull_ms', true);
const pushLatency = new Trend('sync_push_ms', true);
const failures = new Rate('sync_failures');

export const options = {
  scenarios: {
    ramp_to_500: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 100 },
        { duration: '2m', target: 500 },
        { duration: '5m', target: 500 }, // hold 500 concurrent users
        { duration: '1m', target: 0 },
      ],
    },
  },
  thresholds: {
    sync_pull_ms: ['p(95)<400'],
    sync_push_ms: ['p(95)<600'],
    sync_failures: ['rate<0.01'],
    http_req_failed: ['rate<0.01'],
  },
};

const COLLECTIONS = ['notes', 'tasks', 'expenses', 'habits', 'events'];
const session = {}; // per-VU: token, user id, last sync

function signIn() {
  const u = users[(__VU - 1) % users.length];
  const res = http.post(`${URL}/auth/v1/token?grant_type=password`, JSON.stringify(u), {
    headers: { apikey: KEY, 'Content-Type': 'application/json' },
    tags: { name: 'sign_in' },
  });
  check(res, { 'signed in': (r) => r.status === 200 });
  const body = res.json();
  session.token = body.access_token;
  session.uid = body.user && body.user.id;
  session.since = null;
}

function headers() {
  return { apikey: KEY, Authorization: `Bearer ${session.token}`, 'Content-Type': 'application/json' };
}

export default function () {
  if (!session.token) signIn();
  if (!session.token) {
    failures.add(1);
    sleep(5);
    return;
  }

  // Delta pull (index range scan on (user_id, updated_at)).
  let q = `${URL}/rest/v1/user_collections?select=collection,data,updated_at&user_id=eq.${session.uid}`;
  if (session.since) q += `&updated_at=gt.${encodeURIComponent(session.since)}`;
  const pull = http.get(q, { headers: headers(), tags: { name: 'pull' } });
  pullLatency.add(pull.timings.duration);
  failures.add(pull.status !== 200);
  if (pull.status === 401) session.token = null;

  // Push one collection (~40 items), like an edit followed by the 2 s debounce.
  const collection = COLLECTIONS[Math.floor(Math.random() * COLLECTIONS.length)];
  const now = new Date().toISOString();
  const rows = Array.from({ length: 40 }, (_, i) => ({ id: `lt-${__VU}-${i}`, title: `Load test item ${i}`, updatedAt: now }));
  const push = http.post(
    `${URL}/rest/v1/user_collections?on_conflict=user_id,collection`,
    JSON.stringify({ user_id: session.uid, collection, data: rows, updated_at: now }),
    { headers: { ...headers(), Prefer: 'resolution=merge-duplicates,return=minimal' }, tags: { name: 'push' } },
  );
  pushLatency.add(push.timings.duration);
  failures.add(push.status !== 201 && push.status !== 204 && push.status !== 200);
  session.since = now;

  sleep(3 + Math.random() * 4); // a busy user: one sync every 3-7 seconds
}
