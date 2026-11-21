import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kDebugMode
        ? 'https://d1f8-2404-c0-aa07-678c-c571-80e9-d875-ca13.ngrok-free.app/api/v1'
        : 'https://api-phoestore.phoenixtech.web.id/api/v1',
  );
}
