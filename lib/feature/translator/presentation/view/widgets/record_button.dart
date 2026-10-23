import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_icons.dart';
import '../../../../../core/utils/constants/app_strings.dart';

class RecordButton extends StatelessWidget {
  const RecordButton({
    super.key,
    required this.isRecording,
    required this.level,
    required this.onPressed,
  });

  final bool isRecording;
  final double level;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      label: isRecording
          ? AppStrings.stopRecording.tr()
          : AppStrings.startRecording.tr(),
      excludeSemantics: true,
      child: AnimatedScale(
        scale: isRecording ? 1 + level * 0.12 : 1,
        duration: const Duration(milliseconds: 120),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: GestureDetector(
            key: const Key('translator_recordButton'),
            onTap: onPressed,
            child: Container(
              width: 92.r,
              height: 92.r,
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      (isRecording
                              ? context.colors.recording
                              : context.colors.cyanBright)
                          .withValues(alpha: 0.6),
                  width: 2,
                ),
                boxShadow: enabled
                    ? isRecording
                          ? context.colors.micRecordingGlow
                          : context.colors.micGlow
                    : null,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isRecording
                      ? context.colors.micRecording
                      : context.colors.mic,
                ),
                child: Icon(
                  isRecording ? AppIcons.stop : AppIcons.mic,
                  size: 38.r,
                  color: context.colors.onAction,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
