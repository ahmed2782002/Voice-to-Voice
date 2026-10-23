import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_icons.dart';
import '../../../../../core/utils/constants/app_strings.dart';

class ImportAudioButton extends StatelessWidget {
  const ImportAudioButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      label: AppStrings.importAudio.tr(),
      excludeSemantics: true,
      child: Tooltip(
        message: AppStrings.importAudio.tr(),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Material(
            color: colors.surface.withValues(alpha: 0.85),
            shape: CircleBorder(side: BorderSide(color: colors.border)),
            child: InkWell(
              key: const Key('translator_importButton'),
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox(
                width: 56.r,
                height: 56.r,
                child: Icon(
                  AppIcons.upload,
                  size: 26.r,
                  color: colors.cyanBright,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
