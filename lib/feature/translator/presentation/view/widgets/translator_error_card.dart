import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_decorations.dart';
import '../../../../../core/utils/constants/app_icons.dart';
import '../../../../../core/utils/constants/app_text.dart';
import '../../../../../core/widgets/glass_card/glass_card.dart';

class TranslatorErrorCard extends StatelessWidget {
  const TranslatorErrorCard({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: GlassCard(
        key: const Key('translator_errorCard'),
        color: context.colors.errorSurface,
        borderColor: context.colors.error.withValues(alpha: 0.6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.error, size: 22.r, color: context.colors.error),
                SizedBox(width: 10.w),
                Expanded(child: Text(message, style: context.text.body)),
              ],
            ),
            SizedBox(height: 12.h),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlinedButton(
                key: const Key('translator_errorAction'),
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.textPrimary,
                  minimumSize: Size(44.r, 44.r),
                  side: BorderSide(color: context.colors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: context.text.label.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
