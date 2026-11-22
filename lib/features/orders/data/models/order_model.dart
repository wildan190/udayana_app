class OrderModel {
  const OrderModel({
    required this.id,
    required this.items,
    required this.totalCents,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.status,
    required this.createdAt,
    required this.customerName,
    required this.midtransResponse,
    this.shippingFeeCents = 0,
    this.distanceKm = 0,
    this.cancellationReason = '',
    this.refundBankName = '',
    this.refundAccountName = '',
    this.refundAccountNumber = '',
    this.irisPayoutReference = '',
  });

  final int id;
  final List<OrderLineModel> items;
  final int totalCents;
  final String paymentMethod;
  final String shippingAddress;
  final String status;
  final DateTime createdAt;
  final String customerName;
  final Map<String, dynamic> midtransResponse;
  final int shippingFeeCents;
  final double distanceKm;
  final String cancellationReason;
  final String refundBankName;
  final String refundAccountName;
  final String refundAccountNumber;
  final String irisPayoutReference;

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: (json['id'] as num).toInt(),
    items: (json['items'] as List<dynamic>? ?? const [])
        .map((item) => OrderLineModel.fromJson(item as Map<String, dynamic>))
        .toList(),
    totalCents: (json['total_cents'] as num).toInt(),
    paymentMethod: json['payment_method'] as String? ?? 'COD',
    shippingAddress: json['shipping_address'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
    customerName:
        (json['customer'] as Map<String, dynamic>?)?['name'] as String? ?? '',
    midtransResponse:
        json['midtrans_response'] as Map<String, dynamic>? ?? const {},
    shippingFeeCents: (json['shipping_fee_cents'] as num? ?? 0).toInt(),
    distanceKm: (json['distance_km'] as num? ?? 0).toDouble(),
    cancellationReason: json['cancellation_reason'] as String? ?? '',
    refundBankName: json['refund_bank_name'] as String? ?? '',
    refundAccountName: json['refund_account_name'] as String? ?? '',
    refundAccountNumber: json['refund_account_number'] as String? ?? '',
    irisPayoutReference: json['iris_payout_reference'] as String? ?? '',
  );
}

class OrderLineModel {
  const OrderLineModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.priceCents,
  });

  final int productId;
  final String productName;
  final int quantity;
  final int priceCents;

  factory OrderLineModel.fromJson(Map<String, dynamic> json) => OrderLineModel(
    productId: (json['product_id'] as num).toInt(),
    productName: json['product_name'] as String? ?? '',
    quantity: (json['quantity'] as num).toInt(),
    priceCents: (json['price_cents'] as num).toInt(),
  );
}
