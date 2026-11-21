class Order {
  const Order({
    required this.id,
    required this.items,
    required this.totalCents,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.customerName = '',
    this.shippingAddress = '',
    this.shippingFeeCents = 0,
    this.distanceKm = 0,
    this.midtransResponse = const {},
  });

  final int id;
  final List<OrderLine> items;
  final int totalCents;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final String customerName;
  final String shippingAddress;
  final int shippingFeeCents;
  final double distanceKm;
  final Map<String, dynamic> midtransResponse;

  int get subtotalCents => totalCents - shippingFeeCents;

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'processing':
        return 'Diproses';
      case 'shipping':
        return 'Dikirim (Dalam Pengiriman)';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}

class OrderLine {
  const OrderLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.priceCents,
  });

  final int productId;
  final String productName;
  final int quantity;
  final int priceCents;
}

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.province = '',
    this.city = '',
    this.district = '',
    this.subdistrict = '',
    this.rtRw = '',
    this.postalCode = '',
    this.address = '',
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String province;
  final String city;
  final String district;
  final String subdistrict;
  final String rtRw;
  final String postalCode;
  final String address;

  String get formattedAddress {
    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address);
    if (rtRw.isNotEmpty) parts.add('RT/RW $rtRw');
    if (subdistrict.isNotEmpty) parts.add('Kel. $subdistrict');
    if (district.isNotEmpty) parts.add('Kec. $district');
    if (city.isNotEmpty) parts.add(city);
    if (province.isNotEmpty) parts.add(province);
    if (postalCode.isNotEmpty) parts.add(postalCode);
    return parts.join(', ');
  }
}

class SalesReport {
  const SalesReport({
    required this.revenueCents,
    required this.midtransRevenueCents,
    required this.codRevenueCents,
    required this.orderCount,
    required this.topCategories,
    required this.needTypeTotals,
  });

  final int revenueCents;
  final int midtransRevenueCents;
  final int codRevenueCents;
  final int orderCount;
  final List<ReportRow> topCategories;
  final List<ReportRow> needTypeTotals;
}

class ReportRow {
  const ReportRow({required this.label, required this.quantity});

  final String label;
  final int quantity;
}
