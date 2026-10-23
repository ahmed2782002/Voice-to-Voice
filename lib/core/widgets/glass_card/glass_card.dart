import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/constants/app_colors.dart';
import '../../utils/constants/app_decorations.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.gradient,
    this.color,
    this.borderColor,
    this.padding,
  });

  final Widget child;
  final Gradient? gradient;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsetsDirectional.all(16.r),
      decoration: BoxDecoration(
        color: gradient == null
            ? (color ?? context.colors.surface).withValues(alpha: 0.72)
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadii.card.r),
        border: Border.all(
          color: (borderColor ?? context.colors.border).withValues(alpha: 0.8),
        ),
        boxShadow: context.colors.cardShadow,
      ),
      child: child,
    );
  }
}
