import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../products/domain/entities/product.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({
    super.key,
    required this.product,
    required this.imageUrl,
    required this.isAdmin,
    required this.onAddToCart,
  });

  final Product product;
  final String imageUrl;
  final bool isAdmin;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail produk')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ClipRRect(
            borderRadius: AppRadius.cardAll,
            child: AspectRatio(
              aspectRatio: 1.15,
              child: ColoredBox(
                color: colors.primaryContainer.withValues(alpha: .45),
                child: imageUrl.isEmpty
                    ? Icon(
                        Icons.shopping_basket_outlined,
                        color: colors.primary,
                        size: 72,
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.broken_image_outlined,
                          color: colors.primary,
                          size: 60,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tag(context, product.needLabel),
              _tag(context, product.category),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            product.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _money(product.priceCents),
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Text(
            'Deskripsi produk',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            product.description.isEmpty
                ? 'Belum ada deskripsi untuk produk ini.'
                : product.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                product.stock > 0
                    ? 'Stok tersedia: ${product.stock}'
                    : 'Stok sedang habis',
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: isAdmin
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: FilledButton(
                  onPressed: product.stock > 0 ? onAddToCart : null,
                  child: const Text('Tambah ke keranjang'),
                ),
              ),
            ),
    );
  }

  Widget _tag(BuildContext context, String label) =>
      Chip(label: Text(label), visualDensity: VisualDensity.compact);

  String _money(int cents) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(cents / 100);
}
