import '../../../core/result/result.dart';
import 'txn.dart';
import 'txn_filter.dart';

abstract interface class TxnRepository {
  Future<Result<List<Txn>>> search(TxnFilter filter);
}
