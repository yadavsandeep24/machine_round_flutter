/// Every failure the UI can see. Repositories map raw errors (Dio, parsing)
/// into one of these so widgets never import Dio.
sealed class AppException implements Exception {
  const AppException([this.cause]);

  final Object? cause;

  /// A short, user-facing message. Keep technical details in [cause].
  String get userMessage;

  @override
  String toString() => '$runtimeType: $userMessage (cause: $cause)';
}

class NoInternetException extends AppException {
  const NoInternetException([super.cause]);

  @override
  String get userMessage => 'No internet connection. Check your network and try again.';
}

class TimeoutAppException extends AppException {
  const TimeoutAppException([super.cause]);

  @override
  String get userMessage => 'The request timed out. Please try again.';
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.cause]);

  @override
  String get userMessage => 'Your session has expired. Please sign in again.';
}

class NotFoundException extends AppException {
  const NotFoundException([super.cause]);

  @override
  String get userMessage => 'We could not find what you were looking for.';
}

class ServerException extends AppException {
  const ServerException(this.statusCode, [super.cause]);

  final int? statusCode;

  @override
  String get userMessage => 'Something went wrong on our side ($statusCode). Please try again.';
}

class ParseException extends AppException {
  const ParseException([super.cause]);

  @override
  String get userMessage => 'We received unexpected data. Please try again later.';
}

class UnknownException extends AppException {
  const UnknownException([super.cause]);

  @override
  String get userMessage => 'Something went wrong. Please try again.';
}
