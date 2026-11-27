import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../products/domain/entities/product.dart';

class AddToCartFlightNotification extends Notification {
  const AddToCartFlightNotification({
    required this.product,
    required this.sourceRect,
    required this.imageUrl,
  });

  final Product product;
  final Rect sourceRect;
  final String imageUrl;
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.isAdmin,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onAddToCart,
    required this.resolvedImageUrl,
    required this.moneyFormatter,
  });

  final Product product;
  final int quantity;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddToCart;
  final String Function(String) resolvedImageUrl;
  final String Function(int) moneyFormatter;

  @override
  Widget build(BuildContext context) {
    final icon = product.category == 'Perawatan Diri'
        ? Icons.spa_outlined
        : product.category == 'Protein'
        ? Icons.egg_alt_outlined
        : product.category == 'Rumah Tangga'
        ? Icons.home_outlined
        : Icons.rice_bowl_outlined;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              color: AppColors.fill,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (product.imageUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.network(
                        resolvedImageUrl(product.imageUrl),
                        fit: BoxFit.contain,
                        cacheWidth: 350,
                        errorBuilder: (_, _, _) => _imagePlaceholder(icon),
                      ),
                    )
                  else
                    _imagePlaceholder(icon),
                  if (quantity > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadius.tagAll,
                        ),
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.needLabel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    moneyFormatter(product.priceCents),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isAdmin)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Stok ${product.stock}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: onEdit,
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 19,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 19,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          minimumSize: const Size.fromHeight(36),
                        ),
                        onPressed: product.stock == 0
                            ? null
                            : () {
                                final renderObject = context.findRenderObject();
                                if (renderObject is RenderBox &&
                                    renderObject.hasSize) {
                                  final topLeft = renderObject.localToGlobal(
                                    Offset.zero,
                                  );
                                  final imageHeight = renderObject.size.height
                                      .clamp(0.0, 140.0)
                                      .toDouble();
                                  AddToCartFlightNotification(
                                    product: product,
                                    sourceRect: Rect.fromLTWH(
                                      topLeft.dx,
                                      topLeft.dy,
                                      renderObject.size.width,
                                      imageHeight,
                                    ),
                                    imageUrl: product.imageUrl.isEmpty
                                        ? ''
                                        : resolvedImageUrl(product.imageUrl),
                                  ).dispatch(context);
                                }
                                onAddToCart();
                              },
                        child: const Text(
                          'Tambah',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(IconData icon) {
    return ColoredBox(
      color: AppColors.fill,
      child: Center(child: Icon(icon, color: AppColors.primary, size: 42)),
    );
  }
}
