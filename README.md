# Latest feature: Null-aware collection elements (Flutter / Dart, Dart 3.8, 20 May 2025)

Branch: `latest/2026-11-27-null-aware-elements` (built on `01-minimal`).

> Why not something newer? This Mac has Flutter 3.32.5 / Dart 3.8.1. Features from the last 12 months need a newer Flutter SDK, and the SDK must not be upgraded by this job. Null-aware elements is the newest language feature this toolchain can build and test.

## What's new

Dart 3.8 adds **null-aware elements**. Inside a list, set or map literal, put `?` before an element and it is added only when its value is not null.

```dart
final list = [1, ?maybeNumber, 3];          // maybeNumber is skipped when null
final map  = {'q': ?query, ?key: 'value'};  // works for map values and map keys
```

Dart 3.8.1 also added the `use_null_aware_elements` lint, which points out `if (x != null) x` entries you can shorten.

Official sources:
- [What's new in Dart](https://dart.dev/resources/whats-new) (dart.dev; Dart 3.8 section, 20 May 2025)
- [Language evolution: Dart 3.8](https://dart.dev/resources/language/evolution) (dart.dev)
- [Dart & Flutter momentum at Google I/O 2025](https://flutter.dev/blog/dart-flutter-momentum-at-google-i-o-2025) (flutter.dev, 20 May 2025)
- [`use_null_aware_elements` lint](https://dart.dev/tools/linter-rules/use_null_aware_elements) (dart.dev, added in Dart 3.8.1)

## Why it matters

Two things in almost every app are "a collection built from optional values":

1. **API query parameters and JSON bodies.** A filter has many optional fields. You must not send `status=null` or an empty `q=`.
2. **Widget `children` lists.** Some children only exist in some states (an error banner, a filter chip, a badge).

Before Dart 3.8 each optional entry needed `if (x != null) x`. That repeats the expression, and for class fields it also needs `!`, because Dart does not promote public fields (a getter could return a different value the second time). Null-aware elements make each entry one short, safe line.

Use it when "absent" and "null" mean the same thing. Do not use it when the server must see an explicit `null` (for example a PATCH that clears a field). Then you need the key with a `null` value, and `?` would silently drop it.

## Before vs after

```dart
// Before (Dart < 3.8): repeat the condition, and force-unwrap fields with `!`
Map<String, Object> toQueryParametersLegacy() {
  final q = normalizedQuery;
  return {
    if (q != null) 'q': q,
    if (status != null) 'status': status!.name,
    if (minAmountPaise != null) 'min_amount': minAmountPaise!,
    if (since != null) 'since': since!.toUtc().toIso8601String(),
    'limit': limit,
  };
}

// After (Dart 3.8): `?expr` adds the entry only when expr is non-null
Map<String, Object> toQueryParameters() => {
  'q': ?normalizedQuery,
  'status': ?status?.name,
  'min_amount': ?minAmountPaise,
  'since': ?since?.toUtc().toIso8601String(),
  'limit': limit,
};

// In widgets: helpers return Widget?, and `?` drops the nulls
Wrap(children: [
  ?_chip('Status: ${filter.status?.name}', filter.status, () => cubit.setStatus(null)),
  ?_chip('Min Rs ...', filter.minAmountPaise, () => cubit.setMinAmount(null)),
]);
```

## How this branch uses it

The home route is a transaction history screen: search box, status and amount filter chips, a bar of removable "active filter" chips, and the results list.

- `lib/features/transactions/domain/txn_filter.dart`: `toQueryParameters()` (new) and `toQueryParametersLegacy()` (old), plus a `copyWith` that can reset a field to null.
- `lib/features/transactions/data/txn_repository_impl.dart`: Dio repository that sends `filter.toQueryParameters()`; missing filters never reach the URL.
- `lib/features/transactions/data/in_memory_txn_repository.dart`: demo data so the screen runs without a backend.
- `lib/features/transactions/presentation/txn_search_cubit.dart`: Cubit; a request id stops a slow, older search from overwriting a newer one.
- `lib/features/transactions/presentation/txn_search_page.dart`: the screen; `ActiveFiltersBar` builds its chips with `?` in a `children` list.
- `lib/features/transactions/transactions_module.dart`: get_it registrations.
- `analysis_options.yaml`: enables the `use_null_aware_elements` lint.
- `test/features/transactions/txn_filter_test.dart`: parameters, blank query, key order, and old-vs-new parity for several filters.
- `test/features/transactions/txn_repository_impl_test.dart`: captures the real Dio request and checks the URL has no `null` values.
- `test/features/transactions/txn_search_cubit_test.dart`: filter flow and the stale-response race.
- `test/features/transactions/txn_search_page_test.dart`: chips only appear for active filters; deleting a chip clears that filter.

## Interview talking points

- "Null-aware elements (`?expr`) came in Dart 3.8. I use them for query parameters and for optional children in widget lists."
- "The old `if (x != null) x` form repeats the expression and needs `!` for fields, because Dart only promotes local variables and private final fields. `?field` reads the field once, so it is also safer."
- "It works in lists, sets and maps, and in maps for both keys and values."
- "Absent is not the same as null. For a PATCH that clears a value I keep the explicit `null`, so I do not use `?` there."
- "I turned on the `use_null_aware_elements` lint so the team gets a hint to use the shorter form."
- "The filter is a value object (`Equatable`), so the Cubit can compare filters and tests can build expected requests easily."

Likely follow-ups:
- **What is the difference between `?x` and `...?list`?** `...?list` spreads a list that may be null. `?x` adds a single element that may be null.
- **Does it change performance?** No. It compiles to the same conditional add as the `if` form.
- **How do you migrate?** Raise the SDK lower bound to `^3.8.0`, enable `use_null_aware_elements`, and run `dart fix --apply` to rewrite the simple cases.

## Gotchas and compatibility

- Needs language version 3.8: `environment: sdk: ^3.8.0` or higher in `pubspec.yaml` (this repo already has `^3.8.1`). Flutter 3.32 ships Dart 3.8.
- The lint needs Dart 3.8.1+.
- The lint only fires when the checked value is promotable (a local variable). It does not flag `if (field != null) ... field!`, so review those by hand.
- A `?` element must be inside a collection literal. You cannot use it in normal argument lists.
- No dependency bumps in this branch.

## Run it

```bash
git checkout latest/2026-11-27-null-aware-elements
flutter pub get
flutter analyze
flutter test
flutter run
```
