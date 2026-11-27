import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../mappers/user_mapper.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<AuthSession> signIn(String email, String password) async {
    final response = await _remoteDataSource.signIn(email, password);
    return _sessionFrom(response);
  }

  @override
  Future<AuthSession> registerBuyer({
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
  }) async {
    final response = await _remoteDataSource.registerBuyer(
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
    return _sessionFrom(response);
  }

  @override
  Future<AppUser> updateBuyerAddress({
    required String province,
    required String city,
    required String district,
    required String subdistrict,
    required String rtRw,
    required String postalCode,
    required String address,
  }) async {
    final response = await _remoteDataSource.updateBuyerAddress(
      province: province,
      city: city,
      district: district,
      subdistrict: subdistrict,
      rtRw: rtRw,
      postalCode: postalCode,
      address: address,
    );
    final userModel = UserModel.fromJson(
      response['user'] as Map<String, dynamic>,
    );
    return UserMapper.toEntity(userModel);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _remoteDataSource.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  @override
  Future<void> deleteAccount() => _remoteDataSource.deleteAccount();

  @override
  Future<AuthSession> verifyOtp({required int userId, required String otp}) async {
    final response = await _remoteDataSource.verifyOtp(userId: userId, otp: otp);
    return _sessionFrom(response);
  }

  @override
  Future<AuthSession> verifyBackupCode({required int userId, required String backupCode}) async {
    final response = await _remoteDataSource.verifyBackupCode(userId: userId, backupCode: backupCode);
    return _sessionFrom(response);
  }

  @override
  Future<List<String>> toggle2fa({required bool enabled}) =>
      _remoteDataSource.toggle2fa(enabled: enabled);

  @override
  Future<List<String>> getBackupCodes() => _remoteDataSource.getBackupCodes();

  @override
  Future<Map<int, int>> getCart() async {
    final response = await _remoteDataSource.getCart();
    final list = response['items'] as List<dynamic>? ?? [];
    final cart = <int, int>{};
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      final pid = (map['product_id'] as num).toInt();
      final qty = (map['quantity'] as num).toInt();
      if (qty > 0) cart[pid] = qty;
    }
    return cart;
  }

  @override
  Future<void> saveCart(Map<int, int> cart) =>
      _remoteDataSource.saveCart(cart);

  AuthSession _sessionFrom(Map<String, dynamic> response) {
    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
    return AuthSession(
      user: UserMapper.toEntity(user),
      token: response['token'] as String,
    );
  }
}
