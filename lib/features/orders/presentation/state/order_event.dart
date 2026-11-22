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
    this.city = '',
    this.district = '',
  });

  final List<Map<String, int>> items;
  final String paymentMethod;
  final String shippingAddress;
  final String city;
  final String district;
}

class OrderStatusChangeRequested extends OrderEvent {
  const OrderStatusChangeRequested(this.id, this.status);

  final int id;
  final String status;
}

class OrderCancellationRequested extends OrderEvent {
  const OrderCancellationRequested(this.orderId, this.body);

  final int orderId;
  final Map<String, dynamic> body;
}
