import 'package:equatable/equatable.dart';

class TranslationHistoryEntry extends Equatable {
  const TranslationHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.sourceName,
    required this.targetName,
    required this.originalText,
    required this.translatedText,
    required this.audioPath,
  });

  final String id;
  final DateTime createdAt;
  final String sourceName;
  final String targetName;
  final String originalText;
  final String translatedText;
  final String audioPath;

  Map<String, Object> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'sourceName': sourceName,
    'targetName': targetName,
    'originalText': originalText,
    'translatedText': translatedText,
    'audioPath': audioPath,
  };

  static TranslationHistoryEntry? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    final createdAt = DateTime.tryParse('${json['createdAt']}');
    final audioPath = json['audioPath'];
    if (id is! String || createdAt == null || audioPath is! String) {
      return null;
    }
    return TranslationHistoryEntry(
      id: id,
      createdAt: createdAt,
      sourceName: '${json['sourceName'] ?? ''}',
      targetName: '${json['targetName'] ?? ''}',
      originalText: '${json['originalText'] ?? ''}',
      translatedText: '${json['translatedText'] ?? ''}',
      audioPath: audioPath,
    );
  }

  @override
  List<Object?> get props => [
    id,
    createdAt,
    sourceName,
    targetName,
    originalText,
    translatedText,
    audioPath,
  ];
}
