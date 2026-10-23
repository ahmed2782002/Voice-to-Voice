import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/services/audio/audio_limits.dart';
import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_icons.dart';
import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../core/utils/constants/app_text.dart';
import '../../../../../core/utils/format/duration_format.dart';
import '../../../../../core/widgets/audio_control_button/audio_control_button.dart';
import '../../../../../core/widgets/glass_card/glass_card.dart';
import '../../../../../core/widgets/waveform/audio_waveform.dart';
import '../../view_model/translator_state.dart';
import 'playback_controls.dart';

class SourceAudioCard extends StatelessWidget {
  const SourceAudioCard({
    super.key,
    required this.state,
    required this.onPlay,
    required this.onPause,
    required this.onReplay,
    required this.onDiscard,
  });

  final TranslatorState state;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReplay;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final language = context.locale.languageCode;
    const track = AudioTrack.source;
    final locked = state.isProcessing;
    return GlassCard(
      key: const Key('translator_sourceCard'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.sourceAudioTitle.tr(),
                  style: context.text.title,
                ),
              ),
              if (state.isRecording)
                Text(
                  DurationFormat.clock(state.recordElapsed, language),
                  key: const Key('translator_recordTimer'),
                  style: context.text.timer.copyWith(
                    color: context.colors.recording,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          if (state.isRecording || state.hasSource)
            AudioWaveform(
              levels: state.isRecording
                  ? state.recordingBars
                  : state.sourceLevels,
              progress: state.isRecording ? 1 : state.progressOf(track),
              activeColor: state.isRecording
                  ? context.colors.recording
                  : context.colors.accentLight,
              inactiveColor: context.colors.textMuted.withValues(alpha: 0.6),
            ),
          if (state.isRecording) ...[
            SizedBox(height: 10.h),
            Text(AppStrings.recordingNow.tr(), style: context.text.label),
          ] else if (state.hasSource) ...[
            SizedBox(height: 8.h),
            PlaybackControls(
              keyPrefix: 'translator_source',
              title: AppStrings.originalVoice.tr(),
              isPlaying: state.isPlayingTrack(track),
              progressLabel: DurationFormat.progress(
                state.positionOf(track),
                state.durationOf(track),
                language,
              ),
              color: context.colors.textPrimary,
              onPlay: locked ? null : onPlay,
              onPause: onPause,
              onReplay: locked ? null : onReplay,
              trailing: AudioControlButton(
                key: const Key('translator_source_discard'),
                icon: AppIcons.delete,
                semanticLabel: AppStrings.discardRecording.tr(),
                size: 22,
                onPressed: locked ? null : onDiscard,
              ),
            ),
          ] else ...[
            Text(AppStrings.sourceEmptyHint.tr(), style: context.text.body),
            SizedBox(height: 6.h),
            Text(
              AppStrings.recordingLimitHint.tr(
                args: [
                  DurationFormat.clock(AudioLimits.maxRecording, language),
                ],
              ),
              style: context.text.caption,
            ),
            Text(AppStrings.anyLanguageHint.tr(), style: context.text.caption),
          ],
        ],
      ),
    );
  }
}
