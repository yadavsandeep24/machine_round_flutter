import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/result/result.dart';
import 'package:machine_round/features/transactions/data/txn_repository_impl.dart';
import 'package:machine_round/features/transactions/domain/txn.dart';
import 'package:machine_round/features/transactions/domain/txn_filter.dart';

/// Captures the outgoing request and answers with a canned response.
class _CapturingInterceptor extends Interceptor {
  RequestOptions? last;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    last = options;
    handler.resolve(
      Response<List<dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: [
          {
            'id': 't1',
            'merchant': 'Amazon',
            'amount_paise': 249900,
            'status': 'pending',
            'created_at': '2026-11-25T00:00:00Z',
          },
        ],
      ),
    );
  }
}

void main() {
  late _CapturingInterceptor interceptor;
  late TxnRepositoryImpl repository;

  setUp(() {
    interceptor = _CapturingInterceptor();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))..interceptors.add(interceptor);
    repository = TxnRepositoryImpl(dio);
  });

  test('sends only the filters that are set', () async {
    final result = await repository.search(const TxnFilter(query: 'amazon', status: TxnStatus.pending));

    expect(interceptor.last!.queryParameters, {'q': 'amazon', 'status': 'pending', 'limit': 20});
    expect(interceptor.last!.uri.toString(), 'https://api.example.com/transactions?q=amazon&status=pending&limit=20');
    expect(result.dataOrNull?.single.merchant, 'Amazon');
  });

  test('never sends "null" strings for missing filters', () async {
    await repository.search(const TxnFilter());

    expect(interceptor.last!.uri.query, 'limit=20');
    expect(interceptor.last!.uri.toString(), isNot(contains('null')));
  });

  test('maps errors to a typed failure', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) =>
              handler.reject(DioException(requestOptions: options, type: DioExceptionType.connectionError)),
        ),
      );

    final result = await TxnRepositoryImpl(dio).search(const TxnFilter());

    expect(result, isA<Failure<List<Txn>>>());
  });
}
