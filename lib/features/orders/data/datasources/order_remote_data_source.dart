import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/session_storage.dart';

abstract interface class OrderRemoteDataSource {
  Future<dynamic> checkout(
    List<Map<String, int>> items, {
    String paymentMethod = 'COD',
    String shippingAddress = '',
  });
  Future<List<dynamic>> orders({required bool admin});
  Future<List<dynamic>> customers();
  Future<void> updateCustomer(
    int id, {
    required String name,
    required String phone,
    String province = '',
    String city = '',
    String district = '',
    String subdistrict = '',
    String rtRw = '',
    String postalCode = '',
    String address = '',
  });
  Future<Map<String, dynamic>> report(String period, String value);
  Future<void> updateStatus(int id, String status);
  Future<Map<String, dynamic>> withdraw({
    required String bankName,
    required String accountName,
    required String accountNumber,
    required int amountCents,
  });
  Future<Map<String, dynamic>> getPaymentDetails(int orderId);
  Future<void> simulatePayment(int orderId);
  Future<List<dynamic>> listAddresses();
  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> body);
  Future<void> deleteAddress(int id);
  Future<void> setDefaultAddress(int id);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  const OrderRemoteDataSourceImpl(this._api);

  final ApiClient _api;

  @override
  Future<dynamic> checkout(
    List<Map<String, int>> items, {
    String paymentMethod = 'COD',
    String shippingAddress = '',
  }) => _api.post(
    '/orders',
    body: {
      'items': items,
      'payment_method': paymentMethod,
      'shipping_address': shippingAddress,
    },
  );

  @override
  Future<List<dynamic>> orders({required bool admin}) async {
    try {
      final response = await _api.get(admin ? '/admin/orders' : '/orders');
      if (response != null) {
        LocalCache.saveOrders(jsonEncode(response)).catchError((_) {});
      }
      return response as List<dynamic>;
    } catch (_) {
      try {
        final cachedJson = await LocalCache.loadOrders();
        if (cachedJson != null && cachedJson.isNotEmpty) {
          return jsonDecode(cachedJson) as List<dynamic>;
        }
      } catch (_) {
        await LocalCache.clearOrders();
      }
      rethrow;
    }
  }

  @override
  Future<List<dynamic>> customers() async =>
      await _api.get('/admin/customers') as List<dynamic>;

  @override
  Future<void> updateCustomer(
    int id, {
    required String name,
    required String phone,
    String province = '',
    String city = '',
    String district = '',
    String subdistrict = '',
    String rtRw = '',
    String postalCode = '',
    String address = '',
  }) async {
    await _api.put(
      '/admin/customers/$id',
      body: {
        'name': name,
        'phone': phone,
        'province': province,
        'city': city,
        'district': district,
        'subdistrict': subdistrict,
        'rt_rw': rtRw,
        'postal_code': postalCode,
        'address': address,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> report(String period, String value) async =>
      await _api.get(
        '/admin/reports',
        query: {'period': period, 'value': value},
      ) as Map<String, dynamic>;

  @override
  Future<void> updateStatus(int id, String status) async {
    await _api.patch('/admin/orders/$id/status', body: {'status': status});
  }

  @override
  Future<Map<String, dynamic>> withdraw({
    required String bankName,
    required String accountName,
    required String accountNumber,
    required int amountCents,
  }) async =>
      await _api.post(
        '/admin/withdraw',
        body: {
          'bank_name': bankName,
          'account_name': accountName,
          'account_number': accountNumber,
          'amount_cents': amountCents,
        },
      ) as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> getPaymentDetails(int orderId) async =>
      await _api.get('/buyer/orders/$orderId/payment') as Map<String, dynamic>;

  @override
  Future<void> simulatePayment(int orderId) async {
    await _api.post('/admin/orders/$orderId/simulate-payment', body: {'status': 'settlement'});
  }

  @override
  Future<List<dynamic>> listAddresses() async =>
      (await _api.get('/buyer/addresses') as Map<String, dynamic>)['addresses'] as List<dynamic>;

  @override
  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> body) async =>
      await _api.post('/buyer/addresses', body: body) as Map<String, dynamic>;

  @override
  Future<void> deleteAddress(int id) async {
    await _api.delete('/buyer/addresses/$id');
  }

  @override
  Future<void> setDefaultAddress(int id) async {
    await _api.patch('/buyer/addresses/$id/default');
  }
}
