import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_data_source.dart';
import '../mappers/customer_mapper.dart';
import '../mappers/order_mapper.dart';
import '../models/customer_model.dart';
import '../models/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  const OrderRepositoryImpl(this._remoteDataSource);

  final OrderRemoteDataSource _remoteDataSource;

  @override
  Future<Order> checkout(
    List<Map<String, int>> items, {
    String paymentMethod = 'COD',
    String shippingAddress = '',
  }) async {
    final json =
        await _remoteDataSource.checkout(
              items,
              paymentMethod: paymentMethod,
              shippingAddress: shippingAddress,
            )
            as Map<String, dynamic>;
    return OrderMapper.toEntity(OrderModel.fromJson(json));
  }

  @override
  Future<List<Order>> orders({required bool admin}) async =>
      (await _remoteDataSource.orders(admin: admin))
          .map(
            (json) => OrderMapper.toEntity(
              OrderModel.fromJson(json as Map<String, dynamic>),
            ),
          )
          .toList();

  @override
  Future<List<Customer>> customers() async =>
      (await _remoteDataSource.customers())
          .map(
            (json) => CustomerMapper.toEntity(
              CustomerModel.fromJson(json as Map<String, dynamic>),
            ),
          )
          .toList();

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
  }) => _remoteDataSource.updateCustomer(
    id,
    name: name,
    phone: phone,
    province: province,
    city: city,
    district: district,
    subdistrict: subdistrict,
    rtRw: rtRw,
    postalCode: postalCode,
    address: address,
  );

  @override
  Future<SalesReport> report(String period, String value) async {
    final json = await _remoteDataSource.report(period, value);
    List<ReportRow> rows(String key, String labelKey) =>
        (json[key] as List<dynamic>? ?? const []).map((item) {
          final row = item as Map<String, dynamic>;
          return ReportRow(
            label: row[labelKey] as String? ?? '',
            quantity: (row['quantity'] as num).toInt(),
          );
        }).toList();

    return SalesReport(
      revenueCents: (json['revenue_cents'] as num).toInt(),
      midtransRevenueCents:
          (json['midtrans_revenue_cents'] as num? ?? 0).toInt(),
      codRevenueCents: (json['cod_revenue_cents'] as num? ?? 0).toInt(),
      orderCount: (json['order_count'] as num).toInt(),
      topCategories: rows('top_categories', 'category'),
      needTypeTotals: rows('need_type_totals', 'need_type'),
    );
  }

  @override
  Future<void> updateStatus(int id, String status) =>
      _remoteDataSource.updateStatus(id, status);

  @override
  Future<Map<String, dynamic>> withdraw({
    required String bankName,
    required String accountName,
    required String accountNumber,
    required int amountCents,
  }) => _remoteDataSource.withdraw(
    bankName: bankName,
    accountName: accountName,
    accountNumber: accountNumber,
    amountCents: amountCents,
  );

  @override
  Future<Map<String, dynamic>> getPaymentDetails(int orderId) =>
      _remoteDataSource.getPaymentDetails(orderId);

  @override
  Future<void> simulatePayment(int orderId) =>
      _remoteDataSource.simulatePayment(orderId);

  @override
  Future<List<Map<String, dynamic>>> listAddresses() async =>
      (await _remoteDataSource.listAddresses())
          .map((item) => item as Map<String, dynamic>)
          .toList();

  @override
  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> body) =>
      _remoteDataSource.createAddress(body);

  @override
  Future<void> deleteAddress(int id) => _remoteDataSource.deleteAddress(id);

  @override
  Future<void> setDefaultAddress(int id) =>
      _remoteDataSource.setDefaultAddress(id);
}
