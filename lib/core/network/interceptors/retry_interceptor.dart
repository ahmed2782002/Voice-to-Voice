import 'dart:io';

import 'package:dio/dio.dart';

import '../request_extras.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor({required this._dio, this.delays = defaultDelays});

  static const List<Duration> defaultDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  static const Set<int> retryableStatuses = {
    HttpStatus.badGateway,
    HttpStatus.serviceUnavailable,
    HttpStatus.gatewayTimeout,
  };

  static const Set<DioExceptionType> retryableErrors = {
    DioExceptionType.connectionError,
    DioExceptionType.connectionTimeout,
    DioExceptionType.receiveTimeout,
  };

  final Dio _dio;
  final List<Duration> delays;

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;
    if (!retryableStatuses.contains(response.statusCode) ||
        !_canRetry(options)) {
      handler.next(response);
      return;
    }
    try {
      handler.resolve(await _retry(options));
    } on DioException catch (error) {
      handler.reject(error);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (!retryableErrors.contains(err.type) || !_canRetry(options)) {
      handler.next(err);
      return;
    }
    try {
      handler.resolve(await _retry(options));
    } on DioException catch (error) {
      handler.next(error);
    }
  }

  bool _canRetry(RequestOptions options) =>
      options.extra[RequestExtras.idempotent] == true &&
      _attempt(options) < delays.length &&
      !(options.cancelToken?.isCancelled ?? false);

  int _attempt(RequestOptions options) =>
      options.extra[RequestExtras.retryAttempt] as int? ?? 0;

  Future<Response<dynamic>> _retry(RequestOptions options) async {
    final attempt = _attempt(options);
    await Future<void>.delayed(delays[attempt]);
    if (options.cancelToken?.isCancelled ?? false) {
      throw DioException.requestCancelled(
        requestOptions: options,
        reason: options.cancelToken?.cancelError,
      );
    }
    options.extra[RequestExtras.retryAttempt] = attempt + 1;
    return _dio.fetch<dynamic>(RequestExtras.replayable(options));
  }
}
