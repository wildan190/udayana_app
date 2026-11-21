import '../entities/product.dart';
import '../entities/product_page.dart';
import '../repositories/product_repository.dart';

class LoadProducts {
  const LoadProducts(this._repository);

  final ProductRepository _repository;

  Future<ProductPage> call({
    required bool admin,
    required int page,
    required int pageSize,
    required String search,
    required String category,
    required String needType,
  }) => _repository.list(
    admin: admin,
    page: page,
    pageSize: pageSize,
    search: search,
    category: category,
    needType: needType,
  );
}

class SaveProduct {
  const SaveProduct(this._repository);

  final ProductRepository _repository;

  Future<Product> call(Product product, {int? id}) =>
      _repository.save(product, id: id);
}

class RemoveProduct {
  const RemoveProduct(this._repository);

  final ProductRepository _repository;

  Future<void> call(int id) => _repository.remove(id);
}

class UploadProductImage {
  const UploadProductImage(this._repository);

  final ProductRepository _repository;

  Future<String> call(String filename, List<int> bytes) =>
      _repository.uploadImage(filename, bytes);
}
