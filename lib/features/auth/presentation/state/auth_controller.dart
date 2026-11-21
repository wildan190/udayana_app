import 'package:flutter/foundation.dart';

import '../../domain/usecases/register_buyer.dart';
import '../../domain/usecases/sign_in.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._signIn, this._registerBuyer, this._setToken);

  final SignIn _signIn;
  final RegisterBuyer _registerBuyer;
  final void Function(String?) _setToken;
  AuthState _state = const AuthState();

  AuthState get state => _state;

  Future<void> dispatch(AuthEvent event) async {
    switch (event) {
      case SignInRequested(:final email, :final password):
        _state = const AuthState(isLoading: true);
        notifyListeners();
        try {
          final session = await _signIn(email.trim(), password);
          _setToken(session.token);
          _state = AuthState(session: session);
        } on Exception catch (error) {
          _state = AuthState(error: error.toString());
        }
      case RegisterBuyerRequested(
        :final name,
        :final email,
        :final phone,
        :final password,
        :final province,
        :final city,
        :final district,
        :final subdistrict,
        :final rtRw,
        :final postalCode,
        :final address,
      ):
        _state = const AuthState(isLoading: true);
        notifyListeners();
        try {
          final session = await _registerBuyer(
            name: name.trim(),
            email: email.trim(),
            phone: phone.trim(),
            password: password,
            province: province.trim(),
            city: city.trim(),
            district: district.trim(),
            subdistrict: subdistrict.trim(),
            rtRw: rtRw.trim(),
            postalCode: postalCode.trim(),
            address: address.trim(),
          );
          _setToken(session.token);
          _state = AuthState(session: session);
        } on Exception catch (error) {
          _state = AuthState(error: error.toString());
        }
      case SignOutRequested():
        _setToken(null);
        _state = const AuthState();
    }
    notifyListeners();
  }
}
