import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:udayana_app/core/network/api_client.dart';
import 'package:udayana_app/features/products/data/datasources/product_remote_data_source.dart';

void main() {
  test(
    'supports legacy array responses while paging and filtering locally',
    () async {
      final dataSource = ProductRemoteDataSourceImpl(
        ApiClient(
          baseUrl: 'http://localhost/api/v1',
          client: MockClient((request) async {
            expect(request.url.queryParameters['page'], '2');
            expect(request.url.queryParameters['page_size'], '1');
            expect(request.url.queryParameters['search'], 'beras');
            return http.Response(
              jsonEncode([
                _product(1, 'Beras'),
                _product(2, 'Minyak'),
                _product(3, 'Beras organik'),
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );

      final result = await dataSource.list(
        admin: false,
        page: 2,
        pageSize: 1,
        search: 'beras',
        category: '',
        needType: '',
      );

      expect(result.items.single.id, 3);
      expect(result.page, 2);
      expect(result.total, 2);
    },
  );
}

Map<String, dynamic> _product(int id, String name) => {
  'id': id,
  'name': name,
  'description': '',
  'category': 'Bahan Pokok',
  'need_type': 'daily_need',
  'price_cents': 1000,
  'stock': 2,
  'image_url': '',
  'active': true,
};
