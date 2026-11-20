import 'c01_set_state_after_dispose/buggy.dart';
import 'c01_set_state_after_dispose/fixed.dart';
import 'c02_timer_leak/buggy.dart';
import 'c02_timer_leak/fixed.dart';
import 'c03_controller_in_build/buggy.dart';
import 'c03_controller_in_build/fixed.dart';
import 'c04_future_in_build/buggy.dart';
import 'c04_future_in_build/fixed.dart';
import 'c05_mutated_state/buggy.dart';
import 'c05_mutated_state/fixed.dart';
import 'c06_missing_keys/buggy.dart';
import 'c06_missing_keys/fixed.dart';
import 'c07_unbounded_list/buggy.dart';
import 'c07_unbounded_list/fixed.dart';
import 'c08_non_lazy_list/buggy.dart';
import 'c08_non_lazy_list/fixed.dart';
import 'c09_rebuild_storm/buggy.dart';
import 'c09_rebuild_storm/fixed.dart';
import 'c10_json_on_ui_thread/buggy.dart';
import 'c10_json_on_ui_thread/fixed.dart';
import 'challenge.dart';
import 'demos.dart';

Future<String> _slowProfile() => Future.delayed(const Duration(milliseconds: 800), () => 'Ada');

final List<Challenge> challenges = [
  Challenge(
    number: 1,
    title: 'setState() called after dispose()',
    kind: ChallengeKind.bug,
    symptom: 'Profile screen throws after a quick back-tap.',
    reproduce: 'Open the profile and go back before the request finishes.',
    rootCause: 'The async request completes after the State was disposed and still calls setState.',
    fix:
        'Check `mounted` after every await (Cubit: check `isClosed` before emit). Enable the '
        '`use_build_context_synchronously` lint for the same bug with context.',
    buggy: (_) => LeaveEarlyDemo(screen: (load) => ProfileBuggy(load: load)),
    fixed: (_) => LeaveEarlyDemo(screen: (load) => ProfileFixed(load: load)),
  ),
  Challenge(
    number: 2,
    title: 'Timer keeps running after leaving',
    kind: ChallengeKind.bug,
    symptom: 'Counter keeps ticking after leaving the screen; battery drain.',
    reproduce: 'Open the timer screen, go back, watch the callback count.',
    rootCause: 'Timer.periodic is never cancelled, so it outlives the widget.',
    fix:
        'Store the Timer and cancel it in dispose(). Same for StreamSubscription, '
        'AnimationController, controllers, FocusNode and addListener calls.',
    buggy: (_) => LeakDemo(screen: (onTick) => CountdownBuggy(onTick: onTick)),
    fixed: (_) => LeakDemo(screen: (onTick) => CountdownFixed(onTick: onTick)),
  ),
  Challenge(
    number: 3,
    title: 'TextEditingController created in build()',
    kind: ChallengeKind.bug,
    symptom: 'Search input keeps clearing itself while typing.',
    reproduce: 'Type in the field.',
    rootCause:
        'Each setState rebuilds and creates a new, empty controller (and leaks the old one).',
    fix: 'Create the controller once in State, dispose it in dispose(). Keep build() pure.',
    buggy: (_) => const SearchBuggy(),
    fixed: (_) => const SearchFixed(),
  ),
  Challenge(
    number: 4,
    title: 'Future created inside build()',
    kind: ChallengeKind.bug,
    symptom: 'Screen flashes a spinner and refetches on every tap / keyboard open.',
    reproduce: 'Wait for the profile, then tap Like.',
    rootCause: 'FutureBuilder gets a new Future on every build, so it restarts the request.',
    fix: 'Create the Future once (initState / late final) and pass the same instance.',
    buggy: (_) => const ProfileFutureBuggy(fetch: _slowProfile),
    fixed: (_) => const ProfileFutureFixed(fetch: _slowProfile),
  ),
  Challenge(
    number: 5,
    title: 'Mutating state in place',
    kind: ChallengeKind.bug,
    symptom: 'Cart count does not refresh after tapping Add (only the first tap works).',
    reproduce: 'Tap Add three times.',
    rootCause:
        'The same List instance is mutated and re-emitted; Bloc drops an emit equal to the '
        'current state, so the UI never rebuilds.',
    fix:
        'Emit a new object: `emit([...state, item])` / copyWith. Use List.unmodifiable to catch '
        'accidental mutation.',
    buggy: (_) => const CartBuggy(),
    fixed: (_) => const CartFixed(),
  ),
  Challenge(
    number: 6,
    title: 'Missing keys in a dynamic list',
    kind: ChallengeKind.bug,
    symptom: 'Checked state jumps to the wrong row after deleting an item.',
    reproduce: 'Check Task B, then delete Task A.',
    rootCause:
        'Stateful rows without keys are matched by position, so State moves to the next item.',
    fix: 'Use ValueKey(item.id) (never the index), or keep the flag in the model.',
    buggy: (_) => const TasksBuggy(),
    fixed: (_) => const TasksFixed(),
  ),
  Challenge(
    number: 7,
    title: 'ListView inside a Column',
    kind: ChallengeKind.bug,
    symptom: 'Feed crashes with "Vertical viewport was given unbounded height".',
    reproduce: 'Just open it.',
    rootCause: 'Column offers infinite height; ListView tries to fill it.',
    fix: 'Wrap the list in Expanded (or use slivers). Avoid shrinkWrap for long lists.',
    buggy: (_) => const FeedBuggy(),
    fixed: (_) => const FeedFixed(),
  ),
  Challenge(
    number: 8,
    title: 'Building every row up front',
    kind: ChallengeKind.optimisation,
    symptom: 'Leaderboard with 2000 rows takes long to open and uses lots of memory.',
    reproduce: 'Open it; compare open time and scrolling.',
    rootCause: 'SingleChildScrollView + Column builds and lays out all rows eagerly.',
    fix: 'ListView.builder (lazy, recycled) with itemExtent or prototypeItem.',
    buggy: (_) => const LeaderboardBuggy(),
    fixed: (_) => const LeaderboardFixed(),
  ),
  Challenge(
    number: 9,
    title: 'One tap rebuilds the whole list',
    kind: ChallengeKind.optimisation,
    symptom: 'Selecting a user stutters on low-end phones.',
    reproduce: 'Tap users; in DevTools enable "Track widget rebuilds".',
    rootCause: 'Selection is page-level setState, so every visible row rebuilds per tap.',
    fix:
        'Per-row subscriptions: BlocSelector / context.select / ValueListenableBuilder, plus '
        'const widgets and small widget classes instead of helper methods.',
    buggy: (_) => const UsersSelectBuggy(),
    fixed: (_) => const UsersSelectFixed(),
  ),
  Challenge(
    number: 10,
    title: 'Heavy JSON parsing on the UI thread',
    kind: ChallengeKind.optimisation,
    symptom: 'App freezes for a moment when a big list loads.',
    reproduce: 'Tap Load and watch the spinner.',
    rootCause: 'jsonDecode + mapping 60k objects blocks the UI isolate far beyond the 16 ms frame.',
    fix: 'compute(parse, body) / Isolate.run with a top-level function; paginate the API too.',
    buggy: (_) => const CatalogBuggy(),
    fixed: (_) => const CatalogFixed(),
  ),
];
