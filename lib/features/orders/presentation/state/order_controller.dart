import 'package:flutter/foundation.dart';

import '../../domain/usecases/manage_orders.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderController extends ChangeNotifier {
  OrderController(
    this._placeOrder,
    this._loadOrders,
    this._changeOrderStatus,
    this._requestCancellation,
  );

  final PlaceOrder _placeOrder;
  final LoadOrders _loadOrders;
  final ChangeOrderStatus _changeOrderStatus;
  final Future<void> Function(int, Map<String, dynamic>) _requestCancellation;
  OrderState _state = const OrderState();

  OrderState get state => _state;

  Future<void> dispatch(OrderEvent event) async {
    switch (event) {
      case LoadOrdersRequested(:final admin):
        _state = OrderState(orders: _state.orders, isLoading: true);
        notifyListeners();
        try {
          _state = OrderState(orders: await _loadOrders(admin: admin));
        } on Exception catch (error) {
          _state = OrderState(orders: _state.orders, error: error.toString());
        }
      case CheckoutRequested(
        :final items,
        :final paymentMethod,
        :final shippingAddress,
        :final city,
        :final district,
      ):
        _state = OrderState(orders: _state.orders, isLoading: true);
        notifyListeners();
        try {
          final order = await _placeOrder(
            items,
            paymentMethod: paymentMethod,
            shippingAddress: shippingAddress,
            city: city,
            district: district,
          );
          _state = OrderState(orders: _state.orders, lastOrder: order);
        } on Exception catch (error) {
          _state = OrderState(orders: _state.orders, error: error.toString());
        }
      case OrderStatusChangeRequested(:final id, :final status):
        try {
          await _changeOrderStatus(id, status);
          await dispatch(const LoadOrdersRequested(admin: true));
        } on Exception catch (error) {
          _state = OrderState(orders: _state.orders, error: error.toString());
        }
      case OrderCancellationRequested(:final orderId, :final body):
        try {
          await _requestCancellation(orderId, body);
          await dispatch(const LoadOrdersRequested(admin: false));
        } on Exception catch (error) {
          _state = OrderState(
            orders: _state.orders,
            error: error.toString(),
            lastOrder: _state.lastOrder,
            isLoading: false,
          );
        }
    }
    notifyListeners();
  }
}
