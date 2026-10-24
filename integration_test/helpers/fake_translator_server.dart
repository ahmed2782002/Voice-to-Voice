import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class FakeTranslatorServer implements HttpClientAdapter {
  final List<String> paths = [];
  final List<ResponseBody Function()> translateReplies = [];
  bool languagesDown = false;

  static const List<Map<String, Object>> languages = [
    {'code': 'ar', 'name': 'Arabic', 'native': 'العربية'},
    {'code': 'en', 'name': 'English'},
    {'code': 'ja', 'name': 'Japanese', 'native': '日本語'},
  ];

  int get translateCalls =>
      paths.where((path) => path.endsWith('/translate-voice')).length;

  static ResponseBody json(Object body, int status) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json; charset=utf-8'],
    },
  );

  static ResponseBody translation({
    String original = 'مرحبا بك',
    String translated = 'Welcome',
  }) => json({
    'sourceLanguage': 'ar',
    'targetLanguage': 'en',
    'originalText': original,
    'translatedText': translated,
    'audio': {
      'mimeType': 'audio/mpeg',
      'base64': base64Encode(List.filled(256, 7)),
    },
    'aiGenerated': true,
  }, 200);

  static ResponseBody rateLimited() => json({
    'error': {'code': 'RATE_LIMITED', 'message': 'Slow down'},
  }, 429);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    final path = options.uri.path;
    paths.add(path);
    if (path.endsWith('/languages')) {
      if (languagesDown) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      return json(languages, 200);
    }
    if (path.endsWith('/translate-voice')) {
      return translateReplies.isEmpty
          ? translation()
          : translateReplies.removeAt(0)();
    }
    return json({
      'error': {'code': 'NOT_FOUND'},
    }, 404);
  }

  @override
  void close({bool force = false}) {}
}
