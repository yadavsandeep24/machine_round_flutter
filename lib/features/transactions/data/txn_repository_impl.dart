import 'package:dio/dio.dart';

import '../../../core/network/safe_call.dart';
import '../../../core/result/result.dart';
import '../domain/txn.dart';
import '../domain/txn_filter.dart';
import '../domain/txn_repository.dart';

/// Real API version: the filter becomes query parameters, and null filters
/// are simply absent from the URL (no `?status=null`).
class TxnRepositoryImpl implements TxnRepository {
  TxnRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<Txn>>> search(TxnFilter filter) => safeCall(() async {
    final response = await _dio.get<List<dynamic>>('/transactions', queryParameters: filter.toQueryParameters());
    return (response.data ?? const []).cast<Map<String, dynamic>>().map(Txn.fromJson).toList(growable: false);
  });
}
