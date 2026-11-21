import '../../domain/entities/order.dart';

class OrderState {
  const OrderState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.lastOrder,
  });

  final List<Order> orders;
  final bool isLoading;
  final String? error;
  final Order? lastOrder;
}
