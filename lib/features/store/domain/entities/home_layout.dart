class HomeLayout {
  const HomeLayout({required this.components});

  final List<HomeComponent> components;
}

class HomeComponent {
  const HomeComponent({
    required this.type,
    this.title = '',
    this.subtitle = '',
    this.categories = const [],
  });

  final String type;
  final String title;
  final String subtitle;
  final List<HomeCategory> categories;
}

class HomeCategory {
  const HomeCategory({
    required this.label,
    this.category = '',
    this.needType = '',
  });

  final String label;
  final String category;
  final String needType;
}
