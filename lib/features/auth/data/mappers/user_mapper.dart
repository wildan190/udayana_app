import '../../domain/entities/app_user.dart';
import '../models/user_model.dart';

class UserMapper {
  const UserMapper._();

  static AppUser toEntity(UserModel model) => AppUser(
    id: model.id,
    name: model.name,
    email: model.email,
    role: model.role,
    phone: model.phone,
    province: model.province,
    city: model.city,
    district: model.district,
    subdistrict: model.subdistrict,
    rtRw: model.rtRw,
    postalCode: model.postalCode,
    address: model.address,
  );
}
