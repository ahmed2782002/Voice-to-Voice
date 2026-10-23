import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/constants/app_colors.dart';

class AudioControlButton extends StatelessWidget {
  const AudioControlButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.color,
    this.size = 26,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.colors.textSecondary;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: size.r),
        color: tint,
        disabledColor: tint.withValues(alpha: 0.35),
        constraints: BoxConstraints(minWidth: 44.r, minHeight: 44.r),
        padding: EdgeInsets.zero,
        tooltip: semanticLabel,
      ),
    );
  }
}
