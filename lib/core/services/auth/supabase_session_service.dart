import 'package:supabase_flutter/supabase_flutter.dart';

import 'access_token_provider.dart';

class SupabaseSessionService implements AccessTokenProvider {
  SupabaseSessionService(this._auth);

  final GoTrueClient _auth;
  Future<String>? _pending;

  @override
  Future<String> accessToken({bool forceRefresh = false}) =>
      _pending ??= _resolve(forceRefresh).whenComplete(() => _pending = null);

  Future<String> _resolve(bool forceRefresh) async {
    final session = _auth.currentSession;
    if (session == null) return _signInAnonymously();
    if (!forceRefresh && !session.isExpired) return session.accessToken;
    final refreshed = await _refresh();
    return refreshed ?? await _signInAnonymously();
  }

  Future<String?> _refresh() async {
    try {
      final response = await _auth.refreshSession();
      return response.session?.accessToken;
    } on AuthRetryableFetchException {
      rethrow;
    } on AuthException {
      return null;
    }
  }

  Future<String> _signInAnonymously() async {
    final response = await _auth.signInAnonymously();
    final token = response.session?.accessToken;
    if (token == null) {
      throw const AuthException('Anonymous sign-in returned no session');
    }
    return token;
  }
}
