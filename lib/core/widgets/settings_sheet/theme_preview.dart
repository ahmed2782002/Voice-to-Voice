import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/constants/app_decorations.dart';
import '../../utils/constants/app_palette.dart';

class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key, required this.palette, required this.icon});

  final AppPalette palette;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final bar = BorderRadius.circular(AppRadii.pill);
    return ExcludeSemantics(
      child: Container(
        height: 72.h,
        padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          gradient: palette.background,
          borderRadius: BorderRadius.circular(AppRadii.field.r),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: palette.mic,
              ),
              child: Icon(icon, size: 20.r, color: palette.onAction),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 7.h,
                    decoration: BoxDecoration(
                      color: palette.textPrimary.withValues(alpha: 0.85),
                      borderRadius: bar,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: Container(
                      height: 7.h,
                      decoration: BoxDecoration(
                        color: palette.textMuted,
                        borderRadius: bar,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
