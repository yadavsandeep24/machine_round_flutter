import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/storage/key_value_store.dart';
import 'package:machine_round/features/favorites/favorites_cubit.dart';
import 'package:machine_round/features/favorites/favorites_repository.dart';

void main() {
  late KeyValueStore store;
  setUp(() => store = InMemoryStore());

  blocTest<FavoritesCubit, Set<int>>(
    'toggle adds then removes, and persists',
    build: () => FavoritesCubit(LocalFavoritesRepository(store)),
    act: (cubit) async {
      await cubit.toggle(3);
      await cubit.toggle(5);
      await cubit.toggle(3);
    },
    verify: (cubit) async {
      expect(cubit.state, {5});
      // A fresh repository on the same store sees the persisted ids.
      expect(await LocalFavoritesRepository(store).watch().first, {5});
    },
  );
}
