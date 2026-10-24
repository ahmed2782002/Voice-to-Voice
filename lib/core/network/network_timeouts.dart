abstract final class NetworkTimeouts {
  static const Duration connect = Duration(seconds: 10);
  static const Duration receive = Duration(seconds: 30);
  static const Duration send = Duration(seconds: 30);
  static const Duration uploadSend = Duration(seconds: 120);
  static const Duration uploadReceive = Duration(seconds: 90);
}
