abstract final class AudioLimits {
  static const Duration maxRecording = Duration(minutes: 2);
  static const Duration minRecording = Duration(seconds: 1);
  static const int minFileBytes = 2 * 1024;
  static const int maxFileBytes = 5 * 1024 * 1024;
  static const double silenceThreshold = 0.05;
  static const Duration amplitudeInterval = Duration(milliseconds: 100);
  static const Duration translationTimeout = Duration(seconds: 90);
  static const int liveWaveformBars = 48;
}
