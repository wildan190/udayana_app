import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../products/domain/entities/product.dart';
import '../widgets/product_card.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({
    super.key,
    required this.product,
    required this.imageUrl,
    required this.isAdmin,
    required this.onAddToCart,
    this.relatedProducts = const [],
    this.resolveImageUrl,
    this.quantityOf,
    this.onOpenProduct,
    this.onQuickAdd,
  });

  final Product product;
  final String imageUrl;
  final bool isAdmin;
  final VoidCallback onAddToCart;

  /// Produk lain untuk ditampilkan di bawah produk utama.
  final List<Product> relatedProducts;
  final String Function(String)? resolveImageUrl;
  final int Function(int productId)? quantityOf;
  final void Function(Product product)? onOpenProduct;
  final void Function(Product product)? onQuickAdd;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail produk')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          ClipRRect(
            borderRadius: AppRadius.cardAll,
            child: AspectRatio(
              aspectRatio: 1.15,
              child: ColoredBox(
                color: AppColors.fill,
                child: imageUrl.isEmpty
                    ? const Icon(
                        Icons.shopping_basket_outlined,
                        color: AppColors.primary,
                        size: 64,
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textTertiary,
                          size: 56,
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
              if (product.needLabel.isNotEmpty) _tag(product.needLabel),
              if (product.category.isNotEmpty) _tag(product.category),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: AppRadius.controlAll,
              border: Border.all(color: AppColors.split),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: product.stock > 0
                      ? AppColors.textSecondary
                      : AppColors.error,
                ),
                const SizedBox(width: 8),
                Text(
                  product.stock > 0
                      ? 'Stok tersedia: ${product.stock}'
                      : 'Stok sedang habis',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: product.stock > 0
                        ? AppColors.textSecondary
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Deskripsi Produk',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description.isEmpty
                ? 'Belum ada deskripsi untuk produk ini.'
                : product.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
          ),
          if (relatedProducts.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              'Produk Lainnya',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 290,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: relatedProducts.length,
                itemBuilder: (context, index) {
                  final item = relatedProducts[index];
                  return SizedBox(
                    width: 170,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ProductCard(
                        product: item,
                        quantity: quantityOf?.call(item.id) ?? 0,
                        isAdmin: false,
                        onTap: () => onOpenProduct?.call(item),
                        onEdit: () {},
                        onDelete: () {},
                        onAddToCart: () => onQuickAdd?.call(item),
                        resolvedImageUrl: resolveImageUrl ?? (url) => url,
                        moneyFormatter: _money,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: isAdmin
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: AppColors.container,
                border: Border(top: BorderSide(color: AppColors.split)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: product.stock > 0 ? onAddToCart : null,
                      child: const Text('Tambah ke keranjang'),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _tag(String label) =>
      Chip(label: Text(label), visualDensity: VisualDensity.compact);

  String _money(int cents) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(cents / 100);
}
