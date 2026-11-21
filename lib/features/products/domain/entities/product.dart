class Product {
  const Product({
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

  String get needLabel =>
      needType == 'daily_need' ? 'Daily need' : 'Essentials';
}
