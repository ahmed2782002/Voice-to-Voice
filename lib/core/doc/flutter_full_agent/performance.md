# Performance — canonical rules

**Canonical home for:** `PERF-1` … `PERF-6`

**Owner document:** `flutter-expert.md` — rule language (§0.1), canonical-home
rule (§0.2), precedence (§0.3), operating loop (§1), reporting contract (§11).
**Section numbers** (`§4.1`, `§7`, `§9`, …) are the original policy's section numbers and are
kept unchanged; the Section map in `flutter-expert.md` says which file each one lives in.
**Do not restate any rule from this file elsewhere** — cite its Rule ID instead (§0.2).

**Measurement inputs:** the `BlocSelector`/`ListView`/`compute`/`memCacheWidth` counts that tell
you whether these rules are being followed in a given repository come from §3
(`architecture.md`).

---

## 6.4 Performance (`PERF-*`)

**`PERF-1` 🔴 — `build()` does no work.**
```
Forbidden in build(): JSON decoding · sort · filter · date formatting · regex ·
                      any loop over a network-sized list
Belongs in: the cubit (once), or the model as a cheap getter
> 16ms of synchronous work → compute()
```
*Exception:* a cheap, obvious expression inline in `build` is clearer than a stored field —
"cheap" means no allocation per item and no I/O.

**`PERF-2` 🟠 — Use the right Bloc widget for the job.**

| Tool | When |
|---|---|
| `BlocSelector` | One field drives the widget |
| `buildWhen` | Several fields, but a condition decides |
| `BlocBuilder` | The whole state affects the paint |
| `BlocListener` | Side effect only — **must not paint** |

*Exception that matters:* `BlocSelector` over a composite object without a correct `==` rebuilds
on every emit anyway — `buildWhen` on primitive fields is then the faster choice.

**`PERF-3` 🟠 — `SingleChildScrollView` when the item count is known at authoring time; `ListView.
builder`/Sliver when it comes from the server.**
*Why:* `SingleChildScrollView` builds and keeps every child resident — fine for a fixed, small
list; wrong once the count is server-driven. *Exception:* a short server list with a hard,
enforced cap (≤10) is fine — write the cap down.

**`PERF-4` 🟠 — Decode remote images at display size, not source size.**
```dart
CachedNetworkImage(imageUrl: …)                     // decodes at full source resolution
CachedNetworkImage(imageUrl: …, memCacheWidth: 800) // decodes at roughly what's drawn
```
*Why:* an unconstrained camera photo behind a 48×48 avatar is tens of megabytes of bitmap. Many
backends on this stack don't validate upload dimensions — check `PROD-6` before assuming
otherwise. *Where:* inside the shared remote-image widget, once, so no call site repeats it.

**`PERF-5` 🟡 — Treat `const` as a rebuild boundary, not a style preference.**
*Verification:* `prefer_const_constructors` promoted to an error (§7).

**`PERF-6` 🟡 — Startup does the minimum; default GetIt registrations to `registerLazySingleton`.**
*Exception:* `lazy: false` needs a stated reason.
