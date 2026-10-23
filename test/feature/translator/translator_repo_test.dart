import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:voice_to_voice/core/config/supabase_config.dart';
import 'package:voice_to_voice/feature/translator/data/model/translation_language.dart';
import 'package:voice_to_voice/feature/translator/data/model/translator_api_exception.dart';
import 'package:voice_to_voice/feature/translator/data/repo/translator_repo.dart';

import '../../helpers/fakes.dart';

void main() {
  late Directory directory;
  late FakeAccessTokenProvider session;
  late List<http.Request> requests;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('translator_repo_test');
    session = FakeAccessTokenProvider();
    requests = [];
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  TranslatorRepo buildRepo(List<http.Response> responses) {
    final queue = [...responses];
    return TranslatorRepo(
      client: MockClient((request) async {
        requests.add(request);
        return queue.removeAt(0);
      }),
      session: session,
      outputDirectory: () async => directory,
    );
  }

  http.Response json(Object body, int status) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  Future<String> sourceFile(int bytes) async {
    final file = File('${directory.path}/source.m4a');
    await file.writeAsBytes(List.filled(bytes, 1));
    return file.path;
  }

  group('TranslatorRepo', () {
    group('fetchLanguages', () {
      final shapes = <String, Object>{
        'a bare list': [
          {'code': 'ar', 'name': 'Arabic'},
          {'code': 'en', 'name': 'English', 'output': true},
          {'code': 'xx', 'name': 'Input only', 'output': false},
        ],
        'a languages object': {
          'languages': [
            {'code': 'ar', 'name': 'Arabic'},
            {'code': 'en', 'name': 'English'},
            {'code': 'xx', 'name': 'Input only', 'output': false},
          ],
        },
        'a data object': {
          'data': [
            {'code': 'ar', 'name': 'Arabic', 'input': false},
            {'code': 'en', 'name': 'English'},
            {'code': 'xx', 'output': false},
          ],
        },
        'a source object': {
          'source': [
            {'code': 'ar', 'name': 'Arabic', 'native': 'العربية'},
            {'code': 'en', 'name': 'English', 'input': true, 'output': true},
            {'code': 'xx', 'name': 'Input only', 'output': false},
          ],
        },
        'source and target objects': {
          'source': [
            {'code': 'xx', 'name': 'Input only', 'output': false},
          ],
          'target': [
            {'code': 'ar', 'name': 'Arabic', 'output': true},
            {'code': 'en', 'name': 'English', 'output': true},
          ],
        },
      };

      test('reads the native name from the native key', () async {
        final repo = buildRepo([
          json({
            'source': [
              {
                'code': 'ar',
                'name': 'Arabic',
                'native': 'العربية',
                'input': true,
                'output': true,
              },
            ],
          }, 200),
        ]);

        final languages = await repo.fetchLanguages();

        expect(languages.single.nativeName, 'العربية');
        expect(languages.single.displayName, 'Arabic - العربية');
      });

      for (final MapEntry(key: shape, value: body) in shapes.entries) {
        test('parses $shape and keeps only output languages', () async {
          final repo = buildRepo([json(body, 200)]);

          final languages = await repo.fetchLanguages();

          expect(languages.map((language) => language.code), ['ar', 'en']);
        });
      }

      test('sends the user token and the publishable key', () async {
        final repo = buildRepo([
          json([
            {'code': 'en', 'name': 'English'},
          ], 200),
        ]);

        await repo.fetchLanguages();

        final headers = requests.single.headers;
        expect(headers['Authorization'], 'Bearer user-jwt-0');
        expect(headers['apikey'], SupabaseConfig.publishableKey);
        expect(
          requests.single.url.toString(),
          '${SupabaseConfig.functionsUrl}/languages',
        );
      });

      test('refreshes the session once after a 401', () async {
        final repo = buildRepo([
          json({
            'error': {'code': 'UNAUTHORIZED', 'message': 'expired'},
          }, 401),
          json([
            {'code': 'en', 'name': 'English'},
          ], 200),
        ]);

        await repo.fetchLanguages();

        expect(session.requests, [false, true]);
        expect(requests.last.headers['Authorization'], 'Bearer user-jwt-1');
      });

      test('throws a FormatException for an unexpected body', () async {
        final repo = buildRepo([
          json({'unexpected': true}, 200),
        ]);

        expect(repo.fetchLanguages(), throwsA(isA<FormatException>()));
      });
    });

    group('translateVoice', () {
      final audio = base64Encode(List.filled(64, 7));

      test('uploads the recording and saves the translated audio', () async {
        final repo = buildRepo([
          json({
            'sourceLanguage': 'ar',
            'targetLanguage': 'en',
            'originalText': ' مرحبا ',
            'translatedText': 'Hello',
            'audio': {'mimeType': 'audio/mpeg', 'base64': audio},
            'aiGenerated': true,
          }, 200),
        ]);
        final path = await sourceFile(4096);

        final result = await repo.translateVoice(
          sourcePath: path,
          language: const TranslationLanguage(code: 'en', name: 'English'),
        );

        final request = requests.single;
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/translate-voice'));
        expect(request.headers['content-type'], startsWith('multipart/'));
        expect(request.body, contains('name="targetLanguage"'));
        expect(
          request.body,
          contains('name="audio"; filename="recording.m4a"'),
        );
        expect(request.body, isNot(contains('sourceLanguage')));
        expect(result.originalText, 'مرحبا');
        expect(result.translatedText, 'Hello');
        expect(result.sourceLanguageCode, 'ar');
        expect(result.audioPath, endsWith('.mp3'));
        expect(await File(result.audioPath).readAsBytes(), hasLength(64));
      });

      test(
        'rejects a recording under 2 KB without calling the server',
        () async {
          final repo = buildRepo([]);
          final path = await sourceFile(2047);

          await expectLater(
            repo.translateVoice(
              sourcePath: path,
              language: TranslationLanguage.arabic,
            ),
            throwsA(
              isA<TranslatorApiException>().having(
                (error) => error.code,
                'code',
                TranslatorErrorCode.emptyRecording,
              ),
            ),
          );
          expect(requests, isEmpty);
        },
      );

      test('maps a nested error body to a typed exception', () async {
        final repo = buildRepo([
          json({
            'error': {'code': 'RATE_LIMITED', 'message': 'Slow down'},
          }, 429),
        ]);
        final path = await sourceFile(4096);

        await expectLater(
          repo.translateVoice(
            sourcePath: path,
            language: TranslationLanguage.arabic,
          ),
          throwsA(
            isA<TranslatorApiException>()
                .having(
                  (error) => error.code,
                  'code',
                  TranslatorErrorCode.rateLimited,
                )
                .having((error) => error.retryable, 'retryable', isTrue)
                .having((error) => error.message, 'message', 'Slow down'),
          ),
        );
      });

      test(
        'maps a flat error body and falls back to the status code',
        () async {
          final repo = buildRepo([
            json({'code': 'NO_SPEECH', 'message': 'Nothing heard'}, 422),
            http.Response('gateway down', 504),
          ]);
          final path = await sourceFile(4096);

          final first = repo.translateVoice(
            sourcePath: path,
            language: TranslationLanguage.arabic,
          );
          await expectLater(
            first,
            throwsA(
              isA<TranslatorApiException>().having(
                (error) => error.code,
                'code',
                TranslatorErrorCode.noSpeech,
              ),
            ),
          );
          await expectLater(
            repo.translateVoice(
              sourcePath: path,
              language: TranslationLanguage.arabic,
            ),
            throwsA(
              isA<TranslatorApiException>()
                  .having(
                    (error) => error.code,
                    'code',
                    TranslatorErrorCode.upstreamTimeout,
                  )
                  .having((error) => error.retryable, 'retryable', isTrue),
            ),
          );
        },
      );
    });
  });
}
