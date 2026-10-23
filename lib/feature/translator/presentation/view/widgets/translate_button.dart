import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_decorations.dart';
import '../../../../../core/utils/constants/app_icons.dart';
import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../core/utils/constants/app_text.dart';

class TranslateButton extends StatelessWidget {
  const TranslateButton({
    super.key,
    required this.isProcessing,
    required this.onPressed,
  });

  final bool isProcessing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isProcessing;
    return Column(
      children: [
        Opacity(
          opacity: enabled || isProcessing ? 1 : 0.4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: context.colors.action,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              boxShadow: enabled ? context.colors.actionGlow : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: const Key('translator_translateButton'),
                onTap: enabled ? onPressed : null,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: 56.h),
                  alignment: Alignment.center,
                  padding: EdgeInsetsDirectional.symmetric(vertical: 12.h),
                  child: Text(
                    isProcessing
                        ? AppStrings.translating.tr()
                        : AppStrings.translateVoice.tr(),
                    style: context.text.button,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.lock, size: 14.r, color: context.colors.textMuted),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                AppStrings.privacyNotice.tr(),
                style: context.text.caption,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
