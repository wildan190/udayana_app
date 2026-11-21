import '../../domain/entities/product.dart';

sealed class ProductEvent {
  const ProductEvent();
}

class LoadProductsRequested extends ProductEvent {
  const LoadProductsRequested({
    required this.admin,
    this.page = 1,
    this.pageSize = 20,
    this.search = '',
    this.category = '',
    this.needType = '',
    this.append = false,
  });

  final bool admin;
  final int page;
  final int pageSize;
  final String search;
  final String category;
  final String needType;
  final bool append;
}

class ProductSaveRequested extends ProductEvent {
  const ProductSaveRequested(this.product, {this.id});

  final Product product;
  final int? id;
}

class ProductRemoveRequested extends ProductEvent {
  const ProductRemoveRequested(this.id);

  final int id;
}
