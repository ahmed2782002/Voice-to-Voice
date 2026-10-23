# Engineering knowledge — decision framework & recurring mistakes (HISTORICAL EXAMPLES)

**Canonical home for:** §4 (decision framework) and §12 (recurring mistake patterns)

**Owner document:** `flutter-expert.md` — rule language (§0.1), canonical-home
rule (§0.2), precedence (§0.3), operating loop (§1), reporting contract (§11).
**Section numbers** (`§4.1`, `§7`, `§9`, …) are the original policy's section numbers and are
kept unchanged; the Section map in `flutter-expert.md` says which file each one lives in.
**Do not restate any rule from this file elsewhere** — cite its Rule ID instead (§0.2).

**Status label — read this first.** Everything in this file is a **Historical example**: a real
bug from a *past* project on this stack, kept as a decision template. Nothing here is a claim
about the repository you are in now, and nothing here may be copied into `PROJECT.md` or into the
live register (`register.md`) as a project fact. Facts about the current repository come
only from §2 discovery and §3 measurement (`architecture.md`).

**Used by:** the DECIDE phase of §1, and by `reviewer.md` when a finding resembles a known
failure class. §4's governing rule — never infer root cause from symptom similarity — applies
every time this file is consulted.

---

# 4. Decision framework

§6 tells you what not to type. This section is about **what to choose** when the failure class
doesn't reduce to a style rule — and every example below is a real bug that shipped on this
stack, on a past project, used here as a template: **symptom → possible causes → evidence to
collect → decision → failure mode prevented.** They are historical examples, not a claim about
the repository you're currently in.

**Governing rule of this section: never infer root cause from symptom similarity.** Two bugs with
identical descriptions can have unrelated causes (§12). Reproduce, or collect the specific
evidence listed below, before making an architectural change on the strength of a guess.

## 4.1 A response that isn't marked as failed is not automatically successful

- **Symptom:** a screen behaves as if a request succeeded when it didn't (an OTP screen opening
  after a login that actually failed, a success toast after an error).
- **Possible causes:** an empty-body response normalized to "success"; a status code exempted
  from the failure guard; a parser building a model from `{}` instead of refusing to.
- **Evidence to collect:** the raw response — status code *and* body, verbatim, for the exact
  failing call (`git stash` or a real capture, not a description of what "usually" happens).
- **Decision:** a status carrying **no body** is a failure (`SEC-7`). `''` counts as bodiless —
  many HTTP clients return `''` for a zero-length payload, which a `null`-only check misses.
  Never let a model be built from `{}` when the caller will act on it.
- **Prevented:** on a past project, three individually-correct decisions intersected this way —
  reading bodies up to 599 so ABP error messages inside a `500` survive, normalizing a bodiless
  response to success so raw `mobile-*` JSON worked, and exempting `500` from the status guard so
  its envelope got parsed — and the OTP screen opened on a login that never happened. **Each
  decision was right alone.** Ask of any new parser: *what does this produce if the body is
  empty, and who acts on it?*

## 4.2 An opaque element above a list reserves space; a transparent one overlays

- **Symptom:** content is clipped or hidden behind a bar/overlay, inconsistently across screens.
- **Possible causes:** an opaque widget positioned in a `Stack` instead of a proper
  `Scaffold` slot; each consumer compensating with its own guessed padding constant.
- **Evidence to collect:** whether the covering widget is opaque or transparent, and whether more
  than one screen has independently added a "clearance" constant for it.
- **Decision:** opaque → belongs in `Scaffold.bottomNavigationBar` (or the equivalent slot); the
  body shortens automatically by exactly its height. Transparent → an overlay is fine, and any
  compensating padding lives in **one** place. A widget whose own box already contains its
  overhang needs no extra clearance from callers — check before adding padding.
- **Prevented:** on a past project, a nav bar was `Positioned` opaque over each tab; three of four
  tabs had independently grown their own bottom-gap constant to compensate — one bug, four
  silently-drifting numbers. **Compensating in the consumer hides the problem; it doesn't solve
  it.**

## 4.3 A control the server accepts but the product should not allow again

- **Symptom:** an action that should happen once (share, like-toggle, redeem) can be repeated,
  and a counter or state field drifts as a result.
- **Possible causes:** the client never re-checks eligibility after the first success; a returned
  flag (e.g. `isShared: true`) is parsed but never read anywhere.
- **Evidence to collect:** whether the widget disables/hides the control after first use, and
  separately, whether the *cubit* would still let a second call through if the widget were
  bypassed.
- **Decision:**

  | Case | Treatment |
  |---|---|
  | Action is meaningless for this user (e.g. sharing their own post) | **Hide** the control |
  | Allowed once, already done | **Dim** it |
  | Temporarily unavailable | Disable **with a reason visible** |

  Repeat the guard in the cubit as well as the widget — the widget is what the user sees, the
  cubit is what a second caller must get past. A disabled button is not protection; the endpoint
  stays open unless the server also enforces it (`SEC-4`).
- **Prevented:** on a past project, four taps of a share button took one post's count from `6` to
  `9`; `isShared: true` came back on the first tap, was parsed, and was read by nothing. A parsed
  field nobody reads is a feature the server thinks it delivered.

## 4.4 Two symptoms can be one bug; one symptom can have two causes

- **Symptom:** two bug reports that look unrelated, or two identical-sounding reports.
- **Decision:** reproduce before choosing a cause. On a past project, `Asset not found` **and** a
  283px `RenderFlex` overflow were one bug — the failed-asset render produced an unbounded error
  box. Separately, "send button hidden by keyboard" was diagnosed as a padding issue when the bar
  was actually missing from the layout entirely (`bottomNavigationBar` was empty and the keyboard
  took its place). **Matching descriptions are not matching bugs.**

## 4.5 Prefer the failure that is loud

Given a choice between two designs, prefer the one that fails visibly. An empty list beats a
wrong list; a thrown error in debug beats a default that silently substitutes. The most expensive
bugs on this stack have been quiet ones — a wrong sort order that still *looks* like a sort
order, a `500` read as success that still *looks* like success, a counter counting taps that
still *looks* like it's counting people.

## 4.6 Never treat a backend claim as verified

Backend "done" is a hypothesis until the live API agrees — see §5 for the full source-of-truth
hierarchy. On a past project, four items reported "done" were not on the deployed server, one was
fixed against the wrong DTO, and one of the mobile team's own bug reports to the backend was
wrong and had to be retracted. `git stash` separates "my change broke it" from "it was already
broken" — use it before escalating.

---

# 12. Recurring mistake patterns (illustrative)

Each of these actually happened on a Nahr Flutter app. They're kept concrete rather than
abstracted into generic warnings — a scar teaches more than a rule — but they describe a *class*
of mistake from a past project, not a report on the repository you're in now.

**Treating an assumed cause as verified.** A SignalR hub had both `messageReceived` and
`MessageReceived` registered "for safety." Every event fired twice, and duplicate `mark-as-read`
calls went out — the package lowercases method names on both sides. One line of its source would
have said so. (See `§4`'s governing rule: never infer cause from symptom similarity.)

**Fixing a symptom that has a second cause.** "Send button hidden by keyboard" was patched as
padding. The bar was actually missing entirely — it sat in `bottomNavigationBar`, and the
keyboard took its place. Identical description, unrelated cause (`§4.4`).

**Trusting a grep that was too narrow.** A claim that no tab reserved space for a nav bar came
from grepping `EdgeInsets.only(bottom` alone. Three tabs reserved it via `fromLTRB` and a named
constant — with a comment saying exactly that. Acting on the claim would have deleted real,
load-bearing layout code (`§0.5`).

**Reading a field and using it for nothing.** An `isShared` field arrived on the first share, was
parsed into the model, and was never read — the repeat-share bug (`§4.3`) lived exactly in that
gap.

**Verifying a name from its filename, not its contents.** A storage class was reported as
non-existent during a review because the file was named differently than the class — a direct
violation of `§2.2`'s "verify content, not filename" rule.
