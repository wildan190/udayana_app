class HomeLayoutModel {
  const HomeLayoutModel({required this.components});

  final List<HomeComponentModel> components;

  factory HomeLayoutModel.fromJson(Map<String, dynamic> json) =>
      HomeLayoutModel(
        components: (json['components'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  HomeComponentModel.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
}

class HomeComponentModel {
  const HomeComponentModel({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.categories,
  });

  final String type;
  final String title;
  final String subtitle;
  final List<HomeCategoryModel> categories;

  factory HomeComponentModel.fromJson(Map<String, dynamic> json) =>
      HomeComponentModel(
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        categories: (json['categories'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  HomeCategoryModel.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
}

class HomeCategoryModel {
  const HomeCategoryModel({
    required this.label,
    required this.category,
    required this.needType,
  });

  final String label;
  final String category;
  final String needType;

  factory HomeCategoryModel.fromJson(Map<String, dynamic> json) =>
      HomeCategoryModel(
        label: json['label'] as String? ?? '',
        category: json['category'] as String? ?? '',
        needType: json['need_type'] as String? ?? '',
      );
}
