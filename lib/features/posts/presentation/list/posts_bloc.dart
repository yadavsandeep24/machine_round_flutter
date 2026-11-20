import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/result/result.dart';
import '../../../../core/ui/view_status.dart';
import '../../domain/page_result.dart';
import '../../domain/post.dart';
import '../../domain/post_repository.dart';

part 'posts_event.dart';
part 'posts_state.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  PostsBloc(this._repository, {this.debounce = const Duration(milliseconds: 300)})
    : super(const PostsState()) {
    on<PostsStarted>(_onStarted, transformer: droppable());
    on<PostsRefreshed>(_onRefreshed, transformer: droppable());
    on<PostsNextPageRequested>(_onNextPage, transformer: droppable());
    on<PostsQueryChanged>(_onQueryChanged, transformer: _debounceUnlessBlank());
  }

  final PostRepository _repository;
  final Duration debounce;

  /// debounce + switchMap in one: each event waits [debounce] (a blank query
  /// or a retry waits 0), and `switchMap` cancels both the pending wait and
  /// any running search when the next keystroke arrives. A slow response for
  /// "fl" can never overwrite the results for "flutter".
  EventTransformer<PostsQueryChanged> _debounceUnlessBlank() =>
      (events, mapper) => events.switchMap((event) {
        final wait = event.query.trim().isEmpty || event.force ? Duration.zero : debounce;
        if (wait == Duration.zero) return mapper(event);
        return Stream<void>.fromFuture(
          Future<void>.delayed(wait),
        ).asyncExpand((_) => mapper(event));
      });

  Future<void> _onQueryChanged(PostsQueryChanged event, Emitter<PostsState> emit) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      // Clearing is instant and drops back to the cached browse list.
      emit(
        state.copyWith(
          query: '',
          searchStatus: ViewStatus.initial,
          searchResults: const [],
          searchError: () => null,
        ),
      );
      return;
    }
    // distinctUntilChanged: "flutter" -> "flutte" -> "flutter" sends no request.
    if (!event.force && query == state.query && state.searchStatus.isSuccess) return;

    emit(state.copyWith(query: query, searchStatus: ViewStatus.loading, searchError: () => null));
    final result = await _repository.search(query);
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(searchStatus: ViewStatus.success, searchResults: data));
      case Failure(:final error):
        emit(state.copyWith(searchStatus: ViewStatus.failure, searchError: () => error));
    }
  }

  Future<void> _onStarted(PostsStarted event, Emitter<PostsState> emit) async {
    add(const PostsRefreshed());
    // Lives as long as the bloc: every cache write re-renders the list.
    await emit.forEach<List<Post>>(
      _repository.watchPosts(),
      onData: (posts) => state.copyWith(
        posts: posts,
        // Cached data is shown right away, even while the network loads.
        status: posts.isNotEmpty ? ViewStatus.success : state.status,
      ),
    );
  }

  Future<void> _onRefreshed(PostsRefreshed event, Emitter<PostsState> emit) async {
    emit(
      state.copyWith(
        isRefreshing: true,
        status: state.posts.isEmpty ? ViewStatus.loading : state.status,
        error: () => null,
        loadMoreError: () => null,
      ),
    );
    final result = await _repository.refresh();
    switch (result) {
      case Success(data: PageResult(stale: true)):
        emit(state.copyWith(isRefreshing: false));
      case Success(:final data):
        emit(
          state.copyWith(
            isRefreshing: false,
            status: ViewStatus.success,
            nextPage: 2,
            hasReachedEnd: data.endReached,
          ),
        );
      case Failure(:final error):
        emit(
          state.copyWith(
            isRefreshing: false,
            status: state.posts.isEmpty ? ViewStatus.failure : ViewStatus.success,
            error: () => error,
          ),
        );
    }
  }

  Future<void> _onNextPage(PostsNextPageRequested event, Emitter<PostsState> emit) async {
    final blocked =
        state.hasReachedEnd ||
        state.isRefreshing ||
        state.status != ViewStatus.success ||
        (state.loadMoreError != null && !event.isRetry);
    if (blocked) return;

    emit(state.copyWith(isLoadingMore: true, loadMoreError: () => null));
    final result = await _repository.loadPage(state.nextPage);
    switch (result) {
      case Success(data: PageResult(stale: true)):
        emit(state.copyWith(isLoadingMore: false));
      case Success(:final data):
        emit(
          state.copyWith(
            isLoadingMore: false,
            nextPage: state.nextPage + 1,
            hasReachedEnd: data.endReached,
          ),
        );
      case Failure(:final error):
        emit(state.copyWith(isLoadingMore: false, loadMoreError: () => error));
    }
  }
}
