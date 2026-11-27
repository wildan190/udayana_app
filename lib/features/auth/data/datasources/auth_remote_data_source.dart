import '../../../../core/network/api_client.dart';

abstract interface class AuthRemoteDataSource {
  Future<Map<String, dynamic>> signIn(String email, String password);
  Future<Map<String, dynamic>> registerBuyer({
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
  Future<Map<String, dynamic>> updateBuyerAddress({
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
  Future<Map<String, dynamic>> verifyOtp({required int userId, required String otp});
  Future<Map<String, dynamic>> verifyBackupCode({required int userId, required String backupCode});
  Future<List<String>> toggle2fa({required bool enabled});
  Future<List<String>> getBackupCodes();
  Future<Map<String, dynamic>> getCart();
  Future<void> saveCart(Map<int, int> cart);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._api);

  final ApiClient _api;

  @override
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final response = await _api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> registerBuyer({
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
    final response = await _api.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'province': province,
        'city': city,
        'district': district,
        'subdistrict': subdistrict,
        'rt_rw': rtRw,
        'postal_code': postalCode,
        'address': address,
      },
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> updateBuyerAddress({
    required String province,
    required String city,
    required String district,
    required String subdistrict,
    required String rtRw,
    required String postalCode,
    required String address,
  }) async {
    final response = await _api.put(
      '/buyer/address',
      body: {
        'province': province,
        'city': city,
        'district': district,
        'subdistrict': subdistrict,
        'rt_rw': rtRw,
        'postal_code': postalCode,
        'address': address,
      },
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.put(
      '/buyer/password',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  @override
  Future<void> deleteAccount() async {
    await _api.delete('/buyer/account');
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({required int userId, required String otp}) async {
    final response = await _api.post(
      '/auth/verify-otp',
      body: {'user_id': userId, 'otp': otp},
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> verifyBackupCode({required int userId, required String backupCode}) async {
    final response = await _api.post(
      '/auth/verify-backup-code',
      body: {'user_id': userId, 'backup_code': backupCode},
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<List<String>> toggle2fa({required bool enabled}) async {
    final response = await _api.put('/buyer/2fa', body: {'enabled': enabled}) as Map<String, dynamic>;
    final list = response['backup_codes'] as List<dynamic>? ?? [];
    return list.map((e) => e.toString()).toList();
  }

  @override
  Future<List<String>> getBackupCodes() async {
    final response = await _api.get('/buyer/2fa/backup-codes') as Map<String, dynamic>;
    final list = response['backup_codes'] as List<dynamic>? ?? [];
    return list.map((e) => e.toString()).toList();
  }

  @override
  Future<Map<String, dynamic>> getCart() async {
    final response = await _api.get('/buyer/cart');
    return response as Map<String, dynamic>;
  }

  @override
  Future<void> saveCart(Map<int, int> cart) async {
    final items = [
      for (final entry in cart.entries)
        {'product_id': entry.key, 'quantity': entry.value}
    ];
    await _api.put('/buyer/cart', body: {'items': items});
  }
}
