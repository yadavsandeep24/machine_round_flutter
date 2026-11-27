import 'package:equatable/equatable.dart';

enum TxnStatus { success, pending, failed }

class Txn extends Equatable {
  const Txn({
    required this.id,
    required this.merchant,
    required this.amountPaise,
    required this.status,
    required this.createdAt,
  });

  factory Txn.fromJson(Map<String, dynamic> json) => Txn(
    id: json['id'] as String,
    merchant: json['merchant'] as String,
    amountPaise: json['amount_paise'] as int,
    status: TxnStatus.values.byName(json['status'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  final String id;
  final String merchant;

  /// Money as integer minor units. Never use double for money.
  final int amountPaise;
  final TxnStatus status;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, merchant, amountPaise, status, createdAt];
}
