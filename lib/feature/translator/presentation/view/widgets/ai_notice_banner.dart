import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_decorations.dart';
import '../../../../../core/utils/constants/app_icons.dart';
import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../core/utils/constants/app_text.dart';

class AiNoticeBanner extends StatelessWidget {
  const AiNoticeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: 14.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: context.colors.coralSurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadii.field.r),
        border: Border.all(color: context.colors.coral.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.warning, size: 20.r, color: context.colors.coral),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(AppStrings.aiNotice.tr(), style: context.text.notice),
          ),
        ],
      ),
    );
  }
}
