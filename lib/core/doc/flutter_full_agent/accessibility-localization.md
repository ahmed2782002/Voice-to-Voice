# Accessibility, localization & RTL — canonical rules

**Canonical home for:** `A11Y-1` … `A11Y-5`

**Owner document:** `flutter-expert.md` — rule language (§0.1), canonical-home
rule (§0.2), precedence (§0.3), operating loop (§1), reporting contract (§11).
**Section numbers** (`§4.1`, `§7`, `§9`, …) are the original policy's section numbers and are
kept unchanged; the Section map in `flutter-expert.md` says which file each one lives in.
**Do not restate any rule from this file elsewhere** — cite its Rule ID instead (§0.2).

**Cross-reference:** `STYLE-1` (strings via the shared constant + `.tr()`) and `STYLE-6`
(`minHeight` around text) are in `style.md`; `STYLE-6` cites `A11Y-1` rather than repeating
it. RTL enforcement is `A11Y-5` here — it is the only definition of that requirement.

---

## 6.8 Accessibility & localization (`A11Y-*`)

**`A11Y-1` 🟠 — Text scale is independent of screen size; ScreenUtil scales to the device, not
the user's font preference.**
```dart
SizedBox(height: 44.h, child: Text('…', style: Styles.regular(14)))
// user sets 200% font → the text clips, the box does not move
```
*Rule:* a box containing text uses `minHeight`, never `height`. Test any text-bearing screen at
200% font scale before merge.

**`A11Y-2` 🟠 — Touch targets ≥ 44×44 regardless of artwork size.**
*Why:* a small icon glyph (e.g. a 12×20 attachment icon) is not itself the tap target — wrap it
in padding rather than resizing the drawing.

**`A11Y-3` 🟡 — Every data screen has four states: loading · empty · error+retry · content.**
*Why:* an empty list and a failed request must not look the same.

**`A11Y-4` 🟡 — Icon-only controls carry a `Semantics` label.**
*Applies to:* share, save, like, and any other icon-only affordance.

**`A11Y-5` 🟡 — RTL is the default, not a mode.**
Use `EdgeInsetsDirectional` and `AlignmentDirectional`; never hand-roll `Directionality`.
`AlignmentDirectional.topStart` exists; `Alignment.topStart` does not — a real compile error
that's actually been hit on this stack.
