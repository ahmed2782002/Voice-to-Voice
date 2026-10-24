import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/network/dio_client.dart';
import 'core/services/audio/audio_player_service.dart';
import 'core/services/audio/device_audio_file_picker.dart';
import 'core/services/audio/device_audio_player_service.dart';
import 'core/services/audio/device_audio_recorder_service.dart';
import 'core/services/auth/supabase_session_service.dart';
import 'core/services/connectivity/device_connectivity_service.dart';
import 'core/services/preferences/preferences_ai_notice_store.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'feature/history/data/repo/file_translation_history_store.dart';
import 'feature/history/data/repo/translation_history_store.dart';
import 'feature/splash/presentation/view/screen/splash_screen.dart';
import 'feature/translator/data/repo/translator_repo.dart';
import 'feature/translator/presentation/view/screen/translator_screen.dart';
import 'feature/translator/presentation/view_model/translator_cubit.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  await EasyLocalization.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  final repo = TranslatorRepo(
    client: DioClient(
      tokens: SupabaseSessionService(Supabase.instance.client.auth),
      headers: const {'apikey': SupabaseConfig.publishableKey},
    ),
  );
  final history = FileTranslationHistoryStore();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('ar'),
      path: 'assets/translations',
      useOnlyLangCode: true,
      child: VoxBridgeApp(
        preferences: preferences,
        history: history,
        createPlayer: DeviceAudioPlayerService.new,
        createTranslatorCubit: () => TranslatorCubit(
          recorder: DeviceAudioRecorderService(),
          player: DeviceAudioPlayerService(),
          translate: repo.translateVoice,
          loadLanguages: repo.fetchLanguages,
          picker: DeviceAudioFilePicker(),
          saveToHistory: history.save,
          connectivity: DeviceConnectivityService(),
          aiNotice: PreferencesAiNoticeStore(preferences),
        ),
      ),
    ),
  );
  FlutterNativeSplash.remove();
}

class VoxBridgeApp extends StatelessWidget {
  const VoxBridgeApp({
    super.key,
    required this.preferences,
    required this.history,
    required this.createPlayer,
    required this.createTranslatorCubit,
  });

  final SharedPreferences preferences;
  final TranslationHistoryStore history;
  final CreateAudioPlayer createPlayer;
  final TranslatorCubit Function() createTranslatorCubit;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TranslationHistoryStore>.value(value: history),
        RepositoryProvider<CreateAudioPlayer>.value(value: createPlayer),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit(preferences)),
          BlocProvider(create: (_) => createTranslatorCubit()..loadLanguages()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          builder: (context, _) => BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) => MaterialApp(
              title: 'VoxBridge',
              debugShowCheckedModeBanner: false,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              builder: (context, child) => MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.6,
                child: child ?? const SizedBox.shrink(),
              ),
              home: SplashScreen(next: (_) => const TranslatorScreen()),
            ),
          ),
        ),
      ),
    );
  }
}
