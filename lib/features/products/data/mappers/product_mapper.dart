import '../../domain/entities/product.dart';
import '../models/product_model.dart';

class ProductMapper {
  const ProductMapper._();

  static Product toEntity(ProductModel model) => Product(
    id: model.id,
    name: model.name,
    description: model.description,
    category: model.category,
    needType: model.needType,
    priceCents: model.priceCents,
    stock: model.stock,
    imageUrl: model.imageUrl,
    active: model.active,
  );

  static ProductModel toModel(Product product) => ProductModel(
    id: product.id,
    name: product.name,
    description: product.description,
    category: product.category,
    needType: product.needType,
    priceCents: product.priceCents,
    stock: product.stock,
    imageUrl: product.imageUrl,
    active: product.active,
  );
}
