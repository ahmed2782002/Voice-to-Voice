import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/constants/app_colors.dart';
import '../../utils/constants/app_decorations.dart';
import '../../utils/constants/app_icons.dart';
import '../../utils/constants/app_text.dart';

class SettingsChoiceCard extends StatelessWidget {
  const SettingsChoiceCard({
    super.key,
    required this.preview,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Widget preview;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppRadii.field.r);
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: selected ? 1 : 0.96,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Material(
          color: selected
              ? colors.cyanBright.withValues(alpha: 0.1)
              : colors.surfaceRaised.withValues(alpha: 0.6),
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsetsDirectional.fromSTEB(12.w, 14.h, 12.w, 12.h),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: selected ? colors.cyanBright : colors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: preview),
                      SizedBox(height: 12.h),
                      Text(
                        label,
                        style: context.text.body.copyWith(
                          color: selected
                              ? colors.textPrimary
                              : colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 22.r,
                        height: 22.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: colors.mic,
                        ),
                        child: Icon(
                          AppIcons.check,
                          size: 14.r,
                          color: colors.onAction,
                        ),
                      ),
                    ),
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
