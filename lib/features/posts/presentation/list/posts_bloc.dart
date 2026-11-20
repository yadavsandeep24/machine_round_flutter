import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/result/result.dart';
import '../../../../core/ui/view_status.dart';
import '../../domain/post.dart';
import '../../domain/post_repository.dart';

part 'posts_event.dart';
part 'posts_state.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  PostsBloc(this._repository) : super(const PostsState()) {
    on<PostsStarted>(_onStarted, transformer: droppable());
    on<PostsRefreshed>(_onRefreshed, transformer: droppable());
  }

  final PostRepository _repository;

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
      ),
    );
    final result = await _repository.refresh();
    switch (result) {
      case Success():
        emit(state.copyWith(isRefreshing: false, status: ViewStatus.success));
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
}
