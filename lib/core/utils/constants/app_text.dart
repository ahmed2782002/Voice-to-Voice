import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';
import 'app_palette.dart';

extension AppTextContext on BuildContext {
  AppText get text => AppText(colors);
}

class AppText {
  const AppText(this._colors);

  final AppPalette _colors;

  TextStyle get brand => TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: _colors.textPrimary,
  );

  TextStyle get display => TextStyle(
    fontSize: 30.sp,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: 0.5,
    color: _colors.textPrimary,
  );

  TextStyle get title => TextStyle(
    fontSize: 15.sp,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: _colors.textSecondary,
  );

  TextStyle get body => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: _colors.textPrimary,
  );

  TextStyle get label => TextStyle(
    fontSize: 13.sp,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: _colors.textSecondary,
  );

  TextStyle get caption => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: _colors.textMuted,
  );

  TextStyle get notice => TextStyle(
    fontSize: 13.sp,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: _colors.coralLight,
  );

  TextStyle get button => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: _colors.onAction,
  );

  TextStyle get timer => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: _colors.textSecondary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
