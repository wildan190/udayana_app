import '../../domain/entities/product.dart';
import '../../domain/entities/product_page.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';
import '../mappers/product_mapper.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._remoteDataSource);

  final ProductRemoteDataSource _remoteDataSource;

  @override
  Future<ProductPage> list({
    required bool admin,
    required int page,
    required int pageSize,
    required String search,
    required String category,
    required String needType,
  }) async {
    final response = await _remoteDataSource.list(
      admin: admin,
      page: page,
      pageSize: pageSize,
      search: search,
      category: category,
      needType: needType,
    );
    return ProductPage(
      products: response.items.map(ProductMapper.toEntity).toList(),
      page: response.page,
      pageSize: response.pageSize,
      total: response.total,
    );
  }

  @override
  Future<Product> save(Product product, {int? id}) async =>
      ProductMapper.toEntity(
        await _remoteDataSource.save(ProductMapper.toModel(product), id: id),
      );

  @override
  Future<void> remove(int id) => _remoteDataSource.remove(id);

  @override
  Future<String> uploadImage(String filename, List<int> bytes) =>
      _remoteDataSource.uploadImage(filename, bytes);
}
