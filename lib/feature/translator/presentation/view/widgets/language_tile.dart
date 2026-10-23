import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_decorations.dart';
import '../../../../../core/utils/constants/app_icons.dart';
import '../../../../../core/utils/constants/app_text.dart';
import '../../../data/model/translation_language.dart';

class LanguageTile extends StatelessWidget {
  const LanguageTile({
    super.key,
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final TranslationLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? context.colors.accent.withValues(alpha: 0.22)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.field.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.field.r),
        child: Container(
          constraints: BoxConstraints(minHeight: 52.h),
          padding: EdgeInsetsDirectional.symmetric(horizontal: 14.w),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(language.name, style: context.text.body),
                    if (language.nativeName != language.name)
                      Text(language.nativeName, style: context.text.caption),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  AppIcons.check,
                  size: 22.r,
                  color: context.colors.cyanBright,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
