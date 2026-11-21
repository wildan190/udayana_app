import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class UpdateBuyerAddress {
  const UpdateBuyerAddress(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String province,
    required String city,
    required String district,
    required String subdistrict,
    required String rtRw,
    required String postalCode,
    required String address,
  }) => _repository.updateBuyerAddress(
    province: province,
    city: city,
    district: district,
    subdistrict: subdistrict,
    rtRw: rtRw,
    postalCode: postalCode,
    address: address,
  );
}
