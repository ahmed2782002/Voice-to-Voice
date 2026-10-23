import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/constants/app_colors.dart';
import '../../utils/constants/app_decorations.dart';
import '../../utils/constants/app_icons.dart';
import '../../utils/constants/app_text.dart';

class SettingsOptionTile extends StatelessWidget {
  const SettingsOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 8.h),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected
              ? colors.cyanBright.withValues(alpha: 0.12)
              : colors.surfaceRaised.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadii.field.r),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.field.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: BoxConstraints(minHeight: 56.h),
              padding: EdgeInsetsDirectional.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.field.r),
                border: Border.all(
                  color: selected ? colors.cyanBright : colors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 22.r,
                    color: selected ? colors.cyanBright : colors.textSecondary,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(child: Text(label, style: context.text.body)),
                  Icon(
                    selected ? AppIcons.radioOn : AppIcons.radioOff,
                    size: 22.r,
                    color: selected ? colors.cyanBright : colors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
