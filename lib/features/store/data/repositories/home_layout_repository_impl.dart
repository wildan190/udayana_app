import '../../domain/entities/home_layout.dart';
import '../../domain/repositories/home_layout_repository.dart';
import '../datasources/home_layout_remote_data_source.dart';
import '../mappers/home_layout_mapper.dart';

class HomeLayoutRepositoryImpl implements HomeLayoutRepository {
  const HomeLayoutRepositoryImpl(this._remoteDataSource);

  final HomeLayoutRemoteDataSource _remoteDataSource;

  @override
  Future<HomeLayout> load() async =>
      HomeLayoutMapper.toEntity(await _remoteDataSource.load());
}
