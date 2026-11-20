# Machine Round Flutter

A starter project for **Flutter machine coding rounds**: Dart 3, Bloc/Cubit, Clean Architecture, Dio, get_it, go_router, offline-first caching, manual pagination, debounced search, and tests. It is the Flutter counterpart of the Android `MachineCodingStarter`.

The sample feature fetches posts from `jsonplaceholder.typicode.com`, caches them locally, and supports pagination, debounced server-side search, pull-to-refresh, favorites shared across screens, loading/error/empty states, and a detail screen with comments.

## Branches

**Step ladder.** Each branch builds on the one before, so `git diff <prev>..<next>` shows exactly one feature:

| Branch | What it adds |
|---|---|
| `00-empty` | Blank app, all dependencies, Material 3 light/dark theme, strict lints. What many interviewers hand you. |
| `01-minimal` | Core with no features: sealed `AppException`, `Result<T>`, `safeCall`, Dio, `KeyValueStore`, Bloc transformers, shared state widgets, get_it, go_router |
| `02-posts-list` | Offline-first list with Bloc: cache stream, loading/error/empty, pull-to-refresh, dropped duplicate refreshes |
| `feature/post-detail` | Cubit detail screen, `/posts/:id`, cache-then-network fallback, parallel comments with record `.wait` |
| `feature/pagination-manual` | Load-more with a scroll trigger, footer states, end detection, refresh-vs-load-more race guard |
| `feature/search-debounce` | Debounced server-side search with `switchMap` cancellation, instant clear, distinct, retry |
| `main` | Everything above plus app-wide favorites (`FavoritesCubit` above the router, per-row `context.select`) |

**Company and practice problems** (each built from `01-minimal`; sources in [docs/INTERVIEW_RESEARCH.md](docs/INTERVIEW_RESEARCH.md)):

| Branch | Problem |
|---|---|
| `deloitte/users-states-rebuilds` | **Reported Deloitte Flutter round (Jan 2026):** a screen with loading/success/error, then optimise a list to cut rebuilds. Includes a test that proves liking a user rebuilds zero rows. |
| `ecommerce/product-list-cart` | Product grid with category/stock filters and sort, detail, and an app-wide persisted cart with stock caps and exact money (PhonePe / Nykaa-style "data synced across screens") |
| `practice/offline-first-todo` | Local-first todos with a persisted outbox: ordered, idempotent sync, coalescing, backoff, in-flight edit protection, demo offline/server-failure switches |
| `practice/login-persistent-session` | Login form, persisted session, go_router redirect on auth state, single-flight token refresh interceptor |
| `practice/bugs-and-optimisation` | **Top 10 fix-the-bug and optimisation questions** (setState after dispose, timer leak, controller/Future in build, mutated state, missing keys, unbounded ListView, non-lazy list, rebuild storm, JSON on the UI thread). Each has `buggy.dart`, `fixed.dart`, a Buggy/Fixed demo, and a test that proves both. |

```bash
git checkout 02-posts-list && git checkout -b my-attempt      # practise a step yourself
git diff 02-posts-list..feature/post-detail                    # then compare with the reference
```

Also read [docs/DART_FUNDAMENTALS.md](docs/DART_FUNDAMENTALS.md): the "predict the output" and widget-lifecycle questions that open most Flutter rounds.

## Architecture

```
presentation/               domain/                       data/
┌───────────────────┐   ┌─────────────────────────┐   ┌───────────────────────────┐
│ Page (DI, Provider)│   │ Post, Comment (Equatable)│   │ PostRepositoryImpl        │
│ View (stateless)   │   │ PostRepository (iface)   │◄──│  ├─ PostApi (Dio)         │
│   ▲ state │ event  │   │ PageResult               │   │  └─ PostLocalSource (cache│
│ Bloc / Cubit ──────────►                          │   │      stream)              │
└───────────────────┘   └─────────────────────────┘   └───────────────────────────┘
```

- **Dependency rule:** `presentation → domain ← data`. Domain has no Flutter, Dio or storage imports.
- **Offline-first:** the list only observes the cache stream (`emit.forEach`). The network only writes into the cache.
- **Errors:** repositories return `Result<T>`; `safeCall` maps Dio/parse errors to a sealed `AppException` with a `userMessage`. Widgets never import Dio.

## Bloc vs Cubit (both are in the project)

| | **Cubit**: `PostDetailCubit`, `FavoritesCubit` | **Bloc**: `PostsBloc` |
|---|---|---|
| UI → logic | Calls methods (`load()`, `toggle(id)`) | Adds events (`PostsRefreshed`, `PostsQueryChanged`) |
| Concurrency control | Manual (`isClosed`, request tokens) | Per-event transformers: `droppable()` for refresh/load-more, debounce + `switchMap` for search |
| State | Sealed classes (`Loading/Loaded/Error`) | One immutable state with `copyWith` |
| Use it when | Simple screens | Many interactions, or when debounce/cancel/drop matters |

## Pagination
- **Trigger:** `NotificationListener<ScrollNotification>` sends `PostsNextPageRequested` when `extentAfter < 400`.
- **Guards:** `droppable()` plus no load while refreshing, at the end, before page 1 succeeded, or after an error until Retry.
- **Race:** a refresh bumps a generation counter in the repository; a page that started earlier is returned as `stale` and not appended.
- **End:** a short page. Use `hasMore`/`total`/`nextCursor` if the API has one.

## Search
```
keystroke ─► TextField (own controller, never lags)
          ─► PostsQueryChanged ─► switchMap(wait 300 ms, 0 if blank/retry ─► handler)
                                   the next keystroke cancels the wait AND the running search
          handler: trim ─► skip if same query already succeeded ─► GET /posts?q=
```

## Things interviewers look for (already handled)
- Loading, error with Retry, empty and success states; cached data kept on network failure
- `const` widgets, keys in lists, `buildWhen` / `BlocSelector` / `context.select` for targeted rebuilds
- Page/View split: the Page creates the bloc from get_it; the View is pumped in tests with a fake
- `isClosed` / `mounted` checks after `await`; controllers and subscriptions disposed
- Deep-link-safe routes (`int.tryParse`), `extra` with a fetch fallback
- Tests: `bloc_test`, `mocktail`, in-memory fakes, widget tests

## SOLID, briefly
- **S:** `PostApi` (network), `PostLocalSource` (cache), `PostRepositoryImpl` (policy), one bloc per screen.
- **O:** new features are new folders plus a `register*Module()`; core untouched.
- **L:** `FakePostRepository` honours the same contract as `PostRepositoryImpl` (including the network fallback).
- **I:** small interfaces: `PostRepository`, `FavoritesRepository`, `KeyValueStore`.
- **D:** domain owns the interfaces; get_it binds implementations.

## Adapting it in the round (about 10 minutes)
1. Change `kBaseUrl` in `core/network/dio_client.dart` (or pass `baseUrl` to `buildDio`).
2. Copy `features/posts` to `features/<thing>`, rename, and update `fromJson` to the JSON.
3. Register it in a `register<Thing>Module()` called from `configureDependencies()`.
4. Add routes in `core/router/app_router.dart`.
5. No API? Back the repository with an in-memory list, as the test fakes do.

## Gotchas worth knowing (found while building this)
- In `testWidgets` (fake async), `await bloc.close()` on a bloc whose transformer uses `switchMap`/`asyncExpand` never completes. Let `BlocProvider(create:)` own the bloc, or use `tester.runAsync(bloc.close)`.
- `pumpAndSettle` does not flush a pending zero-length `Future.delayed` unless a frame is scheduled; avoid timers when the wait is zero.
- Emitting on a closed cubit throws; check `isClosed` after every `await`.

## Run

```bash
flutter pub get
flutter analyze
flutter test
flutter run            # Android/iOS, or: flutter run -d chrome
```
