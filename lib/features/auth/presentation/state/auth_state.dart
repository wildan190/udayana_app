import '../../domain/repositories/auth_repository.dart';

class AuthState {
  const AuthState({this.isLoading = false, this.session, this.error});

  final bool isLoading;
  final AuthSession? session;
  final String? error;
}
