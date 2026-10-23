# Networking & backend source-of-truth — canonical rules

**Canonical home for:** `NET-1` … `NET-7`, plus the backend source-of-truth hierarchy (§5)

**Owner document:** `flutter-expert.md` — rule language (§0.1), canonical-home
rule (§0.2), precedence (§0.3), operating loop (§1), reporting contract (§11).
**Section numbers** (`§4.1`, `§7`, `§9`, …) are the original policy's section numbers and are
kept unchanged; the Section map in `flutter-expert.md` says which file each one lives in.
**Do not restate any rule from this file elsewhere** — cite its Rule ID instead (§0.2).

**§5 is the canonical source-of-truth hierarchy** for API shape and API behavior. It is the
authority `api-investigator.md` works from; that agent implements §5, it does not restate
it.

---

# 5. Backend source-of-truth hierarchy

For **API shape** (what fields/types exist), trust in this order:
1. Live OpenAPI/Swagger, fetched now, not remembered from last week.
2. A generated client/contract, if the project treats it as authoritative.
3. Verified backend source code, if you have access to it.
4. Real example requests/responses.
5. Assumptions — acceptable only when stated as assumptions, never presented as fact.

For **API behavior** (what actually happens when you call it), trust in this order:
1. A verified live response/behavior you or a teammate has actually observed.
2. Backend tests or docs that describe the behavior explicitly.
3. Backend source code, read directly.
4. Examples that happen to demonstrate the behavior.
5. A team member's claim about what it does.

"The backend says it's done" sits at the bottom of both hierarchies, on its own — it is not
evidence about *shape* (an OpenAPI spec is) or about *behavior* (a real response is). Treat it as
a lead to verify, not a fact to build on (`§4.6`).

On ABP backends specifically: `mobile-*` endpoints commonly carry `[DontWrapResult]` → raw JSON;
`services/app/*` endpoints are usually wrapped in the standard envelope. Confirm which applies
per endpoint — don't assume from the prefix alone without checking at least once.

---

## 6.5 Networking (`NET-*`)

**`NET-1` 🔴 — Separate timeouts for connect, receive, and send; override send for uploads.**
```
connect 10s · receive 30s · send 120s+ for uploads (per-request override)
```
*Why:* one shared 30s timeout fails a large upload at second 30 **after** the user waited,
losing their work and reporting a misleading "timeout." *Verification:* check the current
project's client config against this before assuming a single shared timeout is fine.

**`NET-2` 🟠 — Retry with backoff, and an explicit no-retry list.**
```
Retry:     timeout · connection error · 502 · 503 · 504
Never:     every 4xx · and any POST that is not idempotent
Backoff:   1s → 2s → 4s, max 3 attempts, stop on the first 4xx
```
*Exception (🔴, non-negotiable sub-rule):* a non-idempotent create endpoint (e.g.
`POST …/posts/create`) must **never** retry — a duplicated post is worse than a failed one.

**`NET-3` 🔴 — Cancel in-flight work the user can supersede (search, filter, anything similar).**
```
→ CancelToken, cancelled on the next request and in close()
```
*Why:* a debouncer (see `§2.2`) reduces *how often* you fire a request; it does not cancel one
already in flight, and responses aren't guaranteed to arrive in order — type fast enough and an
older result can overwrite a newer one (`STATE-6`). *Exception:* a request that changed server
state (e.g. `POST share`) is **not** cancelled — cancelling on the client is not a rollback on
the server.

**`NET-4` 🟠 — One in-flight request per intent (single-flight), named as a pattern and reused.**
```dart
Future<T>? _inFlight;
Future<T> load() => _inFlight ??= _load().whenComplete(() => _inFlight = null);
```
*Why:* this tends to get reinvented per-feature without ever becoming a named, shared pattern —
name it once, reuse the implementation. *Exception:* an explicit user retry must still be allowed
through, or the button reads as dead.

**`NET-5` 🟠 — Decide idempotency per mutating call, and write the answer down at the call site.**
```
For every POST/PUT/DELETE: is it idempotent? Write the answer at the call site.
Not idempotent → guard the client AND ask the backend for an idempotency key
```

**`NET-6` 🟠 — Handle status codes by their real meaning; don't collapse them.**

| Code | Handling |
|---|---|
| **401** | Refresh once, retry once, then expire the session. If the interceptor already does this correctly, read it before rewriting it. |
| **403** | **Not** a session problem. Never sign the user out. Show what is not permitted. |
| **429** | Read `Retry-After` and honour it, if the backend sends it. |
| **5xx** | Retryable **only** with a body; empty means failure — see `SEC-7`. |
| **Empty body, any code** | Failure. Never parse — see `SEC-7`. |

**`NET-7` 🟡 — Cache invalidation follows the URL.**
*Why:* image caches typically key on URL. If the backend returns stable filenames rather than
hashed ones, a changed image with the same URL is cached forever — confirm which behavior the
current backend has before assuming invalidation is automatic.
