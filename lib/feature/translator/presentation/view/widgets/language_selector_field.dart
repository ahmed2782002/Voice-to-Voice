import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_decorations.dart';
import '../../../../../core/utils/constants/app_icons.dart';
import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../core/utils/constants/app_text.dart';
import '../../../data/model/translation_language.dart';

class LanguageSelectorField extends StatelessWidget {
  const LanguageSelectorField({
    super.key,
    required this.language,
    required this.onTap,
    this.statusLabel,
  });

  final TranslationLanguage language;
  final VoidCallback? onTap;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.targetLanguageTitle.tr(), style: context.text.title),
        SizedBox(height: 8.h),
        Material(
          color: context.colors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadii.field.r),
          child: InkWell(
            key: const Key('translator_languageSelector'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.field.r),
            child: Container(
              constraints: BoxConstraints(minHeight: 54.h),
              padding: EdgeInsetsDirectional.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.field.r),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      statusLabel ?? language.displayName,
                      style: context.text.body.copyWith(fontSize: 15.sp),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    AppIcons.chevronDown,
                    size: 24.r,
                    color: context.colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
