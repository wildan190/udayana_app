import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/state/product_controller.dart';
import '../widgets/product_card.dart';
import 'view_helpers.dart';

class CategoriesView extends StatelessWidget {
  const CategoriesView({
    super.key,
    required this.productsController,
    required this.isAdmin,
    required this.cart,
    required this.selectedCategoryInTab,
    required this.onSelectCategoryInTab,
    required this.onOpenProductDetail,
    required this.onShowProductForm,
    required this.onRemoveProduct,
    required this.onAddToCart,
    required this.resolvedImageUrl,
    required this.moneyFormatter,
  });

  final ProductController productsController;
  final bool isAdmin;
  final Map<int, int> cart;
  final String? selectedCategoryInTab;
  final ValueChanged<String?> onSelectCategoryInTab;
  final Function(Product) onOpenProductDetail;
  final Function([Product?]) onShowProductForm;
  final Function(Product) onRemoveProduct;
  final Function(Product) onAddToCart;
  final String Function(String) resolvedImageUrl;
  final String Function(int) moneyFormatter;

  static const List<Map<String, dynamic>> categories = [
    {
      'label': 'Bahan Pokok',
      'icon': Icons.rice_bowl_outlined,
      'color': Color(0xFFEAF4E7),
    },
    {
      'label': 'Makanan',
      'icon': Icons.fastfood_outlined,
      'color': Color(0xFFFFF8E1),
    },
    {
      'label': 'Minuman',
      'icon': Icons.local_drink_outlined,
      'color': Color(0xFFE0F7FA),
    },
    {
      'label': 'Protein',
      'icon': Icons.egg_alt_outlined,
      'color': Color(0xFFFFF3E0),
    },
    {
      'label': 'Perawatan Diri',
      'icon': Icons.spa_outlined,
      'color': Color(0xFFE3F2FD),
    },
    {
      'label': 'Rumah Tangga',
      'icon': Icons.home_outlined,
      'color': Color(0xFFF3E5F5),
    },
    {
      'label': 'Daily need',
      'icon': Icons.star_outline_rounded,
      'color': Color(0xFFE0F2F1),
    },
    {
      'label': 'Daily essentials',
      'icon': Icons.local_mall_outlined,
      'color': Color(0xFFFCE4EC),
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (selectedCategoryInTab != null) {
      final categoryName = selectedCategoryInTab!;
      final categoryProducts = productsController.state.products.where((p) {
        if (categoryName == 'Daily need') return p.needType == 'daily_need';
        if (categoryName == 'Daily essentials') {
          return p.needType == 'daily_essentials';
        }
        return p.category == categoryName || p.needLabel == categoryName;
      }).toList();

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => onSelectCategoryInTab(null),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kategori: $categoryName',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: categoryProducts.isEmpty
                ? emptyPanel(
                    'Belum ada produk di kategori ini',
                    'Produk untuk $categoryName akan muncul di sini.',
                    Icons.inventory_2_outlined,
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      8,
                      18,
                      24 + kBottomNavInset,
                    ),
                    itemCount: categoryProducts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 13,
                      crossAxisSpacing: 13,
                      mainAxisExtent: isAdmin ? 296 : 290,
                    ),
                    itemBuilder: (context, index) => ProductCard(
                      product: categoryProducts[index],
                      quantity: cart[categoryProducts[index].id] ?? 0,
                      isAdmin: isAdmin,
                      onTap: () => onOpenProductDetail(categoryProducts[index]),
                      onEdit: () => onShowProductForm(categoryProducts[index]),
                      onDelete: () => onRemoveProduct(categoryProducts[index]),
                      onAddToCart: () => onAddToCart(categoryProducts[index]),
                      resolvedImageUrl: resolvedImageUrl,
                      moneyFormatter: moneyFormatter,
                    ),
                  ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30 + kBottomNavInset),
      children: [
        Text(
          'Kategori Produk',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        for (final cat in categories)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cat['color'] as Color,
                child: Icon(cat['icon'] as IconData, color: AppColors.primary),
              ),
              title: Text(
                cat['label'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => onSelectCategoryInTab(cat['label'] as String),
            ),
          ),
      ],
    );
  }
}
