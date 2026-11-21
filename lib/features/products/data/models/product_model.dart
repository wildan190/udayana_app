class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.needType,
    required this.priceCents,
    required this.stock,
    required this.imageUrl,
    required this.active,
  });

  final int id;
  final String name;
  final String description;
  final String category;
  final String needType;
  final int priceCents;
  final int stock;
  final String imageUrl;
  final bool active;

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    category: json['category'] as String? ?? '',
    needType: json['need_type'] as String? ?? 'daily_need',
    priceCents: (json['price_cents'] as num).toInt(),
    stock: (json['stock'] as num).toInt(),
    imageUrl: json['image_url'] as String? ?? '',
    active: json['active'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'category': category,
    'need_type': needType,
    'price_cents': priceCents,
    'stock': stock,
    'image_url': imageUrl,
    'active': active,
  };
}

class ProductPageModel {
  const ProductPageModel({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<ProductModel> items;
  final int page;
  final int pageSize;
  final int total;

  factory ProductPageModel.fromJson(Map<String, dynamic> json) =>
      ProductPageModel(
        items: (json['items'] as List<dynamic>)
            .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
            .toList(),
        page: (json['page'] as num).toInt(),
        pageSize: (json['page_size'] as num).toInt(),
        total: (json['total'] as num).toInt(),
      );
}
