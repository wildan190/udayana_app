import 'package:flutter/foundation.dart';

import '../../domain/usecases/manage_products.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductController extends ChangeNotifier {
  ProductController(
    this._loadProducts,
    this._saveProduct,
    this._removeProduct,
    this._uploadProductImage,
  );

  final LoadProducts _loadProducts;
  final SaveProduct _saveProduct;
  final RemoveProduct _removeProduct;
  final UploadProductImage _uploadProductImage;
  ProductState _state = const ProductState();
  int _loadRequestId = 0;

  ProductState get state => _state;

  Future<String> uploadImage(String filename, List<int> bytes) =>
      _uploadProductImage(filename, bytes);

  Future<void> dispatch(ProductEvent event) async {
    switch (event) {
      case LoadProductsRequested(
        :final admin,
        :final page,
        :final pageSize,
        :final search,
        :final category,
        :final needType,
        :final append,
      ):
        final requestId = ++_loadRequestId;
        final previous = _state;
        _state = ProductState(
          products: previous.products,
          isLoading: true,
          page: previous.page,
          pageSize: pageSize,
          total: previous.total,
          search: search,
          category: category,
          needType: needType,
        );
        notifyListeners();
        try {
          final result = await _loadProducts(
            admin: admin,
            page: page,
            pageSize: pageSize,
            search: search,
            category: category,
            needType: needType,
          );
          if (requestId != _loadRequestId) return;
          final products = append
              ? {
                  for (final product in previous.products) product.id: product,
                  for (final product in result.products) product.id: product,
                }.values.toList()
              : result.products;
          _state = ProductState(
            products: products,
            page: result.page,
            pageSize: result.pageSize,
            total: result.total,
            search: search,
            category: category,
            needType: needType,
          );
        } on Exception catch (error) {
          if (requestId != _loadRequestId) return;
          _state = ProductState(
            products: previous.products,
            error: error.toString(),
            page: previous.page,
            pageSize: pageSize,
            total: previous.total,
            search: search,
            category: category,
            needType: needType,
          );
        }
      case ProductSaveRequested(:final product, :final id):
        try {
          await _saveProduct(product, id: id);
          await dispatch(
            LoadProductsRequested(
              admin: true,
              pageSize: _state.pageSize,
              search: _state.search,
              category: _state.category,
              needType: _state.needType,
            ),
          );
        } on Exception catch (error) {
          _state = ProductState(
            products: _state.products,
            error: error.toString(),
            page: _state.page,
            pageSize: _state.pageSize,
            total: _state.total,
            search: _state.search,
            category: _state.category,
            needType: _state.needType,
          );
          notifyListeners();
        }
      case ProductRemoveRequested(:final id):
        try {
          final updatedProducts =
              _state.products.where((p) => p.id != id).toList();
          _state = ProductState(
            products: updatedProducts,
            page: _state.page,
            pageSize: _state.pageSize,
            total: _state.total > 0 ? _state.total - 1 : 0,
            search: _state.search,
            category: _state.category,
            needType: _state.needType,
          );
          notifyListeners();

          await _removeProduct(id);
          await dispatch(
            LoadProductsRequested(
              admin: true,
              pageSize: _state.pageSize,
              search: _state.search,
              category: _state.category,
              needType: _state.needType,
            ),
          );
        } on Exception catch (error) {
          _state = ProductState(
            products: _state.products,
            error: error.toString(),
            page: _state.page,
            pageSize: _state.pageSize,
            total: _state.total,
            search: _state.search,
            category: _state.category,
            needType: _state.needType,
          );
          notifyListeners();
        }
    }
    notifyListeners();
  }
}
