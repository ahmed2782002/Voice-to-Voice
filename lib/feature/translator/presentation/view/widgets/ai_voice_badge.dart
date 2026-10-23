import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_decorations.dart';
import '../../../../../core/utils/constants/app_icons.dart';
import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../core/utils/constants/app_text.dart';

class AiVoiceBadge extends StatelessWidget {
  const AiVoiceBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      key: const Key('translator_aiVoiceBadge'),
      padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: colors.coralSurface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: colors.coral.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.aiVoice, size: 13.r, color: colors.coral),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              AppStrings.aiVoiceLabel.tr(),
              style: context.text.caption.copyWith(color: colors.coralLight),
            ),
          ),
        ],
      ),
    );
  }
}
