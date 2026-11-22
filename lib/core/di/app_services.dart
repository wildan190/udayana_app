import '../config/app_config.dart';
import '../network/api_client.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/usecases/change_password.dart';
import '../../features/auth/domain/usecases/register_buyer.dart';
import '../../features/auth/domain/usecases/sign_in.dart';
import '../../features/auth/domain/usecases/update_buyer_address.dart';
import '../../features/orders/data/datasources/order_remote_data_source.dart';
import '../../features/orders/data/repositories/order_repository_impl.dart';
import '../../features/orders/domain/entities/shipping.dart';
import '../../features/orders/domain/usecases/manage_orders.dart';
import '../../features/products/data/datasources/product_remote_data_source.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/usecases/manage_products.dart';
import '../../features/store/data/datasources/home_layout_remote_data_source.dart';
import '../../features/store/data/repositories/home_layout_repository_impl.dart';
import '../../features/store/domain/usecases/load_home_layout.dart';

class AppServices {
  AppServices({String apiBaseUrl = AppConfig.apiBaseUrl, ApiClient? apiClient})
    : api = apiClient ?? ApiClient(baseUrl: apiBaseUrl) {
    final authRepository = AuthRepositoryImpl(AuthRemoteDataSourceImpl(api));
    final productRepository = ProductRepositoryImpl(
      ProductRemoteDataSourceImpl(api),
    );
    final orderRepository = OrderRepositoryImpl(OrderRemoteDataSourceImpl(api));
    final homeLayoutRepository = HomeLayoutRepositoryImpl(
      HomeLayoutRemoteDataSourceImpl(api),
    );

    signIn = SignIn(authRepository);
    registerBuyer = RegisterBuyer(authRepository);
    updateBuyerAddress = UpdateBuyerAddress(authRepository);
    changePassword = ChangePassword(authRepository);
    getCart = authRepository.getCart;
    saveCart = authRepository.saveCart;
    loadProducts = LoadProducts(productRepository);
    saveProduct = SaveProduct(productRepository);
    removeProduct = RemoveProduct(productRepository);
    uploadProductImage = UploadProductImage(productRepository);
    placeOrder = PlaceOrder(orderRepository);
    loadOrders = LoadOrders(orderRepository);
    loadCustomers = LoadCustomers(orderRepository);
    updateCustomer = UpdateCustomer(orderRepository);
    loadReport = LoadReport(orderRepository);
    changeOrderStatus = ChangeOrderStatus(orderRepository);
    withdraw = orderRepository.withdraw;
    getPaymentDetails = orderRepository.getPaymentDetails;
    simulatePayment = orderRepository.simulatePayment;
    updateBankAccount = orderRepository.updateBankAccount;
    requestOrderCancellation = orderRepository.requestCancellation;
    approveCancellation = orderRepository.approveCancellation;
    rejectCancellation = orderRepository.rejectCancellation;
    listAddresses = orderRepository.listAddresses;
    createAddress = orderRepository.createAddress;
    deleteAddress = orderRepository.deleteAddress;
    setDefaultAddress = orderRepository.setDefaultAddress;
    shippingQuote = orderRepository.shippingQuote;
    loadShippingConfig = orderRepository.shippingConfig;
    updateShippingSettings = orderRepository.updateShippingSettings;
    createShippingZone = orderRepository.createShippingZone;
    updateShippingZone = orderRepository.updateShippingZone;
    deleteShippingZone = orderRepository.deleteShippingZone;
    createShippingArea = orderRepository.createShippingArea;
    updateShippingArea = orderRepository.updateShippingArea;
    deleteShippingArea = orderRepository.deleteShippingArea;
    loadHomeLayout = LoadHomeLayout(homeLayoutRepository);
  }

  final ApiClient api;
  late final SignIn signIn;
  late final RegisterBuyer registerBuyer;
  late final UpdateBuyerAddress updateBuyerAddress;
  late final ChangePassword changePassword;
  late final Future<Map<int, int>> Function() getCart;
  late final Future<void> Function(Map<int, int>) saveCart;
  late final LoadProducts loadProducts;
  late final SaveProduct saveProduct;
  late final RemoveProduct removeProduct;
  late final UploadProductImage uploadProductImage;
  late final PlaceOrder placeOrder;
  late final LoadOrders loadOrders;
  late final LoadCustomers loadCustomers;
  late final UpdateCustomer updateCustomer;
  late final LoadReport loadReport;
  late final ChangeOrderStatus changeOrderStatus;
  late final Future<Map<String, dynamic>> Function({
    required String bankName,
    required String accountName,
    required String accountNumber,
    required int amountCents,
  }) withdraw;
  late final Future<Map<String, dynamic>> Function(int) getPaymentDetails;
  late final Future<void> Function(int) simulatePayment;
  late final Future<void> Function(Map<String, dynamic>) updateBankAccount;
  late final Future<void> Function(int, Map<String, dynamic>) requestOrderCancellation;
  late final Future<void> Function(int) approveCancellation;
  late final Future<void> Function(int) rejectCancellation;
  late final Future<List<Map<String, dynamic>>> Function() listAddresses;
  late final Future<Map<String, dynamic>> Function(Map<String, dynamic>) createAddress;
  late final Future<void> Function(int) deleteAddress;
  late final Future<void> Function(int) setDefaultAddress;
  late final Future<ShippingQuote> Function(String city, String district)
  shippingQuote;
  late final Future<ShippingConfig> Function() loadShippingConfig;
  late final Future<void> Function(Map<String, dynamic> body)
  updateShippingSettings;
  late final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)
  createShippingZone;
  late final Future<void> Function(int id, Map<String, dynamic> body)
  updateShippingZone;
  late final Future<void> Function(int id) deleteShippingZone;
  late final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)
  createShippingArea;
  late final Future<void> Function(int id, Map<String, dynamic> body)
  updateShippingArea;
  late final Future<void> Function(int id) deleteShippingArea;
  late final LoadHomeLayout loadHomeLayout;
}
