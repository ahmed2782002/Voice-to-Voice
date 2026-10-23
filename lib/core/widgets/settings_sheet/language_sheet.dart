import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../utils/constants/app_icons.dart';
import '../../utils/constants/app_strings.dart';
import 'settings_option_tile.dart';
import 'settings_sheet.dart';

class LanguageSheet extends StatelessWidget {
  const LanguageSheet({super.key});

  static Future<void> show(BuildContext context) =>
      SettingsSheet.open(context, const LanguageSheet());

  @override
  Widget build(BuildContext context) {
    final current = context.locale.languageCode;
    return SettingsSheet(
      icon: AppIcons.language,
      title: AppStrings.appLanguage.tr(),
      children: [
        for (final (code, label) in const [
          ('ar', AppStrings.languageArabic),
          ('en', AppStrings.languageEnglish),
        ])
          SettingsOptionTile(
            key: Key('settings_language_$code'),
            icon: AppIcons.language,
            label: label.tr(),
            selected: current == code,
            onTap: () {
              context.setLocale(Locale(code));
              Navigator.of(context).pop();
            },
          ),
      ],
    );
  }
}
