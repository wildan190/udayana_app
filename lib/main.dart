import 'package:flutter/material.dart';

import 'core/di/app_services.dart';
import 'core/network/session_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/entities/app_user.dart';
import 'features/store/presentation/pages/store_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  String? token;
  AppUser? user;
  try {
    final result = await SessionStorage.load();
    token = result.$1;
    user = result.$2;
  } catch (_) {
    await SessionStorage.clear();
  }

  final services = AppServices();
  if (token != null && user != null) {
    services.api.token = token;
  }

  runApp(
    UdayanaApp(
      services: services,
      initialToken: token,
      initialUser: user,
    ),
  );
}

class UdayanaApp extends StatelessWidget {
  const UdayanaApp({
    super.key,
    this.services,
    this.initialToken,
    this.initialUser,
  });

  final AppServices? services;
  final String? initialToken;
  final AppUser? initialUser;

  @override
  Widget build(BuildContext context) {
    final s = services ?? AppServices();
    if (initialToken != null) {
      s.api.token = initialToken;
    }
    return MaterialApp(
      title: 'Udayana Market',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: StorePage(
        services: s,
        user:
            initialUser ??
            const AppUser(
              id: 0,
              name: 'Tamu',
              email: '',
              role: 'guest',
              phone: '',
            ),
      ),
    );
  }
}
