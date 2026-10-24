import '../config/supabase_config.dart';

abstract final class Endpoints {
  static const String baseUrl = '${SupabaseConfig.functionsUrl}/';
  static const String languages = 'languages';
  static const String translateVoice = 'translate-voice';
}
