import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState(this.status, {this.expired = false});

  final AuthStatus status;

  /// The session ended on its own (refresh rejected), not by tapping Logout.
  final bool expired;

  @override
  List<Object?> get props => [status, expired];
}

/// App-wide session state. The router redirects on every change.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState(AuthStatus.unknown)) {
    _expiredSub = _repository.sessionExpired.listen(
      (_) => emit(const AuthState(AuthStatus.unauthenticated, expired: true)),
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<void> _expiredSub;

  /// Called once at launch: restores a saved session without a network call.
  void restore() => emit(
    AuthState(_repository.hasSession ? AuthStatus.authenticated : AuthStatus.unauthenticated),
  );

  void loggedIn() => emit(const AuthState(AuthStatus.authenticated));

  Future<void> logout() async {
    await _repository.logout();
    emit(const AuthState(AuthStatus.unauthenticated));
  }

  @override
  Future<void> close() async {
    await _expiredSub.cancel();
    return super.close();
  }
}
