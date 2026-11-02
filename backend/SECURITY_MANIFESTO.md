# NOTtEodo Security Architecture

NOTtEodo is local-first: your data lives on your device, encrypted. The cloud is an
optional mirror, and it can be zero-knowledge. This document describes what is
implemented, what each layer protects against, and what it does not.

---

## 1. On-device encryption (every platform, always on)

| | |
|---|---|
| Cipher | AES-256-GCM, a fresh 96-bit random nonce per write |
| Binding | Each value's storage slot is its AAD, so ciphertexts cannot be swapped between slots |
| Data key | Random 256-bit key, decrypted only in memory |
| Device key | Android Keystore · Apple Keychain (`ThisDeviceOnly`) · non-extractable WebCrypto key in IndexedDB |
| Code | `frontend/lib/core/services/local_store.dart`, `frontend/lib/core/security/` |

**Key hierarchy**

```
                 ┌──────────── no PIN ────────────┐
data key ──wrap──┤                                 ├── device key (Keystore / Keychain / WebCrypto)
                 └─ PIN: PBKDF2-SHA256 600k ─wrap─┘
```

* **No PIN:** the data key is wrapped by the device key, so the app opens instantly.
  Copying the storage to another machine is not enough to read it.
* **PIN set:** the data key is wrapped by PBKDF2-HMAC-SHA256(PIN, 600,000 iterations,
  OWASP 2023), then wrapped again by the device key. The PIN is never stored, hashed or
  otherwise: a wrong PIN simply fails the GCM authentication check. Brute force needs
  this device's secret and costs a full key derivation per guess.
* **Lockout:** after 5 misses each further miss doubles a pause (30 s up to 1 h). The
  counter is persisted, so restarting the app does not reset it. Optionally, the device
  is erased after 10 misses.
* **Biometrics (Android/iOS):** the data key is stored in an OS slot that the secure
  hardware releases only after a strong biometric match (Android `BIOMETRIC_STRONG`
  Keystore key; iOS `biometryCurrentSet`). Enrolling a new fingerprint or face
  invalidates the slot, and the app falls back to the PIN.
* **Auto-lock:** after a configurable time in the background or idle (immediately to
  1 hour). On lock the data key and decrypted data are dropped from memory.
* **Privacy:** the app-switcher snapshot is blurred (mobile), and screenshots can be
  blocked (Android `FLAG_SECURE`). Android cloud backup and device transfer are
  disabled, because an encrypted copy without its Keystore key is useless.
* **Migration:** data from builds before encryption, and the old salted-SHA-256 PIN,
  are upgraded in place on first launch and first unlock.

## 2. Cloud sync (optional)

* **Transport:** TLS only. HSTS on the web app; cleartext traffic is disabled on Android.
* **Isolation:** row-level security on every table. A user can only read and write rows
  where `auth.uid() = user_id`.
* **End-to-end encryption (opt-in, zero-knowledge):** each collection snapshot is
  sealed on the device with a random 256-bit sync key (AES-256-GCM, AAD
  `userId/collection`). The sync key is wrapped with PBKDF2-SHA256(passphrase, 600k)
  and stored in `user_keys`. The server stores only ciphertext and a wrapped key; the
  passphrase never leaves the device. A database trigger rejects plaintext uploads for
  accounts that have turned E2EE on, so an outdated client cannot leak data.
* **Sessions:** PKCE OAuth. On mobile, refresh tokens live in the Keychain/Keystore,
  not SharedPreferences. Refresh tokens rotate, and reuse revokes the session.
* **Two-step verification (TOTP):** when a user enrols an authenticator, RESTRICTIVE
  RLS policies require an AAL2 session for their data. A stolen password alone
  cannot read it.
* **Passwords:** a minimum of 10 characters, with common and sequential passwords
  blocked. Passwords seen in breaches are rejected with a Have I Been Pwned
  k-anonymity check (only 5 hex characters of the SHA-1 leave the device). Email
  confirmation and secure password change are on.

## 3. Server hardening

* `SECURITY DEFINER` functions have a pinned `search_path`, and `anon` and `PUBLIC`
  cannot execute them.
* `check_rate_limit` is callable only with the service role, from edge functions, and
  only for the caller's own user id. Previously any user could exhaust another user's
  quota.
* `log_security_event` validates event names, caps metadata at 2 KB, throttles
  floods, and does not let clients write `CRITICAL` entries.
* Edge functions (`functions/_shared/security.ts`) apply:
  * a CORS origin allowlist (`ALLOWED_ORIGINS`)
  * strict JWT verification
  * body size limits
  * fail-closed, service-role rate limiting
  * timeouts on AI calls
  * security headers
  * generic error messages, with details logged server-side only
* Prompt injection: user text is sanitised, and retrieved context is fenced and
  labelled as untrusted data.

## 4. Web app hardening (nginx)

* **Strict CSP:**
  * `script-src 'self' 'wasm-unsafe-eval'`: no inline scripts, no `eval`. CanvasKit is
    self-hosted via `--no-web-resources-cdn`.
  * `connect-src` is limited to this deployment's Supabase project, Google Fonts and the
    HIBP range API.
  * `frame-ancestors 'none'`, `object-src 'none'`, `base-uri 'self'`.
* **Headers:** HSTS (preload), COOP/CORP same-origin, `nosniff`, `Referrer-Policy:
  no-referrer`, and a Permissions-Policy that allows only the microphone (voice
  capture). The headers apply to every location block; nginx otherwise drops them
  where a location sets its own headers.
* **Container:**
  * The web server runs as non-root nginx on port 8080, with read-only static files,
    `no-new-privileges` and all Linux capabilities dropped.
  * Postgres is bound to localhost and uses SCRAM authentication. Compose refuses to
    start without a real password.

## 5. Data portability

* Backups are encrypted by default: AES-256-GCM with PBKDF2-SHA256(password, 600k).
  An unencrypted export needs an explicit choice.
* CSV exports neutralise spreadsheet formula injection (CWE-1236).
* Text copied to the clipboard as a fallback is wiped after 90 seconds.

## 6. What this does not protect against

The following are limits, stated honestly:

* **A compromised, unlocked device** (malware with root, or a keylogger) can read what
  you can read. No app can prevent that.
* **Web: the device key is non-extractable, but it is not hardware-backed.** A malicious
  browser extension or an XSS bug can use it while the page is open. The CSP makes XSS
  much harder. With a PIN, data at rest stays sealed until you unlock it.
* **A 4–6 digit PIN has little entropy.** On mobile, brute force needs the
  hardware-bound device key, which is what makes short PINs acceptable (the same model
  phones use). On the web, an attacker who copies the browser profile could attempt
  offline guessing at 600k PBKDF2 iterations per guess. Use 6 digits.
* **Without E2EE, the server can read synced data** (RLS isolates users from each
  other, not from the operator). Turn on end-to-end encryption for zero-knowledge sync.
* **The AI assistant sends the snippets relevant to your question to the model
  provider (Groq).** Don't use it for data you would not share with them.
* **A forgotten PIN or passphrase cannot be recovered.** That is the point of
  zero-knowledge.

## 7. Deploying

```bash
supabase link --project-ref <project>
supabase db push                       # applies migrations in order
supabase functions deploy scoped-ai
supabase functions deploy vault-gatekeeper
supabase functions deploy rag-embedder
supabase secrets set GROQ_API_KEY=... ALLOWED_ORIGINS=https://your-app.example.com
```

Migrations, applied in order:

1. `20260905000000_full_schema.sql`
2. `20260905000001_hardened_rls.sql`
3. `20260905000002_security_functions.sql`
4. `20261101000000_user_collections_sync.sql`
5. `20261102000000_security_hardening.sql`: E2EE keys, plaintext guard, MFA (AAL2) RLS,
   and function hardening

In the dashboard, also enable leaked-password protection and CAPTCHA (Pro plan), and set
the production `site_url` and redirect URLs.

`backend/docker-init/00_standalone_auth.sql` is **not** a Supabase migration. It stubs the
`auth` schema and API roles so the schema runs on plain Postgres under Docker Compose.
Never apply it to a Supabase project.

Report vulnerabilities as described in [SECURITY.md](../SECURITY.md).
