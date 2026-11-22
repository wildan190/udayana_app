import 'package:flutter/material.dart';

import '../../../../core/native/cart_math.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../products/domain/entities/product.dart';
import 'view_helpers.dart';

/// Metode pembayaran yang tersedia.
class PaymentMethod {
  const PaymentMethod(
    this.value,
    this.label,
    this.description,
    this.icon, {
    this.logo,
  });

  final String value;
  final String label;
  final String description;
  final IconData icon;

  /// Path aset logo bank (opsional). Bila null, gunakan [icon].
  final String? logo;
}

const List<PaymentMethod> paymentMethods = [
  PaymentMethod(
    'COD',
    'COD (Bayar di Tempat)',
    'Bayar tunai kepada kurir saat barang tiba di alamat pengiriman.',
    Icons.payments_rounded,
  ),
  PaymentMethod(
    'MIDTRANS_MANDIRI',
    'Virtual Account Mandiri',
    'Bayar melalui transfer ATM / M-Banking Mandiri.',
    Icons.account_balance_rounded,
    logo: 'assets/images/bank_logo/mandiri.webp',
  ),
  PaymentMethod(
    'MIDTRANS_BNI',
    'Virtual Account BNI',
    'Bayar melalui transfer ATM / M-Banking BNI.',
    Icons.account_balance_rounded,
    logo: 'assets/images/bank_logo/bni.png',
  ),
  PaymentMethod(
    'MIDTRANS_BRI',
    'Virtual Account BRI',
    'Bayar melalui transfer ATM / M-Banking BRI.',
    Icons.account_balance_rounded,
    logo: 'assets/images/bank_logo/bri.png',
  ),
  PaymentMethod(
    'MIDTRANS_PERMATA',
    'Virtual Account Permata',
    'Bayar melalui transfer ATM / M-Banking Permata.',
    Icons.account_balance_rounded,
    logo: 'assets/images/bank_logo/permata.webp',
  ),
  PaymentMethod(
    'MIDTRANS_CIMB',
    'Virtual Account CIMB Niaga',
    'Bayar melalui transfer ATM / M-Banking CIMB Niaga.',
    Icons.account_balance_rounded,
    logo: 'assets/images/bank_logo/cimb.png',
  ),
  PaymentMethod(
    'MIDTRANS_QRIS',
    'QRIS (GoPay, OVO, Dana, ShopeePay)',
    'Bayar instan via aplikasi dompet digital atau M-Banking.',
    Icons.qr_code_scanner_rounded,
  ),
];

class CartView extends StatelessWidget {
  const CartView({
    super.key,
    required this.knownProducts,
    required this.cart,
    required this.cartCount,
    required this.shippingFeeCents,
    required this.shippingFeeLabel,
    required this.selectedPaymentMethod,
    required this.onChangeQuantity,
    required this.onSelectPaymentMethod,
    required this.onShowAllPaymentMethods,
    required this.onCheckout,
    required this.resolvedImageUrl,
    required this.moneyFormatter,
  });

  final Map<int, Product> knownProducts;
  final Map<int, int> cart;
  final int cartCount;
  final int shippingFeeCents;
  final String shippingFeeLabel;
  final String selectedPaymentMethod;
  final Function(Product, int) onChangeQuantity;
  final ValueChanged<String> onSelectPaymentMethod;
  final VoidCallback onShowAllPaymentMethods;
  final Function(List<Map<String, int>>) onCheckout;
  final String Function(String) resolvedImageUrl;
  final String Function(int) moneyFormatter;

  String get _selectedPaymentMethodValue =>
      paymentMethods.any((m) => m.value == selectedPaymentMethod)
          ? selectedPaymentMethod
          : paymentMethods.first.value;

  @override
  Widget build(BuildContext context) {
    final items = knownProducts.values
        .where((product) => (cart[product.id] ?? 0) > 0)
        .toList();
    final subtotal = CartMath.total(
      items.map((item) => item.priceCents).toList(),
      items.map((item) => cart[item.id]!).toList(),
    );
    final total = subtotal + shippingFeeCents;

    if (items.isEmpty) {
      return emptyPanel(
        'Keranjangmu masih kosong',
        'Tambahkan kebutuhan harian dari katalog produk.',
        Icons.shopping_bag_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30 + kBottomNavInset),
      children: [
        adminHeading(context, 'Keranjang belanja'),
        for (final product in items) _cartItem(context, product),
        const SizedBox(height: 12),
        _paymentMethodSection(),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                summaryRow('Jumlah barang', '$cartCount item'),
                const SizedBox(height: 6),
                summaryRow('Subtotal', moneyFormatter(subtotal)),
                const SizedBox(height: 6),
                summaryRow('Ongkos kirim', shippingFeeLabel),
                const Divider(height: 24),
                summaryRow('Total pembayaran', moneyFormatter(total), bold: true),
                const SizedBox(height: 18),
                primaryButton(
                  label: 'Lanjut checkout',
                  onPressed: () => onCheckout([
                    for (final product in items)
                      {
                        'product_id': product.id,
                        'quantity': cart[product.id]!,
                      },
                  ]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentMethodSection() {
    final selected = _selectedPaymentMethodValue;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Metode Pembayaran',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onShowAllPaymentMethods,
                  child: const Text('Lihat semua'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final method in paymentMethods)
              _paymentMethodTile(
                method,
                selected: selected == method.value,
                onTap: () => onSelectPaymentMethod(method.value),
              ),
          ],
        ),
      ),
    );
  }

  Widget _paymentMethodTile(
    PaymentMethod method, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: AppRadius.controlAll,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryBg : AppColors.container,
            borderRadius: AppRadius.controlAll,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              paymentMethodVisual(
                icon: method.icon,
                logo: method.logo,
                size: 22,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  method.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cartItem(BuildContext context, Product product) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: AppRadius.controlAll,
                child: Container(
                  width: 56,
                  height: 56,
                  color: AppColors.fill,
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          resolvedImageUrl(product.imageUrl),
                          fit: BoxFit.cover,
                          cacheWidth: 150,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.shopping_basket_outlined,
                            color: AppColors.textTertiary,
                            size: 22,
                          ),
                        )
                      : const Icon(
                          Icons.shopping_basket_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(moneyFormatter(product.priceCents)),
                    Text(
                      product.needLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onChangeQuantity(product, -1),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${cart[product.id]}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onChangeQuantity(product, 1),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
