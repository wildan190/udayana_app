import '../entities/order.dart';
import '../entities/shipping.dart';

abstract interface class OrderRepository {
  Future<Order> checkout(
    List<Map<String, int>> items, {
    String paymentMethod = 'COD',
    String shippingAddress = '',
    String city = '',
    String district = '',
  });
  Future<List<Order>> orders({required bool admin});
  Future<List<Customer>> customers();
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
  Future<SalesReport> report(String period, String value);
  Future<void> updateStatus(int id, String status);
  Future<Map<String, dynamic>> withdraw({
    required String bankName,
    required String accountName,
    required String accountNumber,
    required int amountCents,
  });
  Future<Map<String, dynamic>> getPaymentDetails(int orderId);
  Future<void> simulatePayment(int orderId);
  Future<void> updateBankAccount(Map<String, dynamic> body);
  Future<void> requestCancellation(int orderId, Map<String, dynamic> body);
  Future<void> approveCancellation(int orderId);
  Future<void> rejectCancellation(int orderId);
  Future<List<Map<String, dynamic>>> listAddresses();
  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> body);
  Future<void> deleteAddress(int id);
  Future<void> setDefaultAddress(int id);
  Future<ShippingQuote> shippingQuote(String city, String district);
  Future<ShippingConfig> shippingConfig();
  Future<void> updateShippingSettings(Map<String, dynamic> body);
  Future<Map<String, dynamic>> createShippingZone(Map<String, dynamic> body);
  Future<void> updateShippingZone(int id, Map<String, dynamic> body);
  Future<void> deleteShippingZone(int id);
  Future<Map<String, dynamic>> createShippingArea(Map<String, dynamic> body);
  Future<void> updateShippingArea(int id, Map<String, dynamic> body);
  Future<void> deleteShippingArea(int id);
}
