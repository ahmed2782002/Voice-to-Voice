import 'package:equatable/equatable.dart';

import 'translation_language.dart';

typedef TranslateVoice = Future<TranslationResult> Function({
  required String sourcePath,
  required TranslationLanguage language,
});

typedef LoadLanguages = Future<List<TranslationLanguage>> Function();

class TranslationResult extends Equatable {
  const TranslationResult({
    required this.audioPath,
    required this.language,
    this.sourceLanguageCode,
    this.originalText = '',
    this.translatedText = '',
    this.aiGenerated = true,
  });

  final String audioPath;
  final TranslationLanguage language;
  final String? sourceLanguageCode;
  final String originalText;
  final String translatedText;
  final bool aiGenerated;

  @override
  List<Object?> get props => [
    audioPath,
    language,
    sourceLanguageCode,
    originalText,
    translatedText,
    aiGenerated,
  ];
}
