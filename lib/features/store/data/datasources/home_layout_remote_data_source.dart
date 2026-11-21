import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/session_storage.dart';
import '../models/home_layout_model.dart';

abstract interface class HomeLayoutRemoteDataSource {
  Future<HomeLayoutModel> load();
}

class HomeLayoutRemoteDataSourceImpl implements HomeLayoutRemoteDataSource {
  const HomeLayoutRemoteDataSourceImpl(this._api);

  final ApiClient _api;

  @override
  Future<HomeLayoutModel> load() async {
    try {
      final response = await _api.get('/ui/home') as Map<String, dynamic>;
      LocalCache.saveHomeLayout(jsonEncode(response)).catchError((_) {});
      return HomeLayoutModel.fromJson(response);
    } catch (_) {
      try {
        final cachedJson = await LocalCache.loadHomeLayout();
        if (cachedJson != null && cachedJson.isNotEmpty) {
          return HomeLayoutModel.fromJson(
            jsonDecode(cachedJson) as Map<String, dynamic>,
          );
        }
      } catch (_) {
        await LocalCache.clearHomeLayout();
      }
      rethrow;
    }
  }
}
