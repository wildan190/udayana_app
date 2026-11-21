import '../../domain/entities/home_layout.dart';
import '../models/home_layout_model.dart';

class HomeLayoutMapper {
  const HomeLayoutMapper._();

  static HomeLayout toEntity(HomeLayoutModel model) => HomeLayout(
    components: model.components
        .map(
          (component) => HomeComponent(
            type: component.type,
            title: component.title,
            subtitle: component.subtitle,
            categories: component.categories
                .map(
                  (category) => HomeCategory(
                    label: category.label,
                    category: category.category,
                    needType: category.needType,
                  ),
                )
                .toList(),
          ),
        )
        .toList(),
  );
}
