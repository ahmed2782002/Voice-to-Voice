import 'dart:io';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth/access_token_provider.dart';
import '../network_exception.dart';
import '../request_extras.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this._dio, required this._tokens});

  final Dio _dio;
  final AccessTokenProvider _tokens;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final forceRefresh =
        options.extra.remove(RequestExtras.forceTokenRefresh) == true;
    try {
      final token = await _tokens.accessToken(forceRefresh: forceRefresh);
      options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      handler.next(options);
    } on AuthRetryableFetchException catch (error) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: NoConnectionException(error.message),
        ),
      );
    } on AuthException catch (error) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: SessionException(
            statusCode:
                int.tryParse(error.statusCode ?? '') ?? HttpStatus.unauthorized,
            message: error.message,
          ),
        ),
      );
    }
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;
    if (response.statusCode != HttpStatus.unauthorized ||
        options.extra[RequestExtras.authRetried] == true) {
      handler.next(response);
      return;
    }
    options.extra[RequestExtras.authRetried] = true;
    options.extra[RequestExtras.forceTokenRefresh] = true;
    try {
      handler.resolve(await _dio.fetch(RequestExtras.replayable(options)));
    } on DioException catch (error) {
      handler.reject(error);
    }
  }
}
