import '../repositories/auth_repository.dart';

class RegisterBuyer {
  const RegisterBuyer(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call({
    required String name,
    required String email,
    required String phone,
    required String password,
    String province = '',
    String city = '',
    String district = '',
    String subdistrict = '',
    String rtRw = '',
    String postalCode = '',
    String address = '',
  }) => _repository.registerBuyer(
    name: name,
    email: email,
    phone: phone,
    password: password,
    province: province,
    city: city,
    district: district,
    subdistrict: subdistrict,
    rtRw: rtRw,
    postalCode: postalCode,
    address: address,
  );
}
