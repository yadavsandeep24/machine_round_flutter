import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  const Comment({required this.id, required this.name, required this.email, required this.body});

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    body: json['body'] as String,
  );

  final int id;
  final String name;
  final String email;
  final String body;

  @override
  List<Object?> get props => [id, name, email, body];
}
