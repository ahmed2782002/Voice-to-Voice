import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/constants/app_colors.dart';
import '../../utils/constants/app_decorations.dart';
import '../../utils/constants/app_icons.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 36, this.glow = false});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final extent = size.r;
    return Container(
      width: extent,
      height: extent,
      decoration: BoxDecoration(
        gradient: colors.mic,
        borderRadius: BorderRadius.circular(extent * AppRadii.logo),
        boxShadow: glow ? colors.logoGlow : null,
      ),
      child: Icon(AppIcons.mic, size: extent * 0.6, color: colors.onAction),
    );
  }
}
