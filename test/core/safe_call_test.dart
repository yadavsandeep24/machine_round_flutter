import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/error/app_exception.dart';
import 'package:machine_round/core/network/safe_call.dart';
import 'package:machine_round/core/result/result.dart';

DioException _bad(int code) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.badResponse,
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: code,
  ),
);

void main() {
  test('success is wrapped', () async {
    final result = await safeCall(() async => 42);
    expect(result.dataOrNull, 42);
  });

  test('maps HTTP codes to typed exceptions', () {
    expect(mapError(_bad(401)), isA<UnauthorizedException>());
    expect(mapError(_bad(404)), isA<NotFoundException>());
    expect(mapError(_bad(500)), isA<ServerException>());
  });

  test('maps timeouts and connection errors', () {
    final req = RequestOptions(path: '/x');
    expect(
      mapError(DioException(requestOptions: req, type: DioExceptionType.receiveTimeout)),
      isA<TimeoutAppException>(),
    );
    expect(
      mapError(DioException(requestOptions: req, type: DioExceptionType.connectionError)),
      isA<NoInternetException>(),
    );
  });

  test('parse errors become ParseException', () async {
    final result = await safeCall<int>(() async => throw const FormatException('bad'));
    expect(result, isA<Failure<int>>());
    expect((result as Failure<int>).error, isA<ParseException>());
  });

  test('unwraps an AppException carried inside a DioException', () {
    final wrapped = DioException(
      requestOptions: RequestOptions(path: '/x'),
      error: const UnauthorizedException(),
    );
    expect(mapError(wrapped), isA<UnauthorizedException>());
  });
}
