import 'dart:async';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/app_services.dart';
import '../../../../core/native/cart_math.dart';
import '../../../../core/network/session_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';
import '../../../auth/presentation/pages/register_page.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/state/order_controller.dart';
import '../../../orders/presentation/state/order_event.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/state/product_controller.dart';
import '../../../products/presentation/state/product_event.dart';
import '../../domain/entities/home_layout.dart';
import '../widgets/order_card.dart';
import '../widgets/product_card.dart';
import 'product_detail_page.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key, required this.services, required this.user});

  final AppServices services;
  final AppUser user;

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  late final ProductController _products;
  late final OrderController _orders;
  final Map<int, int> _cart = {};
  final Map<int, Product> _knownProducts = {};
  int _tabIndex = 0;
  String _category = 'Semua';
  String _search = '';
  String _categoryFilter = '';
  String _needTypeFilter = '';
  String? _selectedCategoryInTab;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _reportPeriod = 'month';
  String _reportValue = DateFormat('yyyy-MM').format(DateTime.now());
  String _orderDateFilter = 'all';
  DateTime? _customFilterDate;
  List<Customer> _customers = const [];
  SalesReport? _report;
  HomeLayout? _homeLayout;
  String? _homeLayoutError;
  String? _panelError;
  bool _panelLoading = false;
  bool _checkoutInProgress = false;
  String _selectedPaymentMethod = 'COD';
  String _selectedShippingAddress = '';
  late AppUser _user;

  bool get _isAdmin => _user.isAdmin;
  bool get _isGuest => _user.role == 'guest';
  int get _cartCount => _cart.values.fold(0, (total, count) => total + count);

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _products = ProductController(
      widget.services.loadProducts,
      widget.services.saveProduct,
      widget.services.removeProduct,
      widget.services.uploadProductImage,
    );
    _orders = OrderController(
      widget.services.placeOrder,
      widget.services.loadOrders,
      widget.services.changeOrderStatus,
    );
    _reloadProducts();
    if (!_isGuest) {
      _reloadOrders();
      _loadCartFromBackend();
    }
    if (!_isAdmin) _loadHomeLayout();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _products.dispose();
    _orders.dispose();
    super.dispose();
  }

  Future<void> _reloadProducts({bool append = false}) {
    final state = _products.state;
    if (append) _searchDebounce?.cancel();
    final requestAppend =
        append &&
        state.search == _search.trim() &&
        state.category == _categoryFilter &&
        state.needType == _needTypeFilter;
    return _products.dispatch(
      LoadProductsRequested(
        admin: _isAdmin,
        page: requestAppend ? state.page + 1 : 1,
        pageSize: 20,
        search: _search.trim(),
        category: _categoryFilter,
        needType: _needTypeFilter,
        append: requestAppend,
      ),
    );
  }

  void _onProductSearchChanged(String value) {
    setState(() => _search = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _reloadProducts(),
    );
  }

  void _selectCategory(HomeCategory category) {
    _searchDebounce?.cancel();
    setState(() {
      _category = category.label;
      _categoryFilter = category.category;
      _needTypeFilter = category.needType;
    });
    _reloadProducts();
  }

  Future<void> _reloadOrders() => _isGuest
      ? Future<void>.value()
      : _orders.dispatch(LoadOrdersRequested(admin: _isAdmin));

  List<String> get _tabs => _isAdmin
      ? const ['Produk', 'Pesanan', 'Pelanggan', 'Laporan']
      : _isGuest
      ? const ['Belanja', 'Kategori', 'Keranjang']
      : const ['Belanja', 'Kategori', 'Keranjang', 'Pesanan', 'Akun'];

  List<Widget> get _pages => _isAdmin
      ? [_buildProducts(), _buildOrders(), _buildCustomers(), _buildReports()]
      : _isGuest
      ? [_buildProducts(), _buildCategoriesTab(), _buildCart()]
      : [
          _buildProducts(),
          _buildCategoriesTab(),
          _buildCart(),
          _buildOrders(),
          _buildAccountTab(),
        ];

  void _selectTab(int index) {
    setState(() {
      _tabIndex = index;
      _panelError = null;
    });
    if (_isAdmin && index == 2) _loadCustomers();
    if (_isAdmin && index == 3) _loadReport();
    if ((_isAdmin && index == 1) || (!_isAdmin && !_isGuest && index == 3)) {
      _reloadOrders();
    }
    if (_tabIndex == 0) _reloadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: AppRadius.tagAll,
              child: Image.asset(
                'assets/images/logo.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'udayana',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
              ),
            ),
          ],
        ),
        actions: _isGuest
            ? [
                TextButton(onPressed: _openLogin, child: const Text('Masuk')),
                IconButton(
                  tooltip: 'Daftar pembeli',
                  onPressed: _openRegister,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                ),
                const SizedBox(width: 4),
              ]
            : [
                PopupMenuButton<String>(
                  tooltip: 'Akun',
                  onSelected: (value) {
                    if (value == 'profile') _openProfile();
                    if (value == 'address') _openAddressDialog();
                    if (value == 'logout') _signOut();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Text(_isAdmin ? 'Administrator' : _user.name),
                    ),
                    if (!_isAdmin) ...[
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Profil Saya'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'address',
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Alamat Saya'),
                          ],
                        ),
                      ),
                    ],
                    const PopupMenuItem(value: 'logout', child: Text('Keluar')),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Center(
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryBg,
                        child: Text(
                          _user.name.isEmpty
                              ? '?'
                              : _user.name.characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
      ),
      body: IndexedStack(index: _tabIndex, children: _pages),
      bottomNavigationBar: _floatingNavBar(),
      floatingActionButton: _isAdmin && _tabIndex == 0
          ? FloatingActionButton(
              onPressed: _showProductForm,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.controlAll,
              ),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  /// Navbar bawah yang melayang (floating), ramping, dan konsisten.
  Widget _floatingNavBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: AppColors.container,
            borderRadius: AppRadius.overlayAll,
            border: Border.all(color: AppColors.split),
            boxShadow: AppShadows.floating,
          ),
          child: Row(
            children: [
              for (var index = 0; index < _tabs.length; index++)
                Expanded(child: _navItem(index)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index) {
    final selected = _tabIndex == index;
    final color = selected ? AppColors.primary : AppColors.textTertiary;
    return InkWell(
      onTap: () => _selectTab(index),
      borderRadius: AppRadius.overlayAll,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _navigationIcon(index, color: color),
          const SizedBox(height: 3),
          Text(
            _tabs[index],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navigationIcon(int index, {required Color color}) {
    final icons = _isAdmin
        ? const [
            Icons.inventory_2_outlined,
            Icons.receipt_long_outlined,
            Icons.people_outline_rounded,
            Icons.bar_chart_rounded,
          ]
        : _isGuest
        ? const [
            Icons.storefront_outlined,
            Icons.category_outlined,
            Icons.shopping_bag_outlined,
          ]
        : const [
            Icons.storefront_outlined,
            Icons.category_outlined,
            Icons.shopping_bag_outlined,
            Icons.receipt_long_outlined,
            Icons.person_outline_rounded,
          ];
    final icon = Icon(icons[index], color: color, size: 23);
    final cartIndex = 2;
    if (!_isAdmin && index == cartIndex && _cartCount > 0) {
      return Badge(
        label: Text('$_cartCount'),
        backgroundColor: AppColors.error,
        textColor: Colors.white,
        child: icon,
      );
    }
    return icon;
  }

  Widget _buildProducts() {
    return AnimatedBuilder(
      animation: _products,
      builder: (context, _) {
        final state = _products.state;
        for (final product in state.products) {
          _knownProducts[product.id] = product;
        }
        if (state.isLoading && state.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null && state.products.isEmpty) {
          return _errorPanel(state.error!, _reloadProducts);
        }
        final visible = state.products;

        if (!_isAdmin) {
          return RefreshIndicator(
            onRefresh: _reloadProducts,
            child: _buildBuyerHome(visible),
          );
        }

        return RefreshIndicator(
          onRefresh: _reloadProducts,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (_isAdmin) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    child: _adminHeading('Kelola produk'),
                  ),
                ),
                SliverToBoxAdapter(child: _searchBox()),
              ],
              if (state.error != null)
                SliverToBoxAdapter(child: _inlineError(state.error!)),
              if (visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _emptyPanel(
                    _search.isEmpty
                        ? 'Belum ada produk'
                        : 'Produk tidak ditemukan',
                    _search.isEmpty
                        ? 'Produk akan muncul di sini setelah tersambung ke server.'
                        : 'Coba kata kunci atau kategori lain.',
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
                        itemCount: visible.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 13,
                          crossAxisSpacing: 13,
                          mainAxisExtent: _isAdmin ? 296 : 290,
                        ),
                        itemBuilder: (context, index) => ProductCard(
                          product: visible[index],
                          quantity: _cart[visible[index].id] ?? 0,
                          isAdmin: _isAdmin,
                          onTap: () => _openProductDetail(visible[index]),
                          onEdit: () => _showProductForm(visible[index]),
                          onDelete: () => _removeProduct(visible[index]),
                          onAddToCart: () => _addToCart(visible[index]),
                          resolvedImageUrl: _resolvedImageUrl,
                          moneyFormatter: _money,
                        ),
                      );
                    },
                  ),
                ),
              if (state.hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    child: OutlinedButton.icon(
                      onPressed: state.isLoading
                          ? null
                          : () => _reloadProducts(append: true),
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
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
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

  Widget _buildProductGrid(List<Product> products) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _searchBox()),
        SliverToBoxAdapter(
          child: _categorySelector(
            _homeLayout?.components
                    .firstWhere(
                      (c) => c.type == 'category_filters',
                      orElse: () =>
                          const HomeComponent(type: 'category_filters', categories: []),
                    )
                    .categories ??
                [],
          ),
        ),
        if (products.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _emptyPanel(
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
                    mainAxisExtent: _isAdmin ? 296 : 290,
                  ),
                  itemBuilder: (context, index) => ProductCard(
                    product: products[index],
                    quantity: _cart[products[index].id] ?? 0,
                    isAdmin: _isAdmin,
                    onTap: () => _openProductDetail(products[index]),
                    onEdit: () => _showProductForm(products[index]),
                    onDelete: () => _removeProduct(products[index]),
                    onAddToCart: () => _addToCart(products[index]),
                    resolvedImageUrl: _resolvedImageUrl,
                    moneyFormatter: _money,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBuyerHome(List<Product> products) {
    if (_homeLayout == null ||
        _homeLayout!.components.isEmpty ||
        _category != 'Semua' ||
        _search.isNotEmpty) {
      return _buildProductGrid(products);
    }

    final categories = <String, List<Product>>{};
    for (final p in products) {
      final cat = p.category.isNotEmpty ? p.category : p.needLabel;
      categories.putIfAbsent(cat, () => []).add(p);
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _searchBox()),
        SliverToBoxAdapter(
          child: _categorySelector(
            _homeLayout?.components
                    .firstWhere(
                      (c) => c.type == 'category_filters',
                      orElse: () =>
                          const HomeComponent(type: 'category_filters', categories: []),
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
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _category = entry.key;
                        _categoryFilter = entry.key;
                      });
                      _reloadProducts();
                    },
                    child: const Text('Semua >'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: _isAdmin ? 296 : 290,
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
                      quantity: _cart[entry.value[index].id] ?? 0,
                      isAdmin: _isAdmin,
                      onTap: () => _openProductDetail(entry.value[index]),
                      onEdit: () => _showProductForm(entry.value[index]),
                      onDelete: () => _removeProduct(entry.value[index]),
                      onAddToCart: () => _addToCart(entry.value[index]),
                      resolvedImageUrl: _resolvedImageUrl,
                      moneyFormatter: _money,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoriesTab() {
    final categories = [
      {'label': 'Bahan Pokok', 'icon': Icons.rice_bowl_outlined, 'color': const Color(0xFFEAF4E7)},
      {'label': 'Makanan', 'icon': Icons.fastfood_outlined, 'color': const Color(0xFFFFF8E1)},
      {'label': 'Minuman', 'icon': Icons.local_drink_outlined, 'color': const Color(0xFFE0F7FA)},
      {'label': 'Protein', 'icon': Icons.egg_alt_outlined, 'color': const Color(0xFFFFF3E0)},
      {'label': 'Perawatan Diri', 'icon': Icons.spa_outlined, 'color': const Color(0xFFE3F2FD)},
      {'label': 'Rumah Tangga', 'icon': Icons.home_outlined, 'color': const Color(0xFFF3E5F5)},
      {'label': 'Daily need', 'icon': Icons.star_outline_rounded, 'color': const Color(0xFFE0F2F1)},
      {'label': 'Daily essentials', 'icon': Icons.local_mall_outlined, 'color': const Color(0xFFFCE4EC)},
    ];

    if (_selectedCategoryInTab != null) {
      final categoryName = _selectedCategoryInTab!;
      final categoryProducts = _products.state.products.where((p) {
        if (categoryName == 'Daily need') return p.needType == 'daily_need';
        if (categoryName == 'Daily essentials') return p.needType == 'daily_essentials';
        return p.category == categoryName || p.needLabel == categoryName;
      }).toList();

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategoryInTab = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kategori: $categoryName',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: categoryProducts.isEmpty
                ? _emptyPanel(
                    'Belum ada produk di kategori ini',
                    'Produk untuk $categoryName akan muncul di sini.',
                    Icons.inventory_2_outlined,
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    itemCount: categoryProducts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 13,
                      crossAxisSpacing: 13,
                      mainAxisExtent: _isAdmin ? 296 : 290,
                    ),
                    itemBuilder: (context, index) => ProductCard(
                      product: categoryProducts[index],
                      quantity: _cart[categoryProducts[index].id] ?? 0,
                      isAdmin: _isAdmin,
                      onTap: () => _openProductDetail(categoryProducts[index]),
                      onEdit: () => _showProductForm(categoryProducts[index]),
                      onDelete: () => _removeProduct(categoryProducts[index]),
                      onAddToCart: () => _addToCart(categoryProducts[index]),
                      resolvedImageUrl: _resolvedImageUrl,
                      moneyFormatter: _money,
                    ),
                  ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        Text(
          'Kategori Produk',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
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
              title: Text(cat['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                setState(() {
                  _selectedCategoryInTab = cat['label'] as String;
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _homeComponent(HomeComponent component) {
    switch (component.type) {
      case 'hero_banner':
        return _heroBanner(component);
      case 'search_field':
        return _searchBox();
      case 'category_filters':
        return _categorySelector(component.categories);
      default:
        return _inlineError(
          'Komponen beranda "${component.type}" belum didukung aplikasi.',
        );
    }
  }

  Widget _heroBanner(HomeComponent component) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardAll,
        gradient: const LinearGradient(
          colors: [AppColors.primaryActive, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  component.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.local_grocery_store_rounded,
            color: Colors.white.withValues(alpha: 0.9),
            size: 54,
          ),
        ],
      ),
    );
  }

  Widget _searchBox() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submitProductSearch(),
            decoration: InputDecoration(
              hintText: 'Cari beras, minyak, kebutuhan rumah...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _search = '';
                        _submitProductSearch();
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.controlAll,
            ),
          ),
          onPressed: _submitProductSearch,
          child: const Text('Cari'),
        ),
      ],
    ),
  );

  void _submitProductSearch() {
    setState(() {
      _search = _searchController.text.trim();
    });
    _reloadProducts();
  }

  Widget _categorySelector(List<HomeCategory> categories) => SizedBox(
    height: 48,
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      scrollDirection: Axis.horizontal,
      children: [
        for (final category in categories)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category.label),
              selected: _category == category.label,
              onSelected: (_) => _selectCategory(category),
            ),
          ),
      ],
    ),
  );



  Widget _buildCart() {
    final items = _knownProducts.values
        .where((product) => (_cart[product.id] ?? 0) > 0)
        .toList();
    final total = CartMath.total(
      items.map((item) => item.priceCents).toList(),
      items.map((item) => _cart[item.id]!).toList(),
    );
    if (items.isEmpty) {
      return _emptyPanel(
        'Keranjangmu masih kosong',
        'Tambahkan kebutuhan harian dari katalog produk.',
        Icons.shopping_bag_outlined,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        _adminHeading('Keranjang belanja'),
        for (final product in items) _cartItem(product),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _summaryRow('Jumlah barang', '$_cartCount item'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Metode pembayaran'),
                    DropdownButton<String>(
                      value: _selectedPaymentMethod,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'COD',
                          child: Text('COD (Bayar di Tempat)'),
                        ),
                        DropdownMenuItem(
                          value: 'MIDTRANS',
                          child: Text('Midtrans VA (BCA)'),
                        ),
                        DropdownMenuItem(
                          value: 'MIDTRANS_QRIS',
                          child: Text('Midtrans QRIS'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPaymentMethod = val);
                        }
                      },
                    ),
                  ],
                ),
                const Divider(height: 24),
                _summaryRow('Total pembayaran', _money(total), bold: true),
                const SizedBox(height: 18),
                _primaryButton(
                  label: 'Lanjut checkout',
                  onPressed: () => _checkout([
                    for (final product in items)
                      {
                        'product_id': product.id,
                        'quantity': _cart[product.id]!,
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

  Widget _cartItem(Product product) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryBg,
              borderRadius: AppRadius.controlAll,
            ),
            child: const Icon(
              Icons.shopping_basket_outlined,
              color: AppColors.primary,
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
                Text(_money(product.priceCents)),
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
                onPressed: () => _changeQuantity(product, -1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(
                width: 24,
                child: Text(
                  '${_cart[product.id]}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _changeQuantity(product, 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildOrders() {
    return AnimatedBuilder(
      animation: _orders,
      builder: (context, _) {
        final state = _orders.state;
        if (state.isLoading && state.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null && state.orders.isEmpty) {
          return _emptyPanel(
            'Belum ada pesanan',
            'Pesanan yang dibuat akan tampil di sini.',
            Icons.receipt_long_outlined,
          );
        }

        final now = DateTime.now();
        final visibleOrders = state.orders.where((order) {
          if (_orderDateFilter == 'today') {
            return order.createdAt.year == now.year &&
                order.createdAt.month == now.month &&
                order.createdAt.day == now.day;
          }
          if (_orderDateFilter == 'month') {
            return order.createdAt.year == now.year &&
                order.createdAt.month == now.month;
          }
          if (_orderDateFilter == 'year') {
            return order.createdAt.year == now.year;
          }
          if (_orderDateFilter == 'custom' && _customFilterDate != null) {
            return order.createdAt.year == _customFilterDate!.year &&
                order.createdAt.month == _customFilterDate!.month &&
                order.createdAt.day == _customFilterDate!.day;
          }
          return true;
        }).toList();

        return RefreshIndicator(
          onRefresh: _reloadOrders,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              _adminHeading(_isAdmin ? 'Kelola pesanan' : 'Pesanan saya'),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _orderDateFilter,
                decoration: const InputDecoration(
                  labelText: 'Filter Berdasarkan Tanggal',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('Semua Tanggal'),
                  ),
                  const DropdownMenuItem(
                    value: 'today',
                    child: Text('Hari Ini'),
                  ),
                  const DropdownMenuItem(
                    value: 'month',
                    child: Text('Bulan Ini'),
                  ),
                  const DropdownMenuItem(
                    value: 'year',
                    child: Text('Tahun Ini'),
                  ),
                  DropdownMenuItem(
                    value: 'custom',
                    child: Text(
                      _customFilterDate != null
                          ? 'Pilih: ${DateFormat('dd MMM yyyy').format(_customFilterDate!)}'
                          : 'Pilih Tanggal Khusus...',
                    ),
                  ),
                ],
                onChanged: (value) async {
                  if (value == null) return;
                  if (value == 'custom') {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _customFilterDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _customFilterDate = picked;
                        _orderDateFilter = 'custom';
                      });
                    }
                  } else {
                    setState(() {
                      _orderDateFilter = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              if (state.error != null) _inlineError(state.error!),
              if (visibleOrders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(
                    child: Text('Tidak ada pesanan pada rentang waktu ini.'),
                  ),
                )
              else
                for (final order in visibleOrders)
                  OrderCard(
                    order: order,
                    isAdmin: _isAdmin,
                    moneyFormatter: _money,
                    onShowMidtransDetails: () => _showMidtransDetailsDialog(order),
                    onBuyAgain: () => _buyAgain(order),
                    onUpdateStatus: (val) => _updateOrderStatus(order.id, val),
                    onSimulatePayment: () => _simulatePayment(order),
                  ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildCustomers() {
    if (_panelLoading && _customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_panelError != null && _customers.isEmpty) {
      return _errorPanel(_panelError!, _loadCustomers);
    }
    return RefreshIndicator(
      onRefresh: _loadCustomers,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          _adminHeading('Pelanggan'),
          if (_panelError != null) _inlineError(_panelError!),
          if (_customers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Text('Belum ada pelanggan terdaftar.'),
            ),
          for (final customer in _customers)
            Card(
              margin: const EdgeInsets.only(bottom: 9),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(customer.name.isEmpty ? '?' : customer.name[0]),
                ),
                title: Text(customer.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        customer.email,
                        customer.phone,
                      ].where((item) => item.isNotEmpty).join(' · '),
                    ),
                    if (customer.formattedAddress.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Alamat: ${customer.formattedAddress}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  tooltip: 'Edit pelanggan & alamat',
                  onPressed: () => _editCustomer(customer),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReports() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        _adminHeading('Ringkasan penjualan'),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'month', label: Text('Bulanan')),
            ButtonSegment(value: 'year', label: Text('Tahunan')),
          ],
          selected: {_reportPeriod},
          onSelectionChanged: (selection) {
            setState(() {
              _reportPeriod = selection.first;
              _reportValue = _reportPeriod == 'month'
                  ? DateFormat('yyyy-MM').format(DateTime.now())
                  : DateFormat('yyyy').format(DateTime.now());
            });
            _loadReport();
          },
        ),
        const SizedBox(height: 14),
        if (_reportPeriod == 'month')
          OutlinedButton.icon(
            onPressed: _chooseReportMonth,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(_reportValue),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: _reportValue,
            decoration: const InputDecoration(labelText: 'Tahun laporan'),
            items: [
              for (
                var year = DateTime.now().year;
                year >= DateTime.now().year - 4;
                year--
              )
                DropdownMenuItem(value: '$year', child: Text('$year')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _reportValue = value);
              _loadReport();
            },
          ),
        const SizedBox(height: 14),
        if (_panelLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_panelError != null)
          _inlineError(_panelError!)
        else if (_report != null) ...[
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  'Saldo Midtrans',
                  _money(_report!.midtransRevenueCents),
                  Icons.account_balance_wallet_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCard(
                  'Penjualan COD',
                  _money(_report!.codRevenueCents),
                  Icons.payments_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  'Omzet Total',
                  _money(_report!.revenueCents),
                  Icons.monetization_on_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCard(
                  'Total Pesanan',
                  '${_report!.orderCount}',
                  Icons.receipt_long_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _reportCard(
            title: 'Kategori paling sering dibeli',
            rows: _report!.topCategories,
          ),
          const SizedBox(height: 12),
          _reportCard(
            title: 'Kebutuhan pelanggan',
            rows: _report!.needTypeTotals.map((row) {
              final label = row.label == 'daily_need'
                  ? 'Daily need'
                  : 'Daily essentials';
              return ReportRow(label: label, quantity: row.quantity);
            }).toList(),
          ),
          const SizedBox(height: 20),
          Card(
            color: AppColors.primaryBg,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Penarikan Dana (Withdraw Iris)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tarik saldo hasil penjualan Midtrans langsung ke rekening bank Anda.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _openWithdrawDialog,
                    icon: const Icon(Icons.account_balance_rounded),
                    label: const Text('Input Rekening & Tarik Dana'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ],
      ),
    ),
  );

  Widget _reportCard({required String title, required List<ReportRow> rows}) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (rows.isEmpty) const Text('Belum ada data pada periode ini.'),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(child: Text(row.label)),
                      Text(
                        '${row.quantity} item',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildAccountTab() {
    final state = _orders.state;
    final userOrders = state.orders;

    final totalSpentCents = userOrders
        .where((o) => o.status != 'cancelled')
        .fold<int>(0, (sum, o) => sum + o.totalCents);

    final pendingCount =
        userOrders.where((o) => o.status == 'pending').length;
    final processingCount =
        userOrders.where((o) => o.status == 'processing').length;
    final shippingCount =
        userOrders.where((o) => o.status == 'shipping').length;
    final completedCount =
        userOrders.where((o) => o.status == 'completed').length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryBg,
                  child: Text(
                    _user.name.isEmpty ? '?' : _user.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _user.email,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (_user.phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _user.phone,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit Profil',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _openProfile,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          color: AppColors.primaryBg,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total Pengeluaran',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _money(totalSpentCents),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Total akumulasi belanja Anda di Udayana Market.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Status Transaksi Saya',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statusShortcutCard(
                'Belum Bayar',
                pendingCount,
                Icons.hourglass_top_rounded,
                AppColors.warning,
                () {
                  setState(() => _tabIndex = 3);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statusShortcutCard(
                'Diproses',
                processingCount,
                Icons.inventory_2_outlined,
                AppColors.primary,
                () {
                  setState(() => _tabIndex = 3);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _statusShortcutCard(
                'Dikirim',
                shippingCount,
                Icons.local_shipping_outlined,
                AppColors.primary,
                () {
                  setState(() => _tabIndex = 3);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statusShortcutCard(
                'Selesai',
                completedCount,
                Icons.check_circle_outline,
                AppColors.success,
                () {
                  setState(() => _tabIndex = 3);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Profil Saya'),
                subtitle: const Text('Ubah nama, email, dan kata sandi'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _openProfile,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Alamat Pengiriman Saya'),
                subtitle: const Text('Kelola dan pilih alamat pengiriman'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _openAddressSelectionDialog,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _signOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Keluar dari Akun'),
        ),
      ],
    );
  }

  Widget _statusShortcutCard(
    String title,
    int count,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        borderRadius: AppRadius.cardAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: AppRadius.tagAll,
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adminHeading(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
  );

  Widget _summaryRow(String label, String value, {bool bold = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      Text(
        value,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          color: bold ? AppColors.textPrimary : null,
        ),
      ),
    ],
  );

  Widget _primaryButton({
    required String label,
    required VoidCallback onPressed,
  }) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(label),
    ),
  );

  Widget _statusChip(String status) {
    final (label, color) = switch (status) {
      'pending' => ('Menunggu Pembayaran', const Color(0xFF9A6900)),
      'processing' => ('Diproses', const Color(0xFF9A6900)),
      'shipping' => ('Dikirim', const Color(0xFF0C6AB2)),
      'completed' => ('Selesai', const Color(0xFF167D62)),
      'cancelled' => ('Dibatalkan', const Color(0xFFB42318)),
      _ => ('Menunggu Pembayaran', const Color(0xFF52606D)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.tagAll,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyPanel(String title, String subtitle, IconData icon) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.textTertiary),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );

  Widget _errorPanel(String error, Future<void> Function() retry) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('Tidak dapat memuat data'),
          const SizedBox(height: 6),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    ),
  );

  Widget _inlineError(String message) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: 0.08),
      borderRadius: AppRadius.controlAll,
      border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
    ),
    child: Text(message, style: const TextStyle(color: AppColors.error)),
  );

  Future<void> _syncCartToBackend() async {
    if (!_isGuest && !_isAdmin) {
      try {
        await widget.services.saveCart(_cart);
      } catch (_) {}
    }
  }

  Future<void> _loadCartFromBackend() async {
    if (!_isGuest && !_isAdmin) {
      try {
        final cart = await widget.services.getCart();
        if (mounted) {
          setState(() {
            _cart.clear();
            _cart.addAll(cart);
          });
        }
      } catch (_) {}
    }
  }

  void _addToCart(Product product) {
    if ((_cart[product.id] ?? 0) >= product.stock) {
      _showMessage('Jumlah melebihi stok tersedia.');
      return;
    }
    setState(
      () => _cart.update(product.id, (count) => count + 1, ifAbsent: () => 1),
    );
    _syncCartToBackend();
  }

  void _changeQuantity(Product product, int delta) {
    setState(() {
      final next = (_cart[product.id] ?? 0) + delta;
      if (next <= 0) {
        _cart.remove(product.id);
      } else if (next <= product.stock) {
        _cart[product.id] = next;
      } else {
        _showMessage('Jumlah melebihi stok tersedia.');
      }
    });
    _syncCartToBackend();
  }

  Future<void> _openProfile() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProfilePage(services: widget.services, user: _user),
      ),
    );
  }

  Future<void> _openAddressDialog() async {
    await _openAddressSelectionDialog();
  }

  Future<void> _openAddressSelectionDialog() async {
    if (_isGuest) {
      _showMessage('Silakan masuk atau daftar terlebih dahulu.');
      if (await _openLogin() && mounted) await _openAddressSelectionDialog();
      return;
    }

    try {
      List<Map<String, dynamic>> addresses = [];
      try {
        final rawList = await widget.services.listAddresses();
        addresses = rawList.map((item) => item as Map<String, dynamic>).toList();
      } catch (_) {
        if (_user.hasAddress) {
          addresses = [
            {
              'id': 0,
              'label': 'Utama (Profil)',
              'recipient_name': _user.name,
              'phone': _user.phone,
              'address': _user.address,
              'province': _user.province,
              'city': _user.city,
              'district': _user.district,
              'subdistrict': _user.subdistrict,
              'rt_rw': _user.rtRw,
              'postal_code': _user.postalCode,
              'is_default': true,
            }
          ];
        }
      }
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pilih Alamat Pengiriman',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _openAddAddressDialog();
                          await _openAddressSelectionDialog();
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Tambah'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (addresses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Belum ada alamat tersimpan. Silakan tambah alamat baru.',
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 320,
                      child: ListView.builder(
                        itemCount: addresses.length,
                        itemBuilder: (context, index) {
                          final addr = addresses[index];
                          final fullAddr = [
                            addr['address'],
                            if (addr['rt_rw'] != null &&
                                addr['rt_rw'].toString().isNotEmpty)
                              'RT/RW ${addr['rt_rw']}',
                            if (addr['subdistrict'] != null &&
                                addr['subdistrict'].toString().isNotEmpty)
                              'Kel. ${addr['subdistrict']}',
                            if (addr['district'] != null &&
                                addr['district'].toString().isNotEmpty)
                              'Kec. ${addr['district']}',
                            addr['city'],
                            addr['province'],
                            addr['postal_code'],
                          ]
                              .where(
                                (s) => s != null && s.toString().isNotEmpty,
                              )
                              .join(', ');

                          final isDefault = addr['is_default'] == true;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text(
                                    addr['label'] ?? 'Rumah',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBg,
                                        borderRadius: AppRadius.tagAll,
                                      ),
                                      child: const Text(
                                        'Utama',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${addr['recipient_name']} (${addr['phone']})',
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    fullAddr,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedShippingAddress =
                                            '$fullAddr [Penerima: ${addr['recipient_name']} - ${addr['phone']}]';
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Pilih'),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (val) async {
                                      if (val == 'default') {
                                        await widget.services
                                            .setDefaultAddress(
                                              addr['id'] as int,
                                            );
                                        Navigator.pop(context);
                                        await _openAddressSelectionDialog();
                                      } else if (val == 'delete') {
                                        await widget.services.deleteAddress(
                                          addr['id'] as int,
                                        );
                                        Navigator.pop(context);
                                        await _openAddressSelectionDialog();
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      if (!isDefault)
                                        const PopupMenuItem(
                                          value: 'default',
                                          child: Text('Jadikan Utama'),
                                        ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Hapus Alamat'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    } on Exception catch (error) {
      if (mounted) _showMessage(error.toString());
    }
  }

  Future<void> _openAddAddressDialog() async {
    final formKey = GlobalKey<FormState>();
    final label = TextEditingController(text: 'Rumah');
    final recipient = TextEditingController(text: _user.name);
    final phone = TextEditingController(text: _user.phone);
    final province = TextEditingController(text: _user.province);
    final city = TextEditingController(text: _user.city);
    final district = TextEditingController(text: _user.district);
    final subdistrict = TextEditingController(text: _user.subdistrict);
    final rtRw = TextEditingController(text: _user.rtRw);
    final postalCode = TextEditingController(text: _user.postalCode);
    final address = TextEditingController(text: _user.address);
    bool isDefault = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tambah Alamat Baru',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  _formField(label, 'Label Alamat (Contoh: Rumah, Kantor)'),
                  Row(
                    children: [
                      Expanded(child: _formField(recipient, 'Nama Penerima')),
                      const SizedBox(width: 8),
                      Expanded(child: _formField(phone, 'Nomor HP')),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _formField(province, 'Provinsi')),
                      const SizedBox(width: 8),
                      Expanded(child: _formField(city, 'Kota / Kabupaten')),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _formField(district, 'Kecamatan')),
                      const SizedBox(width: 8),
                      Expanded(child: _formField(subdistrict, 'Kelurahan')),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _formField(rtRw, 'RT/RW')),
                      const SizedBox(width: 8),
                      Expanded(child: _formField(postalCode, 'Kode Pos')),
                    ],
                  ),
                  _formField(
                    address,
                    'Alamat Lengkap (Jalan, No. Rumah)',
                    maxLines: 2,
                  ),
                  CheckboxListTile(
                    value: isDefault,
                    onChanged: (val) {
                      if (val != null) setModalState(() => isDefault = val);
                    },
                    title: const Text('Jadikan sebagai alamat utama'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: const Text('Simpan Alamat'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (saved != true || !mounted) return;

    try {
      await widget.services.createAddress({
        'label': label.text.trim(),
        'recipient_name': recipient.text.trim(),
        'phone': phone.text.trim(),
        'province': province.text.trim(),
        'city': city.text.trim(),
        'district': district.text.trim(),
        'subdistrict': subdistrict.text.trim(),
        'rt_rw': rtRw.text.trim(),
        'postal_code': postalCode.text.trim(),
        'address': address.text.trim(),
        'is_default': isDefault,
      });
      _showMessage('Alamat baru berhasil ditambahkan.');
    } on Exception catch (error) {
      if (mounted) _showMessage(error.toString());
    }
  }

  Future<void> _openWithdrawDialog() async {
    final formKey = GlobalKey<FormState>();
    String selectedBank = 'bca';
    final accountName = TextEditingController();
    final accountNumber = TextEditingController();
    final amount = TextEditingController();

    final banks = [
      {'code': 'bca', 'label': 'BCA (Bank Central Asia)'},
      {'code': 'mandiri', 'label': 'Bank Mandiri'},
      {'code': 'bni', 'label': 'BNI (Bank Negara Indonesia)'},
      {'code': 'bri', 'label': 'BRI (Bank Rakyat Indonesia)'},
      {'code': 'cimb', 'label': 'CIMB Niaga'},
      {'code': 'permata', 'label': 'Bank Permata'},
      {'code': 'danamon', 'label': 'Bank Danamon'},
    ];

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Penarikan Dana (Withdraw)',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tarik saldo penjualan Midtrans ke rekening bank Admin via Iris Payouts.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: selectedBank,
                    decoration:
                        const InputDecoration(labelText: 'Nama Bank Tujuan'),
                    items: banks
                        .map(
                          (b) => DropdownMenuItem(
                            value: b['code'],
                            child: Text(b['label']!),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedBank = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: accountName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pemilik Rekening',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Nama pemilik rekening wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: accountNumber,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Rekening Bank',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                    validator: (v) {
                      final val = (v ?? '').trim();
                      return val.isEmpty || !RegExp(r'^\d+$').hasMatch(val)
                          ? 'Nomor rekening harus berupa angka'
                          : null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Penarikan (Rp)',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (v) {
                      final val = int.tryParse((v ?? '').trim()) ?? 0;
                      return val < 10000
                          ? 'Minimal penarikan adalah Rp 10.000'
                          : null;
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Tarik Dana via Midtrans Iris'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context, true);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (submitted != true || !mounted) return;

    try {
      final amountValue = int.parse(amount.text.trim());
      final result = await widget.services.withdraw(
        bankName: selectedBank,
        accountName: accountName.text.trim(),
        accountNumber: accountNumber.text.trim(),
        amountCents: amountValue * 100,
      );
      if (!mounted) return;
      final refId = result['reference_id'] as String? ?? '-';
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Penarikan Dana Berhasil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permintaan penarikan sebesar ${_money(amountValue * 100)} telah dikirim ke Midtrans Iris.',
              ),
              const SizedBox(height: 10),
              Text('Bank: ${selectedBank.toUpperCase()}'),
              Text('Pemilik: ${accountName.text.trim()}'),
              Text('No. Rek: ${accountNumber.text.trim()}'),
              const SizedBox(height: 10),
              Text(
                'Reference ID: $refId',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on Exception catch (error) {
      if (mounted) _showMessage(error.toString());
    }
  }

  Future<void> _checkout(List<Map<String, int>> items) async {
    if (_isGuest) {
      _showMessage('Masuk atau daftar untuk melanjutkan checkout.');
      if (await _openLogin() && mounted) await _checkout(items);
      return;
    }
    if (items.isEmpty || _checkoutInProgress) return;

    if (_selectedShippingAddress.isEmpty) {
      _selectedShippingAddress = _user.formattedAddress;
    }

    setState(() => _checkoutInProgress = true);
    try {
      String selectedPaymentMethod = _selectedPaymentMethod;
      final confirm = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Konfirmasi Checkout Pesanan',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.fill,
                      borderRadius: AppRadius.cardAll,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Alamat Tujuan Pengiriman:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context, false);
                                await _openAddressSelectionDialog();
                                if (mounted) await _checkout(items);
                              },
                              child: const Text('Pilih / Ubah'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedShippingAddress.isNotEmpty
                              ? _selectedShippingAddress
                              : _user.formattedAddress,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Metode Pembayaran:',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedPaymentMethod == 'COD'
                            ? AppColors.primary
                            : AppColors.border,
                        width: selectedPaymentMethod == 'COD' ? 1.5 : 1,
                      ),
                      borderRadius: AppRadius.cardAll,
                    ),
                    child: RadioListTile<String>(
                      value: 'COD',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedPaymentMethod = value);
                        }
                      },
                      title: const Text(
                        'COD (Bayar di Tempat)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Bayar tunai kepada kurir saat barang sampai di alamat pengiriman.',
                      ),
                      secondary: const Icon(
                        Icons.payments_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedPaymentMethod == 'MIDTRANS'
                            ? AppColors.primary
                            : AppColors.border,
                        width: selectedPaymentMethod == 'MIDTRANS' ? 1.5 : 1,
                      ),
                      borderRadius: AppRadius.cardAll,
                    ),
                    child: RadioListTile<String>(
                      value: 'MIDTRANS',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedPaymentMethod = value);
                        }
                      },
                      title: const Text(
                        'Midtrans Virtual Account (BCA)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Bayar melalui transfer ATM / M-Banking BCA.',
                      ),
                      secondary: const Icon(
                        Icons.credit_card_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedPaymentMethod == 'MIDTRANS_QRIS'
                            ? AppColors.primary
                            : AppColors.border,
                        width: selectedPaymentMethod == 'MIDTRANS_QRIS' ? 1.5 : 1,
                      ),
                      borderRadius: AppRadius.cardAll,
                    ),
                    child: RadioListTile<String>(
                      value: 'MIDTRANS_QRIS',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedPaymentMethod = value);
                        }
                      },
                      title: const Text(
                        'Midtrans QRIS (Scan QR)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Bayar instan via GoPay, OVO, Dana, ShopeePay, atau M-Banking.',
                      ),
                      secondary: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _primaryButton(
                    label: 'Buat Pesanan & Antar Ke Alamat',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (confirm != true || !mounted) return;
      setState(() => _selectedPaymentMethod = selectedPaymentMethod);
      await _orders.dispatch(
        CheckoutRequested(
          items,
          paymentMethod: selectedPaymentMethod,
          shippingAddress: _selectedShippingAddress.isNotEmpty
              ? _selectedShippingAddress
              : _user.formattedAddress,
        ),
      );
      if (!mounted) return;
      final state = _orders.state;
      if (state.lastOrder != null) {
        setState(() {
          _cart.clear();
          _tabIndex = _isAdmin ? 1 : 2;
        });
        if (state.lastOrder!.paymentMethod.startsWith('MIDTRANS') &&
            state.lastOrder!.midtransResponse.isNotEmpty) {
          await _showMidtransDetailsDialog(state.lastOrder!);
        } else {
          _showMessage('Pesanan #${state.lastOrder!.id} berhasil dibuat.');
        }
        await _reloadProducts();
        await _reloadOrders();
      } else if (state.error != null) {
        _showMessage(state.error!);
      }
    } finally {
      if (mounted) setState(() => _checkoutInProgress = false);
    }
  }

  Future<void> _showMidtransDetailsDialog(Order order) async {
    Map<String, dynamic> resp = order.midtransResponse;
    if (resp.isEmpty) {
      try {
        resp = await widget.services.getPaymentDetails(order.id);
      } catch (_) {}
    }
    final isQris = order.paymentMethod == 'MIDTRANS_QRIS';
    if (resp.isEmpty) {
      resp = isQris
          ? {
              'status_message': 'Menunggu pembayaran QRIS',
              'qr_string':
                  '00020101021226680016ID.CO.QRIS.WWW011893600914300000000053033605802ID5910Udayana6005Bali6304',
            }
          : {
              'status_message': 'Menunggu pembayaran Virtual Account',
              'va_numbers': [
                {
                  'bank': 'bca',
                  'va_number': '828000${order.id.toString().padLeft(8, '0')}',
                },
              ],
            };
    }

    final vaNumbers = resp['va_numbers'] as List<dynamic>?;
    final vaNumber = vaNumbers != null && vaNumbers.isNotEmpty
        ? (vaNumbers.first as Map<String, dynamic>)['va_number']?.toString()
        : '828000${order.id.toString().padLeft(8, '0')}';
    final bank = vaNumbers != null && vaNumbers.isNotEmpty
        ? (vaNumbers.first as Map<String, dynamic>)['bank']?.toString()
        : 'bca';

    final actions = resp['actions'] as List<dynamic>?;
    final qrAction = actions?.firstWhere(
      (a) => (a as Map<String, dynamic>)['name'] == 'generate-qr-code',
      orElse: () => null,
    ) as Map<String, dynamic>?;
    final qrUrl = qrAction?['url'] as String?;
    final qrString =
        resp['qr_string'] as String? ??
        '00020101021226680016ID.CO.QRIS.WWW011893600914300000000053033605802ID5910Udayana6005Bali6304';

    final itemSummary = order.items
        .map((item) => '${item.quantity}x ${item.productName}')
        .join(', ');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isQris ? 'Pembayaran Midtrans QRIS' : 'Pembayaran Virtual Account',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nominal Pembayaran:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _money(order.totalCents),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Item / Barang:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                itemSummary.isEmpty ? 'Pesanan #${order.id}' : itemSummary,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Divider(height: 24),
              if (isQris) ...[
                const Text(
                  'Silakan scan QRIS di bawah ini untuk melakukan pembayaran:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (qrUrl != null)
                  Center(
                    child: ClipRRect(
                      borderRadius: AppRadius.cardAll,
                      child: Image.network(
                        qrUrl,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Text('QR Code tidak dapat dimuat'),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.fill,
                        borderRadius: AppRadius.cardAll,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.qr_code_2_rounded,
                            size: 56,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            qrString,
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ] else ...[
                Text(
                  'Silakan salin nomor Virtual Account (${bank?.toUpperCase() ?? 'BCA'}) di bawah ini untuk melakukan pembayaran:',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: AppRadius.cardAll,
                    border: Border.all(color: AppColors.primaryBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          vaNumber ??
                              '828000${order.id.toString().padLeft(8, '0')}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Salin No. VA',
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        onPressed: () {
                          final numberToCopy =
                              vaNumber ??
                              '828000${order.id.toString().padLeft(8, '0')}';
                          Clipboard.setData(
                            ClipboardData(text: numberToCopy),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Nomor Virtual Account berhasil disalin!',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _buyAgain(Order order) async {
    setState(() {
      for (final item in order.items) {
        _cart.update(
          item.productId,
          (quantity) => quantity + item.quantity,
          ifAbsent: () => item.quantity,
        );
        _knownProducts.putIfAbsent(
          item.productId,
          () => Product(
            id: item.productId,
            name: item.productName,
            description: '',
            category: 'Lainnya',
            needType: 'daily_need',
            priceCents: item.priceCents,
            stock: 99,
            imageUrl: '',
            active: true,
          ),
        );
      }
      _tabIndex = 2;
    });
    await _syncCartToBackend();
    _showMessage('Pesanan ditambahkan ke keranjang.');
  }

  Future<void> _simulatePayment(Order order) async {
    try {
      await widget.services.simulatePayment(order.id);
      _showMessage(
        'Simulasi pembayaran sukses untuk Pesanan #${order.id}.',
      );
      await _reloadOrders();
    } on Exception catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _updateOrderStatus(int id, String status) async {
    await _orders.dispatch(OrderStatusChangeRequested(id, status));
    if (_orders.state.error != null) _showMessage(_orders.state.error!);
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _panelLoading = true;
      _panelError = null;
    });
    try {
      final customers = await widget.services.loadCustomers();
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _panelLoading = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _panelError = error.toString();
        _panelLoading = false;
      });
    }
  }

  Future<void> _editCustomer(Customer customer) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: customer.name);
    final phone = TextEditingController(text: customer.phone);
    final province = TextEditingController(text: customer.province);
    final city = TextEditingController(text: customer.city);
    final district = TextEditingController(text: customer.district);
    final subdistrict = TextEditingController(text: customer.subdistrict);
    final rtRw = TextEditingController(text: customer.rtRw);
    final postalCode = TextEditingController(text: customer.postalCode);
    final address = TextEditingController(text: customer.address);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit pelanggan & alamat'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Nomor telepon'),
                  validator: (value) => (value?.length ?? 0) > 40
                      ? 'Nomor telepon terlalu panjang'
                      : null,
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: province,
                        decoration:
                            const InputDecoration(labelText: 'Provinsi'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: city,
                        decoration:
                            const InputDecoration(labelText: 'Kota/Kab'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: district,
                        decoration:
                            const InputDecoration(labelText: 'Kecamatan'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: subdistrict,
                        decoration:
                            const InputDecoration(labelText: 'Kelurahan'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: rtRw,
                        decoration: const InputDecoration(labelText: 'RT/RW'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: postalCode,
                        decoration:
                            const InputDecoration(labelText: 'Kode Pos'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: address,
                  decoration:
                      const InputDecoration(labelText: 'Alamat Detail'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) {
      return;
    }
    try {
      await widget.services.updateCustomer(
        customer.id,
        name: name.text.trim(),
        phone: phone.text.trim(),
        province: province.text.trim(),
        city: city.text.trim(),
        district: district.text.trim(),
        subdistrict: subdistrict.text.trim(),
        rtRw: rtRw.text.trim(),
        postalCode: postalCode.text.trim(),
        address: address.text.trim(),
      );
      await _loadCustomers();
      if (mounted) {
        _showMessage(_panelError ?? 'Data pelanggan berhasil diperbarui.');
      }
    } on Exception catch (error) {
      if (mounted) _showMessage(error.toString());
    }
  }

  Future<void> _loadHomeLayout() async {
    try {
      final layout = await widget.services.loadHomeLayout();
      if (!mounted) return;
      setState(() {
        _homeLayout = layout;
        _homeLayoutError = null;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _homeLayoutError = error.toString());
    }
  }

  Future<void> _loadReport() async {
    setState(() {
      _panelLoading = true;
      _panelError = null;
    });
    try {
      final report = await widget.services.loadReport(
        _reportPeriod,
        _reportValue,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _panelLoading = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _panelError = error.toString();
        _panelLoading = false;
      });
    }
  }

  Future<void> _chooseReportMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse('$_reportValue-01') ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (selected == null) return;
    setState(() => _reportValue = DateFormat('yyyy-MM').format(selected));
    _loadReport();
  }

  Future<void> _showProductForm([Product? product]) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: product?.name ?? '');
    final description = TextEditingController(text: product?.description ?? '');
    final categories = [
      'Bahan Pokok',
      'Makanan',
      'Minuman',
      'Protein',
      'Perawatan Diri',
      'Rumah Tangga',
      'Lainnya',
    ];
    var selectedCategory = categories.contains(product?.category)
        ? product!.category
        : categories.first;
    if (product != null &&
        product.category.isNotEmpty &&
        !categories.contains(product.category)) {
      categories.add(product.category);
      selectedCategory = product.category;
    }
    final priceInRupiah = product == null ? 0.0 : product.priceCents / 100;
    final price = TextEditingController(
      text: product == null
          ? ''
          : priceInRupiah.toStringAsFixed(
              priceInRupiah.truncateToDouble() == priceInRupiah ? 0 : 2,
            ),
    );
    final stock = TextEditingController(text: product?.stock.toString() ?? '');
    var needType = product?.needType ?? 'daily_need';
    var imageUrl = product?.imageUrl ?? '';
    XFile? selectedImage;
    Uint8List? selectedImageBytes;
    var isSaving = false;
    final saved = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            widthFactor: 1,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 620,
                maxHeight: MediaQuery.sizeOf(context).height * .88,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        product == null ? 'Tambah produk' : 'Edit produk',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 18),
                      _formField(name, 'Nama produk'),
                      _formField(description, 'Deskripsi'),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori Produk',
                        ),
                        items: categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      _formField(
                        price,
                        'Harga (rupiah)',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        allowDecimal: true,
                      ),
                      _formField(
                        stock,
                        'Stok',
                        keyboardType: TextInputType.number,
                      ),
                      OutlinedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                try {
                                  final image = await ImagePicker().pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 85,
                                    maxWidth: 1600,
                                    maxHeight: 1600,
                                  );
                                  if (image == null) return;
                                  final bytes = await image.readAsBytes();
                                  if (!context.mounted) return;
                                  if (bytes.length > 10 * 1024 * 1024) {
                                    _showMessage('Ukuran foto maksimal 10 MB.');
                                    return;
                                  }
                                  setSheetState(() {
                                    selectedImage = image;
                                    selectedImageBytes = bytes;
                                  });
                                } on Exception catch (error) {
                                  if (context.mounted) {
                                    _showMessage(
                                      'Foto tidak dapat dipilih: $error',
                                    );
                                  }
                                }
                              },
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(
                          selectedImage == null
                              ? 'Pilih foto produk'
                              : 'Ganti foto produk',
                        ),
                      ),
                      if (selectedImageBytes != null ||
                          imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: AppRadius.controlAll,
                          child: AspectRatio(
                            aspectRatio: 2,
                            child: selectedImageBytes != null
                                ? Image.memory(
                                    selectedImageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    _resolvedImageUrl(imageUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Icon(Icons.broken_image_outlined),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: needType,
                        decoration: const InputDecoration(
                          labelText: 'Jenis kebutuhan',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'daily_need',
                            child: Text('Daily need'),
                          ),
                          DropdownMenuItem(
                            value: 'daily_essentials',
                            child: Text('Daily essentials'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() => needType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    setSheetState(() => isSaving = true);
                                    try {
                                      if (selectedImage != null &&
                                          selectedImageBytes != null) {
                                        try {
                                          imageUrl = await _products.uploadImage(
                                            selectedImage!.name,
                                            selectedImageBytes!,
                                          );
                                        } catch (_) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Gagal unggah foto ke S3. Menyimpan produk tanpa foto.',
                                                ),
                                              ),
                                            );
                                          }
                                          imageUrl = product?.imageUrl ?? '';
                                        }
                                      }
                                      if (!context.mounted) return;
                                      final priceCents =
                                          (double.parse(price.text.trim()) *
                                                  100)
                                              .round();
                                      final stockValue = int.parse(
                                        stock.text.trim(),
                                      );
                                      Navigator.pop(
                                        context,
                                        Product(
                                          id: product?.id ?? 0,
                                          name: name.text.trim(),
                                          description: description.text.trim(),
                                          category: selectedCategory,
                                          needType: needType,
                                          priceCents: priceCents,
                                          stock: stockValue,
                                          imageUrl: imageUrl,
                                          active: true,
                                        ),
                                      );
                                    } on Exception catch (error) {
                                      if (context.mounted) {
                                        setSheetState(() => isSaving = false);
                                        _showMessage(error.toString());
                                      }
                                    }
                                  },
                            child: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Simpan'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    name.dispose();
    description.dispose();
    price.dispose();
    stock.dispose();
    if (saved == null || !mounted) return;
    await _products.dispatch(ProductSaveRequested(saved, id: product?.id));
    if (_products.state.error != null) _showMessage(_products.state.error!);
  }

  Widget _formField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool allowDecimal = false,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Wajib diisi';
        if (keyboardType != null) {
          final parsed = allowDecimal
              ? double.tryParse(value.trim())
              : int.tryParse(value.trim());
          if (parsed == null || parsed < 0) return 'Masukkan angka valid';
        }
        return null;
      },
    ),
  );

  Future<void> _removeProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text('${product.name} tidak akan tampil lagi di katalog.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _products.dispatch(ProductRemoveRequested(product.id));
    if (_products.state.error != null) _showMessage(_products.state.error!);
  }

  Future<void> _openProductDetail(Product product) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (pageContext) => ProductDetailPage(
          product: product,
          imageUrl: _resolvedImageUrl(product.imageUrl),
          isAdmin: _isAdmin,
          onAddToCart: () {
            _addToCart(product);
            _showSwalAddToCartSuccess(pageContext, product, () {
              Navigator.of(pageContext).pop();
              setState(() {
                _tabIndex = 2;
              });
            });
          },
        ),
      ),
    );
  }

  void _showSwalAddToCartSuccess(
    BuildContext pageContext,
    Product product,
    VoidCallback onViewCart,
  ) {
    showDialog<void>(
      context: pageContext,
      builder: (dialogContext) => Dialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.overlayAll),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 52,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Berhasil Ditambahkan!',
                style: Theme.of(pageContext)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${product.name} telah berhasil masuk ke keranjang belanja Anda.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.controlAll,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Lanjut Belanja'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.controlAll,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        onViewCart();
                      },
                      child: const Text('Lihat Keranjang'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolvedImageUrl(String imageUrl) =>
      imageUrl.isEmpty ? '' : widget.services.api.resolveUrl(imageUrl);

  Future<bool> _openLogin() async {
    final session = await Navigator.of(context).push<AuthSession>(
      MaterialPageRoute<AuthSession>(
        builder: (_) => LoginPage(services: widget.services),
      ),
    );
    if (session == null) return false;
    await _acceptSession(session);
    return true;
  }

  Future<void> _openRegister() async {
    final session = await Navigator.of(context).push<AuthSession>(
      MaterialPageRoute<AuthSession>(
        builder: (_) => RegisterPage(services: widget.services),
      ),
    );
    if (session != null) await _acceptSession(session);
  }

  Future<void> _acceptSession(AuthSession session) async {
    SessionStorage.save(token: session.token, user: session.user);
    if (!mounted) return;
    if (session.user.isAdmin) {
      _resetProductFilters();
      setState(() {
        _homeLayout = null;
        _homeLayoutError = null;
        _user = session.user;
        _tabIndex = 0;
      });
    } else {
      setState(() {
        _user = session.user;
        _tabIndex = 0;
      });
      await _loadHomeLayout();
    }
    await _loadCartFromBackend();
    await _reloadProducts();
    await _reloadOrders();
  }

  Future<void> _signOut() async {
    widget.services.api.token = null;
    await SessionStorage.clear();
    if (!mounted) return;
    _resetProductFilters();
    setState(() {
      _user = const AppUser(
        id: 0,
        name: 'Tamu',
        email: '',
        role: 'guest',
        phone: '',
      );
      _homeLayout = null;
      _homeLayoutError = null;
      _cart.clear();
      _tabIndex = 0;
    });
    _loadHomeLayout();
    await _reloadProducts();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _money(int cents) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(cents / 100);

  void _resetProductFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    _search = '';
    _category = 'Semua';
    _categoryFilter = '';
    _needTypeFilter = '';
  }
}
