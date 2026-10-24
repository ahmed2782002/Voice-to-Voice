import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_icons.dart';
import '../../../../../core/utils/constants/app_strings.dart';

class CaptureControls extends StatelessWidget {
  const CaptureControls({
    super.key,
    required this.isRecording,
    required this.level,
    required this.onRecord,
    required this.onImport,
  });

  final bool isRecording;
  final double level;
  final VoidCallback? onRecord;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canRecord = onRecord != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 56.r),
        SizedBox(width: 20.w),
        Semantics(
          button: true,
          label: isRecording
              ? AppStrings.stopRecording.tr()
              : AppStrings.startRecording.tr(),
          excludeSemantics: true,
          child: AnimatedScale(
            scale: isRecording ? 1 + level * 0.12 : 1,
            duration: const Duration(milliseconds: 120),
            child: Opacity(
              opacity: canRecord ? 1 : 0.4,
              child: GestureDetector(
                key: const Key('translator_recordButton'),
                onTap: onRecord,
                child: Container(
                  width: 92.r,
                  height: 92.r,
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          (isRecording ? colors.recording : colors.cyanBright)
                              .withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: canRecord
                        ? isRecording
                              ? colors.micRecordingGlow
                              : colors.micGlow
                        : null,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isRecording ? colors.micRecording : colors.mic,
                    ),
                    child: Icon(
                      isRecording ? AppIcons.stop : AppIcons.mic,
                      size: 38.r,
                      color: colors.onAction,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 20.w),
        Semantics(
          button: true,
          label: AppStrings.importAudio.tr(),
          excludeSemantics: true,
          child: Tooltip(
            message: AppStrings.importAudio.tr(),
            child: Opacity(
              opacity: onImport != null ? 1 : 0.4,
              child: Material(
                color: colors.surface.withValues(alpha: 0.85),
                shape: CircleBorder(side: BorderSide(color: colors.border)),
                child: InkWell(
                  key: const Key('translator_importButton'),
                  customBorder: const CircleBorder(),
                  onTap: onImport,
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
        ),
      ],
    );
  }
}
