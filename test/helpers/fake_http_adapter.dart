import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef CapturedRequest = ({RequestOptions options, String body});

class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(List<Object> replies) : _replies = [...replies];

  final List<Object> _replies;
  final List<CapturedRequest> requests = [];

  static ResponseBody json(Object body, int status) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json; charset=utf-8'],
    },
  );

  static ResponseBody text(String body, int status) =>
      ResponseBody.fromString(body, status);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = requestStream == null
        ? <int>[]
        : await requestStream.expand((chunk) => chunk).toList();
    requests.add((
      options: options,
      body: utf8.decode(bytes, allowMalformed: true),
    ));
    final reply = _replies.removeAt(0);
    if (reply is DioExceptionType) {
      throw DioException(requestOptions: options, type: reply);
    }
    return reply as ResponseBody;
  }

  @override
  void close({bool force = false}) {}
}
