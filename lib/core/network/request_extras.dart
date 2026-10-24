import 'package:dio/dio.dart';

abstract final class RequestExtras {
  static const String idempotent = 'idempotent';
  static const String retryAttempt = 'retryAttempt';
  static const String authRetried = 'authRetried';
  static const String forceTokenRefresh = 'forceTokenRefresh';

  static RequestOptions replayable(RequestOptions options) {
    final data = options.data;
    if (data is FormData) options.data = data.clone();
    return options;
  }
}
