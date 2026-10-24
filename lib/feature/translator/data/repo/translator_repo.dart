import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/services/audio/audio_file_store.dart';
import '../../../../core/services/audio/audio_format.dart';
import '../../../../core/services/audio/audio_limits.dart';
import '../model/translation_language.dart';
import '../model/translation_result.dart';
import '../model/translator_api_exception.dart';

class TranslatorRepo {
  TranslatorRepo({required this._client, AudioFileStore? audioStore})
    : _audioStore = audioStore ?? AudioFileStore();

  final DioClient _client;
  final AudioFileStore _audioStore;

  Future<List<TranslationLanguage>> fetchLanguages() async {
    final json = await _guard(() => _client.get(Endpoints.languages));
    final languages = TranslationLanguage.listFromJson(json)
        .where((language) => language.output)
        .toList();
    if (languages.isEmpty) {
      throw const FormatException('No target languages returned');
    }
    return languages;
  }

  Future<TranslationResult> translateVoice({
    required String sourcePath,
    required TranslationLanguage language,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();
    _validateSize(bytes.length);
    final extension = AudioFormat.uploadExtension(sourcePath);
    final json = await _guard(
      () => _client.upload(
        Endpoints.translateVoice,
        FormData.fromMap({
          'targetLanguage': language.code,
          'audio': MultipartFile.fromBytes(
            bytes,
            filename: 'recording.$extension',
            contentType: DioMediaType.parse(AudioFormat.mimeTypeOf(extension)),
          ),
        }),
      ),
    );
    return _toResult(json, language);
  }

  void _validateSize(int length) {
    if (length < AudioLimits.minFileBytes) {
      throw const TranslatorApiException(
        code: TranslatorErrorCode.emptyRecording,
        statusCode: 422,
      );
    }
    if (length > AudioLimits.maxFileBytes) {
      throw const TranslatorApiException(
        code: TranslatorErrorCode.fileTooLarge,
        statusCode: 413,
      );
    }
  }

  Future<Object?> _guard(Future<Object?> Function() request) async {
    try {
      return await request();
    } on HttpStatusException catch (error) {
      throw TranslatorApiException.fromResponse(error.statusCode, error.body);
    } on SessionException catch (error) {
      throw TranslatorApiException(
        code: TranslatorErrorCode.unauthorized,
        statusCode: error.statusCode,
        message: error.message,
        retryable: true,
      );
    }
  }

  Future<TranslationResult> _toResult(
    Object? json,
    TranslationLanguage language,
  ) async {
    if (json is! Map<String, dynamic>) {
      throw FormatException('Unexpected translation response', json);
    }
    final audio = json['audio'];
    if (audio is! Map<String, dynamic> || audio['base64'] is! String) {
      throw const FormatException('Translation response has no audio');
    }
    final bytes = base64Decode(audio['base64'] as String);
    if (bytes.isEmpty) {
      throw const FormatException('Translation audio is empty');
    }
    final mimeType = audio['mimeType'] is String
        ? audio['mimeType'] as String
        : 'audio/mpeg';
    final path = await _audioStore.save(
      bytes,
      prefix: 'translated_${language.code}',
      mimeType: mimeType,
    );
    return TranslationResult(
      audioPath: path,
      language: language,
      sourceLanguageCode: json['sourceLanguage'] as String?,
      originalText: (json['originalText'] as String?)?.trim() ?? '',
      translatedText: (json['translatedText'] as String?)?.trim() ?? '',
      aiGenerated: json['aiGenerated'] as bool? ?? true,
    );
  }
}
