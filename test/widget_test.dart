import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:udayana_app/core/di/app_services.dart';
import 'package:udayana_app/core/network/api_client.dart';
import 'package:udayana_app/main.dart';

void main() {
  testWidgets('opens the public catalog without requiring sign in', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final services = AppServices(
      apiClient: ApiClient(
        baseUrl: 'http://localhost/api/v1',
        client: MockClient((request) async {
          if (request.url.path == '/api/v1/products') {
            return http.Response(
              jsonEncode({
                'items': [
                  {
                    'id': 1,
                    'name': 'Beras',
                    'description': 'Beras pulen.',
                    'category': 'Bahan Pokok',
                    'need_type': 'daily_need',
                    'price_cents': 50000,
                    'stock': 4,
                    'image_url': '',
                    'active': true,
                  },
                ],
                'page': 1,
                'page_size': 20,
                'total': 1,
                'total_pages': 1,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/api/v1/ui/home') {
            return http.Response(
              '{"components":[]}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/api/v1/auth/register') {
            return http.Response(
              jsonEncode({
                'token': 'registered-session',
                'user': {
                  'id': 42,
                  'name': 'Tamu Uji',
                  'email': 'tamu@example.com',
                  'role': 'buyer',
                  'phone': '',
                },
              }),
              201,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/api/v1/orders') {
            return http.Response(
              '[]',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{"error":"not found"}', 404);
        }),
      ),
    );

    await tester.pumpWidget(UdayanaApp(services: services));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Belanja'), findsOneWidget);
    expect(find.text('Keranjang'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Beras'), findsOneWidget);

    await tester.tap(find.text('Beras'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Detail produk'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pump();
    expect(find.text('Beras pulen.'), findsOneWidget);
    expect(find.text('Tambah ke keranjang'), findsOneWidget);

    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 500));
    final addButton = find.widgetWithText(FilledButton, 'Tambah').first;
    await tester.tap(addButton);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
