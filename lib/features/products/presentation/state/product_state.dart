import '../../domain/entities/product.dart';

class ProductState {
  const ProductState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
    this.search = '',
    this.category = '',
    this.needType = '',
  });

  final List<Product> products;
  final bool isLoading;
  final String? error;
  final int page;
  final int pageSize;
  final int total;
  final String search;
  final String category;
  final String needType;

  bool get hasMore => products.length < total;
}
