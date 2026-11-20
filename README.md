# Login with a persistent session and token refresh

Built from `01-minimal`. API: dummyjson auth (`POST /auth/login`, `GET /auth/me`, `POST /auth/refresh`). Use the demo account published in the [dummyjson auth docs](https://dummyjson.com/docs/auth).

## Why this problem
PrepFlutter's Machine Coding track lists **"Login with persistent session"** and the bug-hunt **"Auth refresh that logs users out" (Hard)**; token refresh under concurrency is also the standard follow-up after any authenticated list screen.

## What is built
- **Login:** `Form` validation, show/hide password, autofill hints, loading button, double-submit guard, friendly message for bad credentials (dummyjson answers 400).
- **Persistent session:** `TokenStore` saves tokens; launch restores the session **without a network call** (splash → home or login).
- **Routing by state:** go_router `redirect` + `refreshListenable` on `AuthCubit.stream`. Login, logout and an expired refresh token all route correctly with no `context.go` calls in screens. The rules are a pure function (`authRedirect`), unit-tested.
- **Protected screen:** Profile calls `GET /auth/me` with the bearer token; Logout clears the session.

## The interceptor (what they really probe)
`AuthInterceptor` on the authenticated Dio:
1. `onRequest` adds `Authorization: Bearer <access>`.
2. `onError` on **401**: if another request already refreshed (stored token ≠ the one sent), just retry. Otherwise refresh **once**.
3. **Single-flight:** a shared `Completer` means 5 parallel 401s make **1** refresh call; the other 4 await it and retry with the new token.
4. The retried request is marked (`extra['auth_retried']`) so a second 401 cannot loop.
5. **Only 400/401/403 from the refresh endpoint logs out.** A 5xx or network error keeps the session: the user may only be offline. (Logging users out on any refresh failure is exactly the "Auth refresh that logs users out" bug.)
6. The refresh call uses a **separate Dio without the interceptor**, so it can never recurse.

Alternative to mention: `QueuedInterceptor` serialises all interceptor callbacks, which also prevents parallel refreshes but blocks every request behind each one.

## Tests (17)
Interceptor with a fake `HttpClientAdapter` (4): bearer attached, 5 parallel 401s → 1 refresh, rejected refresh → session cleared + expired callback, 5xx refresh keeps the session. Auth flow (7): redirect rules (3), restore + logout, persistence across restart, bad-credential message, widget test (validation → sign in → redirected home). Core (5) and app shell (1).

## Production notes
- Store tokens with `flutter_secure_storage` (Keychain / Keystore), not SharedPreferences.
- Refresh proactively when the JWT `exp` is near, to avoid the 401 round trip.
- Clear user-scoped caches on logout.
- Biometric unlock: keep the refresh token behind `local_auth` and re-prompt after inactivity.
