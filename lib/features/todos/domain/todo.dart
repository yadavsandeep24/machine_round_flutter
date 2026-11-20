import 'package:equatable/equatable.dart';

enum SyncStatus { pending, synced, failed }

class Todo extends Equatable {
  const Todo({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.done = false,
    this.syncStatus = SyncStatus.pending,
    this.serverKnown = false,
  });

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id'] as String,
    title: json['title'] as String,
    done: json['done'] as bool? ?? false,
    updatedAt: json['updatedAt'] as int,
    syncStatus: SyncStatus.values.byName(json['syncStatus'] as String? ?? 'pending'),
    serverKnown: json['serverKnown'] as bool? ?? false,
  );

  /// Generated on the device, so a todo created offline has a stable id and
  /// replaying its create is idempotent on the server (upsert by id).
  final String id;
  final String title;
  final bool done;

  /// Last local edit (ms since epoch). Used for last-write-wins on pull.
  final int updatedAt;
  final SyncStatus syncStatus;

  /// The server has seen this todo at least once. A todo created and deleted
  /// while offline never needs to reach the server.
  final bool serverKnown;

  Todo copyWith({
    String? title,
    bool? done,
    int? updatedAt,
    SyncStatus? syncStatus,
    bool? serverKnown,
  }) => Todo(
    id: id,
    title: title ?? this.title,
    done: done ?? this.done,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    serverKnown: serverKnown ?? this.serverKnown,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'done': done,
    'updatedAt': updatedAt,
    'syncStatus': syncStatus.name,
    'serverKnown': serverKnown,
  };

  /// What the server stores (no local-only fields).
  Map<String, dynamic> toRemoteJson() => {
    'id': id,
    'title': title,
    'done': done,
    'updatedAt': updatedAt,
  };

  @override
  List<Object?> get props => [id, title, done, updatedAt, syncStatus, serverKnown];
}
