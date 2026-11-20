import 'package:equatable/equatable.dart';

class Session extends Equatable {
  const Session({required this.accessToken, required this.refreshToken});

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
  );

  final String accessToken;
  final String refreshToken;

  Map<String, dynamic> toJson() => {'accessToken': accessToken, 'refreshToken': refreshToken};

  @override
  List<Object?> get props => [accessToken, refreshToken];
}

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.image = '',
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as int,
    username: json['username'] as String? ?? '',
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    image: json['image'] as String? ?? '',
  );

  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String image;

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [id, username, firstName, lastName, email, image];
}
