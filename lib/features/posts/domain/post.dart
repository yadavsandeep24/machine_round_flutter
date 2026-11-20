import 'package:equatable/equatable.dart';

class Post extends Equatable {
  const Post({required this.id, required this.userId, required this.title, required this.body});

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'] as int,
    userId: json['userId'] as int,
    title: json['title'] as String,
    body: json['body'] as String,
  );

  final int id;
  final int userId;
  final String title;
  final String body;

  Map<String, dynamic> toJson() => {'id': id, 'userId': userId, 'title': title, 'body': body};

  @override
  List<Object?> get props => [id, userId, title, body];
}
