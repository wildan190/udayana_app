import '../entities/app_user.dart';

class AuthSession {
  const AuthSession({required this.user, required this.token});

  final AppUser user;
  final String token;
}

abstract interface class AuthRepository {
  Future<AuthSession> signIn(String email, String password);
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
  });
  Future<AppUser> updateBuyerAddress({
    required String province,
    required String city,
    required String district,
    required String subdistrict,
    required String rtRw,
    required String postalCode,
    required String address,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> deleteAccount();
  Future<AuthSession> verifyOtp({required int userId, required String otp});
  Future<AuthSession> verifyBackupCode({required int userId, required String backupCode});
  Future<List<String>> toggle2fa({required bool enabled});
  Future<List<String>> getBackupCodes();
  Future<Map<int, int>> getCart();
  Future<void> saveCart(Map<int, int> cart);
}
