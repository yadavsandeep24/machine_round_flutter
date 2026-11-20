import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/result/result.dart';
import '../../domain/comment.dart';
import '../../domain/post.dart';
import '../../domain/post_repository.dart';

/// Sealed state: the UI switches over it exhaustively.
sealed class PostDetailState extends Equatable {
  const PostDetailState();
  @override
  List<Object?> get props => [];
}

final class PostDetailLoading extends PostDetailState {
  const PostDetailLoading();
}

final class PostDetailError extends PostDetailState {
  const PostDetailError(this.error);
  final AppException error;
  @override
  List<Object?> get props => [error];
}

final class PostDetailLoaded extends PostDetailState {
  const PostDetailLoaded({required this.post, required this.comments, this.commentsError});
  final Post post;
  final List<Comment> comments;

  /// Comments are secondary: their failure does not fail the whole screen.
  final AppException? commentsError;

  @override
  List<Object?> get props => [post, comments, commentsError];
}

/// Cubit (method calls) for a simple screen, versus Bloc (events) for the
/// list. Same testability, less ceremony.
class PostDetailCubit extends Cubit<PostDetailState> {
  PostDetailCubit(this._repository, this.postId) : super(const PostDetailLoading());

  final PostRepository _repository;
  final int postId;

  Future<void> load() async {
    emit(const PostDetailLoading());
    // Run both requests in parallel (Dart 3 record `.wait`).
    final (postResult, commentsResult) = await (
      _repository.getPost(postId),
      _repository.getComments(postId),
    ).wait;
    if (isClosed) return; // user may have navigated back
    switch (postResult) {
      case Failure(:final error):
        emit(PostDetailError(error));
      case Success(data: final post):
        emit(
          PostDetailLoaded(
            post: post,
            comments: commentsResult.dataOrNull ?? const [],
            commentsError: commentsResult.fold((_) => null, (e) => e),
          ),
        );
    }
  }
}
