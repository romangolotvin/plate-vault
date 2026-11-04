import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'plate_appeal.dart';

class AppealPhotoBytes {
  AppealPhotoBytes({required this.filename, required this.bytes});

  final String filename;
  final List<int> bytes;
}

class AppealServerView {
  AppealServerView({
    required this.id,
    required this.status,
    required this.scannedNumber,
    required this.correctedNumber,
  });

  final String id;
  final String status;
  final String scannedNumber;
  final String correctedNumber;

  factory AppealServerView.fromJson(Map<String, dynamic> json) {
    return AppealServerView(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      scannedNumber: json['scannedNumber'] as String? ?? '',
      correctedNumber: json['correctedNumber'] as String? ?? '',
    );
  }
}

class AppealTransportException implements Exception {
  AppealTransportException(this.messageRu);

  final String messageRu;

  @override
  String toString() => messageRu;
}

class AppealClient {
  AppealClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static Uri _endpoint(String baseUrl, String path) {
    final base = Uri.parse(baseUrl.trim());
    if (base.scheme != 'http' && base.scheme != 'https') {
      throw AppealTransportException(
        'Адрес программы должен начинаться с http:// или https://',
      );
    }
    if (!base.hasAuthority) {
      throw AppealTransportException('Адрес программы указан неполно.');
    }
    return base.resolve(path);
  }

  Future<List<AppealPhotoBytes>> readPhotos(List<String> paths) async {
    final photos = <AppealPhotoBytes>[];
    for (final path in paths) {
      if (path.isEmpty) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) continue;
      final slash = path.lastIndexOf(RegExp(r'[/\\]'));
      final name = slash >= 0 ? path.substring(slash + 1) : path;
      photos.add(AppealPhotoBytes(filename: name, bytes: bytes));
    }
    return photos;
  }

  Future<AppealServerView> submit({
    required String baseUrl,
    required String token,
    required PlateAppeal appeal,
    required List<AppealPhotoBytes> photos,
  }) {
    return _send(() async {
      final request = http.MultipartRequest(
        'POST',
        _endpoint(baseUrl, '/v1/appeals'),
      );
      _auth(request.headers, token);
      request.fields['meta'] = jsonEncode(appeal.toDesktopMeta());
      for (final photo in photos) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            photo.bytes,
            filename: photo.filename,
          ),
        );
      }
      final streamed = await _client.send(request);
      final body = await streamed.stream.bytesToString();
      return (streamed.statusCode, body);
    });
  }

  Future<AppealServerView?> fetchStatus({
    required String baseUrl,
    required String token,
    required String id,
  }) async {
    final response = await _request(
      () => _client.get(
        _endpoint(baseUrl, '/v1/appeals/$id'),
        headers: _authHeaders(token),
      ),
    );
    if (response.statusCode == 404) return null;
    return _decode(response.statusCode, response.body);
  }

  Map<String, String> _authHeaders(String token) {
    final headers = <String, String>{};
    _auth(headers, token);
    return headers;
  }

  void _auth(Map<String, String> headers, String token) {
    final trimmed = token.trim();
    if (trimmed.isNotEmpty) {
      headers['Authorization'] = 'Bearer $trimmed';
    }
  }

  Future<AppealServerView> _send(Future<(int, String)> Function() call) async {
    final (status, body) = await _guard(call);
    return _decode(status, body);
  }

  Future<http.Response> _request(Future<http.Response> Function() call) {
    return _guard(call);
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(const Duration(seconds: 25));
    } on AppealTransportException {
      rethrow;
    } on SocketException {
      throw AppealTransportException(
        'Программа владельца недоступна. Заявление останется на телефоне.',
      );
    } on HttpException {
      throw AppealTransportException('Программа владельца ответила с ошибкой.');
    } on FormatException {
      throw AppealTransportException('Адрес программы указан неполно.');
    } catch (e) {
      if (e is AppealTransportException) rethrow;
      throw AppealTransportException(
        'Не удалось связаться с программой владельца.',
      );
    }
  }

  AppealServerView _decode(int status, String body) {
    if (status == 401) {
      throw AppealTransportException(
        'Код доступа не подошёл. Скопируйте его из программы владельца.',
      );
    }
    if (status < 200 || status >= 300) {
      throw AppealTransportException(
        'Программа владельца не приняла заявление ($status).',
      );
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw AppealTransportException(
        'Программа владельца прислала пустой ответ.',
      );
    }
    return AppealServerView.fromJson(Map<String, dynamic>.from(decoded));
  }
}
