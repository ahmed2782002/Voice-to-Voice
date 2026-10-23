import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_icons.dart';
import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../core/utils/constants/app_text.dart';
import '../../../../../core/widgets/audio_control_button/audio_control_button.dart';

class HistoryHeader extends StatelessWidget {
  const HistoryHeader({super.key, required this.onBack, required this.onClear});

  final VoidCallback onBack;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(8.w, 8.h, 8.w, 4.h),
      child: Row(
        children: [
          AudioControlButton(
            key: const Key('history_back'),
            icon: AppIcons.back,
            semanticLabel: AppStrings.back.tr(),
            color: context.colors.textPrimary,
            onPressed: onBack,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(AppStrings.history.tr(), style: context.text.brand),
          ),
          AudioControlButton(
            key: const Key('history_clear'),
            icon: AppIcons.deleteAll,
            semanticLabel: AppStrings.clearHistory.tr(),
            color: context.colors.error,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
