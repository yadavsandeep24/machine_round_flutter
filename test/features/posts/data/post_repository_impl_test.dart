import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/storage/key_value_store.dart';
import 'package:machine_round/features/posts/data/post_api.dart';
import 'package:machine_round/features/posts/data/post_local_source.dart';
import 'package:machine_round/features/posts/data/post_repository_impl.dart';
import 'package:machine_round/features/posts/domain/post.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_post_repository.dart';

class _MockApi extends Mock implements PostApi {}

List<Post> _range(int from, int count) => List.generate(count, (i) => fakePost(from + i));

void main() {
  late _MockApi api;
  late PostLocalSource local;
  late PostRepositoryImpl repo;

  setUp(() {
    api = _MockApi();
    local = PostLocalSource(InMemoryStore());
    repo = PostRepositoryImpl(api, local);
  });

  test('refresh replaces the cache, loadPage appends and dedupes', () async {
    when(() => api.getPosts(page: 1, limit: 20)).thenAnswer((_) async => _range(1, 20));
    when(() => api.getPosts(page: 2, limit: 20)).thenAnswer((_) async => _range(19, 5));

    await repo.refresh();
    final result = await repo.loadPage(2);

    expect(local.read().map((p) => p.id), List.generate(23, (i) => i + 1));
    expect(result.dataOrNull!.endReached, isTrue);
  });

  test('a page that finishes after a refresh is dropped as stale', () async {
    final slowPage = Completer<List<Post>>();
    when(() => api.getPosts(page: 1, limit: 20)).thenAnswer((_) async => _range(1, 20));
    when(() => api.getPosts(page: 2, limit: 20)).thenAnswer((_) => slowPage.future);

    await repo.refresh();
    final pending = repo.loadPage(2);
    await repo.refresh(); // user pulled to refresh meanwhile
    slowPage.complete(_range(21, 20));

    expect((await pending).dataOrNull!.stale, isTrue);
    expect(local.read(), hasLength(20));
  });

  test('getPost uses the cache, then the network', () async {
    when(() => api.getPosts(page: 1, limit: 20)).thenAnswer((_) async => _range(1, 20));
    when(() => api.getPost(99)).thenAnswer((_) async => fakePost(99));
    await repo.refresh();

    expect((await repo.getPost(5)).dataOrNull!.id, 5);
    verifyNever(() => api.getPost(5));
    expect((await repo.getPost(99)).dataOrNull!.id, 99);
  });
}
