# Machine Round Flutter: `01-minimal`

Core infrastructure with no features. Start a round from here when the interviewer lets you bring a skeleton.

```
lib/
  main.dart                 binding, BlocObserver, DI, runApp
  app.dart                  MaterialApp.router (router injectable for tests)
  ui/theme.dart             Material 3 light/dark
  core/
    error/app_exception.dart    sealed AppException + userMessage
    result/result.dart          sealed Result<T> (Success / Failure), fold, map
    network/dio_client.dart     Dio with timeouts and debug logging
    network/safe_call.dart      safeCall(): any error -> typed AppException
    storage/key_value_store.dart KeyValueStore (SharedPrefs + InMemory for tests)
    bloc/transformers.dart      debounceRestartable (debounce + switchMap), dropWhileBusy
    bloc/app_bloc_observer.dart logs bloc errors
    ui/view_status.dart         initial / loading / success / failure
    ui/widgets/state_views.dart LoadingView, ErrorView(retry), EmptyView, LoadMoreFooter
    di/injector.dart            get_it registrations
    router/app_router.dart      go_router shell
```

## Why these choices (be ready to defend them)

- **Sealed `AppException` + `Result<T>`:** repositories never throw. The UI does an exhaustive `switch`, and the compiler tells you when a new error type is not handled. Widgets never import Dio.
- **`safeCall` lives in the data layer.** Interceptor errors that carry an `AppException` (for example a failed token refresh) are unwrapped.
- **`KeyValueStore` interface:** tests use `InMemoryStore`; swapping SharedPreferences for Hive/drift touches one file.
- **Bloc event transformers:** `debounceRestartable` is `debounce` + `restartable()` (switchMap): a new query cancels the previous handler, so a slow old response can never overwrite a newer one.
- **get_it** over Provider for DI: no `BuildContext` needed in repositories, trivial to override in tests (`sl.reset()`).

Next: `git checkout 02-posts-list`.
