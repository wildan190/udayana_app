import 'dart:convert';

import 'package:http/http.dart' as http;
import '../logging/app_logger.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  String? _token;

  set token(String? value) => _token = value;

  Future<dynamic> get(String path, {Map<String, String>? query}) {
    return _send('GET', path, query: query);
  }

  Future<dynamic> post(String path, {Object? body}) {
    return _send('POST', path, body: body);
  }

  Future<dynamic> put(String path, {Object? body}) {
    return _send('PUT', path, body: body);
  }

  Future<dynamic> patch(String path, {Object? body}) {
    return _send('PATCH', path, body: body);
  }

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> uploadImage(
    String path,
    String filename,
    List<int> bytes,
  ) async {
    final request = http.MultipartRequest('POST', _uri(path));
    if (_token case final token?) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      http.MultipartFile.fromBytes('image', bytes, filename: filename),
    );

    AppLogger.info('API', 'Upload foto $filename -> $path');
    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      AppLogger.info('API', 'Upload foto $filename response: ${response.statusCode}');
      return _decodeResponse(response);
    } on ApiException catch (e) {
      AppLogger.error('API', 'Upload foto $filename gagal', e);
      rethrow;
    } on Exception catch (error) {
      AppLogger.error('API', 'Upload foto $filename gagal', error);
      throw ApiException('Tidak dapat mengunggah foto: $error');
    }
  }

  String resolveUrl(String pathOrUrl) {
    final uri = Uri.parse(pathOrUrl);
    if (uri.hasScheme) return uri.toString();
    final baseUri = Uri.parse(_baseUrl);
    return uri.path.startsWith('/')
        ? baseUri.replace(path: uri.path, query: uri.query).toString()
        : baseUri.resolve(pathOrUrl).toString();
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final uri = _uri(path).replace(queryParameters: query);
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token case final token?) {
      headers['Authorization'] = 'Bearer $token';
    }
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    AppLogger.info('API', '$method $uri');
    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);
      AppLogger.info('API', '$method $path -> ${response.statusCode}');
      return _decodeResponse(response);
    } on ApiException catch (e) {
      AppLogger.error('API', '$method $path error: ${e.message}');
      rethrow;
    } on Exception catch (error) {
      AppLogger.error('API', '$method $path network error', error);
      throw ApiException('Tidak dapat terhubung ke server: $error');
    }
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  dynamic _decodeResponse(http.Response response) {
    dynamic decoded;
    if (response.body.isNotEmpty &&
        response.headers['content-type']?.contains('application/json') ==
            true) {
      decoded = jsonDecode(response.body);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString()
          : null;
      throw ApiException(
        message ?? 'Permintaan gagal (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }
}
