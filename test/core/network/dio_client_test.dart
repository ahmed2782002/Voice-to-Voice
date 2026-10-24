import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, AuthRetryableFetchException;
import 'package:voice_to_voice/core/network/dio_client.dart';
import 'package:voice_to_voice/core/network/network_exception.dart';
import 'package:voice_to_voice/core/services/auth/access_token_provider.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fakes.dart';

void main() {
  const retryDelays = [Duration.zero, Duration.zero, Duration.zero];
  late FakeHttpAdapter adapter;

  DioClient buildClient(
    List<Object> replies, {
    AccessTokenProvider? tokens,
    List<Duration> delays = retryDelays,
  }) {
    adapter = FakeHttpAdapter(replies);
    return DioClient(
      tokens: tokens ?? FakeAccessTokenProvider(),
      baseUrl: 'https://api.test/v1/',
      headers: const {'apikey': 'publishable'},
      adapter: adapter,
      retryDelays: delays,
    );
  }

  FormData audioForm() => FormData.fromMap({
    'targetLanguage': 'en',
    'audio': MultipartFile.fromBytes(List.filled(16, 1), filename: 'a.m4a'),
  });

  Matcher httpStatus(int statusCode) => throwsA(
    isA<HttpStatusException>().having(
      (error) => error.statusCode,
      'statusCode',
      statusCode,
    ),
  );

  group('DioClient', () {
    group('get', () {
      test('decodes the JSON body and sends the default headers', () async {
        final client = buildClient([
          FakeHttpAdapter.json({'ok': true}, 200),
        ]);

        final json = await client.get('languages');

        final options = adapter.requests.single.options;
        expect(json, {'ok': true});
        expect(options.uri.toString(), 'https://api.test/v1/languages');
        expect(options.headers['Authorization'], 'Bearer user-jwt-0');
        expect(options.headers['apikey'], 'publishable');
        expect(options.connectTimeout, const Duration(seconds: 10));
        expect(options.receiveTimeout, const Duration(seconds: 30));
      });

      test('throws a FormatException for an empty body', () async {
        final client = buildClient([FakeHttpAdapter.text('  ', 200)]);

        await expectLater(client.get('languages'), throwsFormatException);
      });

      test('throws an HttpStatusException with the raw body', () async {
        final client = buildClient([FakeHttpAdapter.text('missing', 404)]);

        await expectLater(
          client.get('languages'),
          throwsA(
            isA<HttpStatusException>()
                .having((error) => error.statusCode, 'statusCode', 404)
                .having((error) => error.body, 'body', 'missing'),
          ),
        );
        expect(adapter.requests, hasLength(1));
      });

      test('retries 502, 503 and 504 until it succeeds', () async {
        final client = buildClient([
          FakeHttpAdapter.text('bad gateway', 502),
          FakeHttpAdapter.text('unavailable', 503),
          FakeHttpAdapter.text('timeout', 504),
          FakeHttpAdapter.json([1], 200),
        ]);

        final json = await client.get('languages');

        expect(json, [1]);
        expect(adapter.requests, hasLength(4));
      });

      test('stops after the last backoff delay', () async {
        final client = buildClient([
          FakeHttpAdapter.text('down', 503),
          FakeHttpAdapter.text('down', 503),
          FakeHttpAdapter.text('down', 503),
          FakeHttpAdapter.text('down', 503),
        ]);

        await expectLater(client.get('languages'), httpStatus(503));
        expect(adapter.requests, hasLength(4));
      });

      test('retries a connection error once the network is back', () async {
        final client = buildClient([
          DioExceptionType.connectionError,
          FakeHttpAdapter.json([1], 200),
        ]);

        expect(await client.get('languages'), [1]);
        expect(adapter.requests, hasLength(2));
      });

      test('maps an offline request to NoConnectionException', () async {
        final client = buildClient([
          DioExceptionType.connectionError,
        ], delays: const []);

        await expectLater(
          client.get('languages'),
          throwsA(isA<NoConnectionException>()),
        );
      });

      test('maps a receive timeout to RequestTimeoutException', () async {
        final client = buildClient([
          DioExceptionType.receiveTimeout,
        ], delays: const []);

        await expectLater(
          client.get('languages'),
          throwsA(isA<RequestTimeoutException>()),
        );
      });
    });

    group('upload', () {
      test('never retries a failed upload', () async {
        final client = buildClient([FakeHttpAdapter.text('down', 503)]);

        await expectLater(
          client.upload('translate-voice', audioForm()),
          httpStatus(503),
        );
        expect(adapter.requests, hasLength(1));
      });

      test('uses the long upload timeouts', () async {
        final client = buildClient([
          FakeHttpAdapter.json({'ok': true}, 200),
        ]);

        await client.upload('translate-voice', audioForm());

        final options = adapter.requests.single.options;
        expect(options.sendTimeout, const Duration(seconds: 120));
        expect(options.receiveTimeout, const Duration(seconds: 90));
      });
    });

    group('auth', () {
      test('replays an upload with a fresh token after a 401', () async {
        final tokens = FakeAccessTokenProvider();
        final client = buildClient([
          FakeHttpAdapter.text('expired', 401),
          FakeHttpAdapter.json({'ok': true}, 200),
        ], tokens: tokens);

        await client.upload('translate-voice', audioForm());

        expect(tokens.requests, [false, true]);
        expect(
          adapter.requests.last.options.headers['Authorization'],
          'Bearer user-jwt-1',
        );
        expect(adapter.requests.last.body, contains('filename="a.m4a"'));
      });

      test('refreshes only once when the 401 repeats', () async {
        final tokens = FakeAccessTokenProvider();
        final client = buildClient([
          FakeHttpAdapter.text('expired', 401),
          FakeHttpAdapter.text('expired', 401),
        ], tokens: tokens);

        await expectLater(client.get('languages'), httpStatus(401));
        expect(tokens.requests, [false, true]);
        expect(adapter.requests, hasLength(2));
      });

      test('does not refresh the session on a 403', () async {
        final tokens = FakeAccessTokenProvider();
        final client = buildClient([
          FakeHttpAdapter.text('forbidden', 403),
        ], tokens: tokens);

        await expectLater(client.get('languages'), httpStatus(403));
        expect(tokens.requests, [false]);
      });

      test('maps a sign-in failure to SessionException', () async {
        final client = buildClient(
          [],
          tokens: FailingAccessTokenProvider(
            const AuthException('disabled', statusCode: '422'),
          ),
        );

        await expectLater(
          client.get('languages'),
          throwsA(
            isA<SessionException>()
                .having((error) => error.statusCode, 'statusCode', 422)
                .having((error) => error.message, 'message', 'disabled'),
          ),
        );
        expect(adapter.requests, isEmpty);
      });

      test(
        'maps an unreachable auth server to NoConnectionException',
        () async {
          final client = buildClient(
            [],
            tokens: FailingAccessTokenProvider(
              AuthRetryableFetchException(message: 'offline'),
            ),
            delays: const [],
          );

          await expectLater(
            client.get('languages'),
            throwsA(isA<NoConnectionException>()),
          );
        },
      );
    });
  });
}
