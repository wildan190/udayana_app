import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/session_storage.dart';
import '../models/product_model.dart';

abstract interface class ProductRemoteDataSource {
  Future<ProductPageModel> list({
    required bool admin,
    required int page,
    required int pageSize,
    required String search,
    required String category,
    required String needType,
  });
  Future<ProductModel> save(ProductModel product, {int? id});
  Future<void> remove(int id);
  Future<String> uploadImage(String filename, List<int> bytes);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  const ProductRemoteDataSourceImpl(this._api);

  final ApiClient _api;

  @override
  Future<ProductPageModel> list({
    required bool admin,
    required int page,
    required int pageSize,
    required String search,
    required String category,
    required String needType,
  }) async {
    try {
      final response = await _api.get(
        admin ? '/admin/products' : '/products',
        query: {
          'page': '$page',
          'page_size': '$pageSize',
          if (search.isNotEmpty) 'search': search,
          if (category.isNotEmpty) 'category': category,
          if (needType.isNotEmpty) 'need_type': needType,
        },
      );
      if (response != null) {
        LocalCache.saveProducts(jsonEncode(response)).catchError((_) {});
      }
      if (response is Map<String, dynamic>) {
        return ProductPageModel.fromJson(response);
      }
      if (response is List<dynamic>) {
        return _pageFromLegacyList(
          response,
          page: page,
          pageSize: pageSize,
          search: search,
          category: category,
          needType: needType,
        );
      }
    } catch (_) {
      try {
        final cachedJson = await LocalCache.loadProducts();
        if (cachedJson != null && cachedJson.isNotEmpty) {
          final decoded = jsonDecode(cachedJson);
          if (decoded is Map<String, dynamic>) {
            return ProductPageModel.fromJson(decoded);
          }
          if (decoded is List<dynamic>) {
            return _pageFromLegacyList(
              decoded,
              page: page,
              pageSize: pageSize,
              search: search,
              category: category,
              needType: needType,
            );
          }
        }
      } catch (_) {
        await LocalCache.clearProducts();
      }
      rethrow;
    }
    throw const FormatException(
      'Respons katalog harus berupa objek halaman atau daftar produk.',
    );
  }

  @override
  Future<ProductModel> save(ProductModel product, {int? id}) async {
    final response = id == null
        ? await _api.post('/admin/products', body: product.toJson())
        : await _api.put('/admin/products/$id', body: product.toJson());
    return ProductModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> remove(int id) async {
    await _api.delete('/admin/products/$id');
  }

  @override
  Future<String> uploadImage(String filename, List<int> bytes) async {
    final response = await _api.uploadImage(
      '/admin/product-images',
      filename,
      bytes,
    ) as Map<String, dynamic>;
    return response['image_url'] as String;
  }
}

ProductPageModel _pageFromLegacyList(
  List<dynamic> response, {
  required int page,
  required int pageSize,
  required String search,
  required String category,
  required String needType,
}) {
  final products = response
      .map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException(
            'Data produk pada respons katalog tidak valid.',
          );
        }
        return ProductModel.fromJson(item);
      })
      .where((product) {
        final normalizedSearch = search.trim().toLowerCase();
        final matchesSearch =
            normalizedSearch.isEmpty ||
            product.name.toLowerCase().contains(normalizedSearch) ||
            product.description.toLowerCase().contains(normalizedSearch) ||
            product.category.toLowerCase().contains(normalizedSearch);
        return matchesSearch &&
            (category.isEmpty || product.category == category) &&
            (needType.isEmpty || product.needType == needType);
      })
      .toList();

  final offset = (page - 1) * pageSize;
  final items = offset >= products.length
      ? <ProductModel>[]
      : products.skip(offset).take(pageSize).toList();
  return ProductPageModel(
    items: items,
    page: page,
    pageSize: pageSize,
    total: products.length,
  );
}
