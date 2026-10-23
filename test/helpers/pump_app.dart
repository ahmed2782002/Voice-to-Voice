import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_to_voice/core/theme/app_theme.dart';
import 'package:voice_to_voice/core/theme/theme_cubit.dart';
import 'package:voice_to_voice/feature/translator/presentation/view/screen/translator_screen.dart';
import 'package:voice_to_voice/feature/translator/presentation/view_model/translator_cubit.dart';

extension PumpApp on WidgetTester {
  Future<ThemeCubit> pumpShell(
    Widget home, {
    TranslatorCubit? cubit,
    ThemeCubit? themeCubit,
    Locale locale = const Locale('en'),
    Size size = const Size(390, 844),
  }) async {
    rootBundle.clear();
    view.physicalSize = size;
    view.devicePixelRatio = 1;
    addTearDown(view.reset);
    if (cubit != null) addTearDown(cubit.close);
    final theme = themeCubit ?? await _themeCubit();
    addTearDown(theme.close);
    await runAsync(
      () => pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          fallbackLocale: const Locale('en'),
          startLocale: locale,
          saveLocale: false,
          useOnlyLangCode: true,
          path: 'assets/translations',
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: theme),
              if (cubit != null) BlocProvider.value(value: cubit),
            ],
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (context, _) => BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, mode) => MaterialApp(
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  locale: context.locale,
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  themeMode: mode,
                  home: home,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    for (var attempt = 0; attempt < 20; attempt++) {
      await runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await pump();
      if (any(find.byType(Scaffold))) break;
    }
    return theme;
  }

  Future<ThemeCubit> pumpTranslator(
    TranslatorCubit cubit, {
    ThemeCubit? themeCubit,
    Locale locale = const Locale('en'),
    Size size = const Size(390, 844),
  }) => pumpShell(
    const TranslatorScreen(),
    cubit: cubit,
    themeCubit: themeCubit,
    locale: locale,
    size: size,
  );

  Future<ThemeCubit> _themeCubit() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    return ThemeCubit(preferences);
  }
}
