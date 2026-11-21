sealed class AuthEvent {
  const AuthEvent();
}

class SignInRequested extends AuthEvent {
  const SignInRequested({required this.email, required this.password});

  final String email;
  final String password;
}

class RegisterBuyerRequested extends AuthEvent {
  const RegisterBuyerRequested({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.province = '',
    this.city = '',
    this.district = '',
    this.subdistrict = '',
    this.rtRw = '',
    this.postalCode = '',
    this.address = '',
  });

  final String name;
  final String email;
  final String phone;
  final String password;
  final String province;
  final String city;
  final String district;
  final String subdistrict;
  final String rtRw;
  final String postalCode;
  final String address;
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}
