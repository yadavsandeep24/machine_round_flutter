import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';

import '../error/app_exception.dart';
import '../result/result.dart';

/// Runs [block] and converts every failure into a typed [AppException].
/// Use it in the data layer only.
Future<Result<T>> safeCall<T>(Future<T> Function() block) async {
  try {
    return Success(await block());
  } catch (error, stackTrace) {
    final mapped = mapError(error);
    developer.log('safeCall failed: $mapped', error: error, stackTrace: stackTrace);
    return Failure(mapped);
  }
}

AppException mapError(Object error) {
  if (error is AppException) return error;
  if (error is DioException) {
    // Interceptors may wrap an AppException (for example a failed refresh).
    final inner = error.error;
    if (inner is AppException) return inner;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return TimeoutAppException(error);
      case DioExceptionType.connectionError:
        return NoInternetException(error);
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        return switch (code) {
          401 || 403 => UnauthorizedException(error),
          404 => NotFoundException(error),
          _ => ServerException(code, error),
        };
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        if (inner is SocketException) return NoInternetException(error);
        return UnknownException(error);
    }
  }
  if (error is SocketException) return NoInternetException(error);
  if (error is FormatException || error is TypeError) return ParseException(error);
  return UnknownException(error);
}
