import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/theme_cubit.dart';
import '../../utils/constants/app_icons.dart';
import '../../utils/constants/app_palette.dart';
import '../../utils/constants/app_strings.dart';
import 'settings_choice_card.dart';
import 'settings_sheet.dart';
import 'theme_preview.dart';

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
        Row(
          children: [
            for (final (index, (mode, palette, icon, label)) in const [
              (
                ThemeMode.dark,
                AppPalette.dark,
                AppIcons.darkMode,
                AppStrings.themeDark,
              ),
              (
                ThemeMode.light,
                AppPalette.light,
                AppIcons.lightMode,
                AppStrings.themeLight,
              ),
            ].indexed) ...[
              if (index > 0) SizedBox(width: 12.w),
              Expanded(
                child: SettingsChoiceCard(
                  key: Key('settings_theme_${mode.name}'),
                  preview: ThemePreview(palette: palette, icon: icon),
                  label: label.tr(),
                  selected: current == mode,
                  onTap: () {
                    cubit.select(mode);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
