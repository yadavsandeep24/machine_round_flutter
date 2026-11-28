# Latest feature: `Expansible` + `ExpansibleController` (Flutter, 3.32 stable, May 2025)

## What's new

Flutter 3.32 added `Expansible`, a design-agnostic expand/collapse widget in the **widgets** library (not Material). You give it a header builder, a body builder and an `ExpansibleController`. It handles the height animation and hides the collapsed body with `Offstage`. The builders receive the expand animation (0 → 1), so you can sync a chevron or fade with it.

`ExpansionTile` now uses `Expansible` internally. `ExpansionTileController` is deprecated and is just a typedef for `ExpansibleController`. The new controller is a `ChangeNotifier`, so you can listen to it.

Sources:
- [Deprecated ExpansionTileController](https://docs.flutter.dev/release/breaking-changes/expansion-tile-controller) — breaking-change guide: landed in 3.31.0-0.1.pre, in stable **3.32** (released 20 May 2025).
- [Expansible class](https://api.flutter.dev/flutter/widgets/Expansible-class.html) and [ExpansibleController class](https://api.flutter.dev/flutter/widgets/ExpansibleController-class.html) — API reference.

Why this and not something newer: this machine has **Flutter 3.32.5 / Dart 3.8.1**. Newer features (for example Dart 3.10 dot shorthands in Flutter 3.38, Nov 2025) need an SDK upgrade, which this daily job does not do. `Expansible` is one of the newest widget APIs this SDK has, and it was not covered before.

## Why it matters

- Expandable rows are everywhere in payments apps: FAQ / help, transaction details, fee breakdown, order summary, settings groups.
- Before 3.32 the built-in option was Material's `ExpansionTile`. It has a fixed `ListTile` look. A custom design meant writing your own `AnimationController`, `SizeTransition` and `ClipRect`.
- `Expansible` gives you the animation and state, with no styling. Good for a design system or Cupertino-style UI.
- The controller lets the app drive expansion: deep links ("open the 'declined' answer"), accordion mode, expand all / collapse all.
- When not to use it: if the Material `ExpansionTile` look is fine, use `ExpansionTile`. For a long list of independent rows with no external control, a plain `bool` in local state is enough.

## Before vs after

```dart
// Before (≤ 3.29): Material only, controller type now deprecated
final controller = ExpansionTileController();
ExpansionTile(controller: controller, title: Text(q), children: [Text(a)]);

// Custom look before 3.32: hand-rolled
AnimationController _anim = AnimationController(vsync: this, duration: d);
Column(children: [header, ClipRect(child: SizeTransition(sizeFactor: _anim, child: body))]);
```

```dart
// After (3.32+): any look, same controller type for ExpansionTile and Expansible
final controller = ExpansibleController(); // ChangeNotifier: dispose it
Expansible(
  controller: controller,
  headerBuilder: (context, animation) => InkWell(
    onTap: () => controller.isExpanded ? controller.collapse() : controller.expand(),
    child: Row(children: [Text(q), RotationTransition(turns: Tween(begin: 0.0, end: 0.5).animate(animation), child: chevron)]),
  ),
  bodyBuilder: (context, animation) => Text(a),
);
```

## How this branch uses it

A "Payments help" screen: searchable FAQ with an accordion mode, expand all / collapse all, and a deep link (`/?open=declined`) that opens one answer on arrival.

- `lib/features/help/domain/faq_item.dart` — `FaqItem` with a stable id and a `matches(query)` helper.
- `lib/features/help/data/payment_faqs.dart` — static demo content (payments, refunds, security).
- `lib/features/help/presentation/faq_cubit.dart` — single source of truth: `expanded` id set, `singleOpen` mode, search query.
- `lib/features/help/presentation/faq_tile.dart` — the `Expansible` row; a `BlocListener` mirrors cubit state into the tile's `ExpansibleController` (outside build).
- `lib/features/help/presentation/faq_page.dart` — page, search field, accordion switch, app-bar actions, keyed `ListView.builder`.
- `lib/core/router/app_router.dart` — home route reads the `open` query parameter.
- `test/features/help/faq_cubit_test.dart` — accordion, multi-open, expand/collapse all, deep link, search (`bloc_test`).
- `test/features/help/faq_page_test.dart` — widget tests, plus a before-vs-after group (`ExpansionTile` vs bare `Expansible`, same controller type).
- `test/app_test.dart` — app shell and deep-link smoke tests.

## Interview talking points

- "`Expansible` moved expand/collapse logic out of Material into the widgets layer. `ExpansionTile` is now a Material skin on top of it."
- "State lives in the Cubit as a set of open ids. Each tile's `ExpansibleController` only mirrors it. That makes accordion mode, expand-all and deep links one-line state changes, and easy to unit test without widgets."
- "`expand()` and `collapse()` trigger a rebuild, so I never call them in `build`. I call them in `initState` (before the child exists) and in a `BlocListener`, which runs from the stream, outside the build phase."
- "Tiles are keyed by item id. When the search filter changes, each tile keeps its own controller instead of a controller sliding to a different row."
- "The controller is a `ChangeNotifier`, so it must be disposed. That is the one real migration step from `ExpansionTileController`."
- "The collapsed body is `Offstage`, so it is not painted or hit-tested, and default test finders skip it."

**Likely follow-ups**

1. *Why not keep a `bool isExpanded` in each tile's `State`?* — Fine for isolated rows. But the page needs to control the rows (accordion, expand all, deep link), and state inside each tile is lost when the row scrolls away. Lifting it to the Cubit fixes both.
2. *How do you keep expanded state when a row scrolls off screen?* — Here the Cubit holds it, and the tile reads it in `initState`. Without a Cubit, use `PageStorageKey` as the `Expansible` docs suggest.
3. *Performance with many rows?* — Use `ListView.builder` so only visible tiles exist. `maintainState: false` (the default) drops the body subtree when collapsed.

## Gotchas and compatibility

- **Minimum**: Flutter 3.32 (Dart 3.8). No platform minimums; it is pure Dart UI.
- **Migration**: replace `ExpansionTileController` with `ExpansibleController` and add `dispose()`. `ExpansionTileController.of(context)` becomes `ExpansibleController.of(context)`.
- **Not a toggle by itself**: `Expansible` does not react to taps. Your header must call `expand()` / `collapse()`.
- **Newer SDKs**: after Flutter 3.38, `Expansible`'s `duration`, `curve` and `reverseCurve` are deprecated in favour of `animationStyle` (see the API docs). This branch targets 3.32.5, so it still uses `duration` and `curve`.
- **Dependency bumps in this branch**: none.

## Run it

```bash
git checkout latest/2026-11-28-expansible-controller
flutter pub get
flutter analyze
flutter test
flutter run
```
