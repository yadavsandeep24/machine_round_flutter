import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/error/app_exception.dart';
import 'package:machine_round/core/ui/view_status.dart';
import 'package:machine_round/features/users/presentation/users_cubit.dart';

import 'fake_user_repository.dart';

void main() {
  late FakeUserRepository repo;
  setUp(() => repo = FakeUserRepository());

  blocTest<UsersCubit, UsersState>(
    'emits loading then success',
    build: () => UsersCubit(repo),
    act: (c) => c.load(),
    expect: () => [
      isA<UsersState>().having((s) => s.status, 'status', ViewStatus.loading),
      isA<UsersState>()
          .having((s) => s.status, 'status', ViewStatus.success)
          .having((s) => s.users, 'users', hasLength(30)),
    ],
  );

  blocTest<UsersCubit, UsersState>(
    'emits failure with a typed error',
    setUp: () => repo.failWith = const NoInternetException(),
    build: () => UsersCubit(repo),
    act: (c) => c.load(),
    verify: (c) {
      expect(c.state.status, ViewStatus.failure);
      expect(c.state.error, isA<NoInternetException>());
    },
  );

  blocTest<UsersCubit, UsersState>(
    'search filters locally by name or email, case-insensitive',
    setUp: () => repo.users = [
      fakeUser(1, first: 'Emily'),
      fakeUser(2, first: 'Michael'),
      fakeUser(3, first: 'Emma'),
    ],
    build: () => UsersCubit(repo),
    act: (c) async {
      await c.load();
      c.search('  EM ');
    },
    verify: (c) => expect(c.state.visible.map((u) => u.id), [1, 3]),
  );

  blocTest<UsersCubit, UsersState>(
    'double Retry while loading makes one request',
    build: () => UsersCubit(repo),
    act: (c) async => Future.wait([c.load(), c.load()]),
    verify: (_) => expect(repo.calls, 1),
  );

  blocTest<UsersCubit, UsersState>(
    'toggleLike adds and removes',
    build: () => UsersCubit(repo),
    act: (c) => c
      ..toggleLike(1)
      ..toggleLike(2)
      ..toggleLike(1),
    verify: (c) => expect(c.state.likedIds, {2}),
  );
}
