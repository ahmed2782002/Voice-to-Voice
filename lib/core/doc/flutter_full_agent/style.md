# Style & consistency — canonical rules

**Canonical home for:** `STYLE-1` … `STYLE-11`

**Owner document:** `flutter-expert.md` — rule language (§0.1), canonical-home
rule (§0.2), precedence (§0.3), operating loop (§1), reporting contract (§11).
**Section numbers** (`§4.1`, `§7`, `§9`, …) are the original policy's section numbers and are
kept unchanged; the Section map in `flutter-expert.md` says which file each one lives in.
**Do not restate any rule from this file elsewhere** — cite its Rule ID instead (§0.2).

**Precedence note:** `STYLE-*` sits at position 7 — last — in the precedence order (§0.3), and a
task may explicitly ask you to break a ⚪/🟡 style rule; if it does, comply and state which rule
and why in the report (§0.3, §0.7).

---

## 6.10 Style & consistency (`STYLE-*`)

| ID | Requirement | Exception |
|---|---|---|
| `STYLE-1` | Shared strings constant + `.tr()` — no literal user-facing text | — |
| `STYLE-2` | Shared colours constant — no inline `Color(0xFF…)` | — |
| `STYLE-3` | Shared text-style set — no bare `TextStyle`, no direct `FontWeight` | — |
| `STYLE-4` | No `Icons.*` or asset path inlined in a screen — go through the shared icon/image constants | the constants file itself may hold raw `IconData`/paths; the rule is about inlining at call sites, not about the underlying type |
| `STYLE-5` | Shared endpoints constant — no inline path strings | — |
| `STYLE-6` | ScreenUtil for every dimension, one unit family per shape (a circle and its notch both in `.w`/`.r`/`.h` or they drift apart on other aspect ratios); `minHeight` around text, never `height` (`A11Y-1`) | — |
| `STYLE-7` | Route remote images through the shared widget (for its `errorWidget`); `SvgPicture.asset` for SVG | — |
| `STYLE-8` | Toasts triggered from the cubit — never a snackbar, never a toast called from a widget | — |
| `STYLE-9` | `StatelessWidget` for screens; `StatefulWidget` only for widget-local state (`LIFE-3`) | per `LIFE-3` |
| `STYLE-10` | Shared logger only — no `print`, no raw `debugPrint` | — |
| `STYLE-11` | A constant derived from others is computed by an equation, never hand-typed | a hand-typed total one pixel short clips a widget with no error at all |
