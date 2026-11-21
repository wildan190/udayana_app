import 'product.dart';

class ProductPage {
  const ProductPage({
    required this.products,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<Product> products;
  final int page;
  final int pageSize;
  final int total;

  bool get hasMore => products.length < total;
}
