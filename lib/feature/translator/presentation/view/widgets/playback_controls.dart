import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_icons.dart';
import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../core/utils/constants/app_text.dart';
import '../../../../../core/widgets/audio_control_button/audio_control_button.dart';

class PlaybackControls extends StatelessWidget {
  const PlaybackControls({
    super.key,
    required this.keyPrefix,
    required this.isPlaying,
    required this.progressLabel,
    required this.color,
    required this.onPlay,
    required this.onPause,
    required this.onReplay,
    this.title,
    this.trailing,
  });

  final String keyPrefix;
  final bool isPlaying;
  final String progressLabel;
  final Color color;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onReplay;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title ?? '',
                style: context.text.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8.w),
            Text(progressLabel, style: context.text.timer),
          ],
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            AudioControlButton(
              key: Key('${keyPrefix}_play'),
              icon: AppIcons.play,
              semanticLabel: AppStrings.play.tr(),
              color: color,
              onPressed: isPlaying ? null : onPlay,
            ),
            AudioControlButton(
              key: Key('${keyPrefix}_pause'),
              icon: AppIcons.pause,
              semanticLabel: AppStrings.pause.tr(),
              color: color,
              onPressed: isPlaying ? onPause : null,
            ),
            AudioControlButton(
              key: Key('${keyPrefix}_replay'),
              icon: AppIcons.replay,
              semanticLabel: AppStrings.replay.tr(),
              color: color,
              size: 22,
              onPressed: onReplay,
            ),
            const Spacer(),
            ?trailing,
          ],
        ),
      ],
    );
  }
}
