# Machine Round Flutter: `feature/pagination-manual`

> Diff against the previous step: `git diff feature/post-detail..feature/pagination-manual`

## This step: hand-written load-more

- **Trigger:** a `NotificationListener<ScrollNotification>` sends `PostsNextPageRequested` when fewer than 400 px remain (`extentAfter`). No `ScrollController` to dispose, and the widget stays stateless.
- **Guards in the bloc:** `droppable()` (one load at a time), plus no load while refreshing, after the end, before the first page succeeded, or after an error until the user taps Retry (no retry loop while scrolling).
- **Footer:** `LoadMoreFooter` shows a spinner or the error with Retry; it disappears at the end.
- **End of data:** a page shorter than the page size. Swap for `hasMore` / `total` / `nextCursor` when the API gives one.
- **Refresh vs in-flight load-more race:** the repository bumps a `_generation` on refresh. A page that started under an older generation comes back as `PageResult(stale: true)` and is not appended onto the new page 1 (tested with a `Completer`).
- **Dedupe by id** when appending, because offset paging can shift items between pages.
- Tests: 4 bloc pagination tests, 3 repository tests with a mocktail `PostApi` and a real `PostLocalSource` on `InMemoryStore`. 25 total.

> Interviewer says "use a package"? `infinite_scroll_pagination` gives a `PagingController`; explain that it replaces the trigger and footer, while the repository stays the same.

---

## Earlier step: `feature/post-detail`

## This step: detail screen (Cubit) and path-param routing

- **Route** `/posts/:id` nested under `/` in go_router, so the back button works and deep links open straight to a post. The id goes through `int.tryParse`, never `int.parse`.
- **Cubit, not Bloc,** for a simple screen: method calls (`load()`) instead of events. Contrast with `PostsBloc` when asked "Bloc vs Cubit?".
- **Sealed state** (`Loading` / `Loaded` / `Error`) with an exhaustive `switch` in the widget.
- **Cache first, network fallback** in `PostRepositoryImpl.getPost`, for posts that were never cached (deep links, search results).
- **Parallel requests:** post and comments load together with Dart 3 record `.wait`. A comments failure shows inline and does not fail the screen.
- **`isClosed` check** after `await`: the user may have popped the screen; emitting on a closed cubit throws.
- **`registerFactoryParam`** passes the id into the cubit through get_it.
- Tests: 4 more for the cubit (cached, network fallback, not found, comments failure). 18 total.

---

## From `02-posts-list`

A basic feature on top of `01-minimal`: fetch posts from `jsonplaceholder.typicode.com`, cache them locally (offline-first), and show loading, error with retry, empty and success states with pull-to-refresh. State management is **Bloc**.

```
features/posts/
  domain/   Post (Equatable, fromJson/toJson), PostRepository (interface)
  data/     PostApi (Dio), PostLocalSource (observable JSON cache), PostRepositoryImpl
  presentation/list/  PostsBloc (+ event/state parts), PostsPage (route) + PostsView (stateless, testable)
  posts_module.dart   get_it registrations
```

## Data flow

```
PostsStarted ─► add(PostsRefreshed)
            └─► emit.forEach(repo.watchPosts())   // UI only observes the cache
PostsRefreshed ─► repo.refresh() ─► api.getPosts() ─► local.replaceAll() ─► cache stream emits
```

- **Offline-first:** cached posts render immediately. A network error then shows a snackbar over the cached list instead of wiping it. With an empty cache, it shows the full-screen error with Retry.
- **`droppable()` on refresh:** spamming pull-to-refresh sends one request (tested).
- **`emit.forEach`** keeps the cache subscription tied to the bloc's lifetime: no manual `StreamSubscription` to cancel.
- **`RefreshIndicator`** awaits `bloc.stream.firstWhere((s) => !s.isRefreshing)` so the spinner stops at the right moment. The empty state is inside a scrollable so pull-to-refresh still works.
- **Page vs View split:** `PostsPage` creates the bloc from get_it; `PostsView` only reads it, so widget tests pump it with a bloc built on `FakePostRepository`.

## Tests (14)
`safeCall` mapping (5), `PostsBloc` (5: success, empty-cache failure, cached-data failure, retry, dropped duplicate refresh), `PostsView` widget tests (3: data, error + retry, empty), app shell (1).

## Branch ladder
Each next branch builds on the previous one, so `git diff <prev>..<next>` shows exactly one feature:
`02-posts-list` → `feature/post-detail` → `feature/pagination-manual` → `feature/search-debounce` → `main`.
