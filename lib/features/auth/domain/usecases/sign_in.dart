import '../repositories/auth_repository.dart';

class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call(String email, String password) =>
      _repository.signIn(email, password);
}
