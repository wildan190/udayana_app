import '../entities/order.dart';
import '../repositories/order_repository.dart';

class PlaceOrder {
  const PlaceOrder(this._repository);

  final OrderRepository _repository;

  Future<Order> call(
    List<Map<String, int>> items, {
    String paymentMethod = 'COD',
    String shippingAddress = '',
  }) => _repository.checkout(
    items,
    paymentMethod: paymentMethod,
    shippingAddress: shippingAddress,
  );
}

class LoadOrders {
  const LoadOrders(this._repository);

  final OrderRepository _repository;

  Future<List<Order>> call({required bool admin}) =>
      _repository.orders(admin: admin);
}

class LoadCustomers {
  const LoadCustomers(this._repository);

  final OrderRepository _repository;

  Future<List<Customer>> call() => _repository.customers();
}

class UpdateCustomer {
  const UpdateCustomer(this._repository);

  final OrderRepository _repository;

  Future<void> call(
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
  }) => _repository.updateCustomer(
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
}

class LoadReport {
  const LoadReport(this._repository);

  final OrderRepository _repository;

  Future<SalesReport> call(String period, String value) =>
      _repository.report(period, value);
}

class ChangeOrderStatus {
  const ChangeOrderStatus(this._repository);

  final OrderRepository _repository;

  Future<void> call(int id, String status) =>
      _repository.updateStatus(id, status);
}
