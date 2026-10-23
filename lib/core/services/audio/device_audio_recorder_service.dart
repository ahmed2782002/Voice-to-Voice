import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'audio_limits.dart';
import 'audio_recorder_service.dart';

class DeviceAudioRecorderService implements AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<double> _amplitude =
      StreamController<double>.broadcast();
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  @override
  Stream<double> get amplitudeChanges => _amplitude.stream;

  @override
  Future<MicPermission> requestPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted || status.isLimited) return MicPermission.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return MicPermission.permanentlyDenied;
    }
    return MicPermission.denied;
  }

  @override
  Future<void> openSettings() => openAppSettings();

  @override
  Future<void> start() async {
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/source_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(AudioLimits.amplitudeInterval)
        .listen((value) => _amplitude.add(_normalize(value.current)));
  }

  @override
  Future<String?> stop() async {
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    return _recorder.stop();
  }

  @override
  Future<void> cancel() async {
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    await _recorder.cancel();
  }

  @override
  Future<int> fileSize(String path) async {
    final file = File(path);
    if (!await file.exists()) return 0;
    return file.length();
  }

  @override
  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> dispose() async {
    await _amplitudeSubscription?.cancel();
    await _amplitude.close();
    await _recorder.dispose();
  }

  double _normalize(double decibels) {
    if (decibels.isNaN || decibels.isInfinite) return 0;
    return ((decibels + 50) / 50).clamp(0.0, 1.0);
  }
}
