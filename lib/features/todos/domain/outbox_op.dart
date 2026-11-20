import 'package:equatable/equatable.dart';

enum OpType { upsert, delete }

/// One pending change waiting to reach the server. Persisted, so it survives
/// an app kill.
class OutboxOp extends Equatable {
  const OutboxOp({required this.opId, required this.todoId, required this.type, this.attempts = 0});

  factory OutboxOp.fromJson(Map<String, dynamic> json) => OutboxOp(
    opId: json['opId'] as String,
    todoId: json['todoId'] as String,
    type: OpType.values.byName(json['type'] as String),
    attempts: json['attempts'] as int? ?? 0,
  );

  final String opId;
  final String todoId;
  final OpType type;
  final int attempts;

  OutboxOp retried() => OutboxOp(opId: opId, todoId: todoId, type: type, attempts: attempts + 1);

  Map<String, dynamic> toJson() => {
    'opId': opId,
    'todoId': todoId,
    'type': type.name,
    'attempts': attempts,
  };

  @override
  List<Object?> get props => [opId, todoId, type, attempts];
}
