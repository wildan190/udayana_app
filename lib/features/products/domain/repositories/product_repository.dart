import '../entities/product.dart';
import '../entities/product_page.dart';

abstract interface class ProductRepository {
  Future<ProductPage> list({
    required bool admin,
    required int page,
    required int pageSize,
    required String search,
    required String category,
    required String needType,
  });
  Future<Product> save(Product product, {int? id});
  Future<void> remove(int id);
  Future<String> uploadImage(String filename, List<int> bytes);
}
