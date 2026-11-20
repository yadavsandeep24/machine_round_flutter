import '../error/app_exception.dart';

/// A pure-Dart result type. Repositories return it instead of throwing,
/// so callers handle failures with an exhaustive `switch`.
sealed class Result<T> {
  const Result();

  R fold<R>(R Function(T data) onSuccess, R Function(AppException error) onFailure) =>
      switch (this) {
        Success<T>(:final data) => onSuccess(data),
        Failure<T>(:final error) => onFailure(error),
      };

  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success<T>(:final data) => Success(transform(data)),
    Failure<T>(:final error) => Failure(error),
  };

  T? get dataOrNull => switch (this) {
    Success<T>(:final data) => data,
    Failure<T>() => null,
  };
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppException error;
}
