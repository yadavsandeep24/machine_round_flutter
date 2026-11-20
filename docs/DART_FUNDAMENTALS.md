# Dart and Flutter fundamentals for the first 15 minutes

Short answers to the questions that usually open a Flutter round (Deloitte round 1, CRED snippet round, PrepFlutter "Predict Output"). Run any snippet with `dart run`.

## Event loop: predict the order
```dart
void main() {
  print('1');
  Future(() => print('2'));                 // event queue
  scheduleMicrotask(() => print('3'));      // microtask queue
  Future.value().then((_) => print('4'));   // microtask (already-completed future)
  Future.delayed(Duration.zero, () => print('5')); // timer -> event queue
  print('6');
}
// 1 6 3 4 2 5
```
Rule: all synchronous code first, then **every** microtask, then one event, then microtasks again, and so on. A microtask that keeps scheduling microtasks starves the event queue and freezes the UI.

## `async` details
- A `throw` inside an `async` function before any `await` still becomes a **failed Future**, not a synchronous exception.
- `Future.wait` fails as soon as one future fails (the others keep running); use `eagerError: false` or wrap each with `.then/.catchError` to collect all results. Dart 3 records: `final (a, b) = await (f1, f2).wait;`
- An `async*` generator does nothing until someone listens.
- Spinning `while (!done) {}` waiting for a `Completer` never ends: the loop never yields to the event loop.
- `sleep()` (dart:io) blocks the isolate; already-scheduled timers fire late.

## Streams
- **Single-subscription** (default) vs **broadcast** (`StreamController.broadcast()` / `asBroadcastStream()`): listening twice to a single-subscription stream throws "Stream has already been listened to".
- A late subscriber to a broadcast stream does **not** get earlier events (use a BehaviorSubject-like replay, or `emit current then changes`, as `PostLocalSource.watch()` does with `async*`).
- `yield*` forwards every event and error of the inner stream; a try/catch around `yield*` catches inner errors.

## Values and equality
- `final` = assigned once (the object can still mutate: `final list = []; list.add(1)` is fine). `const` = compile-time constant and deeply immutable (`const [1].add(2)` throws). Identical `const` values are canonicalised: `identical(const [1], const [1])` is true.
- Default `==` is identity. Override `==` **and** `hashCode` together (or use `Equatable`/records); otherwise a `Set` keeps duplicates.
- Dart passes object references by value: reassigning a parameter does not affect the caller; mutating the object does. `int`s are immutable, so `x++` inside a function changes nothing outside.
- `a ?? b` reads; `a ??= b` assigns only when `a` is null (later `??=` calls do nothing).
- `late` read before assignment throws `LateInitializationError` at runtime.

## Widgets
- **StatelessWidget vs StatefulWidget:** both are immutable configuration; StatefulWidget owns a `State` object that survives rebuilds.
- **State lifecycle:** `createState → initState → didChangeDependencies → build → (didUpdateWidget / setState → build)* → deactivate → dispose`.
  - Start subscriptions/controllers in `initState`, dispose them in `dispose`.
  - Don't read `InheritedWidget`s in `initState`; use `didChangeDependencies`.
  - Never create a Future inside `build` for a `FutureBuilder` (it refetches on every rebuild).
  - After `await`, check `mounted` before `setState` or using `context`.
- **Keys:** needed when same-type siblings reorder or are filtered (`ValueKey(id)`), otherwise state sticks to the wrong item. `GlobalKey` for `Form` state; use sparingly.
- **Three trees:** Widget (config) → Element (lifecycle, identity) → RenderObject (layout/paint). Rebuilding widgets is cheap; layout and paint are what you protect.
- **Constraints go down, sizes go up, parent sets position.** Overflow errors usually mean an unbounded child (`ListView` in a `Column` → wrap in `Expanded`).
- **BuildContext** is the Element; `context.read` (no rebuild, use in callbacks), `context.watch` (rebuild on any change), `context.select` (rebuild when one value changes).

## Performance answers
`const` constructors, small widgets instead of `_buildX()` helpers, `ListView.builder` + `itemExtent`/`prototypeItem`, `buildWhen`/`BlocSelector`/`select`, `RepaintBoundary` for independently animating parts, `Image.network(cacheWidth:)` / `cached_network_image`, `Isolate.run`/`compute` for heavy JSON, and DevTools (rebuild tracker, performance overlay, frame chart) to prove it.

## State management (one-liners)
- **setState:** local, ephemeral UI state.
- **InheritedWidget/Provider:** dependency injection + rebuilds down the tree.
- **Bloc/Cubit:** streams of immutable states; testable; event transformers for concurrency.
- **Riverpod:** compile-safe providers without BuildContext; good for DI + async caching.
- **GetX:** fast to write, but global and hard to test; avoid defending it as architecture.
