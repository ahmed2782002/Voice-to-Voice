import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/constants/app_colors.dart';
import '../../utils/constants/app_flags.dart';
import '../../utils/constants/app_icons.dart';
import '../../utils/constants/app_strings.dart';
import '../../utils/constants/app_text.dart';
import 'settings_choice_card.dart';
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
        Row(
          children: [
            for (final (index, (code, flag, label)) in const [
              ('ar', AppFlags.arabic, AppStrings.languageArabic),
              ('en', AppFlags.english, AppStrings.languageEnglish),
            ].indexed) ...[
              if (index > 0) SizedBox(width: 12.w),
              Expanded(
                child: SettingsChoiceCard(
                  key: Key('settings_language_$code'),
                  preview: Container(
                    width: 64.r,
                    height: 64.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.surface,
                      border: Border.all(color: context.colors.border),
                      boxShadow: current == code
                          ? context.colors.micGlow
                          : null,
                    ),
                    child: Text(
                      flag,
                      style: context.text.display.copyWith(
                        fontSize: 34.sp,
                        height: 1,
                      ),
                    ),
                  ),
                  label: label.tr(),
                  selected: current == code,
                  onTap: () {
                    context.setLocale(Locale(code));
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
