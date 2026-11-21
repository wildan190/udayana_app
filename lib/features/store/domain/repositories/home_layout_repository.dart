import '../entities/home_layout.dart';

abstract interface class HomeLayoutRepository {
  Future<HomeLayout> load();
}
