import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  /// Basis URL API yang dipakai aplikasi.
  ///
  /// Bisa ditimpa tanpa mengubah kode, contoh:
  /// flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080/api/v1
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kDebugMode ? _devBaseUrl : _prodBaseUrl,
  );

  /// Mode dev/local: ubah [_useLocalBackend] ke `true` untuk memakai backend
  /// lokal tanpa perlu ngrok.
  ///
  /// - `false` : backend via ngrok
  /// - `true`  : backend lokal (127.0.0.1:8080)
  static const _useLocalBackend = false;

  static const _devBaseUrl = _useLocalBackend
      ? _devLocalBaseUrl
      : _devNgrokBaseUrl;

  static const _devNgrokBaseUrl =
      'https://fa83-2404-c0-aa07-678c-adf4-193d-b053-4515.ngrok-free.app/api/v1';
  static const _devLocalBaseUrl = 'http://127.0.0.1:8080/api/v1';
  static const _prodBaseUrl = 'https://api-phoestore.phoenixtech.web.id/api/v1';
}
