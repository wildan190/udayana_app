import 'package:flutter/material.dart';

import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/state/product_controller.dart';
import '../../domain/entities/home_layout.dart';
import '../widgets/product_card.dart';
import '../widgets/skeleton_loader.dart';
import 'view_helpers.dart';

class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.productsController,
    required this.isAdmin,
    required this.cart,
    required this.knownProducts,
    required this.homeLayout,
    required this.category,
    required this.search,
    required this.searchController,
    required this.selectedHomeCategoryAll,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onSelectCategory,
    required this.onReloadProducts,
    required this.onOpenProductDetail,
    required this.onShowProductForm,
    required this.onRemoveProduct,
    required this.onAddToCart,
    required this.onSelectHomeCategoryAll,
    required this.resolvedImageUrl,
    required this.moneyFormatter,
  });

  final ProductController productsController;
  final bool isAdmin;
  final Map<int, int> cart;
  final Map<int, Product> knownProducts;
  final HomeLayout? homeLayout;
  final String category;
  final String search;
  final TextEditingController searchController;
  final String? selectedHomeCategoryAll;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchSubmitted;
  final Function(HomeCategory) onSelectCategory;
  final Future<void> Function({bool append}) onReloadProducts;
  final Function(Product) onOpenProductDetail;
  final Function([Product?]) onShowProductForm;
  final Function(Product) onRemoveProduct;
  final Function(Product) onAddToCart;
  final ValueChanged<String?> onSelectHomeCategoryAll;
  final String Function(String) resolvedImageUrl;
  final String Function(int) moneyFormatter;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: productsController,
      builder: (context, _) {
        final state = productsController.state;
        for (final product in state.products) {
          knownProducts[product.id] = product;
        }
        if (state.isLoading && state.products.isEmpty) {
          return const ProductGridSkeleton();
        }
        if (state.error != null && state.products.isEmpty) {
          return errorPanel(state.error!, () => onReloadProducts());
        }
        final visible = state.products;

        if (!isAdmin) {
          return RefreshIndicator(
            onRefresh: () => onReloadProducts(),
            child: _buildBuyerHome(context, visible),
          );
        }

        return RefreshIndicator(
          onRefresh: () => onReloadProducts(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (isAdmin) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    child: adminHeading(context, 'Kelola produk'),
                  ),
                ),
                SliverToBoxAdapter(child: _searchBox(context)),
              ],
              if (state.error != null)
                SliverToBoxAdapter(child: inlineError(state.error!)),
              if (visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: emptyPanel(
                    search.isEmpty
                        ? 'Belum ada produk'
                        : 'Produk tidak ditemukan',
                    search.isEmpty
                        ? 'Produk akan muncul di sini setelah tersambung ke server.'
                        : 'Coba kata kunci atau kategori lain.',
                    Icons.inventory_2_outlined,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    8,
                    18,
                    16 + kBottomNavInset,
                  ),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.crossAxisExtent > 650 ? 3 : 2;
                      return SliverGrid.builder(
                        itemCount: visible.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 13,
                          crossAxisSpacing: 13,
                          mainAxisExtent: isAdmin ? 296 : 290,
                        ),
                        itemBuilder: (context, index) => ProductCard(
                          product: visible[index],
                          quantity: cart[visible[index].id] ?? 0,
                          isAdmin: isAdmin,
                          onTap: () => onOpenProductDetail(visible[index]),
                          onEdit: () => onShowProductForm(visible[index]),
                          onDelete: () => onRemoveProduct(visible[index]),
                          onAddToCart: () => onAddToCart(visible[index]),
                          resolvedImageUrl: resolvedImageUrl,
                          moneyFormatter: moneyFormatter,
                        ),
                      );
                    },
                  ),
                ),
              if (state.hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      0,
                      18,
                      24 + kBottomNavInset,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: state.isLoading
                          ? null
                          : () => onReloadProducts(append: true),
                      icon: state.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.expand_more_rounded),
                      label: Text(
                        state.isLoading ? 'Memuat produk...' : 'Muat lainnya',
                      ),
                    ),
                  ),
                )
              else if (visible.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      8,
                      18,
                      24 + kBottomNavInset,
                    ),
                    child: Center(
                      child: Text(
                        'Menampilkan ${visible.length} dari ${state.total} produk',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBuyerHome(BuildContext context, List<Product> products) {
    if (selectedHomeCategoryAll != null) {
      return _buildHomeCategoryAllView(context, selectedHomeCategoryAll!);
    }

    if (homeLayout == null ||
        homeLayout!.components.isEmpty ||
        category != 'Semua' ||
        search.isNotEmpty) {
      return _buildProductGrid(context, products);
    }

    final categories = <String, List<Product>>{};
    for (final p in products) {
      final cat = p.category.isNotEmpty ? p.category : p.needLabel;
      categories.putIfAbsent(cat, () => []).add(p);
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _searchBox(context)),
        SliverToBoxAdapter(
          child: _categorySelector(
            homeLayout?.components
                    .firstWhere(
                      (c) => c.type == 'category_filters',
                      orElse: () => const HomeComponent(
                        type: 'category_filters',
                        categories: [],
                      ),
                    )
                    .categories ??
                [],
          ),
        ),
        for (final entry in categories.entries) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => onSelectHomeCategoryAll(entry.key),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    label: const Text('Semua'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: isAdmin ? 296 : 290,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: entry.value.length,
                itemBuilder: (context, index) => SizedBox(
                  width: 170,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ProductCard(
                      product: entry.value[index],
                      quantity: cart[entry.value[index].id] ?? 0,
                      isAdmin: isAdmin,
                      onTap: () => onOpenProductDetail(entry.value[index]),
                      onEdit: () => onShowProductForm(entry.value[index]),
                      onDelete: () => onRemoveProduct(entry.value[index]),
                      onAddToCart: () => onAddToCart(entry.value[index]),
                      resolvedImageUrl: resolvedImageUrl,
                      moneyFormatter: moneyFormatter,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: kBottomNavInset)),
      ],
    );
  }

  Widget _buildProductGrid(BuildContext context, List<Product> products) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _searchBox(context)),
        SliverToBoxAdapter(
          child: _categorySelector(
            homeLayout?.components
                    .firstWhere(
                      (c) => c.type == 'category_filters',
                      orElse: () => const HomeComponent(
                        type: 'category_filters',
                        categories: [],
                      ),
                    )
                    .categories ??
                [],
          ),
        ),
        if (products.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: emptyPanel(
              'Produk tidak ditemukan',
              'Coba kata kunci atau kategori lain.',
              Icons.inventory_2_outlined,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.crossAxisExtent > 650 ? 3 : 2;
                return SliverGrid.builder(
                  itemCount: products.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 13,
                    crossAxisSpacing: 13,
                    mainAxisExtent: isAdmin ? 296 : 290,
                  ),
                  itemBuilder: (context, index) => ProductCard(
                    product: products[index],
                    quantity: cart[products[index].id] ?? 0,
                    isAdmin: isAdmin,
                    onTap: () => onOpenProductDetail(products[index]),
                    onEdit: () => onShowProductForm(products[index]),
                    onDelete: () => onRemoveProduct(products[index]),
                    onAddToCart: () => onAddToCart(products[index]),
                    resolvedImageUrl: resolvedImageUrl,
                    moneyFormatter: moneyFormatter,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHomeCategoryAllView(BuildContext context, String categoryName) {
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
                onPressed: () => onSelectHomeCategoryAll(null),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kategori: $categoryName',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
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
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  itemCount: categoryProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 13,
                    crossAxisSpacing: 13,
                    mainAxisExtent: 350,
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

  Widget _searchBox(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  textAlignVertical: TextAlignVertical.center,
                  onChanged: onSearchChanged,
                  onSubmitted: (_) => onSearchSubmitted(),
                  decoration: InputDecoration(
                    hintText: 'Cari beras, minyak, kebutuhan rumah...',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            visualDensity: VisualDensity.compact,
                            iconSize: 18,
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              searchController.clear();
                              onSearchChanged('');
                              onSearchSubmitted();
                            },
                          )
                        : null,
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  minimumSize: const Size(0, 48),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onSearchSubmitted,
                child: const Text('Cari'),
              ),
            ),
          ],
        ),
      );

  Widget _categorySelector(List<HomeCategory> categories) => SizedBox(
        height: 48,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          scrollDirection: Axis.horizontal,
          children: [
            for (final cat in categories)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat.label),
                  selected: category == cat.label,
                  onSelected: (_) => onSelectCategory(cat),
                ),
              ),
          ],
        ),
      );
}
