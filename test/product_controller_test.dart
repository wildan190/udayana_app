import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:udayana_app/features/products/domain/entities/product.dart';
import 'package:udayana_app/features/products/domain/entities/product_page.dart';
import 'package:udayana_app/features/products/domain/repositories/product_repository.dart';
import 'package:udayana_app/features/products/domain/usecases/manage_products.dart';
import 'package:udayana_app/features/products/presentation/state/product_controller.dart';
import 'package:udayana_app/features/products/presentation/state/product_event.dart';

void main() {
  test('appends server pages and preserves the page metadata', () async {
    final repository = _QueuedProductRepository();
    final controller = _controller(repository);

    final firstPage = controller.dispatch(
      const LoadProductsRequested(admin: false),
    );
    repository.requests[0].complete(_page([_product(1)], page: 1, total: 3));
    await firstPage;

    final nextPage = controller.dispatch(
      const LoadProductsRequested(admin: false, page: 2, append: true),
    );
    repository.requests[1].complete(_page([_product(2)], page: 2, total: 3));
    await nextPage;

    expect(controller.state.products.map((product) => product.id), [1, 2]);
    expect(controller.state.page, 2);
    expect(controller.state.total, 3);
    expect(controller.state.hasMore, isTrue);
    controller.dispose();
  });

  test('ignores a stale response after a newer catalog query', () async {
    final repository = _QueuedProductRepository();
    final controller = _controller(repository);

    final staleRequest = controller.dispatch(
      const LoadProductsRequested(admin: false, search: 'old'),
    );
    final currentRequest = controller.dispatch(
      const LoadProductsRequested(admin: false, search: 'new'),
    );
    repository.requests[1].complete(_page([_product(2)], page: 1, total: 1));
    await currentRequest;
    repository.requests[0].complete(_page([_product(1)], page: 1, total: 1));
    await staleRequest;

    expect(controller.state.products.single.id, 2);
    expect(controller.state.search, 'new');
    controller.dispose();
  });
}

ProductController _controller(_QueuedProductRepository repository) =>
    ProductController(
      LoadProducts(repository),
      SaveProduct(repository),
      RemoveProduct(repository),
      UploadProductImage(repository),
    );

ProductPage _page(
  List<Product> products, {
  required int page,
  required int total,
}) => ProductPage(products: products, page: page, pageSize: 1, total: total);

Product _product(int id) => Product(
  id: id,
  name: 'Produk $id',
  description: '',
  category: 'Bahan Pokok',
  needType: 'daily_need',
  priceCents: 100,
  stock: 3,
  imageUrl: '',
  active: true,
);

class _QueuedProductRepository implements ProductRepository {
  final requests = <Completer<ProductPage>>[];

  @override
  Future<ProductPage> list({
    required bool admin,
    required int page,
    required int pageSize,
    required String search,
    required String category,
    required String needType,
  }) {
    final request = Completer<ProductPage>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<Product> save(Product product, {int? id}) async => product;

  @override
  Future<void> remove(int id) async {}

  @override
  Future<String> uploadImage(String filename, List<int> bytes) async => '';
}
