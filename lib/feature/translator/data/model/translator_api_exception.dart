import 'dart:convert';

enum TranslatorErrorCode {
  badRequest('BAD_REQUEST'),
  unauthorized('UNAUTHORIZED'),
  emptyRecording('EMPTY_RECORDING'),
  fileTooLarge('FILE_TOO_LARGE'),
  unsupportedTargetLanguage('UNSUPPORTED_TARGET_LANGUAGE'),
  unsupportedSourceLanguage('UNSUPPORTED_SOURCE_LANGUAGE'),
  noSpeech('NO_SPEECH'),
  textTooLong('TEXT_TOO_LONG'),
  unsupportedInput('UNSUPPORTED_INPUT'),
  rateLimited('RATE_LIMITED'),
  upstreamError('UPSTREAM_ERROR'),
  upstreamTimeout('UPSTREAM_TIMEOUT'),
  upstreamUnreachable('UPSTREAM_UNREACHABLE'),
  serverMisconfigured('SERVER_MISCONFIGURED'),
  unknown('UNKNOWN');

  const TranslatorErrorCode(this.wire);

  final String wire;

  bool get retryable => switch (this) {
    rateLimited ||
    upstreamError ||
    upstreamTimeout ||
    upstreamUnreachable => true,
    _ => false,
  };

  static TranslatorErrorCode fromWire(String? value) =>
      values.firstWhere((code) => code.wire == value, orElse: () => unknown);

  static TranslatorErrorCode fromStatus(int statusCode) => switch (statusCode) {
    400 => badRequest,
    401 || 403 => unauthorized,
    413 => fileTooLarge,
    422 => emptyRecording,
    429 => rateLimited,
    502 => upstreamError,
    504 => upstreamTimeout,
    _ => unknown,
  };
}

class TranslatorApiException implements Exception {
  const TranslatorApiException({
    required this.code,
    required this.statusCode,
    this.message,
    bool? retryable,
  }) : retryable = retryable ?? false;

  factory TranslatorApiException.fromResponse(int statusCode, String body) {
    final error = _errorObject(body);
    final rawCode = error?['code'];
    final rawMessage = error?['message'];
    final rawRetryable = error?['retryable'];
    final wireCode = TranslatorErrorCode.fromWire(
      rawCode is String ? rawCode : null,
    );
    final code = wireCode == TranslatorErrorCode.unknown
        ? TranslatorErrorCode.fromStatus(statusCode)
        : wireCode;
    return TranslatorApiException(
      code: code,
      statusCode: statusCode,
      message: rawMessage is String ? rawMessage : null,
      retryable: code.retryable || rawRetryable == true,
    );
  }

  final TranslatorErrorCode code;
  final int statusCode;
  final String? message;
  final bool retryable;

  static Map<String, dynamic>? _errorObject(String body) {
    try {
      return switch (jsonDecode(body)) {
        {'error': final Map<String, dynamic> error} => error,
        final Map<String, dynamic> root => root,
        _ => null,
      };
    } on FormatException {
      return null;
    }
  }

  @override
  String toString() =>
      'TranslatorApiException(${code.wire}, $statusCode, $message)';
}
