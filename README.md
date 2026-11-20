# Bugs and optimisation: top 10 Flutter "fix this code" questions

Built from `01-minimal`. Many Flutter rounds include a **fix-the-bug / code-review / make-it-faster** part: the CRED Flutter round had code snippets to "find the error, predict the output, improve it"; Deloitte's live round asked to optimise a list to reduce rebuilds; PrepFlutter's machine-coding track has whole *Fix the Bug* and *Code Review* categories. These are the 10 that come up most, each as a runnable demo with a test that **proves** the bug and the fix.

## How to practise
1. `flutter run`. The home screen lists the 10 challenges. Each opens on **Buggy**: read the symptom, reproduce it, and say the cause out loud before tapping **Show answer**.
2. Fix it yourself in `lib/challenges/cNN_*/buggy.dart` without opening `fixed.dart`.
3. Run that challenge's test: `flutter test test/challenges/c03_controller_in_build_test.dart`. The buggy test asserts the broken behaviour, so after your fix, update it to the fixed expectations and it should pass.
4. Compare with `fixed.dart`.

## The 10

| # | Type | Symptom (how it's reported) | Root cause | Fix | Test proves |
|---|---|---|---|---|---|
| 1 | Bug | Profile screen throws after a quick back-tap | `setState` after `await` on a disposed State | `if (!mounted) return;` (Cubit: `isClosed`) | Buggy future fails with `FlutterError`; fixed completes |
| 2 | Bug | Counter keeps ticking after leaving the screen | `Timer.periodic` never cancelled | Keep the `Timer`, cancel in `dispose` | Ticks stop after leaving (the buggy one fails `testWidgets`' own pending-timer check) |
| 3 | Bug | Search input keeps clearing itself | `TextEditingController` created in `build` | Create once in State, dispose it | Buggy field is empty after typing; fixed keeps text |
| 4 | Bug | Spinner flashes / data refetches on every tap or keyboard open | `FutureBuilder(future: fetch())` in `build` | Create the Future once (`late final`) | 3 fetches vs 1, spinner reappears in buggy |
| 5 | Bug | Cart count doesn't update after tapping Add | Mutated list re-emitted; Bloc drops an emit equal to current state | `emit([...state, item])`, `List.unmodifiable` | Buggy shows 1 after 3 adds; fixed shows 3 |
| 6 | Bug | Checkbox jumps to the wrong row after deleting | Stateful rows without keys matched by position | `ValueKey(item.id)`, never the index | Buggy moves the check from B to C |
| 7 | Bug | "Vertical viewport was given unbounded height" | `ListView` directly inside a `Column` | `Expanded` (or slivers); avoid `shrinkWrap` | Buggy reports the layout error; fixed renders |
| 8 | Perf | 2000-row leaderboard slow to open, high memory | `SingleChildScrollView` + `Column` builds every row | `ListView.builder` + `itemExtent` | 2000 builds vs < 30 |
| 9 | Perf | Selecting a user stutters | Page-level `setState` rebuilds every visible row | `BlocSelector` per row, `context.select` for the count | Many rows vs exactly 1 rebuilt per tap |
| 10 | Perf | App freezes when a big list loads | `jsonDecode` of ~5 MB on the UI isolate | `compute(parse, body)` with a top-level function | Background result equals the UI-thread result |

> Demo 10 shows the difference on a phone/emulator or desktop. On the **web**, `compute` runs on the main thread, so both versions freeze there.

## How to talk about it in the round
Name the **symptom → root cause → fix → how you'd prevent it**:
- **Prevent with lints:** `use_build_context_synchronously` (1), `cancel_subscriptions` and `close_sinks` (2), `prefer_const_constructors` (9). This repo enables them in `analysis_options.yaml`.
- **Prevent with tests:** `testWidgets` already fails on leaked timers (2); widget tests catch layout errors (7); rebuild counters make performance claims testable (8, 9).
- **Prove performance with DevTools:** Flutter Inspector → *Track widget rebuilds*; Performance view → frame chart (UI vs raster thread); `--profile` mode, never debug, for timing.

## Bonus quick ones (often asked as one-liners)
- **"Stream has already been listened to":** a single-subscription stream listened to twice (two `StreamBuilder`s). Use `StreamController.broadcast()` or `asBroadcastStream()`.
- **Double submit:** a button tapped twice sends two orders. Disable it while in flight, or use `droppable()` in Bloc; make the API idempotent with an idempotency key.
- **Error swallowed:** `catch (_) {}` around a sync call, so the button "silently does nothing". Surface an error state and log it.
- **`context` after `await`:** `Navigator.of(context)` after an async gap; check `context.mounted`.
- **Image OOM in grids:** `Image.network(cacheWidth: …)` to decode at display size; `cached_network_image` for disk caching.
- **Expensive work in `build`:** sorting or filtering inside `build`. Compute once in the state (see `UsersState.visible` on the `deloitte/*` branch).
- **Helper methods vs widgets:** `_buildHeader()` rebuilds with its parent; a `const _Header()` widget can be skipped.
- **Animations:** `AnimatedBuilder(child: …)` so the static subtree isn't rebuilt every frame; `RepaintBoundary` around something that repaints on its own.
- **Opacity:** animating `Opacity` with `setState` repaints the subtree every frame; use `FadeTransition` / `AnimatedOpacity`.

## Files
```
lib/challenges/
  challenge.dart, challenges.dart        registry (symptom, cause, fix, demos)
  challenges_page.dart                   list + detail with Buggy/Fixed toggle
  demos.dart                             helpers for the navigation-based demos (1, 2)
  c01_set_state_after_dispose/ … c10_json_on_ui_thread/   buggy.dart, fixed.dart (+ shared.dart)
test/challenges/cNN_*_test.dart          one test file per challenge (26 tests in total, incl. core)
```
