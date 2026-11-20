import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/result/result.dart';
import '../data/auth_repository.dart';

class LoginState extends Equatable {
  const LoginState({this.submitting = false, this.error, this.success = false});

  final bool submitting;
  final String? error;
  final bool success;

  @override
  List<Object?> get props => [submitting, error, success];
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._repository) : super(const LoginState());

  final AuthRepository _repository;

  static String? validateUsername(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Enter your username' : null;

  static String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Enter your password';
    if (v.length < 6) return 'At least 6 characters';
    return null;
  }

  Future<void> submit(String username, String password) async {
    if (state.submitting) return; // double tap
    emit(const LoginState(submitting: true));
    final result = await _repository.login(username.trim(), password);
    if (isClosed) return;
    emit(switch (result) {
      Success() => const LoginState(success: true),
      // dummyjson answers 400 for bad credentials.
      Failure(error: ServerException(statusCode: 400) || UnauthorizedException()) =>
        const LoginState(error: 'Wrong username or password'),
      Failure(:final error) => LoginState(error: error.userMessage),
    });
  }
}
