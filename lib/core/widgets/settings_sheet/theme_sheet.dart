import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/theme_cubit.dart';
import '../../utils/constants/app_icons.dart';
import '../../utils/constants/app_strings.dart';
import 'settings_option_tile.dart';
import 'settings_sheet.dart';

class ThemeSheet extends StatelessWidget {
  const ThemeSheet({super.key});

  static Future<void> show(BuildContext context) =>
      SettingsSheet.open(context, const ThemeSheet());

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ThemeCubit>();
    final current = context.watch<ThemeCubit>().state;
    return SettingsSheet(
      icon: AppIcons.theme,
      title: AppStrings.appTheme.tr(),
      children: [
        for (final (mode, icon, label) in const [
          (ThemeMode.dark, AppIcons.darkMode, AppStrings.themeDark),
          (ThemeMode.light, AppIcons.lightMode, AppStrings.themeLight),
        ])
          SettingsOptionTile(
            key: Key('settings_theme_${mode.name}'),
            icon: icon,
            label: label.tr(),
            selected: current == mode,
            onTap: () {
              cubit.select(mode);
              Navigator.of(context).pop();
            },
          ),
      ],
    );
  }
}
