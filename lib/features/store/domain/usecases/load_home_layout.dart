import '../entities/home_layout.dart';
import '../repositories/home_layout_repository.dart';

class LoadHomeLayout {
  const LoadHomeLayout(this._repository);

  final HomeLayoutRepository _repository;

  Future<HomeLayout> call() => _repository.load();
}
