# Deloitte: users list with states and rebuild optimisation

Built from `01-minimal`. API: `https://dummyjson.com/users` (list) and `/users/{id}` (detail).

## What was reported
A January 2026 candidate write-up of a **Deloitte Flutter interview** (Medium, single first-hand account, not confirmed by Deloitte) describes three rounds:
1. **Fundamentals:** StatelessWidget vs StatefulWidget, widget lifecycle, Future vs Stream.
2. **Live coding + architecture:** build a screen with **loading, success and error** handling, then **optimise a list to cut unnecessary rebuilds**, and explain the choices.
3. **Project deep-dive and behavioural.**

A Deloitte Flutter job listing (Pune) also asks for unit, widget and integration tests. A Techwondoe report (Naukri, Dec 2025) asked the classic variant: fetch users, list them, open a detail on tap. This branch covers both.

## What is built (aim for 45–60 minutes)
- `UsersCubit`: loading / success / failure / empty, Retry (double taps ignored), pull-to-refresh, local search by name or email, like toggle.
- `UsersView`: `switch` over `ViewStatus` with a `when` guard for the empty case.
- `UserDetailPage`: user passed through go_router `extra` for an instant open, with a fetch-by-id fallback for deep links or web refresh (where `extra` is lost). `FutureBuilder` with the future created in `initState`, never in `build`.

## Rebuild optimisations (the part they probe)
| Technique | Where | Why |
|---|---|---|
| `buildWhen` on the body `BlocBuilder` | `UsersView` | Liking a user does not rebuild the list at all |
| `BlocSelector<…, bool>` per row | `LikeButton` | Only the tapped heart rebuilds |
| `context.select` for one number | `_Title` | The app bar title rebuilds only when the liked count changes |
| `const` constructors everywhere possible | all widgets | Const subtrees are skipped during rebuilds |
| `ListView.builder` + `itemExtent` | list | Lazy children; fixed extent skips measuring each row (or `prototypeItem`) |
| `ValueKey(user.id)` | rows | State stays with the right user while filtering |
| Filter computed once in the state constructor | `UsersState.visible` | No filtering work inside `build` |
| Small widgets instead of helper methods | `_Title`, `_SearchBox`, `LikeButton` | Each one is its own rebuild boundary; a `_buildX()` method is not |

**Proof:** `users_page_test.dart` counts `UserRow` builds (`UserRow.debugBuilds`, debug-only) and asserts that liking a user rebuilds **zero** rows. Show this in the interview: it turns "I optimised it" into evidence. In DevTools, the same check is *Track widget rebuilds* in the Flutter Inspector / Performance view.

Other answers to have ready: `RepaintBoundary` for expensive painting that changes independently, `AutomaticKeepAliveClientMixin` for tab state, `cached_network_image` for list thumbnails, `compute()`/`Isolate.run` to parse a large JSON off the UI thread.

## Round 1 quick answers
- **Stateless vs Stateful:** Stateless depends only on constructor args and inherited widgets. Stateful owns a `State` object that survives rebuilds; the widget is recreated, the State is not.
- **State lifecycle:** `createState` → `initState` (once; start controllers/subscriptions) → `didChangeDependencies` (inherited widgets changed) → `build` (many times, keep pure) → `didUpdateWidget` (parent rebuilt with new config) → `deactivate` → `dispose` (cancel/dispose everything). Check `mounted` after an `await` before using `context` or `setState`.
- **Future vs Stream:** one value (or error) later vs many values over time. `FutureBuilder`/`StreamBuilder`; single-subscription vs broadcast streams; `async*`/`yield`.

## Tests (15)
Cubit (5): success, typed failure, local search, single request on double Retry, like toggle. Widget (4): loading → success, error → retry, zero row rebuilds on like, search empty state. Core `safeCall` (5) and app shell (1).
