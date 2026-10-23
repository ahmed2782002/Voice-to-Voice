import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/services/audio/audio_limits.dart';
import '../../../../core/services/auth/access_token_provider.dart';
import '../model/translation_language.dart';
import '../model/translation_result.dart';
import '../model/translator_api_exception.dart';

class TranslatorRepo {
  TranslatorRepo({
    required this._client,
    required this._session,
    Future<Directory> Function()? outputDirectory,
    this._baseUrl = SupabaseConfig.functionsUrl,
  }) : _outputDirectory = outputDirectory ?? getTemporaryDirectory;

  final http.Client _client;
  final AccessTokenProvider _session;
  final Future<Directory> Function() _outputDirectory;
  final String _baseUrl;
  static bool _languagesLogged = false;

  Future<List<TranslationLanguage>> fetchLanguages() async {
    final response = await _send(
      () => http.Request('GET', _endpoint('languages')),
      SupabaseConfig.languagesTimeout,
    );
    _logLanguagesOnce(response.body);
    final languages = TranslationLanguage.listFromJson(
      jsonDecode(response.body),
    ).where((language) => language.output).toList();
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
    final response = await _send(
      () => http.MultipartRequest('POST', _endpoint('translate-voice'))
        ..fields['targetLanguage'] = language.code
        ..files.add(
          http.MultipartFile.fromBytes(
            'audio',
            bytes,
            filename: 'recording.m4a',
            contentType: MediaType('audio', 'mp4'),
          ),
        ),
      AudioLimits.translationTimeout,
    );
    return _toResult(jsonDecode(response.body), language);
  }

  Uri _endpoint(String path) => Uri.parse('$_baseUrl/$path');

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

  Future<http.Response> _send(
    http.BaseRequest Function() build,
    Duration timeout,
  ) async {
    var response = await _attempt(build(), await _token(), timeout);
    if (response.statusCode == HttpStatus.unauthorized) {
      response = await _attempt(
        build(),
        await _token(forceRefresh: true),
        timeout,
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    throw TranslatorApiException.fromResponse(
      response.statusCode,
      response.body,
    );
  }

  Future<http.Response> _attempt(
    http.BaseRequest request,
    String token,
    Duration timeout,
  ) async {
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'apikey': SupabaseConfig.publishableKey,
      'Accept': 'application/json',
    });
    try {
      return await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on http.ClientException catch (error) {
      throw SocketException(error.message);
    }
  }

  Future<String> _token({bool forceRefresh = false}) async {
    try {
      return await _session.accessToken(forceRefresh: forceRefresh);
    } on AuthRetryableFetchException catch (error) {
      throw SocketException(error.message);
    } on AuthException catch (error) {
      throw TranslatorApiException(
        code: TranslatorErrorCode.unauthorized,
        statusCode: int.tryParse(error.statusCode ?? '') ?? 401,
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
    final path = await _writeAudio(bytes, language.code, mimeType);
    return TranslationResult(
      audioPath: path,
      language: language,
      sourceLanguageCode: json['sourceLanguage'] as String?,
      originalText: (json['originalText'] as String?)?.trim() ?? '',
      translatedText: (json['translatedText'] as String?)?.trim() ?? '',
      aiGenerated: json['aiGenerated'] as bool? ?? true,
    );
  }

  Future<String> _writeAudio(
    Uint8List bytes,
    String languageCode,
    String mimeType,
  ) async {
    final directory = await _outputDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${directory.path}/translated_${languageCode}_$stamp.${_extension(mimeType)}',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  String _extension(String mimeType) => switch (mimeType.toLowerCase()) {
    'audio/wav' || 'audio/x-wav' || 'audio/wave' => 'wav',
    'audio/ogg' || 'audio/opus' => 'ogg',
    'audio/aac' => 'aac',
    'audio/mp4' || 'audio/m4a' || 'audio/x-m4a' => 'm4a',
    _ => 'mp3',
  };

  void _logLanguagesOnce(String body) {
    if (_languagesLogged || !kDebugMode) return;
    _languagesLogged = true;
    debugPrint('GET /languages raw response: $body');
  }
}
