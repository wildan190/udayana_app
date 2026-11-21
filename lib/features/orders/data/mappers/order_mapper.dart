import '../../domain/entities/order.dart';
import '../models/order_model.dart';

class OrderMapper {
  const OrderMapper._();

  static Order toEntity(OrderModel model) => Order(
    id: model.id,
    items: model.items
        .map(
          (line) => OrderLine(
            productId: line.productId,
            productName: line.productName,
            quantity: line.quantity,
            priceCents: line.priceCents,
          ),
        )
        .toList(),
    totalCents: model.totalCents,
    paymentMethod: model.paymentMethod,
    shippingAddress: model.shippingAddress,
    shippingFeeCents: model.shippingFeeCents,
    distanceKm: model.distanceKm,
    status: model.status,
    createdAt: model.createdAt,
    customerName: model.customerName,
    midtransResponse: model.midtransResponse,
  );
}
