# NOTtEodo Enterprise Security Manifesto & Architecture Guide

## Executive Security Summary

NOTtEodo is engineered around the principle of **Zero Trust Architecture (ZTA)** and **Defense in Depth**. Every request, query, and cryptographic operation is authenticated, authorized, validated, and logged to prevent unauthorized access, tampering, data exfiltration, or hostile takeovers.

---

## 1. Threat Mitigation Matrix (OWASP Top 10 Defenses)

### A. Broken Access Control & IDOR (A01:2021)
- **Hardened Row Level Security (RLS)**: Enabled unconditionally on **100% of tables**.
- **Tenant Scoping**: All queries are bound to `auth.uid() = user_id`.
- **Write Verification**: `WITH CHECK (auth.uid() = user_id)` guarantees an attacker cannot re-assign ownership or inject foreign spaces/documents belonging to other tenants.

### B. Cryptographic Failures & Vault Privacy (A02:2021)
- **Zero-Knowledge Hidden Vault**: All confidential notes and entries stored in `public.encrypted_vault` are encrypted client-side using **AES-GCM-256** with an **Argon2id / PBKDF2** salt.
- **Server Blindness**: The server, cloud provider, and database administrators store only ciphertext, nonce, and a verification hash. Raw unencrypted data never touches the network or server memory.
- **Enforced TLS 1.3**: All communications require HTTPS/WSS with HSTS.

### C. Injection Attacks (SQLi & XSS) (A03:2021)
- **Parameterized Queries**: All database communications utilize Supabase's PostgREST query engine with strict parameter binding. Direct SQL string concatenation is forbidden.
- **PostgreSQL Check Constraints**: Regex validation and length limits on all text fields (`char_length <= 255`, alphanumeric codes, positive numbers for amounts).
- **Prompt Injection Defense**: The `scoped-ai` Edge Function enforces strict jailbreak regex filters and context sandboxing before passing prompts to Groq LLaMA 3.3.

### D. Insecure Design & Anti-DDoS / Brute Force (A04:2021)
- **In-Database Rate Limiter**: The `check_rate_limit(user_id, endpoint, max_requests, window_seconds)` sliding window function throttles rapid queries and brute-force attempts.
- **Vault Lockout**: 5 failed unlock attempts trigger an exponential backoff lock and emit a `CRITICAL` severity audit log.

### E. Security Logging & Monitoring Failures (A09:2021)
- **Immutable Security Audit Trail**: The `public.security_audit_logs` table records authentication events, rate-limiting triggers, and vault accesses.
- **Anti-Tamper Privilege Revocation**: `UPDATE`, `DELETE`, and `TRUNCATE` privileges on `security_audit_logs` are explicitly revoked from both `authenticated` and `anon` roles. Once written, a log cannot be altered or deleted.

---

## 2. Database Migrations Order

To deploy this backend to any Supabase Cloud project or self-hosted PostgreSQL instance:

```bash
# 1. Login to Supabase CLI
supabase login

# 2. Link your cloud project
supabase link --project-ref your-project-id

# 3. Push migrations to database
supabase db push
```

The migrations execute in deterministic order:
1. `20260905000000_full_schema.sql`: Master table structures, constraints, check rules, and pgvector indexes.
2. `20260905000001_hardened_rls.sql`: RLS activation on all 15 tables with granular CRUD policies and triggers.
3. `20260905000002_security_functions.sql`: Anti-DDoS rate limiting, cosine similarity vector search, and audit procedures.

---

## 3. Deploying Edge Functions

```bash
# Deploy Scoped AI Edge Function
supabase functions deploy scoped-ai --no-verify-jwt=false

# Deploy Document Embedder
supabase functions deploy rag-embedder

# Deploy Vault Gatekeeper
supabase functions deploy vault-gatekeeper

# Set production secrets
supabase secrets set GROQ_API_KEY="gsk_..."
supabase secrets set CLOUDINARY_CLOUD_NAME="..."
```

---

## 4. Frontend Client Security Guarantee

- **Graceful Offline Fallback**: If internet connectivity is interrupted or cloud credentials are not supplied, NOTtEodo operates in pure offline local state via Riverpod, guaranteeing zero crashes and uncompromised user experience.
- **Secure Token Handling**: JWT tokens are refreshed automatically and stored in encrypted local storage.
