import 'package:flutter/material.dart';

import 'app_palette.dart';

extension AppColors on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
