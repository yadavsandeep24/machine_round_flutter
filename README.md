# Machine Round Flutter: `00-empty`

A blank Flutter app with every dependency already added, Material 3 theme (light and dark), and strict lints. This is what many interviewers hand you.

| Package | Why |
|---|---|
| `flutter_bloc`, `bloc_concurrency`, `stream_transform` | State management (Bloc and Cubit), event transformers for debounce and cancellation |
| `equatable` | Value equality for states and models |
| `dio` | HTTP, interceptors, cancel tokens |
| `get_it` | Service locator (DI) |
| `go_router` | Declarative routing with path params and redirects |
| `shared_preferences` | Simple local cache and token storage |
| `bloc_test`, `mocktail` | Bloc tests and mocks |

```bash
flutter pub get
flutter analyze
flutter test
```

Next step: `git checkout 01-minimal`.
