import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.age,
    required this.image,
    required this.company,
    required this.city,
  });

  /// Defensive parsing: nested objects may be missing in some payloads.
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    age: json['age'] as int? ?? 0,
    image: json['image'] as String? ?? '',
    company: (json['company'] as Map<String, dynamic>?)?['name'] as String? ?? '',
    city: ((json['address'] as Map<String, dynamic>?)?['city'] as String?) ?? '',
  );

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final int age;
  final String image;
  final String company;
  final String city;

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isEmpty ? '' : firstName[0]}${lastName.isEmpty ? '' : lastName[0]}';

  @override
  List<Object?> get props => [id, firstName, lastName, email, phone, age, image, company, city];
}
