# Offline-first todo app with an outbox

Built from `01-minimal`. PrepFlutter's Machine Coding track lists **"Offline-first todo app" (Hard)**, and offline sync is the standard senior follow-up after any list screen ("what if the user is on a train?"). The same pattern covers attendance, cart mutations, form drafts and chat sends.

## What is built
- Add, toggle, swipe-to-delete. Every action is written locally first, so the UI is instant and works with no network.
- **Outbox** (persisted): each change queues an op. `SyncEngine` drains it in order when online.
- Per-row sync icon (synced / pending / failed), a banner with the pending count and **Sync now**.
- **Demo controls** in the app bar: an Online/Offline switch, and a fake-server menu (server down, fail next 2 requests, lose next response) so you can show retries live.

```
UI ─► TodosCubit ─► TodoRepository ─► TodoLocalStore (todos + outbox)  ◄── UI observes this
                                   └► SyncEngine.enqueue ─► drain while online:
                                         op = outbox.first ─► TodoRemote.upsert/delete
                                           ok        ─► drop op, mark synced
                                           transient ─► keep op, attempts++, backoff timer, STOP (keep order)
                                           4xx       ─► drop op, mark failed, continue
```

## Guarantees and how they are tested (10 engine tests)
| Guarantee | How |
|---|---|
| Offline changes stay local and sync on reconnect | Connectivity stream triggers `sync()` |
| Order per todo | FIFO; a failed op blocks the ones behind it instead of being skipped |
| No duplicates on retry | Client-generated ids + idempotent `PUT /todos/{id}` and `DELETE`. Tested with "server applied, response lost" |
| Fewer requests | 3 offline edits to one todo → **1** upsert (the upsert always sends the latest row) |
| Created + deleted offline → **0** requests | `serverKnown` flag |
| Edit during an in-flight request is not lost | The in-flight op is never coalesced; a new op is queued behind it |
| Transient vs permanent | 503 / network / timeout retry with backoff (2, 4, 8 … 60 s); 4xx marks the todo failed and moves on |
| Survives an app kill | Outbox persisted; the engine flushes on launch |
| Concurrent `sync()` calls | Share one drain (`_running ??=`) |

## Points to make in the round
- **Conflict resolution:** this version is last-write-wins by `updatedAt` from one device. For multiple devices: send the server `version`/ETag with each write, the server rejects stale writes with 409, and the client re-fetches and either merges per field or asks the user.
- **Real connectivity:** use `connectivity_plus` for the trigger, but never trust it: "has Wi-Fi" is not "can reach the API". Every failed request is treated as possibly offline.
- **Background sync:** `workmanager` (Android WorkManager / iOS BGTaskScheduler) to drain the outbox when the app is closed.
- **Storage:** with drift/sqflite, write the todo row and its outbox entry in one transaction.
- **Pull:** on launch, `GET /todos?since=<cursor>`, apply rows whose `updatedAt` is newer than the local one and that have no pending op.

## Tests (17)
Sync engine (10), widget test: add offline → banner → go online → synced icon (1), core (5), app shell (1).

> Widget-test note: real timers and `Future.delayed` do not advance inside `testWidgets`; the test drives the engine with `tester.runAsync(engine.sync)`.
