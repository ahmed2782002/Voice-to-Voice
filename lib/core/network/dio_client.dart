import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../services/auth/access_token_provider.dart';
import 'endpoints.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'network_exception.dart';
import 'network_timeouts.dart';
import 'request_extras.dart';

class DioClient {
  DioClient({
    required AccessTokenProvider tokens,
    String baseUrl = Endpoints.baseUrl,
    Map<String, String> headers = const {},
    HttpClientAdapter? adapter,
    List<Duration> retryDelays = RetryInterceptor.defaultDelays,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: NetworkTimeouts.connect,
           receiveTimeout: NetworkTimeouts.receive,
           sendTimeout: NetworkTimeouts.send,
           responseType: ResponseType.plain,
           validateStatus: (status) => status != null && status < 600,
           headers: {HttpHeaders.acceptHeader: 'application/json', ...headers},
         ),
       ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
    _dio.interceptors.addAll([
      AuthInterceptor(dio: _dio, tokens: tokens),
      RetryInterceptor(dio: _dio, delays: retryDelays),
      if (kDebugMode) LoggingInterceptor(),
    ]);
  }

  final Dio _dio;

  Future<Object?> get(String path, {CancelToken? cancelToken}) => _send(
    () => _dio.get<String>(
      path,
      cancelToken: cancelToken,
      options: Options(extra: {RequestExtras.idempotent: true}),
    ),
  );

  Future<Object?> upload(
    String path,
    FormData data, {
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.post<String>(
      path,
      data: data,
      cancelToken: cancelToken,
      options: Options(
        sendTimeout: NetworkTimeouts.uploadSend,
        receiveTimeout: NetworkTimeouts.uploadReceive,
        extra: {RequestExtras.idempotent: false},
      ),
    ),
  );

  Future<Object?> _send(Future<Response<String>> Function() request) async {
    final Response<String> response;
    try {
      response = await request();
    } on DioException catch (error) {
      throw _toNetworkException(error);
    }
    final status = response.statusCode ?? 0;
    final body = response.data ?? '';
    if (status < 200 || status >= 300) {
      throw HttpStatusException(statusCode: status, body: body);
    }
    if (body.trim().isEmpty) {
      throw const FormatException('Empty response body');
    }
    return jsonDecode(body);
  }

  Object _toNetworkException(DioException error) => switch (error) {
    DioException(error: final NetworkException inner) => inner,
    DioException(
      type: DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout,
    ) =>
      const RequestTimeoutException(),
    DioException(type: DioExceptionType.cancel) =>
      const RequestCancelledException(),
    DioException(type: DioExceptionType.connectionError) ||
    DioException(
      error: SocketException() || HttpException(),
    ) => NoConnectionException(error.message),
    DioException(error: final Object inner) => inner,
    _ => error,
  };
}
