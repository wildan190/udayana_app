import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/entities/app_user.dart';

class SessionStorage {
  const SessionStorage._();

  static const _kToken = 'udayana_token';
  static const _kId = 'udayana_user_id';
  static const _kName = 'udayana_user_name';
  static const _kEmail = 'udayana_user_email';
  static const _kRole = 'udayana_user_role';
  static const _kPhone = 'udayana_user_phone';
  static const _kProvince = 'udayana_user_province';
  static const _kCity = 'udayana_user_city';
  static const _kDistrict = 'udayana_user_district';
  static const _kSubdistrict = 'udayana_user_subdistrict';
  static const _kRtRw = 'udayana_user_rtrw';
  static const _kPostalCode = 'udayana_user_postalcode';
  static const _kAddress = 'udayana_user_address';
  static const _kBankName = 'udayana_user_bankname';
  static const _kAccountName = 'udayana_user_accountname';
  static const _kAccountNumber = 'udayana_user_accountnumber';

  static Future<void> save({
    required String token,
    required AppUser user,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kToken, token);
      await prefs.setInt(_kId, user.id);
      await prefs.setString(_kName, user.name);
      await prefs.setString(_kEmail, user.email);
      await prefs.setString(_kRole, user.role);
      await prefs.setString(_kPhone, user.phone);
      await prefs.setString(_kProvince, user.province);
      await prefs.setString(_kCity, user.city);
      await prefs.setString(_kDistrict, user.district);
      await prefs.setString(_kSubdistrict, user.subdistrict);
      await prefs.setString(_kRtRw, user.rtRw);
      await prefs.setString(_kPostalCode, user.postalCode);
      await prefs.setString(_kAddress, user.address);
      await prefs.setString(_kBankName, user.bankName);
      await prefs.setString(_kAccountName, user.accountName);
      await prefs.setString(_kAccountNumber, user.accountNumber);
    } catch (_) {}
  }

  static Future<(String?, AppUser?)> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_kToken);
      final id = prefs.getInt(_kId);
      if (token == null || token.isEmpty || id == null) {
        return (null, null);
      }
      final user = AppUser(
        id: id,
        name: prefs.getString(_kName) ?? '',
        email: prefs.getString(_kEmail) ?? '',
        role: prefs.getString(_kRole) ?? 'buyer',
        phone: prefs.getString(_kPhone) ?? '',
        province: prefs.getString(_kProvince) ?? '',
        city: prefs.getString(_kCity) ?? '',
        district: prefs.getString(_kDistrict) ?? '',
        subdistrict: prefs.getString(_kSubdistrict) ?? '',
        rtRw: prefs.getString(_kRtRw) ?? '',
        postalCode: prefs.getString(_kPostalCode) ?? '',
        address: prefs.getString(_kAddress) ?? '',
        bankName: prefs.getString(_kBankName) ?? '',
        accountName: prefs.getString(_kAccountName) ?? '',
        accountNumber: prefs.getString(_kAccountNumber) ?? '',
      );
      return (token, user);
    } catch (_) {
      return (null, null);
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kToken);
      await prefs.remove(_kId);
      await prefs.remove(_kName);
      await prefs.remove(_kEmail);
      await prefs.remove(_kRole);
      await prefs.remove(_kPhone);
      await prefs.remove(_kProvince);
      await prefs.remove(_kCity);
      await prefs.remove(_kDistrict);
      await prefs.remove(_kSubdistrict);
      await prefs.remove(_kRtRw);
      await prefs.remove(_kPostalCode);
      await prefs.remove(_kAddress);
      await prefs.remove(_kBankName);
      await prefs.remove(_kAccountName);
      await prefs.remove(_kAccountNumber);
    } catch (_) {}
  }
}

class LocalCache {
  const LocalCache._();

  static const _kProducts = 'udayana_cached_products';
  static const _kOrders = 'udayana_cached_orders';
  static const _kHomeLayout = 'udayana_cached_home_layout';

  static Future<void> saveProducts(String jsonStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProducts, jsonStr);
    } catch (_) {}
  }

  static Future<String?> loadProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kProducts);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kProducts);
    } catch (_) {}
  }

  static Future<void> saveOrders(String jsonStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kOrders, jsonStr);
    } catch (_) {}
  }

  static Future<String?> loadOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kOrders);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kOrders);
    } catch (_) {}
  }

  static Future<void> saveHomeLayout(String jsonStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kHomeLayout, jsonStr);
    } catch (_) {}
  }

  static Future<String?> loadHomeLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kHomeLayout);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearHomeLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kHomeLayout);
    } catch (_) {}
  }

  static Future<void> clearAll() async {
    await clearProducts();
    await clearOrders();
    await clearHomeLayout();
  }
}
