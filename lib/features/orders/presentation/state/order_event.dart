sealed class OrderEvent {
  const OrderEvent();
}

class LoadOrdersRequested extends OrderEvent {
  const LoadOrdersRequested({required this.admin});

  final bool admin;
}

class CheckoutRequested extends OrderEvent {
  const CheckoutRequested(
    this.items, {
    this.paymentMethod = 'COD',
    this.shippingAddress = '',
  });

  final List<Map<String, int>> items;
  final String paymentMethod;
  final String shippingAddress;
}

class OrderStatusChangeRequested extends OrderEvent {
  const OrderStatusChangeRequested(this.id, this.status);

  final int id;
  final String status;
}
