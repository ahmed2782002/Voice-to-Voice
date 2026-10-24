sealed class NetworkException implements Exception {
  const NetworkException();
}

class NoConnectionException extends NetworkException {
  const NoConnectionException([this.message]);

  final String? message;

  @override
  String toString() => 'NoConnectionException($message)';
}

class RequestTimeoutException extends NetworkException {
  const RequestTimeoutException();

  @override
  String toString() => 'RequestTimeoutException()';
}

class RequestCancelledException extends NetworkException {
  const RequestCancelledException();

  @override
  String toString() => 'RequestCancelledException()';
}

class SessionException extends NetworkException {
  const SessionException({required this.statusCode, this.message});

  final int statusCode;
  final String? message;

  @override
  String toString() => 'SessionException($statusCode, $message)';
}

class HttpStatusException extends NetworkException {
  const HttpStatusException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  String toString() => 'HttpStatusException($statusCode)';
}
