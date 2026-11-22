import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
import '../../../orders/domain/entities/shipping.dart';
import '../../../orders/presentation/state/order_controller.dart';
import '../../../orders/presentation/state/order_event.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/state/product_controller.dart';
import '../../../products/presentation/state/product_event.dart';
import '../../domain/entities/home_layout.dart';
import '../views/account_view.dart';
import '../views/admin_views.dart';
import '../views/cart_view.dart';
import '../views/categories_view.dart';
import '../views/home_view.dart';
import '../views/orders_view.dart';
import '../views/view_helpers.dart';
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
  String? _selectedHomeCategoryAll;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _reportPeriod = 'month';
  String _reportValue = DateFormat('yyyy-MM').format(DateTime.now());
  String _orderDateFilter = 'all';
  String _orderStatusFilter = 'all';
  DateTime? _customFilterDate;
  List<Customer> _customers = const [];
  SalesReport? _report;
  HomeLayout? _homeLayout;
  String? _panelError;
  bool _panelLoading = false;
  bool _checkoutInProgress = false;
  String _selectedPaymentMethod = 'COD';
  String _selectedShippingAddress = '';
  String _selectedCity = '';
  String _selectedDistrict = '';
  ShippingQuote? _shippingQuote;
  final List<Product> _recentlyViewed = [];
  bool _shippingQuoteLoading = false;
  ShippingConfig? _shippingConfig;
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
      widget.services.requestOrderCancellation,
    );
    _reloadProducts();
    if (!_isGuest) {
      _selectedCity = _user.city;
      _selectedDistrict = _user.district;
      _reloadOrders();
      _loadCartFromBackend();
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshShippingQuote());
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

  Future<void> _refreshShippingQuote() async {
    if (_isGuest) return;
    if (_selectedCity.trim().isEmpty && _selectedDistrict.trim().isEmpty) {
      if (mounted) setState(() => _shippingQuote = null);
      return;
    }
    if (mounted) setState(() => _shippingQuoteLoading = true);
    try {
      final quote = await widget.services.shippingQuote(
        _selectedCity,
        _selectedDistrict,
      );
      if (!mounted) return;
      setState(() => _shippingQuote = quote);
    } catch (_) {
      if (!mounted) return;
      setState(() => _shippingQuote = null);
    } finally {
      if (mounted) setState(() => _shippingQuoteLoading = false);
    }
  }

  int get _shippingFeeCents => _shippingQuote?.feeCents ?? 0;

  String get _shippingFeeLabel {
    if (_shippingQuoteLoading) return 'Menghitung...';
    if (_shippingQuote == null) return 'Pilih alamat tujuan';
    if (_shippingQuote!.distanceKm > 0) {
      return '${_money(_shippingQuote!.feeCents)} • ${_shippingQuote!.distanceKm.toStringAsFixed(1)} km';
    }
    return _money(_shippingQuote!.feeCents);
  }

  List<String> get _tabs => _isAdmin
      ? const ['Produk', 'Pesanan', 'Pelanggan', 'Laporan', 'Ongkir']
      : _isGuest
      ? const ['Belanja', 'Kategori', 'Keranjang']
      : const ['Belanja', 'Kategori', 'Keranjang', 'Pesanan', 'Akun'];

  List<Widget> get _pages => _isAdmin
      ? [
          HomeView(
            productsController: _products,
            isAdmin: _isAdmin,
            cart: _cart,
            knownProducts: _knownProducts,
            homeLayout: _homeLayout,
            category: _category,
            search: _search,
            searchController: _searchController,
            selectedHomeCategoryAll: _selectedHomeCategoryAll,
            onSearchChanged: _onProductSearchChanged,
            onSearchSubmitted: _submitProductSearch,
            onSelectCategory: _selectCategory,
            onReloadProducts: _reloadProducts,
            onOpenProductDetail: _openProductDetail,
            onShowProductForm: _showProductForm,
            onRemoveProduct: _removeProduct,
            onAddToCart: _addToCart,
            onSelectHomeCategoryAll: (val) =>
                setState(() => _selectedHomeCategoryAll = val),
            resolvedImageUrl: _resolvedImageUrl,
            moneyFormatter: _money,
          ),
          OrdersView(
            ordersController: _orders,
            isAdmin: _isAdmin,
            orderDateFilter: _orderDateFilter,
            orderStatusFilter: _orderStatusFilter,
            customFilterDate: _customFilterDate,
            onOrderDateFilterChanged: (val) =>
                setState(() => _orderDateFilter = val),
            onCustomFilterDateSelected: (val) => setState(() {
              _customFilterDate = val;
              if (val != null) _orderDateFilter = 'custom';
            }),
            onOrderStatusFilterChanged: (val) =>
                setState(() => _orderStatusFilter = val),
            onReloadOrders: _reloadOrders,
            onShowMidtransDetails: _showMidtransDetailsDialog,
            onBuyAgain: _buyAgain,
            onUpdateStatus: _updateOrderStatus,
            onSimulatePayment: _simulatePayment,
            onRequestCancellation: _requestOrderCancellation,
            onApproveCancellation: _approveCancellation,
            onRejectCancellation: _rejectCancellation,
            moneyFormatter: _money,
          ),
          CustomersView(
            panelLoading: _panelLoading,
            panelError: _panelError,
            customers: _customers,
            onLoadCustomers: _loadCustomers,
            onEditCustomer: _editCustomer,
          ),
          ReportsView(
            panelLoading: _panelLoading,
            panelError: _panelError,
            reportPeriod: _reportPeriod,
            reportValue: _reportValue,
            report: _report,
            onPeriodChanged: (val) {
              setState(() {
                _reportPeriod = val;
                _reportValue = val == 'month'
                    ? DateFormat('yyyy-MM').format(DateTime.now())
                    : DateFormat('yyyy').format(DateTime.now());
              });
              _loadReport();
            },
            onReportValueChanged: (val) {
              setState(() => _reportValue = val);
              _loadReport();
            },
            onChooseReportMonth: _chooseReportMonth,
            onLoadReport: _loadReport,
            onOpenWithdrawDialog: _openWithdrawDialog,
            moneyFormatter: _money,
          ),
          ShippingAdminView(
            panelLoading: _panelLoading,
            panelError: _panelError,
            shippingConfig: _shippingConfig,
            onLoadShippingConfig: _loadShippingConfig,
            onEditShippingSettings: _editShippingSettings,
            onEditShippingZone: _editShippingZone,
            onDeleteShippingZone: _deleteShippingZone,
            onEditShippingArea: _editShippingArea,
            onDeleteShippingArea: _deleteShippingArea,
            moneyFormatter: _money,
          ),
        ]
      : _isGuest
      ? [
          HomeView(
            productsController: _products,
            isAdmin: _isAdmin,
            cart: _cart,
            knownProducts: _knownProducts,
            homeLayout: _homeLayout,
            category: _category,
            search: _search,
            searchController: _searchController,
            selectedHomeCategoryAll: _selectedHomeCategoryAll,
            onSearchChanged: _onProductSearchChanged,
            onSearchSubmitted: _submitProductSearch,
            onSelectCategory: _selectCategory,
            onReloadProducts: _reloadProducts,
            onOpenProductDetail: _openProductDetail,
            onShowProductForm: _showProductForm,
            onRemoveProduct: _removeProduct,
            onAddToCart: _addToCart,
            onSelectHomeCategoryAll: (val) =>
                setState(() => _selectedHomeCategoryAll = val),
            resolvedImageUrl: _resolvedImageUrl,
            moneyFormatter: _money,
          ),
          CategoriesView(
            productsController: _products,
            isAdmin: _isAdmin,
            cart: _cart,
            selectedCategoryInTab: _selectedCategoryInTab,
            onSelectCategoryInTab: (val) =>
                setState(() => _selectedCategoryInTab = val),
            onOpenProductDetail: _openProductDetail,
            onShowProductForm: _showProductForm,
            onRemoveProduct: _removeProduct,
            onAddToCart: _addToCart,
            resolvedImageUrl: _resolvedImageUrl,
            moneyFormatter: _money,
          ),
          CartView(
            knownProducts: _knownProducts,
            cart: _cart,
            cartCount: _cartCount,
            shippingFeeCents: _shippingFeeCents,
            shippingFeeLabel: _shippingFeeLabel,
            selectedPaymentMethod: _selectedPaymentMethod,
            onChangeQuantity: _changeQuantity,
            onSelectPaymentMethod: (val) =>
                setState(() => _selectedPaymentMethod = val),
            onShowAllPaymentMethods: _showAllPaymentMethods,
            onCheckout: _checkout,
            resolvedImageUrl: _resolvedImageUrl,
            moneyFormatter: _money,
          ),
        ]
      : [
          HomeView(
            productsController: _products,
            isAdmin: _isAdmin,
            cart: _cart,
            knownProducts: _knownProducts,
            homeLayout: _homeLayout,
            category: _category,
            search: _search,
            searchController: _searchController,
            selectedHomeCategoryAll: _selectedHomeCategoryAll,
            onSearchChanged: _onProductSearchChanged,
            onSearchSubmitted: _submitProductSearch,
            onSelectCategory: _selectCategory,
            onReloadProducts: _reloadProducts,
            onOpenProductDetail: _openProductDetail,
            onShowProductForm: _showProductForm,
            onRemoveProduct: _removeProduct,
            onAddToCart: _addToCart,
            onSelectHomeCategoryAll: (val) =>
                setState(() => _selectedHomeCategoryAll = val),
            resolvedImageUrl: _resolvedImageUrl,
            moneyFormatter: _money,
          ),
          CategoriesView(
            productsController: _products,
            isAdmin: _isAdmin,
            cart: _cart,
            selectedCategoryInTab: _selectedCategoryInTab,
            onSelectCategoryInTab: (val) =>
                setState(() => _selectedCategoryInTab = val),
            onOpenProductDetail: _openProductDetail,
            onShowProductForm: _showProductForm,
            onRemoveProduct: _removeProduct,
            onAddToCart: _addToCart,
            resolvedImageUrl: _resolvedImageUrl,
            moneyFormatter: _money,
          ),
          CartView(
            knownProducts: _knownProducts,
            cart: _cart,
            cartCount: _cartCount,
            shippingFeeCents: _shippingFeeCents,
            shippingFeeLabel: _shippingFeeLabel,
            selectedPaymentMethod: _selectedPaymentMethod,
            onChangeQuantity: _changeQuantity,
            onSelectPaymentMethod: (val) =>
                setState(() => _selectedPaymentMethod = val),
            onShowAllPaymentMethods: _showAllPaymentMethods,
            onCheckout: _checkout,
            resolvedImageUrl: _resolvedImageUrl,
            moneyFormatter: _money,
          ),
          OrdersView(
            ordersController: _orders,
            isAdmin: _isAdmin,
            orderDateFilter: _orderDateFilter,
            orderStatusFilter: _orderStatusFilter,
            customFilterDate: _customFilterDate,
            onOrderDateFilterChanged: (val) =>
                setState(() => _orderDateFilter = val),
            onCustomFilterDateSelected: (val) => setState(() {
              _customFilterDate = val;
              if (val != null) _orderDateFilter = 'custom';
            }),
            onOrderStatusFilterChanged: (val) =>
                setState(() => _orderStatusFilter = val),
            onReloadOrders: _reloadOrders,
            onShowMidtransDetails: _showMidtransDetailsDialog,
            onBuyAgain: _buyAgain,
            onUpdateStatus: _updateOrderStatus,
            onSimulatePayment: _simulatePayment,
            onRequestCancellation: _requestOrderCancellation,
            onApproveCancellation: _approveCancellation,
            onRejectCancellation: _rejectCancellation,
            moneyFormatter: _money,
          ),
          AccountView(
            user: _user,
            orders: _orders.state.orders,
            recentlyViewed: _recentlyViewed,
            cart: _cart,
            isAdmin: _isAdmin,
            onOpenProfile: _openProfile,
            onOpenAddressSelectionDialog: _openAddressSelectionDialog,
            onOpenOrdersWithStatus: _openOrdersWithStatus,
            onOpenProductDetail: _openProductDetail,
            onShowProductForm: _showProductForm,
            onRemoveProduct: _removeProduct,
            onAddToCart: _addToCart,
            onSignOut: _signOut,
            resolvedImageUrl: _resolvedImageUrl,
            moneyFormatter: _money,
          ),
        ];

  void _selectTab(int index) {
    setState(() {
      _tabIndex = index;
      _panelError = null;
    });
    if (_isAdmin && index == 2) _loadCustomers();
    if (_isAdmin && index == 3) _loadReport();
    if (_isAdmin && index == 4) _loadShippingConfig();
    if ((_isAdmin && index == 1) || (!_isAdmin && !_isGuest && index == 3)) {
      _reloadOrders();
    }
    if (!_isAdmin && !_isGuest && index == 2) _refreshShippingQuote();
    if (_tabIndex == 0) _reloadProducts();
  }

  bool _handleBackPress() {
    if (_tabIndex == 0 && _selectedHomeCategoryAll != null) {
      setState(() => _selectedHomeCategoryAll = null);
      return true;
    }
    if (_tabIndex == 1 && _selectedCategoryInTab != null) {
      setState(() => _selectedCategoryInTab = null);
      return true;
    }
    if (_tabIndex > 0) {
      setState(() {
        _selectedHomeCategoryAll = null;
        _selectedCategoryInTab = null;
        _tabIndex = 0;
      });
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final handled = _handleBackPress();
        if (!handled) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
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
      ),
    );
  }

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
            Icons.local_shipping_outlined,
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

  void _submitProductSearch() {
    setState(() {
      _search = _searchController.text.trim();
    });
    _reloadProducts();
  }

  void _showAllPaymentMethods() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Semua Metode Pembayaran',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              for (final method in paymentMethods)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: AppRadius.cardAll,
                    onTap: () {
                      setState(() => _selectedPaymentMethod = method.value);
                      Navigator.pop(sheetContext);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.container,
                        borderRadius: AppRadius.cardAll,
                        border: Border.all(
                          color: _selectedPaymentMethodValue == method.value
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            method.icon,
                            size: 22,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  method.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  method.description,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedPaymentMethodValue == method.value)
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String get _selectedPaymentMethodValue =>
      paymentMethods.any((m) => m.value == _selectedPaymentMethod)
          ? _selectedPaymentMethod
          : paymentMethods.first.value;

  PaymentMethod _methodFor(String value) => paymentMethods.firstWhere(
    (m) => m.value == value,
    orElse: () => paymentMethods.first,
  );

  void _openOrdersWithStatus(String status) {
    setState(() {
      _orderStatusFilter = status;
      _tabIndex = 3;
      _panelError = null;
    });
    _reloadOrders();
  }

  Future<void> _editShippingSettings() async {
    final settings = _shippingConfig?.settings ?? const ShippingSettings();
    final lat = TextEditingController(
      text: settings.originLatitude == 0
          ? ''
          : settings.originLatitude.toString(),
    );
    final lng = TextEditingController(
      text: settings.originLongitude == 0
          ? ''
          : settings.originLongitude.toString(),
    );
    final fee = TextEditingController(
      text: (settings.defaultFeeCents / 100).toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pengaturan ongkir'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: lat,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Latitude titik asal',
                    hintText: 'Contoh: -8.6705',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lng,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Longitude titik asal',
                    hintText: 'Contoh: 115.2126',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: fee,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tarif bawaan (Rp)',
                    hintText: 'Contoh: 10000',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value?.trim() ?? '');
                    if (parsed == null || parsed < 0) return 'Isi tarif yang valid';
                    return null;
                  },
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
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    try {
      await widget.services.updateShippingSettings({
        'origin_latitude': double.tryParse(lat.text.trim()) ?? 0,
        'origin_longitude': double.tryParse(lng.text.trim()) ?? 0,
        'default_fee_cents': ((double.tryParse(fee.text.trim()) ?? 0) * 100)
            .round(),
      });
      await _loadShippingConfig();
      _showMessage('Pengaturan ongkir disimpan.');
    } on Exception catch (error) {
      _showMessage('Gagal menyimpan: $error');
    }
  }

  Future<void> _editShippingZone([ShippingZone? zone]) async {
    final name = TextEditingController(text: zone?.name ?? '');
    final minKm = TextEditingController(
      text: zone == null ? '' : zone.minKm.toStringAsFixed(1),
    );
    final maxKm = TextEditingController(
      text: zone == null ? '' : zone.maxKm.toStringAsFixed(1),
    );
    final fee = TextEditingController(
      text: zone == null ? '' : (zone.feeCents / 100).toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(zone == null ? 'Tambah zona' : 'Ubah zona'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nama zona (opsional)',
                    hintText: 'Contoh: Dalam kota',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: minKm,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Dari (km)'),
                        validator: _numberValidator,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: maxKm,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(labelText: 'Sampai (km)'),
                        validator: _numberValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: fee,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tarif (Rp)'),
                  validator: _numberValidator,
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
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final body = {
      'name': name.text.trim(),
      'min_km': double.tryParse(minKm.text.trim()) ?? 0,
      'max_km': double.tryParse(maxKm.text.trim()) ?? 0,
      'fee_cents': ((double.tryParse(fee.text.trim()) ?? 0) * 100).round(),
    };
    try {
      if (zone == null) {
        await widget.services.createShippingZone(body);
      } else {
        await widget.services.updateShippingZone(zone.id, body);
      }
      await _loadShippingConfig();
      _showMessage('Zona ongkir disimpan.');
    } on Exception catch (error) {
      _showMessage('Gagal menyimpan: $error');
    }
  }

  Future<void> _deleteShippingZone(ShippingZone zone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus zona?'),
        content: Text(
          zone.name.isEmpty
              ? 'Zona ${zone.minKm.toStringAsFixed(1)} - ${zone.maxKm.toStringAsFixed(1)} km akan dihapus.'
              : 'Zona "${zone.name}" akan dihapus.',
        ),
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
    try {
      await widget.services.deleteShippingZone(zone.id);
      await _loadShippingConfig();
      _showMessage('Zona ongkir dihapus.');
    } on Exception catch (error) {
      _showMessage('Gagal menghapus: $error');
    }
  }

  Future<void> _editShippingArea([ShippingArea? area]) async {
    final city = TextEditingController(text: area?.city ?? '');
    final district = TextEditingController(text: area?.district ?? '');
    final lat = TextEditingController(
      text: area == null || area.latitude == 0 ? '' : area.latitude.toString(),
    );
    final lng = TextEditingController(
      text: area == null || area.longitude == 0
          ? ''
          : area.longitude.toString(),
    );
    final fee = TextEditingController(
      text: area == null || area.feeCents == 0
          ? ''
          : (area.feeCents / 100).toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(area == null ? 'Tambah wilayah' : 'Ubah wilayah'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: city,
                  decoration: const InputDecoration(labelText: 'Kota/Kabupaten'),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Kota wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: district,
                  decoration: const InputDecoration(labelText: 'Kecamatan'),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Kecamatan wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: fee,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tarif ongkir (Rp)',
                    hintText: 'Contoh: 15000',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Tarif wajib diisi';
                    final parsed = double.tryParse(text);
                    if (parsed == null || parsed < 0) {
                      return 'Isi tarif yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Koordinat (opsional) — isi hanya jika memakai zona jarak.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lat,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Latitude (opsional)',
                    hintText: 'Contoh: -8.6500',
                  ),
                  validator: _optionalNumberValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lng,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Longitude (opsional)',
                    hintText: 'Contoh: 115.2167',
                  ),
                  validator: _optionalNumberValidator,
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
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final body = {
      'city': city.text.trim(),
      'district': district.text.trim(),
      'fee_cents': ((double.tryParse(fee.text.trim()) ?? 0) * 100).round(),
      'latitude': double.tryParse(lat.text.trim()) ?? 0,
      'longitude': double.tryParse(lng.text.trim()) ?? 0,
    };
    try {
      if (area == null) {
        await widget.services.createShippingArea(body);
      } else {
        await widget.services.updateShippingArea(area.id, body);
      }
      await _loadShippingConfig();
      _showMessage('Wilayah ongkir disimpan.');
    } on Exception catch (error) {
      _showMessage('Gagal menyimpan: $error');
    }
  }

  Future<void> _deleteShippingArea(ShippingArea area) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus wilayah?'),
        content: Text(
          area.district.isEmpty
              ? 'Wilayah "${area.city}" akan dihapus.'
              : 'Wilayah "${area.district}, ${area.city}" akan dihapus.',
        ),
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
    try {
      await widget.services.deleteShippingArea(area.id);
      await _loadShippingConfig();
      _showMessage('Wilayah ongkir dihapus.');
    } on Exception catch (error) {
      _showMessage('Gagal menghapus: $error');
    }
  }

  String? _numberValidator(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0) return 'Isi angka yang valid';
    return null;
  }

  String? _optionalNumberValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0) return 'Isi angka yang valid';
    return null;
  }

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
                                        _selectedCity = (addr['city'] ?? '')
                                            .toString();
                                        _selectedDistrict =
                                            (addr['district'] ?? '').toString();
                                      });
                                      Navigator.pop(context);
                                      _refreshShippingQuote();
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
    if (_selectedCity.isEmpty && _selectedDistrict.isEmpty) {
      _selectedCity = _user.city;
      _selectedDistrict = _user.district;
    }

    setState(() => _checkoutInProgress = true);
    try {
      await _refreshShippingQuote();
      if (!mounted) return;
      final subtotal = CartMath.total(
        items
            .map((item) => _knownProducts[item['product_id']]?.priceCents ?? 0)
            .toList(),
        items.map((item) => item['quantity']!).toList(),
      );
      final total = subtotal + _shippingFeeCents;
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.fill,
                      borderRadius: AppRadius.cardAll,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _methodFor(selectedPaymentMethod).icon,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _methodFor(selectedPaymentMethod).label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _methodFor(selectedPaymentMethod).description,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                      children: [
                        summaryRow('Subtotal', _money(subtotal)),
                        const SizedBox(height: 6),
                        summaryRow('Ongkos kirim', _shippingFeeLabel),
                        const Divider(height: 20),
                        summaryRow(
                          'Total pembayaran',
                          _money(total),
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  primaryButton(
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
          city: _selectedCity,
          district: _selectedDistrict,
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
              const Text(
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
              const Text(
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

  Future<void> _requestOrderCancellation(int orderId, String status) async {
    final isPaid = status == 'processing';
    final formKey = GlobalKey<FormState>();
    String selectedReason = 'Pesanan salah / ingin ubah produk';
    final customReasonCtrl = TextEditingController();
    final bankCtrl = TextEditingController(
      text: _user.bankName.isNotEmpty ? _user.bankName.toLowerCase() : 'bca',
    );
    final nameCtrl = TextEditingController(
      text: _user.accountName.isNotEmpty ? _user.accountName : _user.name,
    );
    final accCtrl = TextEditingController(text: _user.accountNumber);

    final reasons = [
      'Pesanan salah / ingin ubah produk',
      'Salah alamat pengiriman',
      'Menemukan harga lebih murah di tempat lain',
      'Ingin ganti metode pembayaran',
      'Lainnya',
    ];

    final confirmed = await showModalBottomSheet<bool>(
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
                    isPaid ? 'Ajukan Pembatalan & Refund' : 'Batalkan Pesanan',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isPaid
                        ? 'Pesanan ini sudah dibayar. Masukkan alasan pembatalan dan rekening bank Anda untuk pencairan dana otomatis via Midtrans IRIS.'
                        : 'Pilih alasan pembatalan pesanan Anda.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Alasan Pembatalan:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  for (final reason in reasons)
                    RadioListTile<String>(
                      title: Text(reason, style: const TextStyle(fontSize: 13)),
                      value: reason,
                      groupValue: selectedReason,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedReason = val);
                        }
                      },
                    ),
                  if (selectedReason == 'Lainnya') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: customReasonCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Tuliskan alasan pembatalan',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Alasan wajib diisi' : null,
                    ),
                  ],
                  if (isPaid) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Informasi Rekening Bank (untuk Refund):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value:
                          [
                                'bca',
                                'mandiri',
                                'bni',
                                'bri',
                                'permata',
                                'cimb',
                              ].contains(bankCtrl.text.toLowerCase())
                              ? bankCtrl.text.toLowerCase()
                              : 'bca',
                      decoration: const InputDecoration(
                        labelText: 'Nama Bank Refund',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'bca',
                          child: Text('BCA (Bank Central Asia)'),
                        ),
                        DropdownMenuItem(
                          value: 'mandiri',
                          child: Text('Bank Mandiri'),
                        ),
                        DropdownMenuItem(
                          value: 'bni',
                          child: Text('BNI (Bank Negara Indonesia)'),
                        ),
                        DropdownMenuItem(
                          value: 'bri',
                          child: Text('BRI (Bank Rakyat Indonesia)'),
                        ),
                        DropdownMenuItem(
                          value: 'permata',
                          child: Text('Bank Permata'),
                        ),
                        DropdownMenuItem(
                          value: 'cimb',
                          child: Text('CIMB Niaga'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) bankCtrl.text = val;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Pemilik Rekening',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: accCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Rekening',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    onPressed: () {
                      if (selectedReason == 'Lainnya') {
                        if (!formKey.currentState!.validate()) return;
                      }
                      Navigator.pop(context, true);
                    },
                    child: Text(
                      isPaid
                          ? 'Kirim Pengajuan Batal & Refund'
                          : 'Konfirmasi Batalkan Pesanan',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    final finalReason = selectedReason == 'Lainnya'
        ? customReasonCtrl.text.trim()
        : selectedReason;

    await _orders.dispatch(
      OrderCancellationRequested(orderId, {
        'reason': finalReason,
        'bank_name': isPaid ? bankCtrl.text.trim() : '',
        'account_name': isPaid ? nameCtrl.text.trim() : '',
        'account_number': isPaid ? accCtrl.text.trim() : '',
      }),
    );
    if (_orders.state.error != null) {
      _showMessage(_orders.state.error!);
    } else {
      _showMessage(
        isPaid
            ? 'Pengajuan pembatalan & refund terkirim. Menunggu persetujuan admin.'
            : 'Pesanan berhasil diajukan pembatalan.',
      );
      await _reloadOrders();
    }
  }

  Future<void> _approveCancellation(int orderId) async {
    try {
      await widget.services.approveCancellation(orderId);
      _showMessage(
        'Pembatalan disetujui & dana dikembalikan otomatis via Midtrans IRIS.',
      );
      await _reloadOrders();
    } on Exception catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _rejectCancellation(int orderId) async {
    try {
      await widget.services.rejectCancellation(orderId);
      _showMessage('Pengajuan pembatalan ditolak. Pesanan dilanjutkan.');
      await _reloadOrders();
    } on Exception catch (error) {
      _showMessage(error.toString());
    }
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
      });
    } on Exception catch (error) {
      if (!mounted) return;
      // ignore: empty_catches
      setState(() {});
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

  Future<void> _loadShippingConfig() async {
    setState(() {
      _panelLoading = true;
      _panelError = null;
    });
    try {
      final config = await widget.services.loadShippingConfig();
      if (!mounted) return;
      setState(() {
        _shippingConfig = config;
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
    setState(() {
      _recentlyViewed.removeWhere((p) => p.id == product.id);
      _recentlyViewed.insert(0, product);
      if (_recentlyViewed.length > 10) {
        _recentlyViewed.removeLast();
      }
    });

    final catalog = _products.state.products;
    final related = catalog.where((p) => p.id != product.id).toList()
      ..sort((a, b) {
        final aSame = a.category == product.category ? 0 : 1;
        final bSame = b.category == product.category ? 0 : 1;
        return aSame.compareTo(bSame);
      });

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (pageContext) => ProductDetailPage(
          product: product,
          imageUrl: _resolvedImageUrl(product.imageUrl),
          isAdmin: _isAdmin,
          relatedProducts: related.take(10).toList(),
          resolveImageUrl: _resolvedImageUrl,
          quantityOf: (id) => _cart[id] ?? 0,
          onOpenProduct: _openProductDetail,
          onQuickAdd: (item) {
            _addToCart(item);
            ScaffoldMessenger.of(pageContext).showSnackBar(
              SnackBar(
                content: Text('${item.name} ditambahkan ke keranjang.'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          onAddToCart: () {
            _addToCart(product);
            ScaffoldMessenger.of(pageContext).showSnackBar(
              SnackBar(
                content: Text('${product.name} berhasil ditambahkan ke keranjang.'),
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'Keranjang',
                  onPressed: () {
                    Navigator.of(pageContext).pop();
                    setState(() {
                      _tabIndex = 2;
                    });
                  },
                ),
              ),
            );
          },
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
